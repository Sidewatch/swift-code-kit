//
//  CUDARules.swift
//  CodeHighlighting
//
//  The regex rule table for CUDA C++.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// CUDA C++: C++'s comments, raw strings, preprocessor and keywords, the CUDA execution-space and memory
/// qualifiers (`__global__`, `__shared__`), and the built-in vector types (`float4`, `dim3`).
extension RuleTables {
    static let cuda: [(String, TokenKind)] = cDialect(
        keywords: cppKeywordList + [
            "__global__", "__device__", "__host__", "__shared__", "__constant__", "__managed__", "__restrict__", "__noinline__",
            "__forceinline__", "__launch_bounds__", "__grid_constant__", "__cluster_dims__",
        ],
        types: cStandardTypeList + ["dim3", "half", "__half", "__half2", "__nv_bfloat16", "cudaError_t", "cudaStream_t", "cudaEvent_t"],
        typePatterns: ["\\b(?:u?char|u?short|u?int|u?long|u?longlong|float|double)[1-4]\\b"],
        rawStrings: true
    )
}
