//
//  VRules.swift
//  CodeHighlighting
//
//  The regex rule table for V.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// V: `//` and nesting `/* */` comments, `'…'` and `"…"` strings with `r` / `c` prefixes, `` `a` ``
/// rune literals, the V keywords (a keyword before `(` stays a keyword), `$if` compile-time words,
/// `@[attributes]`, the primitive types, and numbers.
extension RuleTables {
    static let v: [(String, TokenKind)] = [
        lineComment,
        nestedBlock("/*", "*/"),
        ("(?:\\b[rc])?'(?:[^'\\\\]|\\\\[\\s\\S])*'", .string),
        ("(?:\\b[rc])?\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("`(?:[^`\\\\\\n]|\\\\[^`\\n]{1,10})`", .string),
        callee,
        keywords([
            "as", "asm", "assert", "atomic", "break", "const", "continue", "defer", "else", "enum", "fn", "for", "go",
            "goto", "if", "import", "in", "interface", "is", "isreftype", "lock", "match", "module", "mut", "none",
            "or", "pub", "return", "rlock", "select", "shared", "sizeof", "spawn", "static", "struct", "type", "typeof",
            "union", "unsafe", "volatile", "__global", "__offsetof", "implements",
        ]),
        ("\\$(?:if|else|for|embed_file|tmpl|env|compile_error|compile_warn)\\b", .keyword),
        ("@\\[[^\\]\\n]*\\]|^\\[[^\\]\\n]*\\]$", .attribute),
        constants(["true", "false", "nil"]),
        types([
            "bool", "string", "i8", "i16", "int", "i32", "i64", "i128", "u8", "u16", "u32", "u64", "u128", "rune", "f32",
            "f64", "isize", "usize", "voidptr", "byteptr", "charptr", "any", "byte", "char", "thread", "chan",
        ]),
        decimal,
    ]
}
