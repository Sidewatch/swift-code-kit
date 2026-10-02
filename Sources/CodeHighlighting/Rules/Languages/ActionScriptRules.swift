//
//  ActionScriptRules.swift
//  CodeHighlighting
//
//  The regex rule table for ActionScript 3.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// ActionScript 3: `//` and `/* */` comments, `"…"` and `'…'` strings, `/…/flags` regular expressions
/// where an expression starts, the reserved and syntactic keywords of the ActionScript 3 language
/// reference (a keyword before `(` stays a keyword), the built-in types, and numbers.
extension RuleTables {
    static let actionscript: [(String, TokenKind)] = [
        lineComment,
        blockComment,
        doubleQuoted,
        singleQuoted,
        (
            "(?<=(?:[=(,:!&|?;{}\\[]|\\breturn)[ \\t]{0,8})/(?![/*])(?:[^/\\\\\\n\\[]|\\\\.|\\[(?:[^\\]\\\\\\n]|\\\\.)*\\])+/[a-z]*",
            .string
        ),
        callee,
        keywords([
            "as", "break", "case", "catch", "class", "const", "continue", "default", "delete", "do", "else", "extends",
            "finally", "for", "function", "if", "implements", "import", "in", "instanceof", "interface", "internal", "is",
            "native", "new", "package", "private", "protected", "public", "return", "super", "switch", "this", "throw",
            "to", "try", "typeof", "use", "var", "void", "while", "with", "each", "get", "set", "namespace", "include",
            "dynamic", "final", "override", "static",
        ]),
        constants(["true", "false", "null", "undefined", "NaN", "Infinity"]),
        types([
            "int", "uint", "Number", "String", "Boolean", "Object", "Array", "Vector", "Function", "Class", "XML",
            "XMLList", "RegExp", "Date", "Error", "Math",
        ]),
        decimal,
    ]
}
