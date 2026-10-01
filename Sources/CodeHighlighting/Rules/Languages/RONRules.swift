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

/// The regex rule table for RON (Rusty Object Notation).
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
        ("b?r(#+)\"[\\s\\S]*?\"\\1", .string),
        ("b?r\"[^\"]*\"", .string),
        doubleQuoted,
        ("b\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        // A character literal is one character or one escape, so a lone `'` never runs on.
        ("'(?:[^'\\\\\\n]|\\\\(?:u\\{[0-9a-fA-F]+\\}|x[0-9a-fA-F]{2}|[^\\n]))'", .string),
        constants(["true", "false", "None", "inf", "NaN"]),
        ("\\bSome\\b", .keyword),
        ("[+-]?\\b(?:0[xX][0-9a-fA-F_]+|0o[0-7_]+|0b[01_]+|\\d[\\d_]*(?:\\.[\\d_]*)?(?:[eE][+-]?\\d+)?)", .number),
        ("#!\\[[^\\]]*\\]", .attribute),
        ("\\b[A-Z][A-Za-z0-9_]*(?=\\s*\\()", .type),
        ("\\b[A-Za-z_][A-Za-z0-9_]*(?=\\s*:)", .property),
    ]
}
