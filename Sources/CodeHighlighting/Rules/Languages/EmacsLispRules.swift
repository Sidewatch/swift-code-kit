//
//  EmacsLispRules.swift
//  CodeHighlighting
//
//  The regex rule table for Emacs Lisp.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Emacs Lisp: `;` comments, character literals (`?a`, `?\C-x`, `?\^I`, `?\N{…}`), `\`-escaped
/// symbol characters (`symbol\;semi` holds no comment), `:keywords`, the special forms and the
/// standard defining and control macros.
extension RuleTables {
    static let emacsLisp: [(String, TokenKind)] = lispDialect(
        specialForms: [
            "and", "catch", "cond", "condition-case", "defconst", "defvar", "function", "if", "interactive", "let", "let*",
            "or", "prog1", "prog2", "progn", "quote", "save-current-buffer", "save-excursion", "save-restriction", "setq",
            "setq-default", "unwind-protect", "while", "lambda", "declare",
            "cl-defun", "cl-defmacro", "cl-defstruct", "cl-loop", "cl-case", "cl-flet", "cl-labels", "cl-letf", "cl-incf",
            "cl-decf", "cl-dolist", "cl-dotimes", "condition-case-unless-debug", "declare-function", "defadvice", "defclass",
            "defcustom", "defface", "defgeneric", "defgroup", "define-advice", "define-derived-mode", "define-minor-mode",
            "define-globalized-minor-mode", "defmacro", "defmethod", "defsubst", "deftheme", "defun", "defvar-local",
            "dolist", "dotimes", "eval-and-compile", "eval-when-compile", "ert-deftest", "ignore-errors", "letrec",
            "named-let", "pcase", "pcase-dolist", "pcase-exhaustive", "pcase-let", "pcase-let*", "pcase-setq", "pop", "push",
            "rx", "save-match-data", "save-selected-window", "save-window-excursion", "setf", "setq-local", "unless",
            "use-package", "when", "when-let", "when-let*", "if-let", "if-let*", "and-let*", "while-let", "with-current-buffer",
            "with-demoted-errors", "with-eval-after-load", "with-output-to-string", "with-silent-modifications",
            "with-temp-buffer", "with-temp-file", "with-temp-message", "with-timeout", "&optional", "&rest", "&key",
        ],
        constants: ["t", "nil"],
        literals: [
            (
                "(?<![\\w?\\\\-])\\?(?:\\\\(?:[CMSHAs]-|\\^))*(?:\\\\(?:N\\{[^}\\n]*\\}|x[0-9a-fA-F]+|u[0-9a-fA-F]{4}|U[0-9a-fA-F]{8}|.)|[^\\s\\\\])",
                .string
            ),
            ("\\\\.", .string),
        ]
    )
}
