//
//  ObjectiveCRules.swift
//  CodeHighlighting
//
//  The regex rule table for Objective-C.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Objective-C: C's comments, strings, character literals, preprocessor (`#import <…>`) and keywords;
/// `@"…"` strings, the `@` directives and literals (`@interface`, `@[`, `@42`), the ownership and
/// nullability qualifiers, the property attributes inside `@property (…)`, and `id` / `SEL` / `BOOL`; the
/// class or protocol an `@interface`, `@implementation`, `@protocol` or `@class` names as a type; and a
/// method declaration's selector (`- (void)setObject:(id)o forKey:(id)k`) as a function, colons included.
extension RuleTables {
    static let objectiveC: [(String, TokenKind)] = objectiveCTable(baseKeywords: cKeywordList, rawStrings: false)

    /// The Objective-C words added to a C or C++ keyword list.
    static let objectiveCKeywordList: [String] = [
        "self", "super", "in", "out", "inout", "oneway", "bycopy", "byref", "__block", "__weak", "__strong",
        "__unsafe_unretained", "__autoreleasing", "__bridge", "__bridge_transfer", "__bridge_retained", "__kindof",
        "__covariant", "__contravariant", "_Nullable", "_Nonnull", "_Null_unspecified", "nullable", "nonnull",
        "instancetype",
    ]

    /// The Objective-C table over `baseKeywords` (C's for Objective-C, C++'s for Objective-C++).
    static func objectiveCTable(baseKeywords: [String], rawStrings: Bool) -> [(String, TokenKind)] {
        cDialect(
            keywords: baseKeywords + objectiveCKeywordList,
            types: cStandardTypeList + ["id", "Class", "SEL", "IMP", "BOOL", "NSInteger", "NSUInteger", "CGFloat"],
            constants: ["true", "false", "NULL", "nullptr", "nil", "Nil", "YES", "NO"], stringPrefix: "(?:u8|[uUL@])?",
            rawStrings: rawStrings
        ) + [
            ("@(?:interface|implementation|protocol|class)[ \\t]+[A-Za-z_]\\w*", .type),
            ("@[A-Za-z_]+\\b|@(?=[\\[{(\\d])", .keyword),
            (
                "\\b(?:nonatomic|atomic|strong|weak|assign|copy|retain|readonly|readwrite|getter|setter|unsafe_unretained|null_resettable|null_unspecified|class|direct)\\b(?=[^()\\n]*\\))",
                .keyword
            ),
            // A method declaration's selector: the part after the return type, and every `part:`. Each match opens on a
            // character that is rare in code (`)`, a name before `:`) and only then looks back for the `-` / `+` that
            // starts the line.
            (
                "\\)[ \\t]{0,4}[A-Za-z_]\\w{0,80}(?<=^[ \\t]{0,20}[-+][ \\t]{0,4}\\([^()\\n]{0,80}\\)[ \\t]{0,4}[A-Za-z_]\\w{0,80})",
                .function
            ),
            ("\\b[A-Za-z_]\\w*[ \\t]*:(?<=^[ \\t]{0,20}[-+][^;{}\\n]{0,300})", .function),
        ]
    }
}
