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
/// comments anywhere outside quotes. An escaped `\"` outside quotes is a literal quote, so it never
/// opens a string (`cmd = vim -d \"$LOCAL\"`).
extension RuleTables {
    static let gitconfig: [(String, TokenKind)] = [
        ("^\\s*\\[[^\\]\\n]*\\]", .keyword),
        ("^[ \\t]*[A-Za-z][\\w-]*(?=[ \\t]*(?:=|[#;]|$))", .function),
        ("(?i)\\b(true|false|yes|no|on|off)\\b", .number),
        decimal,
        ("(?<!\\\\)\"(?:[^\"\\\\\\n]|\\\\[\\s\\S])*\"", .string),
        ("[#;].*$", .comment),
    ]
}
