//
//  RacketRules.swift
//  CodeHighlighting
//
//  The regex rule table for Racket.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Racket: Scheme's comments, characters and `|symbols|`, plus `#lang`, byte strings (`#"…"`), regexp
/// literals (`#rx"…"`, `#px#"…"`), here strings (`#<<END` to the line `END`), `#:keyword` arguments
/// and Racket's own forms (`define-values`, `for/list`, `match`, `struct`, the module forms).
extension RuleTables {
    static let racket: [(String, TokenKind)] = lispDialect(
        specialForms: schemeSpecialForms + [
            "#lang", "define-syntaxes", "define-for-syntax", "define-struct", "define/contract", "define/public",
            "define/private", "define/override", "define/augment", "define/match", "begin0", "begin-for-syntax", "struct",
            "let/cc", "let/ec", "letrec-values", "letrec-syntaxes+values", "let-syntaxes", "syntax-case*", "syntax/loc",
            "quote-syntax", "module", "module*", "module+", "require", "provide", "only-in", "except-in", "prefix-in",
            "rename-in", "combine-in", "all-defined-out", "all-from-out", "rename-out", "except-out", "prefix-out",
            "struct-out", "contract-out", "for-syntax", "for-label", "for-template", "for-meta", "submod", "local-require",
            "for", "for*", "for/list", "for*/list", "for/vector", "for*/vector", "for/hash", "for*/hash", "for/hasheq",
            "for/fold", "for*/fold", "for/sum", "for*/sum", "for/product", "for/and", "for/or", "for/first", "for/last",
            "for/lists", "for/set", "for*/set", "match", "match*", "match-define", "match-lambda", "match-lambda*",
            "match-let", "match-let*", "match-letrec", "with-handlers", "with-handlers*", "parameterize*", "lazy",
            "class", "class*", "interface", "mixin", "new", "send", "send*", "super-new", "inherit", "field", "init",
            "init-field", "public", "private", "override", "augment", "this", "super", "unit", "local", "shared", "thunk",
            "case->", "->", "->*", "->i", "struct-copy", "set!-values", "with-continuation-mark", "time",
        ],
        constants: ["#t", "#f", "#true", "#false"],
        literals: [
            lispCharacter,
            schemeDatumComment,
            ("#<<(\\S+)\\n[\\s\\S]*?^\\1$", .string),
            ("#(?:rx|px)?#?\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
            ("\\|(?:[^|\\\\]|\\\\.)*\\|", .string),
        ]
    )
}
