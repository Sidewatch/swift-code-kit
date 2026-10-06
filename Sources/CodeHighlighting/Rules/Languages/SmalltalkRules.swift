//
//  SmalltalkRules.swift
//  CodeHighlighting
//
//  The regex rule table for Smalltalk.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Smalltalk (Pharo / Squeak): `"…"` COMMENTS, `'…'` strings, `#symbols`, capitalised class
/// names, keyword selectors `at:put:`, the pseudo-variables, `^` returns, `| temps |`. A character
/// literal `$x` is painted as a string, so `$'` and `$"` never open a string or a comment.
extension RuleTables {
    static let smalltalk: [(String, TokenKind)] = [
        ("\"[^\"]*\"", .comment),
        ("'(?:[^']|'')*'", .string),
        ("\\$.", .string),
        ("#[A-Za-z_][\\w:]*|#\\(|#\\[", .type),
        keywords(["self", "super", "true", "false", "nil", "thisContext"]),
        ("\\^|>>|:=", .keyword),
        ("\\b[a-z][\\w]*:(?!=)", .function),
        ("\\b[A-Z][\\w]*\\b", .type),
        ("\\|[\\s\\w]+\\|", .variable),
        // A literal's minus sign is part of it (`-7`, `-16rFF`); a radix number may carry a fraction and an
        // exponent (`16r1F.8`, `2r1e4`).
        (
            "(?:(?<=[\\s(#\\[{:=^.])-)?\\b(?:\\d+r[0-9A-Z]+(?:\\.[0-9A-Z]+)?(?:e-?\\d+)?|\\d[\\d_]*(\\.\\d+)?(?:[edq]-?\\d+|s\\d*)?)\\b",
            .number
        ),
    ]
}
