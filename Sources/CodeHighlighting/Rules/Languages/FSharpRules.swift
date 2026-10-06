//
//  FSharpRules.swift
//  CodeHighlighting
//
//  The regex rule table for F#.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// F#: `//` and `(* … *)` comments; `"…"` with escapes, `@"…"` verbatim strings (a doubled quote is a quote),
/// `"""…"""` triple-quoted strings, and `'x'` character literals including `'\''` and `'"'`. A prime inside an
/// identifier (`query'`) or a type variable (`'a`) is not a character literal. `$"…"`, `$@"…"` and `$$"""…"""`
/// interpolated strings carry their `$` prefixes; `let!`, `use!`, `return!` and the other bang forms are keywords
/// whole, and the name a `type` declaration binds (a unit of measure's too) is a type.
extension RuleTables {
    static let fsharp: [(String, TokenKind)] = [
        lineComment,
        ("\\(\\*(?!\\))[\\s\\S]*?\\*\\)", .comment),
        ("\\$*\"\"\"[\\s\\S]*?\"\"\"", .string),
        ("[@$]+\"(?:[^\"]|\"\")*\"", .string),
        doubleQuoted,
        ("(?<![\\w'])'(?:[^'\\\\\\n]|\\\\(?:u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8}|x[0-9A-Fa-f]{2}|\\d{3}|.))'B?", .string),
        ("\\btype[ \\t]+[A-Za-z_][\\w']*", .type),
        ("\\b(?:let|use|do|return|yield|match|and)!", .keyword),
        keywords([
            "let", "in", "module", "namespace", "open", "type", "val", "mutable", "rec", "and",
            "fun", "function", "match", "with", "if", "then", "else", "elif", "for", "to",
            "downto", "while", "do", "done", "begin", "end", "try", "finally", "yield", "return",
            "use", "new", "inherit", "interface", "abstract", "override", "member", "static", "private", "public",
            "internal", "inline", "lazy", "async", "task", "not", "of", "as", "when", "upcast", "downcast",
            "exception", "raise", "failwith", "assert", "null", "struct", "class", "delegate", "base", "default", "extern",
            "fixed", "global", "const", "enum", "select", "sig",
        ]),
        ("\\b[A-Z]\\w*\\b", .type),
        ("\\b\\d[\\d_]*(\\.\\d+)?([eE][+-]?\\d+)?[a-zA-Z]{0,2}\\b|\\b0[xXbBoO][0-9a-fA-F_]+[a-zA-Z]{0,2}\\b", .number),
    ]
}
