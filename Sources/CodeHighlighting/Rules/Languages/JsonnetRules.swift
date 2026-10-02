//
//  JsonnetRules.swift
//  CodeHighlighting
//
//  The regex rule table for Jsonnet.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Jsonnet: `//`, `#` and `/* */` comments; `'…'` and `"…"` strings with backslash escapes, `@'…'` and
/// `@"…"` verbatim strings whose only escape is a doubled quote, and `|||` text blocks (`|||-` chomps) that
/// run to the closing `|||` line; the reference's keywords; field names before `:`, `::` and `:::`.
extension RuleTables {
    static let jsonnet: [(String, TokenKind)] = [
        hashComment,
        ("\\|\\|\\|-?[ \\t]*\\n[\\s\\S]*?^[ \\t]*\\|\\|\\|", .string),
        ("@'(?:[^']|'')*'", .string),
        ("@\"(?:[^\"]|\"\")*\"", .string),
        doubleQuoted,
        singleQuoted,
        ("\\b([A-Za-z_]\\w*)(?=\\s*\\+?:{1,3}(?!:))", .property),
        callee,
        wordTrie(
            [
                "assert", "else", "error", "for", "function", "if", "import", "importbin", "importstr", "in", "local",
                "self", "super", "tailstrict", "then",
            ], .keyword),
        constants(["true", "false", "null"]),
        ("\\$(?![\\w$])", .keyword),
        ("\\bstd\\b", .type),
        decimal,
    ]
}
