//
//  VelocityRules.swift
//  CodeHighlighting
//
//  The regex rule table for Velocity.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Velocity: `##` and `#* *#` comments (the language's own), the `#directive` words (also
/// `#{else}`), macro names where a `#macro` declares them and where `#name(…)`, `#@name(…)` or
/// `#{name}` calls them, `$references`, and the strings, numbers and constants of a directive's
/// arguments, with the HTML around them. A quote doubled inside a string is its escape. The content of a
/// `#[[ … ]]#` block is literal text.
extension RuleTables {
    static let velocity: [(String, TokenKind)] = [
        htmlComment,
        // A double-quoted string ends on its line. An HTML attribute value (`="…"`) is one only while it
        // holds no directive: one built from `#if … #end` stays plain around the directives' own
        // colours. A `#set` value may span lines. A single-quoted string ends on its line, so an
        // apostrophe in the page's text cannot open one.
        (outsideUnparsed + "\"(?<!=\")(?:[^\"\\n]|\"\")*\"", .string),
        (outsideUnparsed + "\"(?<==\")(?:[^\"\\n#]|#(?![A-Za-z{@]))*\"", .string),
        (outsideUnparsed + "\"(?<=#set\\(\\$[\\w.]{1,60}\\s{0,3}=\\s{0,3}\")[^\"]*\"", .string),
        (outsideUnparsed + "'(?:[^'\\n]|'')*'", .string),
        ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
        (outsideUnparsed + "\\b[A-Za-z-]+=", .property),
        (outsideUnparsed + "#@?[A-Za-z_]\\w*(?=\\s*\\()|#\\{[A-Za-z_]\\w*\\}", .function),
        (outsideUnparsed + "(?<=macro\\}?\\(\\s{0,8})[A-Za-z_][\\w-]*", .function),
        (
            outsideUnparsed + "#\\{?(?:if|elseif|else|end|foreach|set|macro|parse|include|define|evaluate|break|stop|return)\\b\\}?",
            .keyword
        ),
        (outsideUnparsed + "\\$!?\\{?[A-Za-z_][\\w-]*\\}?", .variable),
        (velocityParentheses + "\\b(?:in|lt|gt|le|ge|eq|ne|and|or|not)\\b", .keyword),
        (outsideUnparsed + "\\b(?:true|false|null)\\b", .number),
        (velocityArguments + "-?\\b\\d+(?:\\.\\d+)?\\b", .number),
    ]

    /// Everything but the `#[[ … ]]#` unparsed-content blocks, whose text Velocity copies out literally: a
    /// directive, reference, string or number inside one is text.
    static let outsideUnparsed = RuleScope.marker(steppingOver: [unparsedBlock], regions: "(?:(?!#\\[\\[)[\\s\\S]){1,2000}", within: 2000)

    /// Inside a `( … )` on its line, outside an unparsed block.
    static let velocityParentheses = RuleScope.marker(steppingOver: [unparsedBlock], regions: "\\([^()\\n]{0,200}[()\\n]?", within: 200)

    /// From a `(` or `[` to the end of its line, outside an unparsed block.
    static let velocityArguments = RuleScope.marker(steppingOver: [unparsedBlock], regions: "[(\\[][^\\n]{0,200}", within: 200)

    /// A `#[[ … ]]#` unparsed-content block.
    private static let unparsedBlock = "#\\[\\[[\\s\\S]*?\\]\\]#"
}
