//
//  CUERules.swift
//  CodeHighlighting
//
//  The regex rule table for CUE.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// CUE: `//` comments (CUE has no block comment), `"…"` strings and `'…'` bytes, `"""…"""` and `'''…'''`
/// multi-line forms, raw `#"…"#` strings of any hash count (an inner `"` ends nothing), the keywords and
/// operator words, `@attr(…)` attributes, `#Definition` names, the built-in types, and numbers. A string's
/// `\(expr)` holes (`\#(expr)` in a raw one) stay code.
extension RuleTables {
    static let cue: [(String, TokenKind)] =
        [
            lineComment,
            ("(##+)\"\"\"[\\s\\S]*?\"\"\"\\1", .string),
            ("(#+)'''[\\s\\S]*?'''\\1", .string),
            ("(##+)\"[^\\n]*?\"\\1", .string),
            ("(#+)'[^\\n]*?'\\1", .string),
            ("'''[\\s\\S]*?'''", .string),
            ("'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ]
        // One tail rule finds the tails of both one-line forms, a raw string's after a `\#( … )`.
        + interpolatedStringPieces(
            [
                InterpolatedStringForm(
                    open: "#\"(?!\"\")", close: "\"#", literal: "[^\"\\\\\\n]|\"(?!#)|\\\\(?!#\\()", hole: "\\\\#" + cueHoleBody,
                    holeOpen: "\\\\#\\(", afterHole: "(?<=\\\\#\\([^\\n]{0,80}\\))"),
                InterpolatedStringForm(
                    open: "\"(?!\"\")", close: "\"", literal: "[^\"\\\\\\n]|\\\\[^(\\n]", hole: "\\\\" + cueHoleBody, holeOpen: "\\\\\\("),
            ], holeClose: "\\)", afterHole: cueAfterHole, skip: cueSkip + [cueTriple])
        + interpolatedStringPieces(
            open: "\"\"\"", close: "\"\"\"", literal: "[^\"\\\\\\n]|\"(?!\"\")|\\\\[^(\\n]", hole: "\\\\" + cueHoleBody,
            holeOpen: "\\\\\\(", holeClose: "\\)", afterHole: cueAfterHole, multiline: true,
            skip: cueSkip + ["#\"(?:[^\"\\n]|\"(?!#))*\"#", "\"(?!\"\")(?:[^\"\\\\\\n]|\\\\.)*\""])
        + [
            callee,
            keywords(["package", "import", "for", "in", "if", "let", "div", "mod", "quo", "rem"]),
            ("@[A-Za-z_]\\w*(?:\\([^)\\n]*\\))?", .attribute),
            ("#[A-Za-z_]\\w*", .type),
            types([
                "string", "int", "float", "bool", "bytes", "number", "null", "uint", "int8", "int16", "int32", "int64", "uint8",
                "uint16", "uint32", "uint64", "float32", "float64", "rune",
            ]),
            constants(["true", "false", "null"]),
            ("_\\|_", .keyword),
            (
                "\\b(?:0[xX][0-9a-fA-F_]+|0[oO][0-7_]+|0[bB][01_]+|\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d+)?(?:[KMGTP]i?)?)\\b|\\B\\.\\d+\\b",
                .number
            ),
        ]

    /// What follows a hole's `\` (or `\#`): `( … )`, brackets two deep and strings inside it.
    private static let cueHoleBody = "\\((?:[^()\"\\n]|\"(?:[^\"\\\\\\n]|\\\\.)*\"|\\((?:[^()\\n]|\\([^()\\n]*\\))*\\))*\\)"

    /// A hole's `)` that closes no call inside it (`\(f(x))`).
    private static let cueAfterHole = "(?<=\\))(?<!\\w\\([^()\\n]{0,30}\\))"

    /// A whole `"""…"""` string, for the scan for one-line strings to step over.
    private static let cueTriple = "\"\"\"[\\s\\S]*?\"\"\""

    /// The comments, bytes and many-hash raw strings the scans step over.
    private static let cueSkip = [
        "//[^\\n]*", "##+\"\"\"[\\s\\S]*?\"\"\"##+", "#+'''[\\s\\S]*?'''#+", "#\"\"\"[\\s\\S]*?\"\"\"#", "##+\"[^\\n]*?\"##+",
        "#+'[^\\n]*?'#+", "'''[\\s\\S]*?'''", "'(?:[^'\\\\\\n]|\\\\.)*'",
    ]
}
