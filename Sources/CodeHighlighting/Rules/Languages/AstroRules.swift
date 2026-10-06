//
//  AstroRules.swift
//  CodeHighlighting
//
//  The regex rule table for Astro.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Astro.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let astro: [(String, TokenKind)] = [
        // The body is markup; its `{ … }` expressions, the frontmatter and `<script>` are TypeScript, painted by
        // ``EmbeddedMarkupHighlighter`` with the grammar (a `//` comment inside an expression is kept here for when
        // the grammar is not loaded). Quotes in the text are text: only an attribute's value is a string.
        htmlComment,
        (inside(opens: ["\\{"], closes: ["\\}"], within: 200) + "//.*$", .comment),
        ("\"(?<==\")[^\"]*\"", .string),
        ("'(?<==')[^']*'", .string),
        ("^---\\s*$", .keyword),
        ("</?[A-Z][\\w.]*", .type),
        ("</?[a-z][\\w-]*", .keyword),
        ("/>|>", .keyword),
        decimal,
        ("\\b[a-zA-Z_:][\\w:-]*=", .function),
    ]
}
