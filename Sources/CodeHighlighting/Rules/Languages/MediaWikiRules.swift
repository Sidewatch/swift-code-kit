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
/// HTML-style tags with their attributes, the JSON of a `<templatedata>` block and the code of a
/// `<syntaxhighlight>` block (a quoted key before `:` is a property). Only a tag attribute's value and
/// those blocks' literals are strings: an apostrophe in the prose (`c'`, `it's`) opens nothing.
extension RuleTables {
    static let mediawiki: [(String, TokenKind)] = [
        htmlComment,
        ("(?<==)\"[^\"\\n]*\"", .string),
        ("(?<==)'[^'\\n]*'", .string),
        // A `<syntaxhighlight>` / `<source>` block is code: its strings, numbers and common keywords.
        (insideSyntaxHighlight + "\"(?![ \\t]*:)(?:[^\"\\\\\\n]|\\\\.)*\"(?![ \\t]*:)", .string),
        (insideSyntaxHighlight + "'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        // A `<templatedata>` block is JSON.
        (insideTemplateData + "\"(?![ \\t]*:)(?:[^\"\\\\\\n]|\\\\.)*\"(?![ \\t]*:)", .string),
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
        tagWords(
            [
                "const", "let", "var", "function", "return", "if", "else", "for", "while", "do", "then", "fi", "done", "in", "def",
                "class", "import", "from", "true", "false", "null",
            ], .keyword, insideSyntaxHighlight),
        (insideSyntaxHighlight + "(?<![\\w.])-?\\d+(?:\\.\\d+)?\\b", .number),
        (insideSyntaxHighlight + insideTemplateData + "\"(?:[^\"\\\\\\n]|\\\\.)*\"(?=[ \\t]*:)", .property),
    ]

    /// Inside a `<templatedata>` block (JSON).
    static let insideTemplateData = inside(opens: ["<templatedata>"], closes: ["</templatedata>"], within: 20000)

    /// Inside a `<syntaxhighlight>` or `<source>` block, between its tags.
    static let insideSyntaxHighlight = inside(
        opens: ["<(?:syntaxhighlight|source)\\b[^>]*>"], closes: ["</(?:syntaxhighlight|source)>"], within: 20000)
}
