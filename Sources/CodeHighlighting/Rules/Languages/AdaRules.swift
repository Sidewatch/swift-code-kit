//
//  AdaRules.swift
//  CodeHighlighting
//
//  The regex rule table for Ada.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Ada: `--` comments, `"…"` strings where `""` is a quote, `'x'` character literals (a tick after a
/// name or `)` is an attribute, `Item'Image`, and opens nothing), the Ada 2022 reserved words in any
/// case, based numbers (`16#FF#`, `2#1010_1010#`) and decimals, the predefined types, and the names a
/// `procedure`, `function`, `entry` or `type` declares (a subprogram's `end Name;` repeats its name).
extension RuleTables {
    static let ada: [(String, TokenKind)] = [
        dashComment,
        ("\"(?:[^\"\\n]|\"\")*\"", .string),
        ("(?<![\\w)\\]])'[^\\n]'", .string),
        callee,
        // A subprogram's name where it is declared and where its `end` repeats it; a declared type's name.
        ("(?i)\\b(?:procedure|function|entry)[ \\t]+[a-z]\\w*|\\bend[ \\t]+[a-z][\\w.]*(?=[ \\t]*;)", .function),
        ("(?i)\\b(?:sub)?type[ \\t]+[a-z]\\w*", .type),
        (
            "\\b(?:Boolean|Integer|Natural|Positive|Float|Long_Float|Long_Long_Float|Short_Float|Short_Integer|Long_Integer|Long_Long_Integer|Character|Wide_Character|Wide_Wide_Character|String|Wide_String|Wide_Wide_String|Duration|Address)\\b",
            .type
        ),
        (
            "(?i)\\b(abort|abs|abstract|accept|access|aliased|all|and|array|at|begin|body|case|constant|declare|delay|delta|digits|do|else|elsif|end|entry|exception|exit|for|function|generic|goto|if|in|interface|is|limited|loop|mod|new|not|null|of|or|others|out|overriding|package|parallel|pragma|private|procedure|protected|raise|range|record|rem|renames|requeue|return|reverse|select|separate|some|subtype|synchronized|tagged|task|terminate|then|type|until|use|when|while|with|xor)\\b",
            .keyword
        ),
        constants(["True", "False"]),
        ("\\b\\d[\\d_]*#[0-9A-Fa-f_]+(?:\\.[0-9A-Fa-f_]+)?#(?:[eE][+-]?\\d+)?", .number),
        decimal,
    ]
}
