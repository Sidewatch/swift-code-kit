//
//  TemplateExpression.swift
//  CodeHighlighting
//
//  One code expression in a component's markup, as TemplateExpressionScanner finds it.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// One code expression in component markup, ready to parse on its own.
struct TemplateExpression: Equatable {
    /// The code itself.
    let body: NSRange
    /// The braces around the code, which are punctuation, not markup text.
    let braces: [NSRange]
    /// Text the code is parsed after, so the fragment parses as what it is: `(` for an expression (an object
    /// literal is not a block), `function ` for a snippet's signature, `const ` for `{@const …}`.
    let prefix: String
    /// Text the code is parsed before, closing what `prefix` opened.
    let suffix: String
}
