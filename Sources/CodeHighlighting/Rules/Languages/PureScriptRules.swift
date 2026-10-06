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
/// identifier, `Symbol'`, opens nothing), the keywords, and capitalised names as types. As in Haskell, the
/// name a signature declares and the lowercase names of an import or export list are functions; the
/// reserved symbols `::`, `->`, `=>`, `<-` (and `∀`, `→`, `⇒`) and a data declaration's `=` are keywords, as
/// VS Code paints them.
extension RuleTables {
    static let purescript: [(String, TokenKind)] = [
        (haskellImportList + haskellExportList + "\\b[a-z_][\\w']*", .function),
        haskellSignatureName,
        ("(?:::|->|=>|<-)(?<![!#$%&*+./<=>?@\\\\^|~:-]..)(?![!#$%&*+./<=>?@\\\\^|~:-])|[∀→⇒←∷]", .keyword),
        (purescriptDataHead + "=(?!=)", .keyword),
        ("^[ \\t]+=(?![!#$%&*+./<=>?@\\\\^|~:-])", .keyword),
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
        ("\\b0[xX][0-9a-fA-F]+\\b|\\b0b[01]+\\b|\\b\\d[\\d_]*(\\.\\d[\\d_]*)?([eE][+-]?\\d+)?\\b", .number),
    ]

    /// A `data` or `newtype` declaration's head, up to its `=` on the same line.
    static let purescriptDataHead = RuleScope.marker(opens: ["(?m:^)(?:data|newtype)\\b"], closes: ["=", "\\n"], within: 200)
}
