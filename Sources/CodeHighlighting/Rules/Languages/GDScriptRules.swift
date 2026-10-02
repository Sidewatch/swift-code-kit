//
//  GDScriptRules.swift
//  CodeHighlighting
//
//  The regex rule table for GDScript.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// GDScript (Godot 4): `#` and `##` comments (the language table adds them); `"…"`, `'…'`, `"""…"""` and
/// `'''…'''` strings, `r"…"` raw strings, `&"StringName"` and `^"NodePath"` literals; `$Node/Path` and
/// `%Unique` node references; `@annotations`; the reference's keywords; capitalised built-in and engine types.
extension RuleTables {
    static let gdscript: [(String, TokenKind)] = [
        (
            "[r&^]?(?:\"\"\"[\\s\\S]*?\"\"\"|'''[\\s\\S]*?''')|r\"[^\"\\n]*\"|r'[^'\\n]*'"
                + "|[&^]?\"(?:[^\"\\\\\\n]|\\\\.)*\"|[&^]?'(?:[^'\\\\\\n]|\\\\.)*'",
            .string
        ),
        callee,
        wordTrie(
            [
                "and", "as", "assert", "await", "break", "breakpoint", "class", "class_name", "const", "continue", "elif",
                "else", "enum", "extends", "for", "func", "if", "in", "is", "match", "not", "or", "pass", "preload",
                "return", "self", "signal", "static", "super", "var", "void", "when", "while", "yield",
            ], .keyword),
        ("\\b(?:bool|int|float|[A-Z][A-Za-z0-9_]*)\\b", .type),
        constants(["true", "false", "null", "PI", "TAU", "INF", "NAN"]),
        ("@[A-Za-z_]\\w*", .attribute),
        ("\\$(?:\"[^\"\\n]*\"|[A-Za-z_][\\w/]*)|%[A-Za-z_]\\w*", .property),
        decimal,
    ]
}
