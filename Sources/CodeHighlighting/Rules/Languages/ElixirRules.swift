//
//  ElixirRules.swift
//  CodeHighlighting
//
//  The regex rule table for Elixir.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Elixir: `#` comments (no block comment); `"…"` strings and `'…'` charlists with `#{ … }`
/// interpolation, `"""` / `'''` heredocs (docs are strings), `~s(…)` sigils in every delimiter with their
/// modifiers, `?a` / `?\n` / `?"` character literals (a quote there opens nothing), `:atoms`, `@attributes`.
extension RuleTables {
    static let elixir: [(String, TokenKind)] = [
        hashComment,
        ("~(?:[a-z]|[A-Z]+)\"\"\"[\\s\\S]*?\"\"\"[a-zA-Z]*", .string),
        ("~(?:[a-z]|[A-Z]+)'''[\\s\\S]*?'''[a-zA-Z]*", .string),
        (
            "~(?:[a-z]|[A-Z]+)(?:\\((?:[^()\\\\]|\\\\[\\s\\S])*\\)|\\[(?:[^\\[\\]\\\\]|\\\\[\\s\\S])*\\]|\\{(?:[^{}\\\\]|\\\\[\\s\\S]|\\{[^{}]*\\})*\\}|<(?:[^<>\\\\]|\\\\[\\s\\S])*>|/(?:[^/\\\\]|\\\\[\\s\\S])*/|\\|(?:[^|\\\\]|\\\\[\\s\\S])*\\||\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"|'(?:[^'\\\\]|\\\\[\\s\\S])*')[a-zA-Z]*",
            .string
        ),
        ("\"\"\"[\\s\\S]*?\"\"\"", .string),
        ("'''[\\s\\S]*?'''", .string),
        ("\"(?:[^\"\\\\#]|\\\\[\\s\\S]|#(?!\\{)|#\\{(?:[^{}]|\\{[^{}]*\\})*\\})*\"", .string),
        ("'(?:[^'\\\\#]|\\\\[\\s\\S]|#(?!\\{)|#\\{(?:[^{}]|\\{[^{}]*\\})*\\})*'", .string),
        ("(?<![\\w?!])\\?(?:\\\\x[0-9a-fA-F]{1,2}|\\\\u\\{[0-9a-fA-F]+\\}|\\\\u[0-9a-fA-F]{4}|\\\\[\\s\\S]|[^\\s\\\\])", .string),
        ("(?<![:\\w]):[A-Za-z_]\\w*[?!]?", .string),
        keywords([
            "def", "defp", "defmacro", "defmacrop", "defmodule", "defstruct", "defprotocol", "defimpl", "defdelegate",
            "defguard", "defguardp", "defexception", "defoverridable", "do", "end", "fn", "if", "else", "unless",
            "case", "cond", "when", "with", "for", "try", "rescue", "catch", "after", "raise", "throw", "reraise",
            "receive", "quote", "unquote", "unquote_splicing", "import", "require", "use", "alias", "in", "and",
            "or", "not", "then", "super",
        ]),
        constants(["nil", "true", "false"]),
        ("@[A-Za-z_]\\w*", .type),
        ("\\b[A-Z][A-Za-z0-9_]*(?:\\.[A-Z][A-Za-z0-9_]*)*", .type),
        ("\\b0[xX][0-9a-fA-F_]+\\b|\\b0[oO][0-7_]+\\b|\\b0[bB][01_]+\\b|\\b\\d[\\d_]*(\\.\\d[\\d_]*)?([eE][+-]?\\d+)?\\b", .number),
        ("\\b([a-z_][A-Za-z0-9_]*[?!]?)(?=\\()", .function),
    ]
}
