//
//  GDResourceRules.swift
//  CodeHighlighting
//
//  The regex rule table for Godot's text scenes, resources and project files.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Godot's text formats, which share one syntax (Godot's TSCN file format page and its variant parser):
/// scenes (`.tscn`, `.escn`), resources (`.tres`) and the ConfigFile files (`project.godot`, `.import`,
/// `.gdextension`, `export_presets.cfg`). `;` comments anywhere outside a string (the language table adds
/// them); a heading's tag (`[gd_scene`, `[node`, `[ext_resource`, `[application`) as a keyword; keys, in a
/// heading or before `=`, as properties (`Button/colors/font_color` and `2d_physics/layer_1` are one key each);
/// `ExtResource(…)` and `SubResource(…)` as keywords and every other constructor or class name (`Vector2(…)`,
/// `Object(InputEventKey, …)`) as a type; `"…"` strings, which may span lines (a built-in script's source),
/// the `&` of a StringName outside them; numbers with a sign and an exponent; `true`, `false`, `null`, `inf`
/// and `nan`.
extension RuleTables {
    static let gdresource: [(String, TokenKind)] = [
        ("\\b[A-Z][A-Za-z0-9_]*\\b", .type),
        ("\\b(?:ExtResource|SubResource)\\b", .keyword),
        (gdHeadingTag + "[A-Za-z_]\\w*", .keyword),
        constants(["true", "false", "null", "nil", "inf", "inf_neg", "nan"]),
        ("-?\\b\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b", .number),
        ("\\b\\w[\\w/.@:-]*(?=[ \\t]*=)", .property),
        doubleQuoted,
    ]

    /// The tag of each heading line, `[node …]` or `[application]`, found by one scan per paint.
    private static let gdHeadingTag = RuleScope.marker(
        steppingOver: [], regions: "(?m)^\\[" + RuleScope.region("[A-Za-z_]\\w*"), within: 80)
}
