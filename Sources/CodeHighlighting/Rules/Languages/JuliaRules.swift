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

/// Julia: `#` and nestable `#= =#` comments, `"…"` and `"""…"""` strings (escapes may cross a line),
/// backtick commands, character literals (`'a'`, `'\n'`, `'\u00e9'`) that a transpose `a'` is not,
/// symbols, macros, the declaration words, numeric literals.
extension RuleTables {
    static let julia: [(String, TokenKind)] = [
        ("#=(?:[^=#]|=(?!#)|#(?!=)|#=(?:[^=]|=(?!#))*=#)*=#", .comment),
        hashComment,
        ("\"\"\"(?:[^\"\\\\]|\\\\[\\s\\S]|\"(?!\"\"))*\"\"\"", .string),
        doubleQuoted,
        ("`[^`]*`", .string),
        // A character literal follows no operand: after a name, `)`, `]`, `}` or `'` the quote is a transpose.
        ("(?<![\\w)\\]}'.!])'(?:\\\\(?:u[0-9a-fA-F]{1,4}|U[0-9a-fA-F]{1,8}|x[0-9a-fA-F]{1,2}|[0-7]{1,3}|.)|[^'\\\\\\n])'", .string),
        ("(?<![\\w:]):[A-Za-z_]\\w*", .string),
        keywords([
            "function", "end", "if", "elseif", "else", "for", "while", "begin", "let", "do", "try", "catch", "finally", "return",
            "break", "continue", "struct", "mutable", "abstract", "primitive", "type", "module", "baremodule", "using", "import",
            "export", "macro", "const", "global", "local", "where", "in", "isa", "quote", "outer",
        ]),
        constants(["true", "false", "nothing", "missing", "NaN", "Inf", "pi", "undef"]),
        ("@[A-Za-z_]\\w*!?", .function),
        ("\\b[A-Z][A-Za-z0-9_]*\\b", .type),
        ("\\b(?:0x[0-9a-fA-F_]+|0b[01_]+|0o[0-7_]+|\\d[\\d_]*(?:\\.[\\d_]*)?(?:[eE][+-]?\\d+)?)\\b", .number),
        ("\\b([A-Za-z_]\\w*!?)(?=\\()", .function),
    ]
}
