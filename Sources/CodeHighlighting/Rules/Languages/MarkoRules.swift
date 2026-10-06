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
/// whitespace, so a URL's `//` opens none) and `/* */`, `<!-- -->` and `<html-comment>` comments,
/// JavaScript's strings, regular expressions and template literals (``templateLiteralPieces(skip:scope:)``),
/// keywords, type names, arrows and numbers, `$ ` scriptlets and `${ }` placeholders, tags with their
/// `.class` / `#id` shorthands, CDATA text, and a style block's language and units.
extension RuleTables {
    static let marko: [(String, TokenKind)] =
        [
            htmlComment,
            ("(?:^|(?<=\\s))//.*$", .comment),
            blockComment,
            // The text of an `<html-comment>` tag is a comment that reaches the output.
            ("(?<=<html-comment>)[^<]*(?=</html-comment>)", .comment),
            // A CDATA section's text is raw, `${ }` included.
            ("(?<=<!\\[CDATA\\[)[\\s\\S]*?(?=\\]\\]>)", .string),
            // A regular expression literal where an expression starts: after `${`, `(`, `,`, `=` or `:`.
            ("/(?<=(?:\\$\\{|[(,=:][ \\t]?)/)(?:[^/\\\\\\s]|\\\\.)(?:[^/\\\\\\n]|\\\\.)*/[dgimsuy]*", .string),
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
            ("=>", .keyword),
            // A type name a declaration introduces (`interface Input`) or a generic one (`Array<…>`).
            ("\\b[A-Z][\\w$]*(?=<)|\\b[A-Z][\\w$]*\\b(?<=(?:interface|class|type|enum|extends|implements) [A-Z][\\w$]{0,80})", .type),
            // A style block's language (`style.less {`) and a stylesheet's units (`10%`).
            ("(?<=\\bstyle)\\.[a-z]+(?=\\s*\\{)|%(?<=\\d%)", .keyword),
            constants(["true", "false", "null", "undefined"]),
            decimal,
            ("\\B\\.\\d+\\b", .number),
        ]
        + templateLiteralPieces(skip: [htmlComment.0, "//(?<!\\S//)[^\\n]*", blockComment.0, "\"(?:[^\"\\\\\\n]|\\\\.)*\"", "'(?:[^'\\\\\\n]|\\\\.)*'"])
}
