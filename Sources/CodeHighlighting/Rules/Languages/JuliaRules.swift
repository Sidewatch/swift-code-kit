//
//  JuliaRules.swift
//  CodeHighlighting
//
//  The regex rule table for Julia.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Julia: `#` and nestable `#= =#` comments, `"…"` and `"""…"""` strings (escapes may cross a line), a `"…"`
/// string's `$( … )` interpolations painted as code, prefixed literals (`raw"…"`, `r"…"`, `b"…"`, `big"…"`) whole,
/// backtick commands, character literals (`'a'`, `'\n'`, `'\u00e9'`) that a transpose `a'` is not,
/// symbols (a `<:` is the subtype operator and `.:` a broadcast, not one), macros, the declaration words, and numeric literals in
/// every form (`0x1.8p3`, `2.5f0`, `1f-3`, `.5`, `5.`, `4im`, the `2` of `2x`).
extension RuleTables {
    static let julia: [(String, TokenKind)] =
        [
            ("#=(?:[^=#]|=(?!#)|#(?!=)|#=(?:[^=]|=(?!#))*=#)*=#", .comment),
            hashComment,
            ("\\b[A-Za-z_]\\w*\"\"\"[\\s\\S]*?\"\"\"", .string),
            ("\\b[A-Za-z_]\\w*\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
            // A `"""…"""` string paints whole, holes included; only a `"…"` string is split around its holes.
            (juliaTriple, .string),
        ]
        + interpolatedStringPieces(
            whole: juliaStrings, skip: juliaSkip, open: "\"", close: "\"",
            literal: "[^\"\\\\$]|\\\\[\\s\\S]|\\$(?!\\()", holeClose: "\\)", nested: "\\w\\([^()\\n]{0,30}\\)")
        + [
            ("`[^`]*`", .string),
            // A character literal follows no operand: after a name, `)`, `]`, `}` or `'` the quote is a transpose.
            ("(?<![\\w)\\]}'.!])'(?:\\\\(?:u[0-9a-fA-F]{1,4}|U[0-9a-fA-F]{1,8}|x[0-9a-fA-F]{1,2}|[0-7]{1,3}|.)|[^'\\\\\\n])'", .string),
            ("(?<![\\w:<.]):[A-Za-z_]\\w*", .string),
            wordTrie(
                [
                    "function", "end", "if", "elseif", "else", "for", "while", "begin", "let", "do", "try", "catch", "finally", "return",
                    "break", "continue", "struct", "mutable", "abstract", "primitive", "type", "module", "baremodule", "using", "import",
                    "export", "macro", "const", "global", "local", "where", "in", "isa", "quote", "outer",
                ], .keyword),
            wordTrie(
                ["true", "false", "nothing", "missing", "NaN", "Inf", "pi", "undef", "Inf16", "Inf32", "Inf64", "NaN16", "NaN32", "NaN64"],
                .number),
            ("@[A-Za-z_]\\w*!?", .function),
            ("\\b[A-Z][A-Za-z0-9_]*\\b", .type),
            (
                "(?:\\b0x[0-9a-fA-F_]+(?:\\.[0-9a-fA-F_]*)?(?:p[-+]?\\d+)?|\\b0b[01_]+|\\b0o[0-7_]+|(?:\\b\\d[\\d_]*(?:\\.(?![.\\d]*\\.)[\\d_]*)?|(?<![\\w.])\\.\\d[\\d_]*)(?:[eEf][-+]?\\d[\\d_]*)?)(?:im\\b)?",
                .number
            ),
            ("\\b([A-Za-z_]\\w*!?)(?=\\()", .function),
        ]

    /// Every interpolated string, `"""…"""` before `"…"`: where a `"…"` string's tail may start.
    private static let juliaStrings = juliaTriple + "|" + "\"(?:[^\"\\\\$]|\\\\[\\s\\S]|\\$(?!\\()|" + juliaHole + ")*\""

    /// A `"""…"""` string, holes included.
    private static let juliaTriple = "\"\"\"(?:[^\"\\\\$]|\\\\[\\s\\S]|\\$(?!\\()|\"(?!\"\")|" + juliaHole + ")*\"\"\""

    /// The comments, prefixed literals, commands and characters a search for a `"…"` string steps over.
    private static let juliaSkip = [
        "#=[\\s\\S]*?=#", "#[^\\n]*", "\\b[A-Za-z_]\\w*\"\"\"[\\s\\S]*?\"\"\"", "\\b[A-Za-z_]\\w*\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"",
        "`[^`]*`", "(?<![\\w)\\]}'.!])'(?:\\\\.[^'\\n]{0,8}|[^'\\\\\\n])'",
    ]

    /// A `$( … )` hole: brackets two deep, strings inside it (which may hold a hole of their own).
    private static let juliaHole: String = {
        let simpleString = #""(?:[^"\\$]|\\.|\$(?!\())*""#
        let inner = #"\$\((?:[^()"]|"# + simpleString + #"|\([^()]*\))*\)"#
        let string = #""(?:[^"\\$]|\\.|\$(?!\()|"# + inner + #")*""#
        return #"\$\((?:[^()"]|"# + string + #"|\((?:[^()"]|"# + string + #"|\([^()]*\))*\))*\)"#
    }()
}
