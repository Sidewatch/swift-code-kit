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

/// Elixir: `#` comments (no block comment); `"…"` strings and `'…'` charlists, their `"""` / `'''` heredocs
/// (docs are strings) and the lowercase sigils quoted the same way (`~s"…"`, `~c'…'`), each with `#{ … }`
/// interpolations that stay code; the other `~s(…)` sigils in every delimiter with their modifiers, painted
/// whole; `?a` / `?\n` / `?"` character literals (a quote there opens nothing), `:atoms`, `@attributes`.
extension RuleTables {
    static let elixir: [(String, TokenKind)] =
        [
            ("~[A-Z]+\"\"\"[\\s\\S]*?\"\"\"[a-zA-Z]*", .string),
            ("~[A-Z]+'''[\\s\\S]*?'''[a-zA-Z]*", .string),
            (elixirSigil, .string),
            ("(?<![\\w?!])\\?(?:\\\\x[0-9a-fA-F]{1,2}|\\\\u\\{[0-9a-fA-F]+\\}|\\\\u[0-9a-fA-F]{4}|\\\\[\\s\\S]|[^\\s\\\\])", .string),
            ("(?<![:\\w]):[A-Za-z_]\\w*[?!]?", .string),
            // A charlist and a charlist heredoc paint whole, holes included (see below).
            ("(?:~[a-z])?'''[\\s\\S]*?'''", .string),
            ("(?:~[a-z])?'(?!'')(?:[^'\\\\]|\\\\[\\s\\S])*'[a-zA-Z]*", .string),
        ]
        // A string and a heredoc are painted around their holes (a sigil's modifiers after its close, `~r"…"i`).
        // A form's text may hold the other's quotes, so each finds its own tails, a pass over the text each; a
        // charlist's two forms, now written `~c"…"`, would be two more.
        + elixirQuoted(
            "\"\"\"", text: "[^\"\\\\#{\\n]|\"(?!\"\")",
            others: ["\"(?!\"\")(?:[^\"\\\\]|\\\\[\\s\\S])*\"", "'''[\\s\\S]*?'''", "'(?!'')(?:[^'\\\\]|\\\\[\\s\\S])*'"])
        + elixirQuoted(
            "\"(?!\"\")", close: "\"[a-zA-Z]*", text: "[^\"\\\\#{\\n]",
            others: ["\"\"\"[\\s\\S]*?\"\"\"", "'''[\\s\\S]*?'''", "'(?!'')(?:[^'\\\\]|\\\\[\\s\\S])*'"])
        + [
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

    /// A sigil painted whole: a lowercase one in a bracket, slash or pipe delimiter, an uppercase one (which
    /// interpolates nothing) in any.
    private static let elixirSigil =
        "~(?:[a-z](?=[(\\[{</|])|[A-Z]+)(?:\\((?:[^()\\\\]|\\\\[\\s\\S])*\\)|\\[(?:[^\\[\\]\\\\]|\\\\[\\s\\S])*\\]|\\{(?:[^{}\\\\]|\\\\[\\s\\S]|\\{[^{}]*\\})*\\}|<(?:[^<>\\\\]|\\\\[\\s\\S])*>|/(?:[^/\\\\]|\\\\[\\s\\S])*/|\\|(?:[^|\\\\]|\\\\[\\s\\S])*\\||\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"|'(?:[^'\\\\]|\\\\[\\s\\S])*')[a-zA-Z]*"

    /// The pieces of one quoted form, opened by `quote` (a lowercase sigil may come first) and closed by
    /// `close` (the quote itself by default); `text` is one character of its text on a line other than an
    /// escape, a `#` or a `{`; `others` are the other forms, which its scans step over.
    private static func elixirQuoted(_ quote: String, close: String? = nil, text: String, others: [String]) -> [(String, TokenKind)] {
        interpolatedStringPieces(
            open: "(?:~[a-z])?" + quote, close: close ?? quote, literal: text + "|\\\\[\\s\\S]|#(?!\\{)|\\{", hole: elixirHole,
            holeOpen: "#\\{", holeClose: "\\}", multiline: true,
            skip: [
                "#(?!\\{)[^\\n]*", "\\?(?<![\\w?!]\\?)(?:\\\\[\\s\\S]|[^\\s\\\\])", "~[A-Z]+\"\"\"[\\s\\S]*?\"\"\"",
                "~[A-Z]+'''[\\s\\S]*?'''",
                elixirSigil,
            ] + others.map { "(?:~[a-z])?" + $0 })
    }

    /// A `#{ … }` hole, its `#` included: Elixir's comment is a `#` that no `{` follows, so the `#` is code.
    /// Braces and strings may be inside it, a string holding a hole of its own (`#{"a #{b}"}`).
    private static let elixirHole: String = {
        let flat = "\"(?:[^\"\\\\#]|\\\\[\\s\\S]|#(?!\\{))*\""
        let inner = "#\\{(?:[^{}\"]|\(flat)|\\{[^{}]*\\})*\\}"
        let string = "\"(?:[^\"\\\\#]|\\\\[\\s\\S]|#(?!\\{)|\(inner))*\""
        return "#\\{(?:[^{}\"']|\(string)|'(?:[^'\\\\]|\\\\.)*'|\\{(?:[^{}\"]|\(string)|\\{[^{}]*\\})*\\})*\\}"
    }()
}
