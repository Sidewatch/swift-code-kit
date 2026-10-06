(boolean_scalar) @boolean

(null_scalar) @constant.builtin

[
  (double_quote_scalar)
  (single_quote_scalar)
  (block_scalar)
  (string_scalar)
] @string
;; YAML 1.1 booleans (`yes`, `No`, `ON`…), which the 1.2 core schema reads as strings but most tools
;; that read config (Ansible, PyYAML, Psych) still take as booleans.
((string_scalar) @boolean
  (#match? @boolean "^(yes|Yes|YES|no|No|NO|on|On|ON|off|Off|OFF)$"))

[
  (integer_scalar)
  (float_scalar)
] @number

(comment) @comment

[
  (anchor_name)
  (alias_name)
] @label

(tag) @type

[
  (yaml_directive)
  (tag_directive)
  (reserved_directive)
] @attribute

(block_mapping_pair
  key: (flow_node
    [
      (double_quote_scalar)
      (single_quote_scalar)
    ] @property))

(block_mapping_pair
  key: (flow_node
    (plain_scalar
      (string_scalar) @property)))

(flow_mapping
  (_
    key: (flow_node
      [
        (double_quote_scalar)
        (single_quote_scalar)
      ] @property)))

(flow_mapping
  (_
    key: (flow_node
      (plain_scalar
        (string_scalar) @property))))

[
  ","
  "-"
  ":"
  ">"
  "?"
  "|"
] @punctuation.delimiter

[
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  "*"
  "&"
  "---"
  "..."
] @punctuation.special

; Sidewatch: a directive's version is a number and its tag handle a keyword (`%YAML 1.2`, `%TAG !e! …`), as
; VS Code scopes them.
(yaml_directive
  (yaml_version) @number)
(tag_directive
  (tag_handle) @keyword)
; The rest of the YAML 1.1 booleans (`y`, `n`) and timestamps (`2026-03-01`, `2026-03-01T09:30:00Z`), which
; VS Code paints as constants.
((string_scalar) @boolean
  (#match? @boolean "^(y|Y|n|N)$"))
((string_scalar) @number
  (#match? @number "^[0-9]{4}-([0-9]{2}-[0-9]{2}|[0-9]{1,2}-[0-9]{1,2}([Tt]|[ \t]+)[0-9]{1,2}:[0-9]{2}:[0-9]{2}(\\.[0-9]*)?([ \t]*Z|[ \t]*[-+][0-9]{1,2}(:[0-9]{2})?)?)$"))
