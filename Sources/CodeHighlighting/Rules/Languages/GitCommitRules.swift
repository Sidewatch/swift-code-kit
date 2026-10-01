//
//  GitCommitRules.swift
//  CodeHighlighting
//
//  The regex rule table for Git commit messages.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Git commit messages: git's `#` comment lines (and `;` when `core.commentChar` is `;`), the Conventional
/// Commits type on the subject, and `Key: value` trailers. There are no strings — an apostrophe in the prose
/// (`bar's`) opens nothing.
extension RuleTables {
    static let gitcommit: [(String, TokenKind)] = [
        ("^[a-z]+(\\([^)\\n]*\\))?!?(?=: )", .keyword),
        ("^[A-Z][A-Za-z-]*(?=: )", .property),
        ("(?<![\\w#])#\\d+\\b", .number),
        ("^[#;].*$", .comment),
    ]
}
