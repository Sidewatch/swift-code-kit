//
//  UnityYAMLTests.swift
//  CodeHighlightingTests
//
//  Unity's serialised YAML (scenes, prefabs, assets) read as structure: one document per object,
//  its `!u!` tag and file-ID anchor dropped, and an object marked `stripped` read like the rest.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import CodeHighlighting

final class UnityYAMLTests: XCTestCase {
    static let prefab = """
        %YAML 1.1
        %TAG !u! tag:unity3d.com,2011:
        --- !u!1 &1588413716425361842
        GameObject:
          m_ObjectHideFlags: 0
          serializedVersion: 6
          m_Component:
          - component: {fileID: 1588413716425361843}
          m_Layer: 0
          m_Name: Player
          m_IsActive: 1
        --- !u!4 &1588413716425361843
        Transform:
          m_GameObject: {fileID: 1588413716425361842}
          m_LocalPosition: {x: 0, y: 1, z: 0}
          m_Children: []
        --- !u!4 &7429012345678901234 stripped
        Transform:
          m_CorrespondingSourceObject: {fileID: 400000, guid: 1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d, type: 3}
          m_PrefabInstance: {fileID: 7429012345678900000}
        """

    private func classes(_ text: String) -> [String] {
        YAMLStructure.documents(in: text).map { doc in
            guard case .mapping(let pairs) = doc else { return "not a mapping: \(doc)" }
            return pairs.map(\.key).joined(separator: ",")
        }
    }

    /// The grammar alone loses the FIRST object of a file with a `stripped` one and reads the
    /// stripped one as a string.
    func testEveryObjectIsADocumentNamedByItsClassStrippedOnesToo() throws {
        XCTAssertEqual(classes(Self.prefab), ["GameObject", "Transform", "Transform"])
        guard case .mapping(let pairs) = try XCTUnwrap(YAMLStructure.documents(in: Self.prefab).first),
            case .mapping(let object) = try XCTUnwrap(pairs.first?.value)
        else { return XCTFail("the GameObject is a mapping") }
        XCTAssertEqual(object.first { $0.key == "m_Name" }?.value, .string("Player"))
    }

    /// The marker is read as spaces, so an edit site's range is still the text's own.
    func testAnEditSiteInsideAStrippedObjectPointsIntoTheText() throws {
        let site = try XCTUnwrap(
            YAMLStructure.site(in: Self.prefab, path: [.index(2), .key("Transform"), .key("m_PrefabInstance")]))
        XCTAssertEqual((Self.prefab as NSString).substring(with: site.value), "{fileID: 7429012345678900000}")
    }

    func testTheWordStrippedAnywhereElseIsLeftAlone() {
        let text = "--- !u!1 &1\nGameObject:\n  m_Name: stripped\n  note: --- !u!4 &2 stripped\n"
        guard case .mapping(let pairs) = YAMLStructure.documents(in: text).first, case .mapping(let object) = pairs.first?.value
        else { return XCTFail("one GameObject mapping") }
        XCTAssertEqual(object.first { $0.key == "m_Name" }?.value, .string("stripped"))
    }
}
