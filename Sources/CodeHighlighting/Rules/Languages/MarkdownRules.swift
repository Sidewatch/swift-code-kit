//
//  MarkdownRules.swift
//  CodeHighlighting
//
//  The regex rule table for Markdown.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Markdown.
/// Later rules repaint earlier ones; strings and comments paint last. A code span closes on a backtick run
/// as long as the one that opened it, so a double-backtick span can hold a single backtick; a fenced block,
/// of backticks or tildes, closes only on a fence of its own character at least as long, so a four-backtick
/// block can show a three-backtick fence inside it.
extension RuleTables {
    static let markdown: [(String, TokenKind)] = [
        ("^>+\\s?.*$", .comment),
        ("^\\s*(\\*{3,}|-{3,}|_{3,})\\s*$", .comment),
        ("^\\s*[\\-\\*+]\\s", .keyword),
        ("^\\s*\\d+\\.\\s", .keyword),
        ("!?\\[([^\\]]+)\\]\\(([^)]+)\\)", .type),
        ("(?<!\\*)\\*(?![\\s*])[^*\\n]+?(?<![\\s*])\\*(?!\\*)", .type),
        ("(?<!\\w)_(?![\\s_])[^_\\n]+?(?<![\\s_])_(?!\\w)", .type),
        ("\\*\\*(?:[^*\\n]|\\*(?!\\*))+?\\*\\*", .function),
        ("__(?:[^_\\n]|_(?!_))+?__", .function),
        ("^#{1,6}\\s+.*$", .keyword),
        ("(?<!`)(`+)(?!`)[^\\n]*?(?<!`)\\1(?!`)", .string),
        ("^[ \\t]{0,3}(`{3,})[^`\\n]*\\n[\\s\\S]*?^[ \\t]{0,3}\\1`*[ \\t]*$", .string),
        ("^[ \\t]{0,3}(~{3,}).*\\n[\\s\\S]*?^[ \\t]{0,3}\\1~*[ \\t]*$", .string),
    ]
}
