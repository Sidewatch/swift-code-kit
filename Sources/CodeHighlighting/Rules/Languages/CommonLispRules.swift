//
//  CommonLispRules.swift
//  CodeHighlighting
//
//  The regex rule table for Common Lisp.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Common Lisp: `;` and nesting `#| |#` comments, character literals (`#\Space`, `#\;`), `|escaped
/// symbols|` and `\`-escaped symbol characters, uninterned `#:symbols` and `:keywords`, the special
/// operators, the standard macros, lambda-list keywords (`&optional`) and declaration identifiers.
extension RuleTables {
    static let commonLisp: [(String, TokenKind)] = lispDialect(
        specialForms: [
            "block", "catch", "eval-when", "flet", "function", "go", "if", "labels", "let", "let*", "load-time-value", "locally",
            "macrolet", "multiple-value-call", "multiple-value-prog1", "progn", "progv", "quote", "return-from", "setq",
            "symbol-macrolet", "tagbody", "the", "throw", "unwind-protect", "lambda", "declare",
            "and", "assert", "case", "ccase", "check-type", "cond", "ctypecase", "decf", "declaim", "defclass", "defconstant",
            "defgeneric", "define-compiler-macro", "define-condition", "define-method-combination", "define-modify-macro",
            "define-setf-expander", "define-symbol-macro", "defmacro", "defmethod", "defpackage", "defparameter", "defsetf",
            "defstruct", "deftype", "defun", "defvar", "destructuring-bind", "do", "do*", "do-all-symbols",
            "do-external-symbols", "do-symbols", "dolist", "dotimes", "ecase", "etypecase", "formatter", "handler-bind",
            "handler-case", "ignore-errors", "in-package", "incf", "loop", "loop-finish", "multiple-value-bind",
            "multiple-value-list", "multiple-value-setq", "nth-value", "or", "pop", "print-unreadable-object", "prog",
            "prog*", "prog1", "prog2", "psetf", "psetq", "push", "pushnew", "remf", "restart-bind", "restart-case", "return",
            "rotatef", "setf", "shiftf", "step", "time", "typecase", "unless", "when", "with-accessors",
            "with-compilation-unit", "with-condition-restarts", "with-hash-table-iterator", "with-input-from-string",
            "with-open-file", "with-open-stream", "with-output-to-string", "with-package-iterator", "with-simple-restart",
            "with-slots", "with-standard-io-syntax",
            "&allow-other-keys", "&aux", "&body", "&environment", "&key", "&optional", "&rest", "&whole",
            "dynamic-extent", "ftype", "ignorable", "ignore", "inline", "notinline", "optimize", "special", "type",
        ],
        constants: ["t", "nil"],
        literals: [
            lispCharacter,
            ("\\|(?:[^|\\\\]|\\\\[\\s\\S])*\\|", .string),
            ("\\\\.", .string),
        ],
        definitions: [
            lispDefinedName(after: ["defun", "defmacro", "defgeneric", "defmethod", "define-compiler-macro"], parenthesised: false)
        ]
    )
}
