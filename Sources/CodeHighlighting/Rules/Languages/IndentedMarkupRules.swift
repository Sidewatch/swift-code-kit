//
//  IndentedMarkupRules.swift
//  CodeHighlighting
//
//  The regex rule table for Pug, Haml and Slim.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The indented template languages — Pug, Haml, Slim: comment lines, tags at the start of a
/// line (Haml's `%tag`), `.class` / `#id` shorthands, `(attributes)`, the control words, `-` and
/// `=` code lines, `#{…}` interpolation, `|` piped text, `+mixin` calls.
extension RuleTables {
    static let indentedMarkup: [(String, TokenKind)] = [
        // A comment line (`//`, `//-`, Haml's `-#` and `/`) and every line indented deeper below it: a
        // marker alone on its line opens a block comment. A conditional comment (`/[if IE]`) is its line
        // only; the markup nested under it is rendered.
        ("^([ \\t]*)(?:-#|/(?!\\[)).*(?:\\n\\1[ \\t]+\\S.*|\\n[ \\t]*(?=\\n))*", .comment),
        ("^[ \\t]*/\\[.*$", .comment),
        ("#\\{[^}]*\\}|\\$\\{[^}]*\\}|!\\{[^}]*\\}", .property),
        // Quotes delimit code strings and attribute values, which end on their line: an apostrophe in
        // the text cannot pair with one lines away.
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ("^\\s*\\|.*$", .string),
        ("^\\s*(doctype|!!!)\\b.*$", .keyword),
        (
            "\\b(if|else|elif|elsif|unless|each|for|in|of|while|case|when|default|mixin|include|extends|block|append|prepend|yield|end|do|render|javascript|css|coffee|markdown|sass|scss|var|let|const|return|function)\\b",
            .keyword
        ),
        ("^\\s*%[\\w:-]+", .keyword),
        ("^\\s*[a-z][\\w:-]*(?=[\\s.#(=:]|$)", .keyword),
        ("[.#][A-Za-z_][\\w-]*", .type),
        ("\\+[\\w-]+", .function),
        ("\\b[\\w:-]+(?==)", .attribute),
        ("^\\s*[-=!]=?", .variable),
        decimal,
    ]
}
