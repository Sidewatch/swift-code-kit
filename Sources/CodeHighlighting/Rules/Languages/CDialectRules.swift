//
//  CDialectRules.swift
//  CodeHighlighting
//
//  The builder behind the C-dialect tables: GLSL, HLSL, CUDA, Metal, OpenCL, Objective-C, Vala and
//  ShaderLab's program blocks.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The builder behind the C-dialect tables. Every dialect shares C's comments, strings, character
/// literals, preprocessor lines and numbers; each brings its own keyword and type words. A call's
/// name is painted as a function unless it is one of those words: a keyword or type written like a
/// call (`if (`, `float4(`) keeps its own colour, and is painted once — each paint costs more the more
/// the pass has painted.
extension RuleTables {
    /// The C23 keywords.
    static let cKeywordList: [String] = [
        "alignas", "alignof", "auto", "bool", "break", "case", "char", "const", "constexpr", "continue", "default", "do",
        "double", "else", "enum", "extern", "false", "float", "for", "goto", "if", "inline", "int", "long", "nullptr",
        "register", "restrict", "return", "short", "signed", "sizeof", "static", "static_assert", "struct", "switch",
        "thread_local", "true", "typedef", "typeof", "typeof_unqual", "union", "unsigned", "void", "volatile", "while",
        "_Alignas", "_Alignof", "_Atomic", "_BitInt", "_Bool", "_Complex", "_Decimal128", "_Decimal32", "_Decimal64",
        "_Generic", "_Imaginary", "_Noreturn", "_Static_assert", "_Thread_local", "asm", "__asm__", "__attribute__",
    ]

    /// The C++23 keywords and the contextual `final` / `override` / `import` / `module`.
    static let cppKeywordList: [String] = [
        "alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand", "bitor", "bool", "break", "case", "catch", "char",
        "char8_t", "char16_t", "char32_t", "class", "compl", "concept", "const", "consteval", "constexpr", "constinit",
        "const_cast", "continue", "co_await", "co_return", "co_yield", "decltype", "default", "delete", "do", "double",
        "dynamic_cast", "else", "enum", "explicit", "export", "extern", "false", "float", "for", "friend", "goto", "if",
        "inline", "int", "long", "mutable", "namespace", "new", "noexcept", "not", "not_eq", "nullptr", "operator", "or",
        "or_eq", "private", "protected", "public", "register", "reinterpret_cast", "requires", "return", "short", "signed",
        "sizeof", "static", "static_assert", "static_cast", "struct", "switch", "template", "this", "thread_local",
        "throw", "true", "try", "typedef", "typeid", "typename", "union", "unsigned", "using", "virtual", "void",
        "volatile", "wchar_t", "while", "xor", "xor_eq", "final", "override", "import", "module",
    ]

    /// The fixed-width integer and size types of `<stdint.h>` / `<stddef.h>`.
    static let cStandardTypeList: [String] = [
        "size_t", "ssize_t", "ptrdiff_t", "intptr_t", "uintptr_t", "int8_t", "int16_t", "int32_t", "int64_t", "uint8_t",
        "uint16_t", "uint32_t", "uint64_t",
    ]

    /// C numbers: hex (with a binary exponent), binary, decimal with a fraction and exponent, `'` digit
    /// separators, a leading-dot fraction (`.5f`), a trailing-dot one (`1.f`) and the type suffixes.
    static let cNumber: (String, TokenKind) = (
        "(?<![\\w.])(?:0[xX][0-9a-fA-F']+(?:\\.[0-9a-fA-F']*)?(?:[pP][+-]?\\d+)?|0[bB][01']+|(?:\\d[\\d']*(?:\\.[\\d']*)?|\\.\\d[\\d']*)(?:[eE][+-]?\\d+)?)[uUlLfFhH]*(?!\\w)",
        .number
    )

    /// The keywords that declare a type, each followed by the type's name: `struct Point`, `enum class
    /// Mode`, `template <typename T>`.
    static let cTypeDeclarationKeywords: [String] = [
        "enum[ \\t]+class", "enum[ \\t]+struct", "struct", "union", "enum", "class", "typename", "interface",
    ]

    /// A C-dialect table: comments, `"…"` strings (with `stringPrefix` before the quote; a trailing `\`
    /// continues one), C++ raw strings when `rawStrings`, `'…'` character literals that are never the
    /// digit separator in `1'000`, `#include <path>`, preprocessor directives, the name after each of
    /// `declarations` as a type, then the words.
    static func cDialect(
        keywords words: [String], types typeWords: [String] = [], typePatterns: [String] = [],
        declarations: [String] = cTypeDeclarationKeywords,
        constants constantWords: [String] = ["true", "false", "NULL", "nullptr"], stringPrefix: String = "(?:u8|[uUL])?",
        rawStrings: Bool = false, blockComment block: (String, TokenKind) = blockComment
    ) -> [(String, TokenKind)] {
        let notACall = "(?:" + (words + typeWords).joined(separator: "|") + ")"
        var rules: [(String, TokenKind)] = [lineComment, block]
        if rawStrings { rules.append(("(?:u8|[uUL])?R\"([^()\\\\ \\t\\n]{0,16})\\([\\s\\S]*?\\)\\1\"", .string)) }
        rules += [
            (stringPrefix + "\"(?:[^\"\\\\\\n]|\\\\[\\s\\S])*\"", .string),
            ("(?<![\\w'])(?:u8|[uUL])?'(?:[^'\\\\\\n]|\\\\(?:x[0-9a-fA-F]+|[0-7]{1,3}|u[0-9a-fA-F]{4}|U[0-9a-fA-F]{8}|[^\\n]))'", .string),
            ("(?<=include|import)[ \\t]*<[^>\\n]*>", .string),
            ("\\b[A-Za-z_]\\w*(?=[ \\t]*\\()(?<!\\b" + notACall + ")", .function),
            ("^[ \\t]*#[ \\t]*[A-Za-z_]+", .keyword),
        ]
        if !declarations.isEmpty { rules.append(declaration(after: declarations)) }
        rules.append(keywords(words))
        // A call of the qualified `::operator new(n)` / `::operator delete(p)` functions; the word opens the match, so the
        // lookbehind runs only there.
        rules.append(("\\b(?:new|delete)\\b(?<=::operator[ \\t]{0,4}(?:new|delete))", .function))
        if !typeWords.isEmpty { rules.append(types(typeWords)) }
        rules += typePatterns.map { ($0, .type) }
        if !constantWords.isEmpty { rules.append(constants(constantWords)) }
        rules.append(cNumber)
        return rules
    }
}
