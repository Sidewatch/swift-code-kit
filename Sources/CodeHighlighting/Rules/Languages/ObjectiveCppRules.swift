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

/// Objective-C++: the Objective-C table over C++'s keywords, with C++ raw strings `R"delim(…)delim"`
/// (their quotes and backslashes mean nothing).
extension RuleTables {
    static let objectiveCpp: [(String, TokenKind)] = objectiveCTable(baseKeywords: cppKeywordList, rawStrings: true)
}
