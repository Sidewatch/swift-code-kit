//
//  ClojureRules.swift
//  CodeHighlighting
//
//  The regex rule table for Clojure.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Clojure: `;` comments, `"…"` strings and `#"…"` regexes, character literals (`\a`, `\space`,
/// `A`, `\"` — a quote after a backslash opens nothing), `:keywords`, the special forms and defining
/// forms, `nil` / `true` / `false`, and numbers in every reader form (`-17`, `0x1F`, `2r1010`, `22/7`,
/// `1.E2`, `1N`, `1.0M`, `##Inf`). The symbol at the head of a list is a call and paints as a function,
/// whole — `System/nanoTime`, `.getMessage`, `java.util` — as both reference highlighters paint it.
extension RuleTables {
    static let clojure: [(String, TokenKind)] = [
        (";.*$", .comment),
        doubleQuoted,
        ("#\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("\\\\(?:newline|space|tab|formfeed|backspace|return|u[0-9a-fA-F]{4}|o[0-7]{1,3}|[\\s\\S])", .string),
        ("(?<=\\()[^\\s()\\[\\]{}\"';@^`~\\\\,:#\\d][^\\s()\\[\\]{}\"';@^`~\\\\,]*", .function),
        (lispWordStart + "::?[^\\s()\\[\\]{}\"';,]+", .type),
        lispWords(
            [
                "def", "if", "do", "let", "quote", "var", "fn", "loop", "recur", "throw", "try", "catch", "finally", "new",
                "def-", "defn", "defn-", "defmacro", "defmulti", "defmethod", "defstruct", "defonce", "declare", "definline",
                "definterface", "defprotocol", "defrecord", "deftype", "defproject", "ns", "in-ns",
            ], .keyword),
        lispWords(["nil", "true", "false"], .number),
        (
            lispWordStart
                + "(?:##(?:-?Inf|NaN)|[+-]?(?:0[xX][0-9a-fA-F]+N?|(?:3[0-6]|[12]\\d|[2-9])[rR][0-9a-zA-Z]+N?|\\d+/\\d+|\\d+(?:\\.\\d*)?(?:[eE][+-]?\\d+)?[NM]?))"
                + lispWordEnd,
            .number
        ),
    ]
}
