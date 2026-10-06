//
//  CMakeRules.swift
//  CodeHighlighting
//
//  The regex rule table for CMake.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// CMake: the shell-like family's rules, plus bracket arguments `[[…]]` / `[=[…]=]` as strings (no
/// escapes and no `${}` expansion inside one; a `#[[…]]` bracket comment opens earlier and wins).
extension RuleTables {
    static let cmake: [(String, TokenKind)] = [("\\[(=*)\\[[\\s\\S]*?\\]\\1\\]", .string)] + shellLikeFamily
}
