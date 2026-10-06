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
/// `server_name ~^(?<sub>.+)\.example\.net$`) as a string, the operator itself left code — never a `(?<name>`
/// read as a tag — and the URIs and patterns of `location`, `rewrite` and `fastcgi_split_path_info` as strings.
extension RuleTables {
    static let nginx: [(String, TokenKind)] = [
        hashComment,
        doubleQuoted,
        singleQuoted,
        // Each rule opens on a literal and checks what precedes it with a lookbehind after that literal: a
        // lookbehind that opens a pattern runs at every character of the file.
        // A pattern right after `~` or `~*` that opens on `^`, `\`, `(`, `[`, `.` or `/` (nearly all of them) is a
        // string from its first character, the operator left code; the lookbehind runs only at those characters.
        // One that opens on a word character takes the operator with it: a lookbehind at every letter is slow.
        ("[\\^\\\\(\\[./](?<=~.|~\\*.)(?<![\\w~!^]~.|[\\w~!^]~\\*.)[^\\s;{\"']*", .string),
        ("~(?<![\\w~!^]~)\\*?(?=\\w)[^\\s;{\"']*", .string),
        ("[ \\t](?<=[\\s(!]~[ \\t]|[\\s(!]~\\*[ \\t])[ \\t]*[^\\s;{\"'][^\\s;{\"']*?(?=\\)?(?:[\\s;{]|$))", .string),
        // A location's URI, a rewrite's pattern and replacement, a split_path_info pattern: each `/…` or `^…` piece
        // is a string up to a `$variable` or the end anchor.
        (nginxUriArguments + "[\\^/][^\\s;{$]*", .string),
        ("^[ \\t]*[a-z_]\\w*(?=[ \\t;{]|$)", .keyword),
        ("[ \\t](?<=[{;][ \\t])[ \\t]*[a-z_]\\w*(?=[ \\t;{]|$)", .keyword),
        ("(?i)\\b(on|off)\\b", .number),
        decimal,
        ("\\$\\{?\\w+\\}?", .type),
    ]

    /// After `location` (and its `=` or `^~`), `rewrite` or `fastcgi_split_path_info`, to the statement's end.
    static let nginxUriArguments = RuleScope.marker(
        opens: ["\\blocation[ \\t]+(?:=[ \\t]+|\\^~[ \\t]+)?", "\\brewrite[ \\t]+", "\\bfastcgi_split_path_info[ \\t]+"],
        closes: [";", "\\{"], within: 400)
}
