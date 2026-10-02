//
//  MetalRules.swift
//  CodeHighlighting
//
//  The regex rule table for the Metal Shading Language.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Metal Shading Language: C++'s comments, preprocessor and keywords, Metal's function and address-space
/// qualifiers (`kernel`, `device`, `threadgroup`), and its vector, matrix, texture and sampler types.
extension RuleTables {
    static let metal: [(String, TokenKind)] = cDialect(
        keywords: cppKeywordList + [
            "kernel", "vertex", "fragment", "visible", "device", "constant", "thread", "threadgroup",
            "threadgroup_imageblock", "ray_data", "object_data", "stitchable", "mesh", "object",
        ],
        types: cStandardTypeList + [
            "half", "bfloat", "uchar", "ushort", "uint", "ulong", "sampler", "atomic_int", "atomic_uint", "atomic_bool",
        ],
        typePatterns: [
            "\\b(?:packed_)?(?:bool|char|uchar|short|ushort|int|uint|long|ulong|half|float|bfloat)[2-4]\\b",
            "\\b(?:half|float)[2-4]x[2-4]\\b",
            "\\b(?:texture|depth)(?:1d|2d|3d|cube)(?:_array)?(?:_ms)?(?:_array)?\\b|\\btexture_buffer\\b",
        ],
        rawStrings: true
    )
}
