//
//  NginxRules.swift
//  CodeHighlighting
//
//  The regex rule table for NGINX configuration.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// NGINX: `#` comments, `"…"` and `'…'` strings with escapes, the directive that opens each statement
/// (after a line start, `{` or `;`), `$variables`, sizes and times (`10m`, `30s`), `on` / `off`, and a
/// regular expression after `~`, `~*`, `!~` or `!~*` (`location ~* \.(css|js)$`,
/// `server_name ~^(?<sub>.+)\.example\.net$`) as a string — never a `(?<name>` read as a tag.
extension RuleTables {
    static let nginx: [(String, TokenKind)] = [
        hashComment,
        doubleQuoted,
        singleQuoted,
        // Each rule opens on a literal and checks what precedes it with a lookbehind after that literal: a
        // lookbehind that opens a pattern runs at every character of the file.
        ("~(?<![\\w~!^]~)\\*?[^\\s;{\"'*][^\\s;{\"']*", .string),
        ("[ \\t](?<=[\\s(!]~[ \\t]|[\\s(!]~\\*[ \\t])[ \\t]*[^\\s;{\"'][^\\s;{\"']*?(?=\\)?(?:[\\s;{]|$))", .string),
        ("^[ \\t]*[a-z_]\\w*(?=[ \\t;{]|$)", .keyword),
        ("[ \\t](?<=[{;][ \\t])[ \\t]*[a-z_]\\w*(?=[ \\t;{]|$)", .keyword),
        ("(?i)\\b(on|off)\\b", .number),
        decimal,
        ("\\$\\{?\\w+\\}?", .type),
    ]
}
