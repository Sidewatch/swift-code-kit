//
//  NushellRules.swift
//  CodeHighlighting
//
//  The regex rule table for Nushell.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Nushell: `#` comments that start a word (`r#'…'#` is a raw string, not a comment), `"…"`, `'…'`,
/// `` `…` ``, `r#'…'#` raw strings, `$"…(expr)…"` interpolations whose `( … )` may hold quotes, `./paths`,
/// numbers with their units (`10kb`, `500ms`, `1.5MiB`), `$variables`, `@attributes`, and the language's
/// keywords and word operators.
extension RuleTables {
    static let nushell: [(String, TokenKind)] = [
        ("#(?<![^\\s;|(\\[{]#).*$", .comment),
        ("r(#+)'[\\s\\S]*?'\\1", .string),
        nushellInterpolated(quote: "\""),
        nushellInterpolated(quote: "'"),
        doubleQuoted,
        singleQuotedPlain,
        backQuoted,
        // A path opens on its `../`, `./` or `~/` and then checks that nothing word-like precedes it.
        ("(?:\\.\\./(?<![\\w$.]\\.\\./)|\\./(?<![\\w$.]\\./)|~/(?<![\\w$.]~/))[^\\s|;)\\]}]*", .string),
        ("(?<![^\\s(\\[{|;])\\b(?:" + nushellKeywords.joined(separator: "|") + ")(?![\\w-])", .keyword),
        constants(["true", "false", "null"]),
        decimal,
        ("\\$[A-Za-z_]\\w*", .type),
        ("^[ \\t]*@[\\w-]+", .attribute),
    ]

    /// The keywords and word operators of Nushell.
    static let nushellKeywords = [
        "def", "let", "mut", "const", "use", "export-env", "export", "extern", "module", "overlay", "source-env", "source",
        "alias", "if", "else", "match", "for", "in", "while", "loop", "break", "continue", "return", "try", "catch",
        "finally", "do", "where", "hide-env", "hide", "and", "or", "xor", "not-in", "not-like", "not-has", "not", "mod",
        "starts-with", "ends-with", "like", "has", "bit-and", "bit-or", "bit-xor", "bit-shl", "bit-shr", "error make",
    ]

    /// `$"…"` / `$'…'`: a `( … )` hole may hold quoted strings and one more level of parentheses.
    private static func nushellInterpolated(quote: String) -> (String, TokenKind) {
        let escape = quote == "\"" ? "|\\\\[\\s\\S]" : ""
        let hole = "\\((?:[^()\"']|\"(?:[^\"\\\\\\n]|\\\\.)*\"|'[^'\\n]*'|\\((?:[^()\"']|\"[^\"\\n]*\"|'[^'\\n]*')*\\))*\\)"
        return ("\\$\(quote)(?>[^\(quote)\\\\(]+\(escape)|\(hole)|\\(|\\\\)*\(quote)", .string)
    }
}
