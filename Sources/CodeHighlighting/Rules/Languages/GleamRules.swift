//
//  GleamRules.swift
//  CodeHighlighting
//
//  The regex rule table for Gleam.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Gleam: `//`, `///` and `////` comments (the language table adds `//`) — there is no `--` or `{- -}`
/// comment; `"…"` strings with backslash escapes; the reserved words; capitalised types and constructors;
/// `@attributes`; numbers with `_` separators and `0x` / `0o` / `0b` prefixes.
extension RuleTables {
    static let gleam: [(String, TokenKind)] = [
        doubleQuoted,
        ("\\b([a-z_]\\w*)(?=\\s*\\()", .function),
        keywords([
            "as", "assert", "auto", "case", "const", "delegate", "derive", "echo", "else", "fn", "if", "implement",
            "import", "let", "macro", "opaque", "panic", "pub", "test", "todo", "type", "use",
        ]),
        ("\\b[A-Z][A-Za-z0-9_]*", .type),
        ("@[a-z_]\\w*", .attribute),
        decimal,
    ]
}
