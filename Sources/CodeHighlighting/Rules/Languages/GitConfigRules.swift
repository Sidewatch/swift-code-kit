//
//  GitConfigRules.swift
//  CodeHighlighting
//
//  The regex rule table for Git config files.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Git config (`.gitconfig`, `.git/config`): `[section "subsection"]` headers, `name =` keys, `"…"`
/// values with `\"` `\\` `\n` `\t` `\b` escapes that may continue past a trailing `\`, and `#` / `;`
/// comments anywhere outside quotes. A boolean or number paints only as the whole value. An escaped `\"`
/// outside quotes is a literal quote, so it never opens a string (`cmd = vim -d \"$LOCAL\"`).
extension RuleTables {
    static let gitconfig: [(String, TokenKind)] = [
        ("^\\s*\\[[^\\]\\n]*\\]", .keyword),
        ("^[ \\t]*[A-Za-z][\\w-]*(?=[ \\t]*(?:=|[#;]|$))", .function),
        // A boolean or a number is the whole value (`prune = true`, `abbrev = 12`, `bigFileThreshold = 512m`), never
        // a word inside one (`--no-edit`, `HEAD~1`, `-20`, the `y=2` of a URL).
        (gitConfigWholeValue + "(?i)\\b(?:true|false|yes|no|on|off)\\b|[+-]?\\b\\d[\\d.]*[kmgKMG]?\\b", .number),
        ("(?<!\\\\)\"(?:[^\"\\\\\\n]|\\\\[\\s\\S])*\"", .string),
        ("[#;].*$", .comment),
    ]

    /// A key's value when it is one boolean or number and nothing else, found by one scan per paint.
    static let gitConfigWholeValue = RuleScope.marker(
        steppingOver: [],
        regions: "(?im)^[ \\t]*[A-Za-z][\\w-]*[ \\t]*=[ \\t]*"
            + RuleScope.region("(?:true|false|yes|no|on|off|[+-]?\\d+(?:\\.\\d+)?[kmg]?)(?=[ \\t]*(?:[#;]|$))"),
        within: 200)
}
