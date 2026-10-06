//
//  ElmRules.swift
//  CodeHighlighting
//
//  The regex rule table for Elm.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Elm: `--` and nesting `{- -}` comments (the language table adds them), `"""…"""` and `"…"` strings,
/// `'x'` character literals with `\u{…}` escapes, Elm's own reserved words (`type alias`, `port`,
/// `exposing`, `as` — there is no `class` or `data`), capitalised types and constructors, and numbers.
/// The name a type annotation declares (`name :` opening a line) and the lowercase names of an
/// `exposing ( … )` list are functions, as VS Code paints them.
extension RuleTables {
    static let elm: [(String, TokenKind)] = [
        (elmExposingList + "\\b[a-z_]\\w*", .function),
        ("^[ \\t]*[a-z_]\\w*(?=[ \\t]*:(?![:!#$%&*+./<=>?@\\\\^|~-]))", .function),
        tripleDoubleQuoted,
        doubleQuoted,
        ("'(?:[^'\\\\\\n]|\\\\(?:u\\{[0-9a-fA-F]+\\}|.))'", .string),
        keywords([
            "if", "then", "else", "case", "of", "let", "in", "type", "alias", "module", "where", "import", "exposing", "as",
            "port", "effect", "infix",
        ]),
        ("\\b[A-Z]\\w*", .type),
        ("\\b(?:0x[0-9a-fA-F]+|\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\b", .number),
    ]

    /// A module's or an import's `exposing ( … )` list, to the `)` that ends its line.
    static let elmExposingList = RuleScope.marker(opens: ["\\bexposing[ \\t]*\\("], closes: ["\\)(?m:[ \\t]*$)"], within: 2000)
}
