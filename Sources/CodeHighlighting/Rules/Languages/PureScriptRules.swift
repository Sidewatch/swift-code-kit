//
//  PureScriptRules.swift
//  CodeHighlighting
//
//  The regex rule table for PureScript.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// PureScript: `--` and nested `{- -}` comments, `"""…"""` raw strings across lines, `"…"` strings
/// with escapes and `\`-gaps, one-character `'…'` literals with escapes (a prime inside an
/// identifier, `Symbol'`, opens nothing), the keywords, and capitalised names as types.
extension RuleTables {
    static let purescript: [(String, TokenKind)] = [
        ("\\{-(?:[^-{]|-(?!\\})|\\{(?!-)|\\{-(?:[^-{]|-(?!\\})|\\{(?!-))*-\\})*-\\}", .comment),
        dashComment,
        tripleDoubleQuoted,
        doubleQuoted,
        ("(?<![\\w'])'(?:[^'\\\\\\n]|\\\\(?:x[0-9a-fA-F]+|[^\\n]))'", .string),
        keywords([
            "module", "where", "import", "as", "hiding", "qualified", "data", "newtype", "type", "class", "instance",
            "derive", "foreign", "forall", "let", "in", "if", "then", "else", "case", "of", "do", "ado", "infix",
            "infixl", "infixr", "deriving", "role", "nominal", "representational", "phantom",
        ]),
        constants(["true", "false"]),
        ("\\b[A-Z]\\w*'*", .type),
        ("\\b0[xX][0-9a-fA-F]+\\b|\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b", .number),
    ]
}
