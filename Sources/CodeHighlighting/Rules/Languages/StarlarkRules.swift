//
//  StarlarkRules.swift
//  CodeHighlighting
//
//  The regex rule table for Starlark (Bazel, Buck, Tilt).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Starlark: `#` comments; `"…"`, `'…'` and triple-quoted strings with `r` / `b` prefixes; the Starlark
/// keywords (Python's subset, with `load`); `True` / `False` / `None`; numbers with `_` separators and
/// `0o` / `0b` / `0x` forms; calls.
extension RuleTables {
    static let starlark: [(String, TokenKind)] = [
        ("(?i:[rb]{0,2})\"\"\"[\\s\\S]*?\"\"\"", .string),
        ("(?i:[rb]{0,2})'''[\\s\\S]*?'''", .string),
        hashComment,
        ("(?i:[rb]{0,2})\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("(?i:[rb]{0,2})'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ("\\b[A-Za-z_]\\w*(?=[ \\t]*\\()", .function),
        keywords([
            "and", "break", "continue", "def", "elif", "else", "for", "if", "in", "lambda", "load", "not", "or", "pass",
            "return", "while",
        ]),
        constants(["True", "False", "None"]),
        decimal,
    ]
}
