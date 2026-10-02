//
//  VyperRules.swift
//  CodeHighlighting
//
//  The regex rule table for Vyper.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Vyper: `#` comments, `"""…"""` docstrings, `"…"` / `'…'` strings with a `b` or `x` prefix, the
/// Vyper 0.4 keywords, `@external`-style decorators, the built-in types, and numbers with `_`
/// separators and `0x` hex.
extension RuleTables {
    static let vyper: [(String, TokenKind)] = [
        hashComment,
        tripleDoubleQuoted,
        tripleSingleQuoted,
        ("(?:\\b[bx])?\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("(?:\\b[bx])?'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        callee,
        keywords([
            "def", "return", "if", "elif", "else", "for", "in", "pass", "break", "continue", "raise", "assert", "import",
            "from", "as", "log", "event", "struct", "interface", "implements", "uses", "initializes", "exports", "flag",
            "enum", "not", "and", "or", "constant", "immutable", "public", "indexed", "extcall", "staticcall", "range",
            "self", "unreachable",
        ]),
        ("@[A-Za-z_]\\w*", .attribute),
        constants(["True", "False", "empty", "max_value", "min_value"]),
        (
            "\\b(?:u?int(?:8|16|32|64|128|256)?|address|bool|bytes(?:[1-9]|[12]\\d|3[0-2])?|Bytes|String|DynArray|HashMap|decimal)\\b",
            .type
        ),
        decimal,
    ]
}
