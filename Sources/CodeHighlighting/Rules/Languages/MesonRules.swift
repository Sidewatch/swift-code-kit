//
//  MesonRules.swift
//  CodeHighlighting
//
//  The regex rule table for Meson.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Meson: `#` comments, `'…'` strings, the build functions and control words, `kwarg :`
/// names, method calls, the built-in objects, and decimal, `0x` hex, `0o` octal and `0b` binary numbers.
extension RuleTables {
    static let meson: [(String, TokenKind)] = [
        hashComment,
        ("'''[\\s\\S]*?'''", .string),
        singleQuoted,
        keywords(["if", "elif", "else", "endif", "foreach", "endforeach", "and", "or", "not", "in", "true", "false", "break", "continue"]),
        ("\\b(meson|host_machine|build_machine|target_machine)\\b", .type),
        ("\\b[a-z_]\\w*(?=\\s*:)", .attribute),
        ("\\.[a-z_]\\w*(?=\\()", .function),
        ("\\b[a-z_]\\w*(?=\\()", .function),
        ("\\b(?:0[xX][0-9a-fA-F]+|0[oO][0-7]+|0[bB][01]+|\\d+)\\b", .number),
    ]
}
