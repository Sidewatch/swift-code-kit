//
//  FileKindTests.swift
//  CodeLanguageTests
//
//  Each non-code kind's one list of extensions, and the glyph every one of them gets.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import CodeLanguage

final class FileKindTests: XCTestCase {
    func testEveryExtensionBelongsToOneKindAndLooksItsKindUp() {
        var seen: [String: FileKind] = [:]
        for kind in FileKind.allCases {
            for ext in kind.extensions {
                XCTAssertEqual(ext, ext.lowercased(), "\(ext) is looked up lower-cased")
                XCTAssertNil(seen[ext], "\(ext) is both \(seen[ext].map { "\($0)" } ?? "") and \(kind)")
                seen[ext] = kind
                XCTAssertEqual(FileKind(extension: ext), kind)
            }
        }
        XCTAssertNil(FileKind(extension: "swift"))
    }

    func testGameTexturesAreImagesAndOpusAndCoreAudioAreSound() {
        for ext in ["dds", "ktx", "ktx2", "astc", "tga", "exr", "hdr", "psd", "pvr"] {
            XCTAssertEqual(FileKind(extension: ext), .image, ext)
        }
        XCTAssertEqual(FileKind(extension: "opus"), .audio)
        XCTAssertEqual(FileKind(extension: "caf"), .audio)
    }

    /// The file list's glyph comes from the same lists the previews read, so a kind a preview
    /// shows never falls back to a plain document's icon.
    func testEveryPreviewedExtensionWearsItsKindsGlyph() {
        let glyphs: [FileKind: String] = [
            .image: "photo", .audio: "waveform", .video: "film", .font: "textformat", .archive: "archivebox", .database: "cylinder",
            .pdf: "doc.fill", .model: "cube",
        ]
        for kind in FileKind.allCases {
            for ext in kind.extensions {
                let expected = ext == "svg" ? "square.on.circle" : glyphs[kind]
                XCTAssertEqual(Language.symbolName(forFilename: "file.\(ext)"), expected, ext)
            }
        }
    }

    func testTheModelFormatsAreModels() {
        for ext in ["usdz", "usd", "usda", "usdc", "obj", "stl", "ply", "abc", "dae", "scn", "gltf", "glb"] {
            XCTAssertEqual(FileKind(extension: ext), .model, ext)
        }
        XCTAssertNil(FileKind(extension: "fbx"), "nothing on a Mac reads FBX")
    }

    func testFormatsNoPreviewOpensKeepTheirKindsGlyphOnly() {
        XCTAssertNil(FileKind(extension: "mkv"))
        XCTAssertEqual(Language.symbolName(forExtension: "mkv"), "film")
        XCTAssertNil(FileKind(extension: "rar"))
        XCTAssertEqual(Language.symbolName(forExtension: "rar"), "archivebox")
    }
}

/// A file's kind by name, the one the file lists group by and draw their glyph from.
final class FileKindByNameTests: XCTestCase {
    func testEveryKindExtensionAndTheFormatsNoPreviewOpens() {
        let expected: [String: FileKind] = [
            "example.zip": .archive, "sample.whl": .archive, "sample.ipa": .archive, "sample.TAR": .archive,
            "backup.tar.gz": .archive, "dist.7z": .archive, "logo.png": .image, "icon.svg": .image, "clip.mkv": .video,
            "song.mp3": .audio, "font.woff2": .font, "app.sqlite": .database, "manual.pdf": .pdf, "scene.glb": .model,
        ]
        for (name, kind) in expected { XCTAssertEqual(Language.fileKind(forFilename: name), kind, name) }
    }

    func testCodeAndTextHaveNoKind() {
        for name in ["main.swift", "README.md", "Package.resolved", "Cargo.lock", "LICENSE", ".env", "notes"] {
            XCTAssertNil(Language.fileKind(forFilename: name), name)
        }
    }

    /// The glyph and the kind agree for every kind extension.
    func testTheGlyphFollowsTheKind() {
        for name in ["a.zip", "a.gz", "a.rar", "a.mkv", "a.avi", "a.png", "a.ttf", "a.db", "a.pdf", "a.usdz", "a.flac"] {
            guard let kind = Language.fileKind(forFilename: name) else { return XCTFail(name) }
            let ext = (name as NSString).pathExtension
            XCTAssertEqual(Language.symbolName(forFilename: name), kind.symbolName(forExtension: ext), name)
        }
    }
}
