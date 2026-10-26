//
//  FileKind+Extensions.swift
//  CodeLanguage
//
//  Each kind's extensions and glyph, and the kind of an extension.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension FileKind {
    /// The lower-cased extensions of this kind that a preview can show. Images are what ImageIO
    /// decodes, game textures included (DDS in every block format, KTX, KTX2, ASTC, TGA, EXR,
    /// Radiance HDR, Photoshop's composite, PVR); sound and video are what AVFoundation plays, plus
    /// WebM through WebKit; models are what SceneKit reads and glTF.
    var extensions: Set<String> {
        switch self {
        case .image: Self.imageExtensions
        case .audio: Self.audioExtensions
        case .video: Self.videoExtensions
        case .font: Self.fontExtensions
        case .archive: Self.archiveExtensions
        case .database: Self.databaseExtensions
        case .pdf: Self.pdfExtensions
        case .model: Self.modelExtensions
        }
    }

    /// The kind of a file with the lower-cased extension `ext`, or nil for anything else.
    init?(extension ext: String) {
        guard let kind = Self.byExtension[ext] else { return nil }
        self = kind
    }

    /// The SF Symbol for a file of this kind with the lower-cased extension `ext`: SVG, the one
    /// image that is also markup, has its own.
    func symbolName(forExtension ext: String) -> String {
        switch self {
        case .image: ext == "svg" ? "square.on.circle" : "photo"
        case .audio: "waveform"
        case .video: "film"
        case .font: "textformat"
        case .archive: "archivebox"
        case .database: "cylinder"
        case .pdf: "doc.fill"
        case .model: "cube"
        }
    }

    private static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "svg", "ico", "bmp", "tiff", "tif", "heic", "icns", "avif",
        "dds", "ktx", "ktx2", "astc", "tga", "exr", "hdr", "psd", "pvr",
    ]
    private static let audioExtensions: Set<String> = ["mp3", "wav", "m4a", "aac", "flac", "aiff", "aif", "ogg", "opus", "caf"]
    private static let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "webm"]
    private static let fontExtensions: Set<String> = ["ttf", "otf", "woff", "woff2"]
    private static let archiveExtensions: Set<String> = ["zip", "jar", "war", "ear", "ipa", "vsix", "whl", "nupkg", "crx", "xpi", "tar"]
    private static let databaseExtensions: Set<String> = ["sqlite", "sqlite3", "db", "db3"]
    private static let pdfExtensions: Set<String> = ["pdf"]
    private static let modelExtensions: Set<String> = [
        "usdz", "usd", "usda", "usdc", "obj", "stl", "ply", "abc", "dae", "scn", "gltf", "glb",
    ]

    /// Every kind's extensions, looked up once per name rather than kind by kind.
    private static let byExtension: [String: FileKind] = Dictionary(
        allCases.flatMap { kind in kind.extensions.map { ($0, kind) } }, uniquingKeysWith: { first, _ in first })
}
