//
//  IdrisRules.swift
//  CodeHighlighting
//
//  The regex rule table for Idris.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Idris 2: `--` and `|||` doc comments, nesting `{- -}` block comments — `(*)` is the multiplication
/// section, not an ML comment — `"…"` strings, `'x'` character literals (a prime ending a name,
/// `Monoid'`, opens nothing), the keywords, `%default`-style pragmas, capitalised names as types, and numbers.
extension RuleTables {
    static let idris: [(String, TokenKind)] = [
        ("\\|\\|\\|.*$", .comment),
        dashComment,
        nestedBlock("{-", "-}"),
        ("\"\"\"[\\s\\S]*?\"\"\"", .string),
        doubleQuoted,
        ("(?<![\\w'])'(?:[^'\\\\\\n]|\\\\[^'\\n]{1,6}|\\\\')'", .string),
        keywords([
            "data", "record", "interface", "implementation", "where", "let", "in", "case", "of", "if", "then", "else",
            "do", "with", "import", "module", "namespace", "public", "export", "private", "total", "partial",
            "covering", "mutual", "parameters", "using", "auto", "default", "impossible", "rewrite", "proof", "infix",
            "infixl", "infixr", "prefix", "forall", "failing", "constructor", "codata", "syntax", "pattern",
            "term",
        ]),
        ("%[a-z_]+\\b", .keyword),
        ("\\b[A-Z][\\w']*", .type),
        ("\\b(?:0x[0-9a-fA-F]+|0o[0-7]+|0b[01]+|\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\b", .number),
    ]
}
