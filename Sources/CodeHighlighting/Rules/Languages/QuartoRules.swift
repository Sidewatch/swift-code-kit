//
//  QuartoRules.swift
//  CodeHighlighting
//
//  The regex rule table for Quarto.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Quarto (and R Markdown's shape): Markdown plus `{r}` / `{python}` fences, `#|` chunk
/// options, inline `r …` code, `:::` fenced divs, the frontmatter's keys.
extension RuleTables {
    static let quarto: [(String, TokenKind)] =
        [
            ("^```\\{[^}]*\\}\\s*$|^```\\s*$", .keyword),
            ("^#\\|\\s*[\\w-]+:", .attribute),
            ("`r [^`]+`", .function),
            ("^:::+.*$", .keyword),
            ("^[\\w-]+:(?=\\s)", .property),
            // A frontmatter fence; a `---` under a line of text is a setext heading's underline instead.
            ("^(?<![^\\n]\\n)---\\s*$", .comment),
        ] + markdown.filter { rule in !quartoReplacedMarkdown.contains(rule.0) } + quartoMarkdown

    /// Quarto without its fence rules, for ``EmbeddedMarkupHighlighter``, which finds the fenced blocks
    /// itself and paints each chunk in its own language.
    static let quartoMarkup: [(String, TokenKind)] = quarto.filter { rule in !markdownFences.contains { $0.0 == rule.0 } }

    /// The Markdown rules Quarto paints its own way (``quartoMarkdown``): a block quote's line and a thematic break.
    private static let quartoReplacedMarkdown: Set<String> = ["^>+\\s?.*$", "^\\s*(\\*{3,}|-{3,}|_{3,})\\s*$"]

    /// Markdown as the tree-sitter tier paints it: a block quote's markers (not its text) and a thematic break as
    /// comments, a setext heading's underline as a keyword, a backslash escape, a link's title and an HTML attribute's
    /// quoted value as strings.
    private static let quartoMarkdown: [(String, TokenKind)] = [
        ("^[ \\t]{0,3}>(?:[ \\t]?>)*", .comment),
        ("^(?<![^\\n]\\n)\\s*(\\*{3,}|-{3,}|_{3,})\\s*$", .comment),
        ("^(?<=[^\\n]\\n)[ \\t]{0,3}(?:=+|-+)[ \\t]*$", .keyword),
        ("\\\\[!-/:-@\\[-`{-~]", .string),
        ("\"[^\"\\n]*\"(?=\\))(?<=\\]\\([^)\\s]{1,300}[ \\t]{1,10}\"[^\"\\n]{0,200}\")", .string),
        ("\"[^\"\\n]*\"(?=[ \\t]*$)(?<=^\\[[^\\]\\n]{1,100}\\]:[^\\n]{1,300})", .string),
        // A bracketed Pandoc citation (`[@smith2020; @jones2021, p. 12]`, `[-@jones2021]`), a link to the reference.
        ("\\[-?@[^\\]\\n]*\\]", .type),
        // A quoted attribute value in an HTML tag (`<div class="note">`).
        ("\"[^\"\\n]*\"(?=[^<>\\n]{0,200}>)(?<=<[A-Za-z][\\w-]{0,30}\\s[^<>\\n]{0,200}=\"[^\"\\n]{0,200}\")", .string),
    ]
}
