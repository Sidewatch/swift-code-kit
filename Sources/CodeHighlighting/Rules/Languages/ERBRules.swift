//
//  ERBRules.swift
//  CodeHighlighting
//
//  The regex rule table for ERB (Embedded Ruby).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// ERB: `<%# %>` comments (the language's own), the `<% %>` / `<%= %>` / `<%- -%>` delimiters, and
/// the Ruby inside them — `#` comments to the line end or the tag's close, `=begin … =end` blocks,
/// strings (a `"…"` string's `#{ }` interpolations stay code:
/// ``interpolatedStrings(quote:sigil:scope:multiline:)``) and `%w[]` literals, symbols, instance variables, keywords and numbers — with the HTML around them.
extension RuleTables {
    static let erb: [(String, TokenKind)] =
        [
            htmlComment,
            // A `#{` opens an interpolation, not a comment.
            (insideScriptletTag + "#(?!\\{)(?:(?!%>)[^\\n])*", .comment),
            (insideScriptletTag + "^=begin\\b[\\s\\S]*?^=end\\b.*$", .comment),
            // `%w[a b]`, `%i(x y)`, `%q{text}`: a percent literal on one line.
            (insideScriptletTag + "%[qQwWiI]?(?:\\[[^\\]\\n]*\\]|\\([^)\\n]*\\)|\\{[^}\\n]*\\})", .string),
        ] + interpolatedStrings(quote: "\"", sigil: "#", scope: insideScriptletTag) + [
            (insideScriptletTag + "'(?:[^'\\\\]|\\\\[\\s\\S])*'", .string),
            ("(?<==)\"[^\"{<\\n]*\"", .string),
            ("(?<==)'[^'{<\\n]*'", .string),
            ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .attribute),
            ("<%(?!%)[-=]{0,2}|-?%>", .keyword),
            (insideScriptletTag + "\\b([a-z_]\\w*[?!]?)(?=\\()", .function),
            tagWords(
                [
                    "alias", "and", "begin", "break", "case", "class", "def", "defined", "do", "else", "elsif", "end", "ensure", "for",
                    "if", "in", "module", "next", "not", "or", "redo", "rescue", "retry", "return", "self", "super", "then", "undef",
                    "unless", "until", "when", "while", "yield", "lambda", "proc", "raise", "require",
                ], .keyword, insideScriptletTag),
            tagWords(["true", "false", "nil"], .number, insideScriptletTag),
            (insideScriptletTag + "(?<![\\w:]):[A-Za-z_]\\w*[?!]?", .string),
            (insideScriptletTag + "@{1,2}[A-Za-z_]\\w*", .type),
            (insideScriptletTag + "\\b[A-Z][A-Z0-9_]*\\b", .type),
            (insideScriptletTag + decimal.0, .number),
        ]
}
