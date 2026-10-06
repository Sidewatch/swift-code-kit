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
/// `Monoid'`, opens nothing), `#"…"#` raw strings, the keywords and the lexer's reserved symbols (`:`,
/// `=`, `->`, `=>`, `<-`, `\\`, `|`, …) and `_`, `%default`-style pragmas, capitalised names as types,
/// numbers with `_` separators, and the name a signature declares (`name :` opening a line, a data
/// constructor's or a record field's too) as a function.
extension RuleTables {
    static let idris: [(String, TokenKind)] = [
        ("\\|\\|\\|.*$", .comment),
        dashComment,
        nestedBlock("{-", "-}"),
        ("(#+)\"[\\s\\S]*?\"\\1(?!#)", .string),
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
        idrisReservedSymbol,
        ("\\b_\\b", .keyword),
        ("\\b[A-Z][\\w']*", .type),
        ("\\b(?:0x[0-9a-fA-F_]+|0o[0-7_]+|0b[01_]+|\\d[\\d_]*(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\b", .number),
        ("^[ \\t]*[A-Za-z_][\\w']*(?=[ \\t]*:(?![!#$%&*+./<=>?@\\\\^|~:-]))", .function),
    ]

    /// A reserved symbol of the Idris 2 lexer standing alone, not part of a longer operator: `:`, `=`,
    /// `|`, `\\`, `?`, `!`, `&`, `~`, `@`, `%`, `<-`, `->`, `=>`, `:=`, `$=`, `**`, `..`.
    static let idrisReservedSymbol: (String, TokenKind) = {
        let op = "[!#$%&*+./<=>?@\\\\^|~:-]"
        let two = "(?:<-|->|=>|:=|\\$=|\\*\\*|\\.\\.)(?<!\(op)..)(?!\(op))"
        let one = "[:=|?!&~@%\\\\](?<!\(op).)(?!\(op))"
        return (two + "|" + one, .keyword)
    }()
}
