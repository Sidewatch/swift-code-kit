//
//  LLVMRules.swift
//  CodeHighlighting
//
//  The regex rule table for LLVM IR.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// LLVM IR: `;` comments, `%locals`, `@globals`, `!metadata`, the integer and float types,
/// the instruction and linkage words, `c"…"` constants.
extension RuleTables {
    static let llvm: [(String, TokenKind)] = [
        (";.*$", .comment),
        ("c?\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("%[\\w.]+", .variable),
        ("@[\\w.]+", .function),
        ("![\\w.]+", .property),
        ("\\b(i\\d+|void|half|bfloat|float|double|fp128|x86_fp80|ppc_fp128|ptr|label|token|metadata|x86_mmx|opaque)\\b", .type),
        ("\\[\\s*\\d+\\s+x\\b", .type),
        keywords([
            "define", "declare", "ret", "br", "switch", "indirectbr", "invoke", "resume", "unreachable", "call", "tail", "musttail", "icmp",
            "fcmp", "phi", "select", "add", "fadd", "sub", "fsub", "mul", "fmul", "udiv", "sdiv", "fdiv", "urem", "srem", "frem", "shl",
            "lshr", "ashr", "and", "or", "xor", "load", "store", "alloca", "getelementptr", "fence", "cmpxchg", "atomicrmw", "trunc",
            "zext", "sext", "fptrunc", "fpext", "fptoui", "fptosi", "uitofp", "sitofp", "ptrtoint", "inttoptr", "bitcast", "addrspacecast",
            "extractelement", "insertelement", "shufflevector", "extractvalue", "insertvalue", "landingpad", "global", "constant",
            "private", "internal", "external", "linkonce", "weak", "common", "appending", "unnamed_addr", "local_unnamed_addr", "align",
            "nsw", "nuw", "exact", "inbounds", "volatile", "target", "datalayout", "triple", "attributes", "source_filename", "eq", "ne",
            "ugt", "uge", "ult", "ule", "sgt", "sge", "slt", "sle", "oeq", "ogt", "oge", "olt", "ole", "one", "ord", "uno", "true", "false",
            "null", "undef", "poison", "zeroinitializer", "nocapture", "noalias", "readonly", "nounwind", "noinline", "alwaysinline",
            "dso_local", "type", "to",
        ]),
        // Linkage, visibility, calling conventions, atomic orderings, fast-math flags and attributes (LangRef).
        keywords([
            "linkonce_odr", "weak_odr", "available_externally", "extern_weak", "hidden", "protected", "default",
            "dllimport", "dllexport", "thread_local", "localdynamic", "initialexec", "localexec", "externally_initialized",
            "comdat", "any", "exactmatch", "largest", "nodeduplicate", "samesize", "section", "partition", "alias", "ifunc",
            "personality", "prefix", "prologue", "gc", "addrspace", "distinct", "module", "asm", "sideeffect", "inteldialect",
            "blockaddress", "dso_local_equivalent", "no_cfi", "within", "from", "ccc", "fastcc", "coldcc", "cc", "swiftcc",
            "swifttailcc", "tailcc", "ghccc", "webkit_jscc", "anyregcc", "preserve_mostcc", "preserve_allcc", "cxx_fast_tlscc",
            "x86_stdcallcc", "x86_fastcallcc", "x86_thiscallcc", "x86_vectorcallcc", "arm_apcscc", "arm_aapcscc",
            "arm_aapcs_vfpcc", "ptx_kernel", "ptx_device", "spir_kernel", "spir_func", "amdgpu_kernel", "atomic", "unordered",
            "monotonic", "acquire", "release", "acq_rel", "seq_cst", "syncscope", "singlethread", "fast", "nnan", "ninf",
            "nsz", "arcp", "contract", "afn", "reassoc", "fneg", "freeze", "va_arg", "catchswitch", "catchret", "cleanupret",
            "catchpad", "cleanuppad", "callbr", "cleanup", "catch", "filter", "unwind", "une", "ueq", "true", "false",
            "noundef", "nonnull", "signext", "zeroext", "inreg", "byval", "byref", "sret", "inalloca", "preallocated",
            "returned", "nest", "swiftself", "swiftasync", "swifterror", "immarg", "dereferenceable",
            "dereferenceable_or_null", "writeonly", "readnone", "nofree", "nosync", "willreturn", "mustprogress", "ssp",
            "sspstrong", "sspreq", "uwtable", "optnone", "optsize", "minsize", "cold", "hot", "convergent", "inlinehint",
            "naked", "nobuiltin", "nocf_check", "noduplicate", "noimplicitfloat", "nomerge", "nonlazybind", "noredzone",
            "noreturn", "norecurse", "nocallback", "noprofile", "nosanitize_coverage", "null_pointer_is_valid",
            "returns_twice", "safestack", "sanitize_address", "sanitize_memory", "sanitize_thread", "speculatable",
            "strictfp", "memory", "argmem", "inaccessiblemem", "read", "write", "readwrite", "none", "allocsize",
            "allockind", "nounwind", "uselistorder", "vscale", "splat", "notail", "x",
        ]),
        ("\\b-?\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b", .number),
    ]
}
