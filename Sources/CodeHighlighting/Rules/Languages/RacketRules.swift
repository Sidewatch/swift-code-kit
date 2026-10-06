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
/// and Racket's own forms (`define-values`, `for/list`, `match`, `struct`, the module forms); octal
/// characters (`#\101`), complex and inexact-digit numbers, quoted symbols with escapes and verbatim
/// sections, and the name a `(define (name …)` binds as a function.
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
            ("#\\\\[0-7]{3}", .string),
            racketQuotedSymbol,
            schemeDatumComment,
            ("#<<(\\S+)\\n[\\s\\S]*?^\\1$", .string),
            ("#(?:rx|px)?#?\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
            ("\\|(?:[^|\\\\]|\\\\.)*\\|", .string),
        ],
        quotedSymbols: false,
        numbers: [lispNumber, racketNumber],
        definitions: [lispDefinedName(after: ["define", "define/contract", "define/public", "define/private"], parenthesised: true)]
    )

    /// A quoted symbol the way Racket reads one: ordinary characters, `\`-escaped ones (`'a\ b`) and
    /// `|verbatim|` sections in any mix (`'|a b|c`), and the `#%` prefix of a kernel name (`'#%app`).
    static let racketQuotedSymbol: (String, TokenKind) = {
        let piece = "(?:[^\\s()\\[\\]{}\"',`;|\\\\]|\\\\[\\s\\S]|\\|[^|\\n]*\\|)"
        return ("(?<![\\w#\\\\])'(?:#%|(?!#)\(piece))\(piece)*", .string)
    }()

    /// Racket's other number forms: complex numbers (`1+2i`, `-i`, `3.0-4.5i`), polar ones (`1@2`), and
    /// inexact digits written `#` (`1#.#`, `12##`).
    static let racketNumber: (String, TokenKind) = {
        let unsigned = "(?:(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eEdDfFsSlLtT][+-]?\\d+)?|inf\\.[0ft]|nan\\.[0ft])"
        let real = "[+-]?" + unsigned
        let complex = "(?:" + real + ")?[+-]" + unsigned + "?i|" + real + "@" + real + "|[+-]?\\d+#*\\.#*|[+-]?\\d+#+"
        return (lispWordStart + "(?:" + complex + ")" + lispWordEnd, .number)
    }()
}
