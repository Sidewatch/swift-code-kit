#ifndef TREE_SITTER_GRAMMARS_H
#define TREE_SITTER_GRAMMARS_H

/// Present so the dynamic library has a symbol of its own; the grammars' entry points
/// (`tree_sitter_swift()` and the rest) come from their own modules.
int tree_sitter_grammars_version(void);

#endif
