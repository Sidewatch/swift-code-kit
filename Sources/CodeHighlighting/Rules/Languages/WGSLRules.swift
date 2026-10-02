//
//  WGSLRules.swift
//  CodeHighlighting
//
//  The regex rule table for WGSL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// WGSL (WebGPU Shading Language): `//` and NESTING `/* */` comments, the reserved keywords, the address
/// spaces and access modes, and the scalar, vector, matrix, array, pointer, sampler and texture types.
/// WGSL has no string or character literals.
extension RuleTables {
    static let wgsl: [(String, TokenKind)] = [
        lineComment,
        nestedBlock("/*", "*/"),
        // A call's name, unless a type constructor (`vec4f(`, `array<f32, 4>(`) or a keyword (`if (`).
        (
            "\\b[A-Za-z_]\\w*(?=[ \\t]*\\()(?<!\\b(?:if|for|while|switch|return|loop|bool|f16|f32|i32|u32|array|atomic|ptr|vec[234][fhiu]?|mat[234]x[234][fh]?))",
            .function
        ),
        keywords([
            "alias", "break", "case", "const", "const_assert", "continue", "continuing", "default", "diagnostic", "discard",
            "else", "enable", "fn", "for", "if", "let", "loop", "override", "requires", "return", "struct", "switch", "var",
            "while", "function", "private", "workgroup", "uniform", "storage", "read", "write", "read_write",
        ]),
        types(["bool", "f16", "f32", "i32", "u32", "array", "atomic", "ptr", "sampler", "sampler_comparison"]),
        ("\\b(?:vec[234][fhiu]?|mat[234]x[234][fh]?|texture_\\w+)\\b", .type),
        constants(["true", "false"]),
        (
            "(?<![\\w.])(?:0[xX][0-9a-fA-F]+(?:\\.[0-9a-fA-F]*)?(?:[pP][+-]?\\d+)?|(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?)[iufh]?(?!\\w)",
            .number
        ),
        ("@\\w+", .attribute),
    ]
}
