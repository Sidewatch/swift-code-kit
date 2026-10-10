//
//  Language.swift
//  CodeLanguage
//
//  The set of source, markup, and config languages this package recognizes.
//  GENERATED from a curated language catalog — edit the generator, not this file.
//
//  Created by David Sherlock on 7/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A source, markup, or configuration language this package can identify.
///
/// Detected from a file's name/extension via ``detect(for:)``. Carries display
/// metadata (``displayName``, ``lineCommentToken``, ``blockComment``) and a coarse
/// ``family`` used to drive fallback syntax highlighting.
public enum Language: String, CaseIterable, Sendable {

    /// ABAP.
    case abap
    /// ActionScript.
    case actionscript
    /// Ada.
    case ada
    /// Agda.
    case agda
    /// Apache Conf.
    case apacheconf
    /// AppleScript.
    case applescript
    /// AsciiDoc.
    case asciidoc
    /// Assembly.
    case assembly
    /// Astro.
    case astro
    /// Avro IDL.
    case avdl
    /// AWK.
    case awk
    /// Bash.
    case bash
    /// Batch/CMD.
    case batch
    /// BibTeX.
    case bibtex
    /// Bicep.
    case bicep
    /// Blade (Laravel).
    case blade
    /// C.
    case c
    /// Caddyfile.
    case caddyfile
    /// Cairo.
    case cairo
    /// Cap'n Proto.
    case capnp
    /// Carbon.
    case carbon
    /// ColdFusion (CFML).
    case cfml
    /// CLIPS.
    case clips
    /// Clojure.
    case clojure
    /// CMake.
    case cmake
    /// COBOL.
    case cobol
    /// CoffeeScript.
    case coffeescript
    /// Common Lisp.
    case commonlisp
    /// Coq.
    case coq
    /// C++.
    case cpp
    /// Crontab.
    case crontab
    /// Crystal.
    case crystal
    /// C#.
    case csharp
    /// CSS.
    case css
    /// CSV.
    case csv
    /// CUDA C++.
    case cuda
    /// CUE.
    case cue
    /// Cypher.
    case cypher
    /// D.
    case d
    /// Dart.
    case dart
    /// Dhall.
    case dhall
    /// Diff / Patch.
    case diff
    /// Dockerfile.
    case dockerfile
    /// Graphviz DOT.
    case dot
    /// dotenv.
    case dotenv
    /// EdgeQL.
    case edgeql
    /// EditorConfig.
    case editorconfig
    /// EJS.
    case ejs
    /// Emacs Lisp.
    case elisp
    /// Elixir.
    case elixir
    /// Elm.
    case elm
    /// ERB (Embedded Ruby).
    case erb
    /// Erlang.
    case erlang
    /// Fennel.
    case fennel
    /// Fish.
    case fish
    /// Fortran.
    case fortran
    /// FreeMarker.
    case freemarker
    /// F#.
    case fsharp
    /// GDScript (Godot).
    case gdscript
    /// Gettext translation catalogs (.po/.pot).
    case gettext
    /// Git Attributes.
    case gitattributes
    /// Git Commit Message.
    case gitcommit
    /// Git Config.
    case gitconfig
    /// Git Ignore.
    case gitignore
    /// Gleam.
    case gleam
    /// GLSL.
    case glsl
    /// Go.
    case go
    /// Go Module.
    case gomod
    /// Gradle.
    case gradle
    /// GraphQL.
    case graphql
    /// Groovy.
    case groovy
    /// Hack.
    case hack
    /// Haml.
    case haml
    /// Handlebars.
    case handlebars
    /// Haskell.
    case haskell
    /// Haxe.
    case haxe
    /// HCL.
    case hcl
    /// HiveQL.
    case hiveql
    /// Hjson.
    case hjson
    /// HLSL.
    case hlsl
    /// Hosts File.
    case hosts
    /// HTML.
    case html
    /// HTTP request files (`.http`, the JetBrains / VS Code REST Client format).
    case http
    /// A static host's `_headers` file (Cloudflare Pages / Workers Static Assets, Netlify).
    case staticheaders
    /// A static host's `_redirects` file (Cloudflare Pages / Workers Static Assets, Netlify).
    case staticredirects
    /// Idris.
    case idris
    /// INI.
    case ini
    /// Java.
    case java
    /// JavaScript.
    case javascript
    /// Jinja.
    case jinja
    /// jq.
    case jq
    /// JSON.
    case json
    /// JSON5.
    case json5
    /// JSON with Comments.
    case jsonc
    /// JSON Lines.
    case jsonlines
    /// Jsonnet.
    case jsonnet
    /// JSP (JavaServer Pages).
    case jsp
    /// JSX.
    case jsx
    /// Julia.
    case julia
    /// Just.
    case just
    /// KDL.
    case kdl
    /// Kotlin.
    case kotlin
    /// LaTeX.
    case latex
    /// Lex / Flex.
    case lex
    /// Lean.
    case lean
    /// Less.
    case less
    /// Liquid.
    case liquid
    /// LLVM IR.
    case llvm
    /// Log File.
    case log
    /// Lua.
    case lua
    /// Makefile.
    case makefile
    /// Java Manifest.
    case manifest
    /// Markdown.
    case markdown
    /// Marko.
    case marko
    /// MATLAB.
    case matlab
    /// MDX.
    case mdx
    /// MediaWiki.
    case mediawiki
    /// Mermaid.
    case mermaid
    /// Meson.
    case meson
    /// Metal.
    case metal
    /// Move.
    case move
    /// Mustache.
    case mustache
    /// MySQL.
    case mysql
    /// NGINX Conf.
    case nginx
    /// Nim.
    case nim
    /// Ninja.
    case ninja
    /// Nix.
    case nix
    /// Nunjucks.
    case nunjucks
    /// Nushell.
    case nushell
    /// Objective-C.
    case objectivec
    /// Objective-C++.
    case objectivecpp
    /// OCaml.
    case ocaml
    /// Odin.
    case odin
    /// OpenCL.
    case opencl
    /// Org.
    case org
    /// Pascal.
    case pascal
    /// Perl.
    case perl
    /// PHP.
    case php
    /// Pip Requirements.
    case piprequirements
    /// PlantUML.
    case plantuml
    /// Property List.
    case plist
    /// PL/pgSQL.
    case plpgsql
    /// PL/SQL.
    case plsql
    /// PostCSS.
    case postcss
    /// PowerShell.
    case powershell
    /// Prisma.
    case prisma
    /// Prolog.
    case prolog
    /// Java Properties.
    case properties
    /// Protocol Buffers.
    case protobuf
    /// PRQL.
    case prql
    /// Pug.
    case pug
    /// PureScript.
    case purescript
    /// Python.
    case python
    /// Q#.
    case qsharp
    /// Quarto.
    case quarto
    /// R.
    case r
    /// Racket.
    case racket
    /// Raku.
    case raku
    /// Razor (ASP.NET).
    case razor
    /// Reason.
    case reason
    /// Rego (OPA).
    case rego
    /// ReScript.
    case rescript
    /// reStructuredText.
    case restructuredtext
    /// R Markdown.
    case rmarkdown
    /// RON (Rusty Object Notation).
    case ron
    /// Ruby.
    case ruby
    /// Rust.
    case rust
    /// SAS.
    case sas
    /// Sass.
    case sass
    /// Scala.
    case scala
    /// Scheme.
    case scheme
    /// SCSS.
    case scss
    /// Shell Script (POSIX).
    case sh
    /// ShaderLab (Unity).
    case shaderlab
    /// Slim.
    case slim
    /// Smalltalk.
    case smalltalk
    /// Smarty.
    case smarty
    /// Standard ML.
    case sml
    /// Solidity.
    case solidity
    /// SPARQL.
    case sparql
    /// SQL.
    case sql
    /// SQLite.
    case sqlite
    /// Starlark.
    case starlark
    /// Stata.
    case stata
    /// Apple Strings.
    case strings
    /// Stylus.
    case stylus
    /// Svelte.
    case svelte
    /// Swift.
    case swift
    /// Yacc / Bison.
    case yacc
    /// systemd Unit.
    case systemd
    /// SystemVerilog.
    case systemverilog
    /// Tcl.
    case tcl
    /// Terraform.
    case terraform
    /// Texinfo.
    case texinfo
    /// Textile.
    case textile
    /// Thrift.
    case thrift
    /// TOML.
    case toml
    /// T-SQL.
    case tsql
    /// TSV.
    case tsv
    /// TSX.
    case tsx
    /// Turtle (RDF).
    case turtle
    /// Twig.
    case twig
    /// TypeScript.
    case typescript
    /// V.
    case v
    /// Vala.
    case vala
    /// Visual Basic .NET.
    case vbnet
    /// VBScript.
    case vbscript
    /// Velocity.
    case velocity
    /// Verilog.
    case verilog
    /// VHDL.
    case vhdl
    /// Vim script.
    case vimscript
    /// Vue.
    case vue
    /// Vyper.
    case vyper
    /// WebAssembly Text.
    case wat
    /// WGSL (WebGPU).
    case wgsl
    /// Mathematica / Wolfram Language.
    case wolfram
    /// Xcode Config.
    case xcconfig
    /// XML.
    case xml
    /// XQuery.
    case xquery
    /// XSLT.
    case xslt
    /// YAML.
    case yaml
    /// Zig.
    case zig
    /// Zsh.
    case zsh
    /// Plain text — the fallback for files no rule recognizes.
    case plainText = "plaintext"
}
