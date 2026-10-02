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
/// `#{else}`), `$references`, and the strings, numbers and constants of a directive's arguments,
/// with the HTML around them. A quote doubled inside a string is its escape.
extension RuleTables {
    static let velocity: [(String, TokenKind)] = [
        htmlComment,
        // A double-quoted string may span lines; a single-quoted one ends on its line, so an apostrophe
        // in the page's text cannot open one.
        ("\"(?:[^\"]|\"\")*\"", .string),
        ("'(?:[^'\\n]|'')*'", .string),
        ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
        ("\\b[A-Za-z-]+=", .attribute),
        (
            "#\\{?(?:if|elseif|else|end|foreach|set|macro|parse|include|define|evaluate|break|stop|return)\\b\\}?|#@?[A-Za-z_]\\w*(?=\\()",
            .keyword
        ),
        ("\\$!?\\{?[A-Za-z_][\\w-]*\\}?", .variable),
        (inside(opens: ["\\("], closes: ["[()\\n]"], within: 200) + "\\b(?:in|lt|gt|le|ge|eq|ne|and|or|not)\\b", .keyword),
        ("\\b(?:true|false|null)\\b", .number),
        (inside(opens: ["[(\\[]"], closes: ["\\n"], within: 200) + "-?\\b\\d+(?:\\.\\d+)?\\b", .number),
    ]
}
