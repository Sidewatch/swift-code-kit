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
/// a promoted constructor (`'Just`) or a MagicHash suffix after a literal is not a second quote. The name a
/// type signature declares (`name :: T` at a line's start) and the lowercase names of an import list or
/// the module's export list are functions, as VS Code paints them.
extension RuleTables {
    static let haskell: [(String, TokenKind)] = [
        (haskellImportList + haskellExportList + "\\b[a-z_][\\w']*", .function),
        haskellSignatureName,
        ("(?<![!#$%&*+./<=>?@\\\\^|~:-])--+(?![!#$%&*+./<=>?@\\\\^|~:-]).*$", .comment),
        ("\\{-[\\s\\S]*?-\\}", .comment),
        ("\"\"\"[\\s\\S]*?\"\"\"", .string),
        doubleQuoted,
        ("(?<![\\w'])'(?:[^'\\\\\\n]|\\\\(?:\\^.|[A-Z]{2,3}|[xXoO]?[0-9a-fA-F]+|.))'", .string),
        keywords([
            "let", "in", "module", "import", "qualified", "as", "hiding", "type", "data", "newtype",
            "class", "instance", "where", "case", "of", "if", "then", "else", "do", "deriving",
            "forall", "infix", "infixl", "infixr", "default", "foreign", "family", "pattern", "mdo", "proc",
        ]),
        ("\\b[A-Z][\\w']*", .type),
        ("\\b\\d[\\d_]*(\\.\\d+)?([eE][+-]?\\d+)?#{0,2}\\b|\\b0[xXbBoO][0-9a-fA-F_]+#{0,2}\\b", .number),
    ]

    /// The names a type signature declares: `name ::` or `a, b ::` opening a line, at any indentation (a
    /// class method's, a `where` block's); the commas between them too, as VS Code paints the list.
    static let haskellSignatureName: (String, TokenKind) = (
        "^[ \\t]*[a-z_][\\w']*(?:[ \\t]*,[ \\t]*[a-z_][\\w']*)*(?=[ \\t]*::)", .function
    )

    /// An `import` line's parenthesised name list, from `import` to the `)` that ends the line.
    static let haskellImportList = RuleScope.marker(opens: ["(?m:^)import\\b[^(\\n]*\\("], closes: ["\\)(?m:[ \\t]*$)"], within: 2000)

    /// The module header's export list, from `module` to its `where`.
    static let haskellExportList = RuleScope.marker(opens: ["(?m:^)module\\b"], closes: ["\\bwhere\\b"], within: 4000)
}
