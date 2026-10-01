//
//  NinjaRules.swift
//  CodeHighlighting
//
//  The regex rule table for Ninja.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Ninja: `#` comments and no strings at all — a quote is an ordinary character in a command line,
/// so `'$$ORIGIN'` and `\"x\"` must not open one. The top-level statements, `name =` bindings,
/// `$var` / `${var}` references and the `$$` / `$ ` / `$:` escapes.
extension RuleTables {
    static let ninja: [(String, TokenKind)] = [
        hashComment,
        ("^(rule|build|pool|default|include|subninja)\\b", .keyword),
        ("\\$(?:\\{[A-Za-z_][\\w.-]*\\}|[A-Za-z_][\\w-]*)", .type),
        ("\\$[$ :]", .attribute),
        ("^\\s*[A-Za-z_][\\w.-]*(?=\\s*=)", .property),
        ("\\b\\d+(\\.\\d+)*\\b", .number),
    ]
}
