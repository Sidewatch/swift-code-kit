//
//  Language+Symbol.swift
//  CodeLanguage
//
//  The SF Symbol that stands for a language's files — one glyph per CATEGORY (code, page,
//  stylesheet, data, config, build, shell, prose, query, diagram, hardware, maths, git…).
//
//  Created by David Sherlock on 9/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension Language {
    /// The SF Symbol name for this language's files. Grouped by what the file IS rather than one
    /// glyph per language: a tab or a row already names the file, so the icon anchors the kind.
    /// An EXHAUSTIVE switch, so a new case does not compile until it is placed. Lives here
    /// because language facts belong to this package, not to the app.
    var symbolName: String {
        switch self {
        // Programming languages: the code brackets. Swift wears its own bird.
        case .swift:
            return "swift"
        case .abap, .actionscript, .ada, .applescript, .awk, .c, .cairo, .carbon, .cfml, .clips, .clojure, .cobol,
            .coffeescript, .commonlisp, .cpp, .crystal, .csharp, .d, .dart, .elisp, .elixir, .elm, .erlang, .fennel,
            .fortran, .fsharp, .gdscript, .gleam, .go, .groovy, .hack, .haskell, .haxe, .java, .javascript, .jq, .jsx,
            .kotlin, .lex, .lua, .move, .nim, .objectivec, .objectivecpp, .ocaml, .odin, .pascal, .perl, .php, .prolog,
            .purescript, .python, .qsharp, .racket, .raku, .reason, .rego, .rescript, .ruby, .rust, .scala, .scheme,
            .smalltalk, .sml, .solidity, .tcl, .tsx, .typescript, .v, .vala, .vbnet, .vbscript, .vimscript, .vyper,
            .yacc, .zig:
            return "chevron.left.forwardslash.chevron.right"
        // Web pages, components and templates.
        case .html, .astro, .vue, .svelte, .blade, .ejs, .erb, .haml, .handlebars, .jinja, .jsp, .liquid, .marko,
            .mustache, .nunjucks, .pug, .razor, .slim, .smarty, .twig, .velocity, .freemarker:
            return "globe"
        // Markup that is not a page.
        case .xml, .xquery, .xslt, .plist:
            return "chevron.left.forwardslash.chevron.right"
        // Stylesheets.
        case .css, .scss, .sass, .less, .stylus, .postcss:
            return "paintbrush"
        // Structured data and interface definitions.
        case .json, .json5, .jsonc, .jsonlines, .jsonnet, .hjson, .ron, .kdl, .cue, .dhall, .graphql, .capnp, .protobuf,
            .thrift, .avdl:
            return "curlybraces"
        // Configuration.
        case .yaml, .toml, .ini, .properties, .editorconfig, .xcconfig, .apacheconf, .nginx, .caddyfile, .hosts, .systemd,
            .crontab, .manifest:
            return "slider.horizontal.3"
        case .dotenv:
            return "key"
        case .http:
            return "network"
        // Build files and packaging.
        case .makefile, .cmake, .gradle, .just, .starlark, .meson, .ninja:
            return "hammer"
        case .dockerfile, .gomod, .piprequirements:
            return "shippingbox"
        // Infrastructure definitions.
        case .terraform, .hcl, .bicep, .nix:
            return "server.rack"
        // Tables.
        case .csv, .tsv:
            return "tablecells"
        // Prose and documents.
        case .markdown, .mdx, .rmarkdown, .quarto, .asciidoc, .restructuredtext, .org, .textile, .mediawiki, .texinfo,
            .latex, .bibtex:
            return "doc.richtext"
        case .plainText:
            return "doc.text"
        case .gettext, .strings:
            return "textformat"
        // Shells.
        case .bash, .sh, .zsh, .fish, .nushell, .powershell, .batch:
            return "terminal"
        // Queries and schemas.
        case .sql, .mysql, .plpgsql, .plsql, .tsql, .sqlite, .hiveql, .cypher, .sparql, .edgeql, .prql, .prisma, .turtle:
            return "cylinder"
        // Diagrams.
        case .mermaid, .plantuml, .dot:
            return "point.3.connected.trianglepath.dotted"
        // GPU, hardware and the metal underneath.
        case .glsl, .hlsl, .wgsl, .metal, .shaderlab, .opencl, .cuda, .verilog, .systemverilog, .vhdl, .llvm, .assembly,
            .wat:
            return "cpu"
        // Maths, statistics and proofs.
        case .matlab, .r, .julia, .sas, .stata, .wolfram, .lean, .coq, .agda, .idris:
            return "function"
        // Git and diffs.
        case .gitcommit, .gitconfig, .gitattributes, .gitignore:
            return "arrow.triangle.branch"
        case .diff:
            return "plus.forwardslash.minus"
        case .log:
            return "list.bullet.rectangle"
        }
    }
}
