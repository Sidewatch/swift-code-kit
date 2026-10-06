//
//  RuleTables+Declarations.swift
//  CodeHighlighting
//
//  The builder for a declaration keyword and the name it declares.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The builder for a declaration keyword and the name it declares (`class Order`, `struct Point`,
/// `fn total`). The keyword and the name are one match painted `kind`, so the rule never opens with a
/// lookbehind (which would run at every character); a keyword rule placed AFTER it in the table repaints
/// the keyword itself, leaving the name in `kind`.
extension RuleTables {
    /// A plain name.
    static let declaredName = "[A-Za-z_]\\w*"

    /// `keyword name` for every keyword in `keywords` (regex-safe; a multi-word keyword such as
    /// `enum class` is listed before its first word), the name matched by `name`, painted `kind`. Spaces
    /// and tabs separate them, never a line break.
    static func declaration(after keywords: [String], name: String = declaredName, _ kind: TokenKind = .type) -> (String, TokenKind) {
        ("\\b(?:" + keywords.joined(separator: "|") + ")[ \\t]+" + name, kind)
    }
}
