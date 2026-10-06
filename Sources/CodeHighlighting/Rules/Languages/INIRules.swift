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

/// INI: `;` and `#` comments, `[section]` headers, `key =` names (which may start with a digit, `-` or
/// `.`), and `"…"` / `'…'` values that end at the line end — an unterminated quote
/// (`key = "unterminated`) must not run on into the lines below.
extension RuleTables {
    static let ini: [(String, TokenKind)] = [
        ("^\\s*\\[[^\\]\\n]*\\]", .keyword),
        ("^[ \\t]*[\\w.$-]+(?=[ \\t]*[=:])", .function),
        // An interpolation to its closing brace (`${paths:data}`, extended interpolation's section:key), or `$name`.
        ("\\$\\{[^}\\n]*\\}|\\$\\w+", .type),
        ("%\\{[^}\\n]*\\}", .type),
        // A boolean is the whole value (`enabled = on`), never a word in a sentence.
        (iniWholeBoolean + "(?i)\\b(?:on|off|true|false|yes|no|none|null|enabled|disabled)\\b", .number),
        // A number stands alone: the parts of a dotted address (`127.0.0.1`) or a version (`1.2.3`) are not numbers.
        ("(?<![\\w.])(?:0[xX][0-9a-fA-F]+|\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)(?:[a-zA-Z]{1,3})?(?![\\w.])", .number),
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'[^'\\n]*'", .string),
        hashComment,
        ("(?:^|\\s);.*$", .comment),
    ]

    /// A key's value when it is one boolean and nothing else, found by one scan per paint.
    static let iniWholeBoolean = RuleScope.marker(
        steppingOver: [],
        regions: "(?im)^[ \\t]*[\\w.$-]+[ \\t]*[=:][ \\t]*"
            + RuleScope.region("(?:on|off|true|false|yes|no|none|null|enabled|disabled)(?=[ \\t]*(?:[#;]|$))"),
        within: 200)
}
