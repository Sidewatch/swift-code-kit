//
//  LuauRules.swift
//  CodeHighlighting
//
//  The regex rule table for Luau.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Luau (Roblox's typed Lua, as luau.org's grammar and lexer define it): `--` comments and long comments of
/// any level, `--[==[ … ]==]` (the `--!strict` directives are comments too; the language table adds the line
/// form); `"…"` and `'…'` strings, which end at a raw line break, long strings of any level, and backtick
/// strings whose `{…}` holes stay code; Lua's keywords with Luau's `continue`, and `type`, `export`, `const`,
/// `read` and `write` only where they declare; capitalised names, the name a `type` declares and the built-in
/// type names after `:` or `->` as types; called functions, generic ones (`wrap<T>(…)`) included; `@native`
/// and the other attributes; numbers as the lexer reads them (`_` separators, `0x`, `0b`, a leading `.`);
/// `true`, `false` and `nil`.
extension RuleTables {
    static let luau: [(String, TokenKind)] = {
        // A long bracket of any level; standalone rules only, as the scans join patterns (below).
        let longBracket = "\\[(=*)\\[[\\s\\S]*?\\]\\1\\]"
        let doubleQuote = "\"(?:[^\"\\\\\\n]|\\\\[\\s\\S])*\""
        let singleQuote = "'(?:[^'\\\\\\n]|\\\\[\\s\\S])*'"
        // A hole holds code: strings, a backtick string with holes of its own, and braces one deep.
        let inner = "`(?:[^`\\\\{\\n]|\\\\.|\\{[^{}`\\n]*\\})*`"
        let hole = "\\{(?:[^{}`\"'\\n]|\(doubleQuote)|\(singleQuote)|\(inner)|\\{[^{}`\\n]*\\})*\\}"
        let rules: [(String, TokenKind)] = [
            ("\\b[A-Z][A-Za-z0-9_]*\\b", .type),
            // A call, its generic parameters between the name and the bracket (`wrap<T>(value)`).
            ("\\b[a-zA-Z_]\\w*(?=[ \\t]*(?:<[A-Za-z_][\\w.]*(?:[ \\t]*,[ \\t]*[A-Za-z_][\\w.]*)*>[ \\t]*)?\\()", .function),
            declaration(after: ["type"]),
            wordTrie(
                [
                    "and", "break", "continue", "do", "else", "elseif", "end", "for", "function", "if", "in", "local", "not",
                    "or", "repeat", "return", "then", "until", "while",
                ], .keyword),
            // The contextual keywords, each only where it starts what it declares.
            (
                "\\b(?:export(?=[ \\t]+type\\b)|type(?=[ \\t]+(?:function\\b|[A-Za-z_]))|const(?=[ \\t]+(?:function\\b|[A-Za-z_]))"
                    + "|read(?=[ \\t]+[\\w\\[])|write(?=[ \\t]+[\\w\\[]))", .keyword
            ),
            // A built-in type in a type position; `string.format` is the library.
            (
                "\\b(?=[abnstuv])(?<=(?::|->)[ \\t]{0,8})(?:any|boolean|buffer|never|number|string|thread|unknown|vector)\\b",
                .type
            ),
            constants(["true", "false", "nil"]),
            ("@[A-Za-z_]\\w*|@\\[[ \\t]*[A-Za-z_]\\w*", .attribute),
            // The lexer reads digits, `.` and `_`, an exponent and any letters after as one number (0xFF, 0b_0101, 1e1_0).
            ("\\b\\d[\\d_.]*(?:[eE][+-]?[\\d_]+)?[A-Za-z_\\d]*|(?<![\\w.])\\.\\d[\\d_]*(?:[eE][+-]?[\\d_]+)?", .number),
            (doubleQuote, .string),
            (singleQuote, .string),
            (longBracket, .string),
            ("--" + longBracket, .comment),
        ]
        // The scans join their patterns into one, where a backreference would name another pattern's group:
        // long brackets of levels 0 to 4 written out.
        let anyLevel = (0...4).map { level in
            let equals = String(repeating: "=", count: level)
            return "\\[\(equals)\\[[\\s\\S]*?\\]\(equals)\\]"
        }.joined(separator: "|")
        return rules
            + interpolatedStringPieces(
                open: "`", close: "`", literal: "[^`\\\\{\\n]|\\\\[\\s\\S]", hole: hole, holeOpen: "\\{", holeClose: "\\}",
                skip: ["--(?:\(anyLevel))", "--[^\\n]*", doubleQuote, singleQuote, anyLevel])
    }()
}
