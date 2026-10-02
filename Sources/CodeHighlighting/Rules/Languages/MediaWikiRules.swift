//
//  MediaWikiRules.swift
//  CodeHighlighting
//
//  The regex rule table for MediaWiki wikitext.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// MediaWiki wikitext: `<!-- -->` comments; the markup — `== headings ==`, `'''bold'''` and `''italic''`
/// markers, list and table markers at a line's start, `__MAGIC__` words, `~~~~` signatures, rules —
/// as keywords; `[[links]]` and `[external links]` as types; `{{templates}}` and `{{{parameters}}}`;
/// HTML-style tags with their attributes. Only a tag attribute's value is a string: an apostrophe in the
/// prose (`c'`, `it's`) opens nothing.
extension RuleTables {
    static let mediawiki: [(String, TokenKind)] = [
        htmlComment,
        ("(?<==)\"[^\"\\n]*\"", .string),
        ("(?<==)'[^'\\n]*'", .string),
        ("^(={1,6}).*?\\1[ \\t]*$", .keyword),
        ("'{2,5}", .keyword),
        ("^[*#:;]+", .keyword),
        ("^[ \\t]*(?:\\{\\||\\|\\}|\\|-+|\\|\\+|!|\\|)", .keyword),
        ("\\|\\||!!", .keyword),
        ("__[A-Z]+__|~{3,5}|^-{4,}", .keyword),
        ("\\[\\[[^\\]\\n]*\\]\\]", .type),
        ("\\[(?:https?:|ftp:|irc:|mailto:|//)[^\\]\\n]*\\]", .type),
        ("\\{\\{\\{[^{}\\n]*\\}\\}\\}", .variable),
        ("\\{\\{#?[^{}|\\n]*|\\}\\}", .function),
        ("</?[A-Za-z][\\w:-]*|/?>", .keyword),
        ("(?<=\\s)[A-Za-z-]+(?==)", .property),
    ]
}
