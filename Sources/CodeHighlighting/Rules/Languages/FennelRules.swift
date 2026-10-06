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

/// Fennel: `;` comments, `"…"` strings and `:string` shorthand, Lua's hex numbers (`0x1.8p1` too) and `1_000_000`
/// separators, `nil` / `true` / `false`, and the special forms with the threading and nil-safe forms
/// (`->>`, `?.`). The arithmetic, comparison and access operators (`+`, `=`, `..`, `.`, `#`, `:`) are
/// special forms in Fennel and paint as keywords where they stand alone, as both VS Code and Pygments
/// paint them; `x#` (an auto-gensym) stays one name.
extension RuleTables {
    static let fennel: [(String, TokenKind)] = lispDialect(
        specialForms: [
            "fn", "lambda", "λ", "local", "var", "global", "macro", "macros", "let", "set", "tset", "set-forcibly!", "values",
            "if", "when", "do", "while", "each", "for", "case", "case-try", "match", "match-try", "collect", "icollect",
            "fcollect", "accumulate", "faccumulate", "doto", "with-open", "pick-values", "pick-args", "partial", "hashfn",
            "lua", "quote", "unquote", "comment", "include", "import-macros", "require-macros", "eval-compiler",
            "macrodebug", "assert-repl", "tail!", "length", "not", "not=", "and", "or", "band", "bor", "bxor", "bnot",
            "lshift", "rshift", "->", "->>", "-?>", "-?>>", "?.", "+", "-", "*", "/", "//", "%", "^", "..", ".", "#", ":",
            "=", "~=", "<", ">", "<=", ">=",
        ],
        constants: ["nil", "true", "false"],
        quotedSymbols: false,
        numbers: [
            lispNumber, (lispWordStart + "-?0[xX][0-9a-fA-F_]*(?:\\.[0-9a-fA-F_]*)?(?:[pP][+-]?\\d+)?" + lispWordEnd, .number),
            (lispWordStart + "[+-]?\\d[\\d_]*(?:\\.[\\d_]*)?(?:[eE][+-]?\\d+)?" + lispWordEnd, .number),
        ]
    )
}
