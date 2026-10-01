//
//  INIRules.swift
//  CodeHighlighting
//
//  The regex rule table for INI.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// INI: `;` and `#` comments, `[section]` headers, `key =` names, and `"…"` / `'…'` values that end at the
/// line end — an unterminated quote (`key = "unterminated`) must not run on into the lines below.
extension RuleTables {
    static let ini: [(String, TokenKind)] = [
        ("^\\s*\\[[^\\]\\n]*\\]", .keyword),
        ("^\\s*[A-Za-z_][\\w.-]*(?=\\s*[=:])", .function),
        ("\\$\\{?\\w+\\}?", .type),
        ("%\\{[^}\\n]*\\}", .type),
        ("(?i)\\b(on|off|true|false|yes|no|none|null|enabled|disabled)\\b", .number),
        decimal,
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'[^'\\n]*'", .string),
        hashComment,
        ("(?:^|\\s);.*$", .comment),
    ]
}
