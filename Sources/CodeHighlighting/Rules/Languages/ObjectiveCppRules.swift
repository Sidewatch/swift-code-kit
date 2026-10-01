//
//  ObjectiveCppRules.swift
//  CodeHighlighting
//
//  The regex rule table for Objective-C++.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Objective-C++: `//` and `/* */` comments, `"…"` and `@"…"` strings that end at the line, C++ raw
/// strings `R"delim(…)delim"` (their quotes and backslashes mean nothing), one-character `'…'`
/// literals with escapes and `u8`/`u`/`U`/`L` prefixes (the `'` in `1'000` is a digit separator),
/// preprocessor lines, `@interface`-style directives, and the C, C++ and Objective-C words.
extension RuleTables {
    static let objectiveCpp: [(String, TokenKind)] = [
        lineComment,
        blockComment,
        ("(?:u8|[uUL])?R\"([^()\\\\ \\t\\n]{0,16})\\([\\s\\S]*?\\)\\1\"", .string),
        ("(?:u8|[uUL@])?\"(?:[^\"\\\\\\n]|\\\\[\\s\\S])*\"", .string),
        ("(?<![\\w'])(?:u8|[uUL])?'(?:[^'\\\\\\n]|\\\\(?:x[0-9a-fA-F]+|[0-7]{1,3}|u[0-9a-fA-F]{4}|[^\\n]))'", .string),
        ("#\\s*(include|import|define|undef|ifdef|ifndef|endif|if|else|elif|pragma|error|warning)\\b.*$", .attribute),
        (
            "@(interface|implementation|end|protocol|property|synthesize|dynamic|class|selector|encode|try|catch|finally|throw|autoreleasepool|synchronized|available|optional|required|public|private|protected|package)\\b",
            .keyword
        ),
        keywords([
            "auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else",
            "enum", "extern", "float", "for", "goto", "if", "int", "long", "register", "return",
            "short", "signed", "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned", "void",
            "volatile", "while", "inline", "class", "namespace", "template", "typename", "virtual", "public", "private",
            "protected", "override", "final", "new", "delete", "this", "try", "catch", "throw", "using",
            "constexpr", "consteval", "constinit", "noexcept", "concept", "requires", "operator", "explicit",
            "self", "super", "in", "co_await", "co_yield", "co_return", "decltype", "static_assert",
        ]),
        constants(["true", "false", "NULL", "nullptr", "nil", "YES", "NO"]),
        types([
            "size_t", "int8_t", "int16_t", "int32_t", "int64_t", "uint8_t", "uint16_t", "uint32_t", "uint64_t", "bool",
            "id", "SEL", "BOOL", "NSString", "NSArray", "NSDictionary", "NSObject", "NSInteger", "NSUInteger",
            "string", "vector", "map", "set", "unique_ptr", "shared_ptr", "optional", "variant",
        ]),
        ("\\b0[xX][0-9a-fA-F']+|\\b0[bB][01']+|\\b\\d[\\d']*(\\.\\d[\\d']*)?([eE][+-]?\\d+)?[uUlLfF]*", .number),
        ("\\b[A-Z][A-Za-z0-9]*\\b", .type),
        call,
    ]
}
