//
//  GameFileDetectionTests.swift
//  CodeLanguageTests
//
//  The files game engines and their tools write, detected as the languages they are written in.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import CodeLanguage

final class GameFileDetectionTests: XCTestCase {
    func testUnitysSerialisedAssetsAreYAML() {
        for name in ["Main.unity", "Player.prefab", "GameSettings.asset", "Hero.mat", "Run.anim", "Hero.controller", "Player.cs.meta"] {
            XCTAssertEqual(Language.detect(filename: name), .yaml, name)
        }
    }

    func testEngineAndToolJSONIsJSON() {
        for name in [
            "Shooter.uproject", "Inventory.uplugin", "Game.asmdef", "Game.Tests.asmref", "Controls.inputactions", "World.ldtk",
            "level1.tmj", "tiles.tsj",
        ] {
            XCTAssertEqual(Language.detect(filename: name), .json, name)
        }
    }

    func testEngineAndToolXMLIsXML() {
        for name in ["MainMenu.uxml", "level1.tmx", "Place.rbxlx", "Sword.rbxmx", "Localizable.xliff", "en.xlf"] {
            XCTAssertEqual(Language.detect(filename: name), .xml, name)
        }
    }

    func testShadersAndStyleSheetsWearTheirLanguage() {
        XCTAssertEqual(Language.detect(filename: "Theme.uss"), .css)
        XCTAssertEqual(Language.detect(filename: "Default.tss"), .css)
        XCTAssertEqual(Language.detect(filename: "Blur.compute"), .hlsl)
        XCTAssertEqual(Language.detect(filename: "BasePassPixelShader.usf"), .hlsl)
        XCTAssertEqual(Language.detect(filename: "Common.ush"), .hlsl)
        XCTAssertEqual(Language.detect(filename: "water.gdshader"), .glsl)
        XCTAssertEqual(Language.detect(filename: "noise.gdshaderinc"), .glsl)
    }
}
