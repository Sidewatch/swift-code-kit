//
//  GraphQLRules.swift
//  CodeHighlighting
//
//  The regex rule table for GraphQL.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for GraphQL: `"""…"""` block strings run to the first unescaped `"""` (a `"` or an
/// escaped `\"""` inside ends nothing). Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let graphql: [(String, TokenKind)] = [
        hashComment,
        ("\"\"\"(?:\\\\\"\"\"|[\\s\\S])*?\"\"\"", .string),
        doubleQuoted,
        keywords([
            "type", "query", "mutation", "subscription", "input", "enum", "interface", "union", "scalar", "fragment",
            "schema", "extend", "directive", "implements", "on", "repeatable",
        ]),
        constants(["true", "false", "null"]),
        ("@\\w+", .attribute),  // @directives
        ("\\$[A-Za-z_]\\w*", .property),  // $variables
        ("\\b[A-Z]\\w*\\b", .type),  // Types
        decimal,
    ]
}
