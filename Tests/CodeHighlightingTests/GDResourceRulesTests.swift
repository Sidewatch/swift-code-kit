//
//  GDResourceRulesTests.swift
//  CodeHighlightingTests
//
//  Godot's text scenes, resources and project files: headings, keys, values and comments as Godot's text
//  format defines them, and the outline of each.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class GDResourceRulesTests: XCTestCase {
    private let scene = """
        [gd_scene load_steps=2 format=3 uid="uid://b6x8q4k2y1v7m"]

        [ext_resource type="Script" path="res://player.gd" id="1_player"]

        [node name="Player" type="CharacterBody2D"] ; the root
        script = ExtResource("1_player")
        jump_velocity = -400.0
        gravity_scale = 1e-2
        spawn_point = Vector2(64, -32.5)
        visible = true
        owner_id = null
        tags = &"hero"
        note = "a;b"
        script/source = "extends Node
        var speed = 10
        var greeting = \\"hi\\"
        "

        [connection signal="body_entered" from="Hitbox" to="." method="_on_body_entered"]
        """

    private let project = """
        config_version=5

        [application]

        config/name="Sky Courier"
        run/main_scene="res://main.tscn"

        [layer_names]

        2d_physics/layer_1="world"
        """

    func testAHeadingsTagIsAKeywordAndItsBracketIsNot() {
        let painted = PaintedKinds(scene + "\n" + project, .gdresource)
        XCTAssertEqual(painted.kind("gd_scene"), .keyword)
        XCTAssertEqual(painted.kind("node name"), .keyword)
        XCTAssertEqual(painted.kind("application"), .keyword)
        XCTAssertNil(painted.kind("[node"), "the bracket is punctuation")
        XCTAssertEqual(painted.kind("load_steps"), .property, "a heading's key")
    }

    func testKeysAreOneNameEach() {
        let painted = PaintedKinds(project, .gdresource)
        XCTAssertEqual(Set(painted.kinds(along: "config/name")), [.property])
        XCTAssertEqual(Set(painted.kinds(along: "2d_physics/layer_1")), [.property], "a key may start with a digit")
        XCTAssertEqual(painted.kind("=5", 1), .number)
    }

    func testValues() {
        let painted = PaintedKinds(scene, .gdresource)
        XCTAssertEqual(painted.kind("ExtResource"), .keyword)
        XCTAssertEqual(painted.kind("Vector2"), .type)
        XCTAssertEqual(Set(painted.kinds(along: "-400.0")), [.number], "a number's sign is part of it")
        XCTAssertEqual(Set(painted.kinds(along: "1e-2")), [.number])
        XCTAssertEqual(Set(painted.kinds(along: "-32.5")), [.number])
        XCTAssertEqual(painted.kind("true"), .number, "a constant wears the number colour")
        XCTAssertEqual(painted.kind("null"), .number)
        XCTAssertEqual(painted.kind("\"res://player.gd\""), .string)
        XCTAssertNil(painted.kind("&\"hero\""), "a StringName's marker is outside the string")
        XCTAssertEqual(painted.kind("&\"hero\"", 1), .string)
    }

    func testAStringMaySpanLinesAndHidesWhatLooksLikeKeys() {
        let painted = PaintedKinds(scene, .gdresource)
        XCTAssertEqual(painted.kind("var speed"), .string, "a built-in script's source is one string")
        XCTAssertEqual(painted.kind("greeting = \\\"hi", 13), .string, "an escaped quote stays inside")
        XCTAssertEqual(painted.kind("connection"), .keyword, "the string ends at its closing quote, not an escaped one")
    }

    func testASemicolonOpensACommentAnywhereOutsideAString() {
        let painted = PaintedKinds(scene, .gdresource)
        XCTAssertEqual(painted.kind("; the root"), .comment, "after a heading")
        XCTAssertEqual(Set(painted.kinds(along: "\"a;b\"")), [.string])
    }

    func testTheOutlineNamesEachHeadingByWhatItNames() {
        let symbols = RegexOutline.symbols(in: scene, language: .gdresource)
        XCTAssertEqual(
            symbols.map(\.name),
            [
                "res://player.gd", "Player", "script", "jump_velocity", "gravity_scale", "spawn_point", "visible", "owner_id", "tags",
                "note", "script/source", "body_entered",
            ])
        XCTAssertEqual(
            RegexOutline.symbols(in: project, language: .gdresource).map(\.name),
            [
                "config_version", "application", "config/name", "run/main_scene", "layer_names", "2d_physics/layer_1",
            ])
    }
}
