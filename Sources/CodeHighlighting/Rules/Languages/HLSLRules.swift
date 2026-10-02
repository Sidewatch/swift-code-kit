//
//  HLSLRules.swift
//  CodeHighlighting
//
//  The regex rule table for HLSL.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// HLSL (Shader Model 6): C's comments and preprocessor, the HLSL keywords and qualifiers, the scalar,
/// vector and matrix types (`float4`, `half3x3`, `min16float`), and the buffer, texture and effect
/// object types.
extension RuleTables {
    static let hlslKeywordList: [String] = [
        "asm", "asm_fragment", "break", "case", "cbuffer", "centroid", "class", "column_major", "compile",
        "compile_fragment", "const", "continue", "default", "discard", "do", "else", "export", "extern", "for", "fxgroup",
        "globallycoherent", "groupshared", "if", "in", "inline", "inout", "interface", "line", "lineadj", "linear",
        "namespace", "nointerpolation", "noperspective", "out", "packoffset", "pass", "pixelfragment", "point", "precise",
        "register", "return", "row_major", "sample", "shared", "snorm", "stateblock", "stateblock_state", "static",
        "struct", "switch", "tbuffer", "technique", "technique10", "technique11", "triangle", "triangleadj", "typedef",
        "uniform", "unorm", "unsigned", "vertexfragment", "volatile", "while", "template", "typename", "using",
    ]
    static let hlslTypeList: [String] = [
        "void", "string", "vector", "matrix", "sampler", "sampler1D", "sampler2D", "sampler3D", "samplerCUBE",
        "SamplerState", "SamplerComparisonState", "Buffer", "RWBuffer", "ByteAddressBuffer", "RWByteAddressBuffer",
        "StructuredBuffer", "RWStructuredBuffer", "AppendStructuredBuffer", "ConsumeStructuredBuffer", "ConstantBuffer",
        "InputPatch", "OutputPatch", "PointStream", "LineStream", "TriangleStream", "RaytracingAccelerationStructure",
        "BlendState", "DepthStencilState", "RasterizerState", "VertexShader", "PixelShader", "GeometryShader",
        "HullShader", "DomainShader", "ComputeShader",
    ]
    static let hlslTypePatterns: [String] = [
        "\\b(?:bool|int|uint|dword|half|float|double|min16float|min10float|min16int|min12int|min16uint|int16_t|uint16_t|int64_t|uint64_t|float16_t|float64_t)(?:[1-4](?:x[1-4])?)?\\b",
        "\\b(?:RW|RasterizerOrdered)?Texture(?:1D|2D|3D|Cube)(?:Array)?(?:MS)?(?:Array)?\\b|\\btexture(?:1D|2D|3D|CUBE)?\\b",
    ]

    static let hlsl: [(String, TokenKind)] = cDialect(
        keywords: hlslKeywordList, types: hlslTypeList, typePatterns: hlslTypePatterns, constants: ["true", "false", "NULL"],
        stringPrefix: ""
    )
}
