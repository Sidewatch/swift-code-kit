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
/// operator words, `@attr(…)` attributes, `#Definition` names, the built-in types, and numbers.
extension RuleTables {
    static let cue: [(String, TokenKind)] = [
        lineComment,
        ("(#+)\"\"\"[\\s\\S]*?\"\"\"\\1", .string),
        ("(#+)'''[\\s\\S]*?'''\\1", .string),
        ("(#+)\"[^\\n]*?\"\\1", .string),
        ("(#+)'[^\\n]*?'\\1", .string),
        ("\"\"\"[\\s\\S]*?\"\"\"", .string),
        ("'''[\\s\\S]*?'''", .string),
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        callee,
        keywords(["package", "import", "for", "in", "if", "let", "div", "mod", "quo", "rem"]),
        ("@[A-Za-z_]\\w*(?:\\([^)\\n]*\\))?", .attribute),
        ("#[A-Za-z_]\\w*", .type),
        types([
            "string", "int", "float", "bool", "bytes", "number", "null", "uint", "int8", "int16", "int32", "int64", "uint8", "uint16",
            "uint32", "uint64", "float32", "float64", "rune",
        ]),
        constants(["true", "false", "null"]),
        ("_\\|_", .keyword),
        (
            "\\b(?:0[xX][0-9a-fA-F_]+|0[oO][0-7_]+|0[bB][01_]+|\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d+)?(?:[KMGTP]i?)?)\\b|\\B\\.\\d+\\b",
            .number
        ),
    ]
}
