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
        ("\\b\\d+r[0-9A-Z]+\\b|\\b\\d+(\\.\\d+)?(?:[edq]-?\\d+|s\\d*)?\\b", .number),
    ]
}
