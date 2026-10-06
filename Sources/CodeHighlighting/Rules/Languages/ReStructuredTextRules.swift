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
/// `links`_, **bold**, *italic*, list markers, `:field:` names and roles, |substitutions| and the
/// directive that defines one, simple tables, and the numbers of a `code-block`'s body. A comment is an
/// explicit markup start (`..`) that is not a directive (`.. name::`), a substitution (`.. |name|`), a
/// footnote or citation (`.. [1]`) or a target (`.. _name:`), together with the indented lines under
/// it; a bare `..` line comments the indented block that follows. A standalone URL is text, and inline
/// markup does not nest: a ``literal`` inside **bold** is bold text.
extension RuleTables {
    static let restructuredtext: [(String, TokenKind)] = [
        ("^\\.\\. [\\w-]+::.*$", .keyword),
        ("^\\.\\. \\|[^|\\n]+\\| [\\w-]+::", .keyword),
        ("^\\.\\. _[^:]+:.*$", .function),
        ("^\\.\\.(?:[ \\t]+(?![\\[_|])(?![\\w:+.-]+::(?:[ \\t]|$))[^\\n]*|[ \\t]*)$(?:\\n[ \\t]+\\S[^\\n]*)*", .comment),
        ("^(=+|-+|~+|\\^+|\\*+|#+|\"+|\\++|`+)\\s*$", .keyword),
        ("^={2,}(\\s+={2,})+\\s*$", .keyword),
        ("``[^`]+``(?<!\\*\\*[^*\\s][^*\\n]{0,200}``[^`]{1,200}``)", .string),
        ("`[^`]+`_{1,2}", .function),
        (":[\\w+.-]+:`[^`]+`", .property),
        ("^\\s*:[\\w -]+:", .property),
        ("\\*\\*[^*\\n]+\\*\\*", .type),
        ("\\*[^*\\n]+\\*", .variable),
        ("\\|[^|\\n]+\\|", .property),
        ("^\\s*([-*+]|\\d+\\.|#\\.)\\s", .keyword),
        (codeBlockBody + "-?\\b\\d+(?:\\.\\d+)?\\b", .number),
    ]

    /// The indented body of a `code-block`, `code` or `sourcecode` directive.
    private static let codeBlockBody = inside(
        opens: ["(?m)^\\.\\. (?:code-block|code|sourcecode)::[^\\n]*"], closes: ["\\n(?=\\S)"], within: 20000)
}
