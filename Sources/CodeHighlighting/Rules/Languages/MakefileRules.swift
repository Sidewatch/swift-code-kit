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

/// Makefile: `#` comments (a `\#` is a literal hash, painted as an escape), quotes that only ever hold a
/// line (make itself has no strings; a recipe's quote that never closes must not run into the next line),
/// a line-ending `\` continuation, `$(…)` references and functions, automatic variables, directives,
/// targets (grouped `a b &:` ones too, and `\#` in a name), assignments. Make expands a reference inside a
/// `"…"` quote too, so the references there stay code.
extension RuleTables {
    static let makefile: [(String, TokenKind)] =
        [
            ("(?<!\\\\)#.*$", .comment),
            ("(?<![\\w\\\\])'[^'\\n]*'", .string),
        ]
        // One short look back finds where a hole may end; the long ones run only after a bracket.
        + interpolatedStringPieces(
            open: "\"(?<!\\\\\")", close: "\"", literal: "[^\"\\\\$\\n]|\\\\.",
            hole: "\\$(?:[@<^+?*%|$A-Za-z]|\\([^()\\n]*\\)|\\{[^{}\\n]*\\})", holeOpen: "\\$", holeClose: "[@<^+?*%|$A-Za-z)}]",
            afterHole: "(?<=\\$[@<^+?*%|$A-Za-z]|[)}])(?:(?<=\\$.)|(?<=\\$\\([^()\\n]{0,80}\\))|(?<=\\$\\{[^{}\\n]{0,80}\\}))",
            skip: ["#(?<!\\\\#)[^\\n]*", "'(?<![\\w\\\\]')[^'\\n]*'"])
        + [
            // A line-ending backslash continues the line; `\#` outside a target name is an escaped hash.
            ("\\\\$|\\\\#(?![^\\s:=]*:)", .string),
            keywords([
                "ifeq", "ifneq", "ifdef", "ifndef", "else", "endif", "include", "-include", "sinclude", "define", "endef", "export",
                "unexport", "override", "private", "undefine", "vpath", "load",
            ]),
            (
                "\\$\\((?:subst|patsubst|strip|findstring|filter-out|filter|sort|word|wordlist|words|firstword|lastword|dir|notdir|suffix|basename|addsuffix|addprefix|join|wildcard|realpath|abspath|shell|if|or|and|foreach|call|value|origin|flavor|eval|info|warning|error|file|let|intcmp)(?=[\\s)])",
                .function
            ),
            ("\\$[@<^+?*%|]|\\$\\([@<^+?*%][DF]?\\)", .variable),
            ("\\$\\$|\\$[\\({][A-Za-z_.][\\w.-]*[\\)}]|\\$[A-Za-z]", .type),
            ("^\\.[A-Z_]+(?=\\s*:)", .keyword),
            ("^(?:[^\\s#:=$\\\\]|\\\\.)(?:[^:=#\\\\]|\\\\.)*?(?=\\s*::?(?!=))", .function),
            ("^\\s*[A-Za-z_][\\w.-]*(?=\\s*(?:::=|:=|\\?=|\\+=|!=|=))", .property),
            ("\\b\\d+\\b", .number),
        ]
}
