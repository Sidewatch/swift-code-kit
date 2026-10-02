//
//  AsciiDocRules.swift
//  CodeHighlighting
//
//  The regex rule table for AsciiDoc.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// AsciiDoc: `=` headings, `//` comments, block titles, `[attribute]` lines, `:name:` entries,
/// block delimiters, inline bold / italic / mono, `<<xrefs>>`, admonitions, tables, list
/// markers. A heading or list marker is followed by a space on its own line: a `\s` there would reach across
/// the line break and paint the paragraph under a `====` delimiter as a heading.
extension RuleTables {
    static let asciidoc: [(String, TokenKind)] = [
        ("^//.*$", .comment),
        ("^(----|====|\\*\\*\\*\\*|\\+\\+\\+\\+|____|\\.\\.\\.\\.|\\|===)\\s*$", .comment),
        ("^=+[ \\t].*$", .keyword),
        ("^\\.[A-Za-z].*$", .type),
        ("^\\[[^\\]]*\\]\\s*$", .attribute),
        ("^:[\\w-]+!?:", .property),
        ("^[ \\t]*[*.-]+[ \\t]", .keyword),
        ("^[ \\t]*\\d+\\.[ \\t]", .keyword),
        ("\\b(NOTE|TIP|IMPORTANT|WARNING|CAUTION):", .removed),
        ("<<[^>]+>>", .function),
        ("\\b(https?|link|xref|image|include|mailto):[^\\s\\[]+(\\[[^\\]]*\\])?", .string),
        ("`[^`\\n]+`", .string),
        ("\\*[^*\\n]+\\*", .type),
        ("_[^_\\n]+_", .variable),
        ("^\\|", .comment),
    ]
}
