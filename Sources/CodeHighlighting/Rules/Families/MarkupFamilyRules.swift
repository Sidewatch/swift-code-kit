//
//  MarkupFamilyRules.swift
//  CodeHighlighting
//
//  The regex rule table shared by every language of the Markup family that has no table of its
//  own.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table shared by every language of the Markup family that has no table of its own.
extension RuleTables {
    /// A quoted value is a string only where it opens inside a tag: between tags, quotes are text
    /// (`<xsl:processing-instruction>format="html"</…>`).
    static let markupFamily: [(String, TokenKind)] = [
        htmlComment,
        (insideMarkupTag + "\"[^\"]*\"", .string),
        (insideMarkupTag + "'[^']*'", .string),
        ("</?[A-Za-z][\\w:-]*", .keyword),
        ("/>|>", .keyword),
        ("\\b[A-Za-z-]+=", .property),
    ]

    /// Inside a `<name …>` or `<?name …?>` tag, from its `<` to the next `>`.
    static let insideMarkupTag = inside(opens: ["<[A-Za-z?]"], closes: [">"], within: 4000)
}
