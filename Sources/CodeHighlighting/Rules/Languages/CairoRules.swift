//
//  CairoRules.swift
//  CodeHighlighting
//
//  The regex rule table for Cairo.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Cairo (1.x, the Rust-like language Starknet contracts are written in): `//` comments (the language
/// table adds them); `"…"` byte-array strings with escapes and `'…'` short strings (a felt252); `#[attributes]`;
/// the language's keywords and built-in types; the name a `struct`, `enum`, `trait`, `impl`, `type` or `mod`
/// declares as a type; the name an `fn` declares, every call and every macro (`assert!`, `array!`) as a function.
extension RuleTables {
    static let cairo: [(String, TokenKind)] = [
        doubleQuoted,
        ("'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        declaration(after: ["struct", "enum", "trait", "impl", "type", "mod"]),
        declaration(after: ["fn"], .function),
        callee,
        ("\\b[A-Za-z_]\\w*!(?=[ \\t]*[(\\[{])", .function),
        wordTrie(
            [
                "as", "break", "const", "continue", "else", "enum", "extern", "fn", "for", "if", "impl", "implicits", "in",
                "let", "loop", "match", "mod", "mut", "nopanic", "of", "pub", "ref", "return", "self", "struct", "super",
                "trait", "type", "use", "while", "crate", "Self", "macro",
            ], .keyword),
        wordTrie(
            [
                "felt252", "bool", "u8", "u16", "u32", "u64", "u128", "u256", "usize", "i8", "i16", "i32", "i64", "i128",
                "bytes31", "ByteArray", "ContractAddress", "ClassHash", "Array", "Span", "Option", "Result", "Felt252Dict",
                "Nullable", "Box",
            ], .type),
        constants(["true", "false"]),
        ("#\\[[^\\]\\n]*\\]", .attribute),
        decimal,
    ]
}
