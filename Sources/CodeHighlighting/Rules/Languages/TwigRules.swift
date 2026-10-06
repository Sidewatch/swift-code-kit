//
//  TwigRules.swift
//  CodeHighlighting
//
//  The regex rule table for Twig.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Twig 3: `{# #}` comments, the `{% %}` / `{{ }}` delimiters with their `-` and `~` trims, the tag
/// words and their `end…` closers, the word operators (`b-and`, `starts with`, `same as`), `| filters`,
/// and HTML around them. Quotes are strings inside a tag, and an HTML attribute value without a tag
/// in it is one too; the escapes (`'it\'s'`) keep a string from ending early.
extension RuleTables {
    static let twig: [(String, TokenKind)] =
        [("\\{#[\\s\\S]*?#\\}", .comment), htmlComment] + templateTagStrings + templateAttributeStrings + [
            ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .property),
            ("\\{%[-~]?|[-~]?%\\}|\\{\\{[-~]?|[-~]?\\}\\}", .keyword),
            ("\\|\\s*[a-z_]\\w*", .function),
            ("\\b[a-zA-Z_]\\w*(\\.[a-zA-Z_]\\w*)+\\b", .property),
            (
                "(?<=\\{%[-~]?\\s{0,8})(?:end)?[a-z_]+\\b",
                .keyword
            ),
            templateTagKeywords([
                "if", "elseif", "else", "for", "in", "set", "block", "extends", "include", "import", "from", "as", "macro", "use",
                "with", "only", "embed", "apply", "autoescape", "verbatim", "sandbox", "spaceless", "flush", "cache", "deprecated",
                "do", "guard", "types", "line", "is", "not", "and", "or", "xor", "b-and", "b-or", "b-xor", "matches", "starts", "ends",
                "same", "divisible", "by", "defined", "empty", "ignore", "missing", "ttl", "trans", "into",
            ]),
            ("\\b(true|false|null|none)\\b", .number),
            (
                "\\b(?:0[xX][0-9a-fA-F_]+|0[oO][0-7_]+|0[bB][01_]+|\\d[\\d_]*(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\b|(?<![\\w.])\\.\\d+\\b",
                .number
            ),
        ]
}
