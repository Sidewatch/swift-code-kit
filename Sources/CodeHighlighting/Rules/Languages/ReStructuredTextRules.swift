//
//  ReStructuredTextRules.swift
//  CodeHighlighting
//
//  The regex rule table for reStructuredText.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// reStructuredText: `..` directives and comments, heading underlines, ``literals``,
/// `links`_, **bold**, *italic*, list markers, `:field:` names and roles, |substitutions|,
/// simple tables. A comment is an explicit markup start (`..`) that is not a directive (`.. name::`), a
/// substitution (`.. |name|`), a footnote or citation (`.. [1]`) or a target (`.. _name:`), together with
/// the indented lines under it; a bare `..` line comments the indented block that follows.
extension RuleTables {
    static let restructuredtext: [(String, TokenKind)] = [
        ("^\\.\\. [\\w-]+::.*$", .keyword),
        ("^\\.\\. _[^:]+:.*$", .function),
        ("^\\.\\.(?:[ \\t]+(?![\\[_|])(?![\\w:+.-]+::(?:[ \\t]|$))[^\\n]*|[ \\t]*)$(?:\\n[ \\t]+\\S[^\\n]*)*", .comment),
        ("^(=+|-+|~+|\\^+|\\*+|#+|\"+|\\++|`+)\\s*$", .keyword),
        ("^={2,}(\\s+={2,})+\\s*$", .comment),
        ("``[^`]+``", .string),
        ("`[^`]+`_{1,2}", .function),
        (":[\\w+.-]+:`[^`]+`", .property),
        ("^\\s*:[\\w -]+:", .property),
        ("\\*\\*[^*\\n]+\\*\\*", .type),
        ("\\*[^*\\n]+\\*", .variable),
        ("\\|[^|\\n]+\\|", .property),
        ("^\\s*([-*+]|\\d+\\.|#\\.)\\s", .keyword),
        ("\\bhttps?://\\S+", .string),
    ]
}
