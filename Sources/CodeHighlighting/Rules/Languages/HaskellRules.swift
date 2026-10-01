//
//  HaskellRules.swift
//  CodeHighlighting
//
//  The regex rule table for Haskell.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Haskell: `--` and `{- … -}` comments; `"…"` strings with escapes and `\ … \` gaps, `"""…"""` multiline
/// strings, and `'x'` character literals including `'\''` and `'"'`. A prime inside an identifier (`Void'`),
/// a promoted constructor (`'Just`) or a MagicHash suffix after a literal is not a second quote.
extension RuleTables {
    static let haskell: [(String, TokenKind)] = [
        ("(?<![!#$%&*+./<=>?@\\\\^|~:-])--+(?![!#$%&*+./<=>?@\\\\^|~:-]).*$", .comment),
        ("\\{-[\\s\\S]*?-\\}", .comment),
        ("\"\"\"[\\s\\S]*?\"\"\"", .string),
        doubleQuoted,
        ("(?<![\\w'])'(?:[^'\\\\\\n]|\\\\(?:\\^.|[A-Z]{2,3}|[xXoO]?[0-9a-fA-F]+|.))'#?", .string),
        keywords([
            "let", "in", "module", "import", "qualified", "as", "hiding", "type", "data", "newtype",
            "class", "instance", "where", "case", "of", "if", "then", "else", "do", "deriving",
            "forall", "infix", "infixl", "infixr", "default", "foreign", "family", "pattern", "mdo", "proc",
        ]),
        ("\\b[A-Z][\\w']*\\b", .type),
        ("\\b\\d[\\d_]*(\\.\\d+)?([eE][+-]?\\d+)?#{0,2}\\b|\\b0[xXbBoO][0-9a-fA-F_]+#{0,2}\\b", .number),
    ]
}
