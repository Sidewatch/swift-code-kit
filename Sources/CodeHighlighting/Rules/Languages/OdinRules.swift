//
//  OdinRules.swift
//  CodeHighlighting
//
//  The regex rule table for Odin.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Odin: `//` and nesting `/* */` comments (the language table adds them); `"…"` strings with escapes,
/// `` `raw` `` strings and `'c'` runes; `#directives` and `@(attributes)`; the language's keywords and
/// built-in types; numbers with `0x` / `0o` / `0b` / `0h` prefixes and `_` separators; the package a
/// `package` names and every type name (Ada_Case by the language's convention, `Vec2`, `Maybe_Int`, a
/// single-capital `T`) as a type, with the name a `::` declaration gives a `struct`, `enum`, `union`,
/// `distinct`, `bit_set` or `bit_field`, and the parameter a `$T` introduces; a `proc` declared with `::`
/// and every call as a function.
extension RuleTables {
    static let odin: [(String, TokenKind)] = [
        doubleQuoted,
        backQuoted,
        ("'(?:[^'\\\\\\n]|\\\\(?:x[0-9a-fA-F]{2}|u[0-9a-fA-F]{4}|U[0-9a-fA-F]{8}|[0-7]{3}|[^\\n]))'", .string),
        ("\\b[A-Z](?:[a-z0-9]\\w*)?\\b", .type),
        ("\\$[A-Za-z_]\\w*", .type),
        (
            "\\b[A-Za-z_]\\w*(?=[ \\t]*::[ \\t]*(?:distinct|struct|enum|union|bit_set|bit_field)\\b)",
            .type
        ),
        declaration(after: ["package"]),
        callee,
        ("\\b[A-Za-z_]\\w*(?=[ \\t]*::[ \\t]*(?:#force_inline[ \\t]+|#force_no_inline[ \\t]+)?proc\\b)", .function),
        wordTrie(
            [
                "asm", "auto_cast", "bit_field", "bit_set", "break", "case", "cast", "context", "continue", "defer", "distinct",
                "do", "dynamic", "else", "enum", "fallthrough", "for", "foreign", "if", "import", "in", "map", "matrix", "not_in",
                "or_break", "or_continue", "or_else", "or_return", "package", "proc", "return", "struct", "switch", "transmute",
                "typeid", "union", "using", "when", "where",
            ], .keyword),
        wordTrie(
            [
                "bool", "b8", "b16", "b32", "b64", "int", "i8", "i16", "i32", "i64", "i128", "uint", "u8", "u16", "u32", "u64",
                "u128", "uintptr", "i16le", "i32le", "i64le", "i128le", "u16le", "u32le", "u64le", "u128le", "i16be", "i32be",
                "i64be", "i128be", "u16be", "u32be", "u64be", "u128be", "f16", "f32", "f64", "f16le", "f32le", "f64le", "f16be",
                "f32be", "f64be", "complex32", "complex64", "complex128", "quaternion64", "quaternion128", "quaternion256",
                "rune", "string", "cstring", "rawptr", "any",
            ], .type),
        constants(["true", "false", "nil"]),
        ("#\\+?[A-Za-z_]\\w*", .keyword),
        ("@\\(?[A-Za-z_]\\w*", .attribute),
        ("\\b0h[0-9a-fA-F_]+\\b", .number),
        decimal,
    ]
}
