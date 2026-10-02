//
//  GroovyRules.swift
//  CodeHighlighting
//
//  The regex rule table for Groovy and Gradle build scripts.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Groovy (and Gradle's Groovy DSL): `//` and `/* */` comments, `"…"` / `'…'` strings, `"""…"""` and
/// `'''…'''` across lines, slashy `/…/` strings where a value starts (after `=`, `(`, `,`, `~`, `:`,
/// `[`, `{`, `return`), dollar-slashy `$/…/$` across lines, the Groovy keywords, the primitive types,
/// annotations and calls.
extension RuleTables {
    static let groovy: [(String, TokenKind)] = [
        lineComment,
        blockComment,
        tripleDoubleQuoted,
        tripleSingleQuoted,
        ("\\$/[\\s\\S]*?/\\$", .string),
        ("(?:(?<=[=(,~:\\[{!&|?][ \\t]{0,20})|(?<=^[ \\t]{0,40})|(?<=\\breturn[ \\t]{1,20}))/(?![/*\\s])(?:[^/\\\\\\n]|\\\\.)+/", .string),
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ("\\b[A-Za-z_]\\w*(?=[ \\t]*\\()", .function),
        keywords([
            "abstract", "as", "assert", "break", "case", "catch", "class", "const", "continue", "def", "default", "do", "else",
            "enum", "extends", "final", "finally", "for", "goto", "if", "implements", "import", "in", "instanceof",
            "interface", "native", "new", "non-sealed", "package", "permits", "private", "protected", "public", "record",
            "return", "sealed", "static", "strictfp", "super", "switch", "synchronized", "this", "threadsafe", "throw",
            "throws", "trait", "transient", "try", "var", "void", "volatile", "while", "yield",
        ]),
        types(["boolean", "byte", "char", "short", "int", "long", "float", "double"]),
        constants(["true", "false", "null"]),
        decimal,
        ("@[A-Za-z_][\\w.]*", .attribute),
    ]
}
