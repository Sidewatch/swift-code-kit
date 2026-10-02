//
//  OpenCLRules.swift
//  CodeHighlighting
//
//  The regex rule table for OpenCL C.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// OpenCL C: C's comments, preprocessor and keywords, the address-space, access and function qualifiers
/// (`__kernel`, `__global`, `read_only`), and the vector, image and atomic types.
extension RuleTables {
    static let opencl: [(String, TokenKind)] = cDialect(
        keywords: cKeywordList + [
            "__kernel", "kernel", "__global", "global", "__local", "local", "__constant", "constant", "__private", "private",
            "__generic", "generic", "__read_only", "read_only", "__write_only", "write_only", "__read_write", "read_write",
            "uniform", "pipe",
        ],
        types: cStandardTypeList + [
            "half", "uchar", "ushort", "uint", "ulong", "sampler_t", "event_t", "queue_t", "clk_event_t", "ndrange_t",
            "reserve_id_t", "atomic_int", "atomic_uint", "atomic_long", "atomic_ulong", "atomic_float", "atomic_double",
            "atomic_flag", "atomic_intptr_t", "atomic_uintptr_t", "atomic_size_t", "atomic_ptrdiff_t", "memory_order",
            "memory_scope",
        ],
        typePatterns: [
            "\\b(?:char|uchar|short|ushort|int|uint|long|ulong|float|double|half)(?:2|3|4|8|16)\\b",
            "\\bimage(?:1d|2d|3d)(?:_array|_buffer)?(?:_depth|_msaa)*_t\\b",
        ],
        constants: ["true", "false", "NULL"]
    )
}
