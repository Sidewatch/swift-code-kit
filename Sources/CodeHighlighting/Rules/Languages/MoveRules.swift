//
//  MoveRules.swift
//  CodeHighlighting
//
//  The regex rule table for Move.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Move: `//` and `/* */` comments (the language table adds them); `"…"`, `b"…"` byte and `x"…"` hex
/// strings — there are no `'…'` strings, a `'name` is a loop or block label; `@0x1` addresses; integer
/// suffixes (`10u64`); the keywords of Move 2 and its specification language.
extension RuleTables {
    static let move: [(String, TokenKind)] = [
        ("\\b[bx]?\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("\\b([A-Za-z_]\\w*)(?=\\s*(?:<[^<>()]*>)?\\s*\\()", .function),
        keywords([
            "abort", "aborts_if", "aborts_with", "acquires", "address", "apply", "as", "assert", "assume", "axiom",
            "break", "choose", "const", "continue", "copy", "decreases", "else", "emits", "ensures", "entry", "enum",
            "except", "exists", "forall", "friend", "fun", "global", "has", "if", "in", "include", "inline",
            "invariant", "let", "local", "loop", "macro", "match", "modifies", "module", "move", "mut", "native",
            "package", "phantom", "pragma", "public", "requires", "return", "schema", "script", "spec", "struct",
            "succeeds_if", "to", "update", "use", "where", "while", "with",
        ]),
        types(["u8", "u16", "u32", "u64", "u128", "u256", "bool", "address", "signer", "vector", "Self"]),
        constants(["true", "false"]),
        ("'[A-Za-z_]\\w*", .attribute),
        ("@0x[0-9a-fA-F]+|@[A-Za-z_]\\w*", .number),
        ("#\\[[^\\]\\n]*\\]", .attribute),
        decimal,
    ]
}
