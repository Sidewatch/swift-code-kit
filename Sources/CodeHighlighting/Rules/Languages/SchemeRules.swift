//
//  SchemeRules.swift
//  CodeHighlighting
//
//  The regex rule table for Scheme.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Scheme (R7RS, with the common `syntax-case` extensions): `;`, nesting `#| |#` and `#;` datum
/// comments, character literals (`#\space`, `#\x3BB`), `|symbols|`, `#t` / `#f`, the syntax keywords.
extension RuleTables {
    static let schemeSpecialForms: [String] = [
        "define", "define-values", "define-record-type", "define-syntax", "define-library", "let", "let*", "letrec",
        "letrec*", "let-values", "let*-values", "let-syntax", "letrec-syntax", "syntax-rules", "syntax-error", "lambda",
        "case-lambda", "if", "cond", "case", "and", "or", "when", "unless", "do", "begin", "delay", "delay-force",
        "make-promise", "parameterize", "guard", "quote", "quasiquote", "unquote", "unquote-splicing", "set!", "include",
        "include-ci", "import", "export", "cond-expand", "else", "=>", "...", "_", "library", "syntax-case", "syntax",
        "with-syntax", "quasisyntax", "unsyntax", "unsyntax-splicing", "identifier-syntax", "define-syntax-rule", "λ",
    ]
    /// A `#;` datum comment: it comments out the next datum, a word or a list up to two levels deep.
    static let schemeDatumComment: (String, TokenKind) = (
        "#;\\s*(?:\\((?:[^()]|\\((?:[^()]|\\([^()]*\\))*\\))*\\)|\\[(?:[^\\[\\]]|\\[[^\\[\\]]*\\])*\\]|[^\\s()\\[\\]]+)", .comment
    )

    static let scheme: [(String, TokenKind)] = lispDialect(
        specialForms: schemeSpecialForms,
        constants: ["#t", "#f", "#true", "#false"],
        literals: [lispCharacter, schemeDatumComment, ("\\|(?:[^|\\\\]|\\\\.)*\\|", .string)]
    )
}
