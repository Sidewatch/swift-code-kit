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
/// arguments, with the HTML around them. A quote doubled inside a string is its escape.
extension RuleTables {
    static let velocity: [(String, TokenKind)] = [
        htmlComment,
        // A double-quoted string ends on its line. An HTML attribute value (`="…"`) is one only while it
        // holds no directive: one built from `#if … #end` stays plain around the directives' own
        // colours. A `#set` value may span lines. A single-quoted string ends on its line, so an
        // apostrophe in the page's text cannot open one.
        ("\"(?<!=\")(?:[^\"\\n]|\"\")*\"", .string),
        ("\"(?<==\")(?:[^\"\\n#]|#(?![A-Za-z{@]))*\"", .string),
        ("\"(?<=#set\\(\\$[\\w.]{1,60}\\s{0,3}=\\s{0,3}\")[^\"]*\"", .string),
        ("'(?:[^'\\n]|'')*'", .string),
        ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
        ("\\b[A-Za-z-]+=", .attribute),
        ("#@?[A-Za-z_]\\w*(?=\\s*\\()|#\\{[A-Za-z_]\\w*\\}", .function),
        ("(?<=macro\\}?\\(\\s{0,8})[A-Za-z_][\\w-]*", .function),
        (
            "#\\{?(?:if|elseif|else|end|foreach|set|macro|parse|include|define|evaluate|break|stop|return)\\b\\}?",
            .keyword
        ),
        ("\\$!?\\{?[A-Za-z_][\\w-]*\\}?", .variable),
        (inside(opens: ["\\("], closes: ["[()\\n]"], within: 200) + "\\b(?:in|lt|gt|le|ge|eq|ne|and|or|not)\\b", .keyword),
        ("\\b(?:true|false|null)\\b", .number),
        (inside(opens: ["[(\\[]"], closes: ["\\n"], within: 200) + "-?\\b\\d+(?:\\.\\d+)?\\b", .number),
    ]
}
