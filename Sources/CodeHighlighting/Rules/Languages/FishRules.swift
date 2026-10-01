//
//  FishRules.swift
//  CodeHighlighting
//
//  The regex rule table for Fish.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Fish: `#` comments, `'…'` strings whose only escapes are `\'` and `\\` (so a string may hold an escaped
/// quote and still end), a backslash-escaped character outside quotes, `"…"` with backslash escapes, `$variables`, the block words and builtins.
extension RuleTables {
    static let fish: [(String, TokenKind)] = [
        hashComment,
        ("\\\\[\\s\\S]", .string),  // an escaped character outside quotes: `\'` is no quote
        doubleQuoted,
        singleQuoted,
        keywords([
            "if", "else", "end", "for", "in", "while", "switch", "case", "function", "return",
            "begin", "break", "continue", "and", "or", "not", "set", "exit", "source", "alias",
            "abbr", "echo", "builtin", "command", "test", "argparse",
        ]),
        ("\\$+\\{?[A-Za-z_]\\w*\\}?", .type),
        ("\\b\\d+\\b", .number),
    ]
}
