//
//  RegoRules.swift
//  CodeHighlighting
//
//  The regex rule table for Rego (Open Policy Agent).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Rego: `#` comments, `"…"` strings with escapes, `` `raw` `` strings, the v1 keywords (`if`,
/// `contains`, `every`, `some`, `in`), `true` / `false` / `null`, signed numbers, `:=` rules and calls.
extension RuleTables {
    static let rego: [(String, TokenKind)] = [
        hashComment,
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("`[^`]*`", .string),
        ("\\b[A-Za-z_][\\w.]*(?=\\()", .function),
        keywords([
            "package", "import", "as", "default", "else", "if", "contains", "every", "some", "in", "not", "with", "set", "data", "input",
        ]),
        constants(["true", "false", "null"]),
        ("(?<![\\w.])-?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b", .number),
    ]
}
