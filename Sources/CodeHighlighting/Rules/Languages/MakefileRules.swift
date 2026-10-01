//
//  MakefileRules.swift
//  CodeHighlighting
//
//  The regex rule table for Makefile.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Makefile: `#` comments (a `\#` is a literal hash), quotes that only ever hold a line (make itself
/// has no strings; a recipe's quote that never closes must not run into the next line), `$(…)`
/// references and functions, automatic variables, directives, targets, assignments.
extension RuleTables {
    static let makefile: [(String, TokenKind)] = [
        ("(?<!\\\\)#.*$", .comment),
        ("(?<!\\\\)\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("(?<![\\w\\\\])'[^'\\n]*'", .string),
        keywords([
            "ifeq", "ifneq", "ifdef", "ifndef", "else", "endif", "include", "-include", "sinclude", "define", "endef", "export", "unexport",
            "override", "private", "undefine", "vpath", "load",
        ]),
        (
            "\\$\\((?:subst|patsubst|strip|findstring|filter-out|filter|sort|word|wordlist|words|firstword|lastword|dir|notdir|suffix|basename|addsuffix|addprefix|join|wildcard|realpath|abspath|shell|if|or|and|foreach|call|value|origin|flavor|eval|info|warning|error|file|let|intcmp)(?=[\\s)])",
            .function
        ),
        ("\\$[@<^+?*%|]|\\$\\([@<^+?*%][DF]?\\)", .variable),
        ("\\$\\$|\\$[\\({][A-Za-z_.][\\w.-]*[\\)}]|\\$[A-Za-z]", .type),
        ("^\\.[A-Z_]+(?=\\s*:)", .keyword),
        ("^[^\\s#:=$][^:=#]*?(?=\\s*&?::?(?!=))", .function),
        ("^\\s*[A-Za-z_][\\w.-]*(?=\\s*(?:::=|:=|\\?=|\\+=|!=|=))", .property),
        ("\\b\\d+\\b", .number),
    ]
}
