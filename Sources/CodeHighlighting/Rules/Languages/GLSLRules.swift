//
//  GLSLRules.swift
//  CodeHighlighting
//
//  The regex rule table for GLSL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// GLSL 4.60 / GLSL ES: C's comments and preprocessor, the storage, layout, interpolation and precision
/// qualifiers, and the scalar, vector, matrix, sampler, image and texture types.
extension RuleTables {
    static let glsl: [(String, TokenKind)] = cDialect(
        keywords: [
            "attribute", "break", "buffer", "case", "centroid", "coherent", "const", "continue", "default", "discard", "do",
            "else", "flat", "for", "highp", "if", "in", "inout", "invariant", "layout", "lowp", "mediump", "noperspective",
            "out", "patch", "precise", "precision", "readonly", "restrict", "return", "sample", "shared", "smooth", "struct",
            "subroutine", "switch", "uniform", "varying", "volatile", "while", "writeonly",
        ],
        types: ["void", "bool", "int", "uint", "float", "double", "atomic_uint"],
        typePatterns: [
            "\\b(?:[biud]?vec[234]|d?mat[234](?:x[234])?)\\b",
            "\\b[iu]?(?:sampler|image|texture|subpassInput)(?:1D|2D|3D|Cube|2DRect|Buffer|MS)?\\w*\\b",
        ],
        constants: ["true", "false"], stringPrefix: ""
    )
}
