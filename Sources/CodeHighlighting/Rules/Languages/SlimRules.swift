//
//  SlimRules.swift
//  CodeHighlighting
//
//  The regex rule table for Slim.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Slim.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let slim: [(String, TokenKind)] = [
        // `/` opens a code comment and `/!` an HTML comment, each to the end of its line and over every
        // line indented deeper below it; `/[if IE]` opens a conditional one, its line only, whose nested
        // markup is rendered.
        ("^([ \\t]*)/(?!\\[).*(?:\\n\\1[ \\t]+\\S.*|\\n[ \\t]*(?=\\n))*", .comment),
        ("#\\{[^}\\n]*\\}", .property),
        // Quotes only delimit attribute values, which end on their line; a `'` that opens a line is a
        // text block, painted whole before any quote inside it can pair.
        ("^\\s*[|'].*$", .string),
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        // A Ruby symbol (`as: :item`, `params[:q]`) after a space, bracket or comma.
        ("(?<=[\\s(\\[,{]):[A-Za-z_]\\w*[?!]?", .string),
        ("^\\s*(doctype)\\b.*$", .keyword),
        (
            "\\b(if|else|elsif|unless|each|for|in|while|case|when|do|end|yield|render|javascript|css|coffee|markdown|sass|scss|ruby)\\b",
            .keyword
        ),
        ("^\\s*[a-z][\\w:-]*(?=[\\s.#(\\[=:<>]|$)", .keyword),
        ("[.#][A-Za-z_][\\w-]*", .type),
        ("\\b[\\w:-]+(?==)", .attribute),
        ("^\\s*[-=]=?[<>]?", .variable),
        ("\\b\\d+(\\.\\d+)?\\b", .number),
    ]
}
