//
//  MarkoRules.swift
//  CodeHighlighting
//
//  The regex rule table for Marko.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Marko: a JavaScript module and its markup in one file — `//` comments (at a line's start or after
/// whitespace, so a URL's `//` opens none) and `/* */` and `<!-- -->` comments, JavaScript's strings and
/// template literals, keywords and numbers, `$ ` scriptlets and `${ }` placeholders, and tags with their
/// `.class` / `#id` shorthands.
extension RuleTables {
    static let marko: [(String, TokenKind)] = [
        htmlComment,
        ("(?:^|(?<=\\s))//.*$", .comment),
        blockComment,
        backQuoted,
        // JavaScript strings end on their line, so an apostrophe in the markup's text cannot run on.
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ("</?[A-Za-z@][\\w:.#-]*|/>|>", .keyword),
        ("\\b[A-Za-z][\\w-]*(?==)", .attribute),
        call,
        keywords([
            "as", "async", "await", "break", "case", "catch", "class", "const", "continue", "declare", "default", "delete", "do",
            "else", "export", "extends", "finally", "for", "from", "function", "if", "import", "in", "instanceof", "interface", "let",
            "new", "of", "return", "static", "style", "switch", "this", "throw", "try", "type", "typeof", "var", "void", "while",
        ]),
        ("^[ \\t]*\\$(?=\\s)|\\$!?\\{", .keyword),
        constants(["true", "false", "null", "undefined"]),
        decimal,
    ]
}
