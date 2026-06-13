default:
  @just --choose

about:
    @awk '/^#/ {print} !/^#/ {exit}' "{{justfile()}}"
    @echo 'Summarises the purpose of this file.'
    @echo 'This lists the comment lines of the file until the first line that does not start with a '#' character. Then it lists the targets of the file.'
    @just --list



br:
  dart run build_runner watch
frb:
  flutter_rust_bridge_codegen generate --watch