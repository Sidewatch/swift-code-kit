//
//  NunjucksRules.swift
//  CodeHighlighting
//
//  The regex rule table for Nunjucks.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Nunjucks: Jinja's tags and comments with its own words (`elseif`, `asyncEach`, `ifAsync`…), in
/// an HTML page, so an attribute value without a tag in it is a string too.
extension RuleTables {
    static let nunjucks: [(String, TokenKind)] =
        jinja + templateAttributeStrings + [
            templateTagKeywords([
                "elseif", "asyncEach", "endeach", "asyncAll", "endall", "ifAsync", "endifAsync", "each", "switch", "endswitch", "case",
                "default", "null",
            ])
        ]
}
