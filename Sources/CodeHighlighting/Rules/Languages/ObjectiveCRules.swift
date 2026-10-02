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
/// nullability qualifiers, the property attributes inside `@property (…)`, and `id` / `SEL` / `BOOL`.
extension RuleTables {
    static let objectiveC: [(String, TokenKind)] =
        cDialect(
            keywords: cKeywordList + [
                "self", "super", "in", "out", "inout", "oneway", "bycopy", "byref", "__block", "__weak", "__strong",
                "__unsafe_unretained", "__autoreleasing", "__bridge", "__bridge_transfer", "__bridge_retained", "__kindof",
                "__covariant", "__contravariant", "_Nullable", "_Nonnull", "_Null_unspecified", "nullable", "nonnull",
                "instancetype",
            ],
            types: cStandardTypeList + ["id", "Class", "SEL", "IMP", "BOOL", "NSInteger", "NSUInteger", "CGFloat"],
            constants: ["true", "false", "NULL", "nil", "Nil", "YES", "NO"], stringPrefix: "(?:u8|[uUL@])?"
        ) + [
            ("@[A-Za-z_]+\\b|@(?=[\\[{(\\d])", .keyword),
            (
                "\\b(?:nonatomic|atomic|strong|weak|assign|copy|retain|readonly|readwrite|getter|setter|unsafe_unretained|null_resettable|null_unspecified|class|direct)\\b(?=[^()\\n]*\\))",
                .keyword
            ),
        ]
}
