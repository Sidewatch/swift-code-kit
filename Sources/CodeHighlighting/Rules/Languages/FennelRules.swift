//
//  FennelRules.swift
//  CodeHighlighting
//
//  The regex rule table for Fennel.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Fennel: `;` comments, `"…"` strings and `:string` shorthand, Lua's hex numbers, `nil` / `true` /
/// `false`, and the special forms with the threading and nil-safe forms (`->>`, `?.`). The arithmetic,
/// comparison and access operators (`+`, `=`, `.`, `:`) are forms too but stay plain, as operators do
/// in every table: they are a third of a program's tokens, and each paint costs more the more the pass
/// has painted.
extension RuleTables {
    static let fennel: [(String, TokenKind)] = lispDialect(
        specialForms: [
            "fn", "lambda", "λ", "local", "var", "global", "macro", "macros", "let", "set", "tset", "set-forcibly!", "values",
            "if", "when", "do", "while", "each", "for", "case", "case-try", "match", "match-try", "collect", "icollect",
            "fcollect", "accumulate", "faccumulate", "doto", "with-open", "pick-values", "pick-args", "partial", "hashfn",
            "lua", "quote", "unquote", "comment", "include", "import-macros", "require-macros", "eval-compiler",
            "macrodebug", "assert-repl", "tail!", "length", "not", "not=", "and", "or", "band", "bor", "bxor", "bnot",
            "lshift", "rshift", "->", "->>", "-?>", "-?>>", "?.",
        ],
        constants: ["nil", "true", "false"],
        quotedSymbols: false,
        numbers: [lispNumber, (lispWordStart + "-?0[xX][0-9a-fA-F_]+" + lispWordEnd, .number)]
    )
}
