//
//  OCamlRules.swift
//  CodeHighlighting
//
//  The regex rule table for OCaml.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// OCaml: nesting `(* *)` comments (the language table adds them) — there is no `--` or `{- -}` comment;
/// `"…"` strings with backslash escapes, `{|…|}` / `{id|…|id}` quoted strings and `'a'` / `'\n'` / `'\x41'`
/// character literals, while a type variable `'a` opens nothing; the manual's keywords; capitalised
/// constructors and modules; numbers with `_`, prefixes and `l` / `L` / `n` suffixes.
extension RuleTables {
    static let ocaml: [(String, TokenKind)] = [
        ("\\{([a-z_]*)\\|[\\s\\S]*?\\|\\1\\}", .string),
        doubleQuoted,
        ("'(?:\\\\(?:[\\\\'\"ntbr ]|\\d{3}|x[0-9a-fA-F]{2}|o[0-3][0-7]{2})|[^\\\\'\\n])'", .string),
        keywords([
            "and", "as", "assert", "asr", "begin", "class", "constraint", "do", "done", "downto", "else", "end",
            "exception", "external", "for", "fun", "function", "functor", "if", "in", "include", "inherit",
            "initializer", "land", "lazy", "let", "lor", "lsl", "lsr", "lxor", "match", "method", "mod", "module",
            "mutable", "new", "nonrec", "object", "of", "open", "or", "private", "rec", "sig", "struct", "then", "to",
            "try", "type", "val", "virtual", "when", "while", "with",
        ]),
        constants(["true", "false"]),
        ("\\b[A-Z][A-Za-z0-9_']*", .type),
        decimal,
    ]
}
