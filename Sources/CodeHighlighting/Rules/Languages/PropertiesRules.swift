//
//  PropertiesRules.swift
//  CodeHighlighting
//
//  The regex rule table for Java properties files.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Java properties: a `#` or `!` comment is a whole line from its first glyph (the language table's
/// `exactLineComment`), so an escaped `\#` or `\!` inside a key or value opens nothing; a key runs to its
/// first unescaped `=`, `:` or whitespace and may hold `\ ` escapes; a line after an odd number of trailing
/// backslashes continues the value before it and holds no key; `${placeholders}`; a value that is just a
/// number or boolean. There are no sections and no tags.
extension RuleTables {
    static let properties: [(String, TokenKind)] = [
        ("(?<!(?<!\\\\)(?:\\\\\\\\){0,4}\\\\\\n)^[ \\t]*(?:\\\\.|[^\\s=:\\\\#!])(?:\\\\.|[^\\s=:\\\\])*", .property),
        ("(?<=[=:][ \\t]{0,8})(?:-?\\d[\\d_]*(?:\\.\\d+)?|0[xX][0-9a-fA-F]+|true|false)[ \\t]*$", .number),
        ("\\$\\{(?:[^{}\\n]|\\$\\{[^{}\\n]*\\})*\\}|\\$[A-Za-z_]\\w*", .type),
    ]
}
