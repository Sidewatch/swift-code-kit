//
//  VBNetRules.swift
//  CodeHighlighting
//
//  The regex rule table for Visual Basic .NET.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Visual Basic .NET (case-insensitive): `'` and `REM` comments (the language table adds them); `"…"`
/// strings whose only escape is a doubled quote, `$"…"` interpolated strings and `"a"c` characters; `#…#`
/// date literals and `#If` / `#Const` / `#Region` directives — a `#` opens no comment; `<Attributes>`;
/// numbers with `&H` / `&O` / `&B` prefixes and type suffixes; the language reference's keywords.
extension RuleTables {
    static let vbnet: [(String, TokenKind)] = [
        ("\\$?\"(?:[^\"]|\"\")*\"[cC]?", .string),
        callee,
        wordTrie(
            [
                "AddHandler", "AddressOf", "Alias", "And", "AndAlso", "As", "ByRef", "ByVal", "Call", "Case", "Catch", "Class", "Const",
                "Continue", "Custom", "Declare", "Default", "Delegate", "Dim", "DirectCast", "Do", "Each", "Else", "ElseIf", "End",
                "EndIf", "Enum", "Erase", "Error", "Event", "Exit", "Finally", "For", "Friend", "Function", "Get", "GetType",
                "GetXMLNamespace", "Global", "GoSub", "GoTo", "Handles", "If", "Implements", "Imports", "In", "Inherits", "Interface",
                "Is", "IsNot", "Iterator", "Let", "Lib", "Like", "Loop", "Me", "Mod", "Module", "MustInherit", "MustOverride", "MyBase",
                "MyClass", "NameOf", "Namespace", "Narrowing", "New", "Next", "Not", "NotInheritable", "NotOverridable", "Of", "On",
                "Operator", "Option", "Optional", "Or", "OrElse", "Out", "Overloads", "Overridable", "Overrides", "ParamArray", "Partial",
                "Private", "Property", "Protected", "Public", "RaiseEvent", "ReadOnly", "ReDim", "RemoveHandler", "Resume", "Return",
                "Select", "Set", "Shadows", "Shared", "Static", "Step", "Stop", "Structure", "Sub", "SyncLock", "Then", "Throw", "To",
                "Try", "TryCast", "TypeOf", "Using", "Wend", "When", "While", "Widening", "With", "WithEvents", "WriteOnly", "Xor",
                "Async", "Await", "Yield", "Key", "Explicit", "Strict", "Infer", "Compare", "Binary", "Text", "Preserve", "From", "Where",
                "Select", "Order", "By", "Group", "Join", "Into", "Aggregate", "Distinct", "Skip", "Take", "Ascending", "Descending",
                "Equals",
            ],
            .keyword, caseInsensitive: true
        ),
        wordTrie(
            [
                "Boolean", "Byte", "CBool", "CByte", "CChar", "CDate", "CDbl", "CDec", "Char", "CInt", "CLng", "CObj", "CSByte", "CShort",
                "CSng", "CStr", "CType", "CUInt", "CULng", "CUShort", "Date", "Decimal", "Double", "Integer", "Long", "Object", "SByte",
                "Short", "Single", "String", "UInteger", "ULong", "UShort",
            ],
            .type, caseInsensitive: true
        ),
        ("(?i)\\b(True|False|Nothing)\\b", .number),
        ("#[^#\\n]+#", .number),
        ("(?im)^[ \\t]*#[ \\t]*(?:If|ElseIf|Else|End If|End Region|Const|Region|ExternalSource|Disable|Enable)\\b", .keyword),
        ("(?i)&[HOB][0-9A-F_]+[SILU]*|\\b\\d[\\d_]*(?:\\.\\d+)?(?:E[+-]?\\d+)?(?:[FRDSIL@!#%&]|U[SIL])?(?!\\w)", .number),
        ("<[A-Za-z_][\\w.]*(?=[(>])", .attribute),
    ]
}
