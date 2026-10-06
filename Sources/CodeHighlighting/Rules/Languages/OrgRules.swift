//
//  OrgRules.swift
//  CodeHighlighting
//
//  The regex rule table for Org mode.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Org mode. Org has no quoted strings — an apostrophe in prose is prose —
/// so the markup family's `'…'` rules, which paired apostrophes across lines, are not used. Headings,
/// `#+KEYWORD:` lines, comment blocks, TODO states, emphasis, links, timestamps, list markers (`*` is
/// one when indented, a heading at a line's start), tables (their rows as strings) and source blocks.
extension RuleTables {
    static let org: [(String, TokenKind)] = [
        ("^\\*+[ \\t].*$", .keyword),  // headings, every level
        ("(?i)^[ \\t]*#\\+[a-z_]+:?", .attribute),  // #+TITLE: and the other keyword lines
        ("(?i)^[ \\t]*#\\+(?:begin|end)_\\w+.*$", .attribute),  // #+begin_src … / #+end_src
        ("\\b(?:TODO|NEXT|WAITING|DONE|CANCELLED|FIXED)\\b", .keyword),
        ("\\[\\[[^\\]\\n]*\\](?:\\[[^\\]\\n]*\\])?\\]", .function),  // [[link][description]]
        ("[<\\[]\\d{4}-\\d{2}-\\d{2}[^>\\]\\n]*[>\\]]", .number),  // <2026-09-24 Wed> and [2026-09-24]
        ("(?<![\\w*])\\*[^*\\s\\n](?:[^*\\n]*[^*\\s\\n])?\\*(?![\\w*])", .type),  // *bold*
        ("(?<![\\w=])=[^=\\s\\n](?:[^=\\n]*[^=\\s\\n])?=(?![\\w=])", .string),  // =verbatim=
        ("(?<![\\w~])~[^~\\s\\n](?:[^~\\n]*[^~\\s\\n])?~(?![\\w~])", .string),  // ~code~
        ("^[ \\t]*(?:[-+]|\\d+[.)])(?=[ \\t])|^[ \\t]+\\*(?=[ \\t])", .keyword),  // list markers (an indented `*` too)
        ("^[ \\t]*\\|.*$", .string),  // table rows: their cells are data
        ("^[ \\t]*:[A-Z_]+:.*$", .property),  // :PROPERTIES: drawers and :KEY: value
        // The body of a comment block, between its `#+begin_comment` and `#+end_comment` lines, is a comment.
        // The match opens on the begin line's newline, so the lookbehind runs once per line, not per character.
        ("(?i)\\n(?<=#\\+begin_comment[ \\t]{0,8}\\n)[\\s\\S]*?(?=^[ \\t]*#\\+end_comment\\b)", .comment),
    ]
}
