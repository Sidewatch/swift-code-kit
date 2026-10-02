//
//  ShaderLabRules.swift
//  CodeHighlighting
//
//  The regex rule table for Unity ShaderLab.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Unity ShaderLab: the HLSL table for the `HLSLPROGRAM` / `CGPROGRAM` blocks, plus ShaderLab's own
/// structure (`Shader`, `SubShader`, `Pass`, `Tags`), render-state commands (`ZWrite`, `Blend`), program
/// block markers and property types (`Range`, `2D`, `Color`).
extension RuleTables {
    static let shaderlab: [(String, TokenKind)] =
        cDialect(
            keywords: hlslKeywordList + [
                "Shader", "Properties", "SubShader", "Pass", "UsePass", "GrabPass", "Tags", "Category", "Fallback", "FallBack",
                "CustomEditor", "CustomEditorForRenderPipeline", "Dependency", "LOD", "Name", "PackageRequirements", "Stencil",
                "Blend", "BlendOp", "ZWrite", "ZTest", "ZClip", "Cull", "ColorMask", "Offset", "AlphaToMask", "Conservative",
                "Lighting", "Material", "SetTexture", "Fog", "Ref", "ReadMask", "WriteMask", "Comp", "PassOp", "FailOp",
                "ZFailOp", "CGPROGRAM", "ENDCG", "CGINCLUDE", "HLSLPROGRAM", "ENDHLSL", "HLSLINCLUDE", "GLSLPROGRAM",
                "ENDGLSL", "Range", "Float", "Int", "Integer", "Color", "Vector", "Cube", "2D", "3D", "2DArray", "CubeArray",
            ],
            types: hlslTypeList + ["fixed", "fixed2", "fixed3", "fixed4", "fixed2x2", "fixed3x3", "fixed4x4"],
            typePatterns: hlslTypePatterns, constants: ["true", "false", "NULL"], stringPrefix: ""
        )
}
