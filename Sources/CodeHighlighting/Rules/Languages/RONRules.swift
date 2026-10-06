//
//  RONRules.swift
//  CodeHighlighting
//
//  The regex rule table for RON (Rusty Object Notation).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for RON (Rusty Object Notation): nesting block comments, raw, byte and character
/// literals, numbers, `#![…]` extensions, field names, and capitalised names as types (`None`, `NaN` and `inf`
/// keep the constant colour). After `0`, `XFF` is a name: the radix prefixes are lowercase only.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let ron: [(String, TokenKind)] = [
        lineComment,
        // Block comments nest in RON; ICU has no recursion, so two levels are spelled out.
        (
            "/\\*(?:[^/*]|/(?!\\*)|\\*(?!/)|/\\*(?:[^/*]|/(?!\\*)|\\*(?!/))*\\*/)*\\*/",
            .comment
        ),
        // Raw strings end at the matching hash count, so quotes inside them do not close them.
        // A raw byte string's `b` stays code and the literal starts at `r`, as VS Code paints it; a plain byte
        // string `b"…"` is a string from its `b`.
        ("r(?<=(?:^|[^\\w]|\\bb)r)(#+)\"[\\s\\S]*?\"\\1", .string),
        ("r(?<=(?:^|[^\\w]|\\bb)r)\"[^\"]*\"", .string),
        doubleQuoted,
        ("\\bb\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        // A character literal is one character or one escape, so a lone `'` never runs on.
        ("'(?:[^'\\\\\\n]|\\\\(?:u\\{[0-9a-fA-F]+\\}|x[0-9a-fA-F]{2}|[^\\n]))'", .string),
        // The radix prefixes are lowercase only (`0XFF` is not a RON number).
        ("[+-]?\\b(?:0x[0-9a-fA-F_]+|0o[0-7_]+|0b[01_]+|\\d[\\d_]*(?:\\.[\\d_]*)?(?:[eE][+-]?\\d+)?)", .number),
        ("#!\\[[^\\]]*\\]", .attribute),
        ("\\b[a-z_][A-Za-z0-9_]*(?=\\s*:)", .property),
        // A capitalised name is a struct, an enum variant or a unit value (`Production`, `Some`), even as a key.
        ("[A-Z](?<![A-Za-z_][A-Z])(?<![0-9.]E)[A-Za-z0-9_]*\\b", .type),  // never an exponent's `E`
        constants(["true", "false", "None", "inf", "NaN"]),
    ]
}
