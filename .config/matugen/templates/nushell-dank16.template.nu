$env.theme = {
    binary: "{{dank16.color1.default.hex}}"
    block: "{{dank16.color7.default.hex}}"
    bool: "{{dank16.color14.default.hex}}"
    cell-path: "{{dank16.color8.default.hex}}"
    date: "{{dank16.color14.default.hex}}"
    duration: "{{dank16.color8.default.hex}}"
    empty: "{{dank16.color8.default.hex}}"
    filesize: "{{dank16.color13.default.hex}}"
    float: "{{dank16.color13.default.hex}}"
    header: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    hints: "{{dank16.color8.default.hex}}"
    int: "{{dank16.color14.default.hex}}"
    leading_trailing_space_bg: { attr: "n" }
    list: "{{dank16.color7.default.hex}}"
    nothing: "{{dank16.color8.default.hex}}"
    range: "{{dank16.color14.default.hex}}"
    record: "{{dank16.color7.default.hex}}"
    row_index: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    search_result: { fg: "{{dank16.color15.default.hex}}" bg: "{{dank16.color5.default.hex}}" }
    separator: "{{dank16.color8.default.hex}}"
    shape_and: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_binary: { fg: "{{dank16.color1.default.hex}}" attr: "b" }
    shape_block: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    shape_bool: "{{dank16.color14.default.hex}}"
    shape_closure: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    shape_custom: "{{dank16.color12.default.hex}}"
    shape_datetime: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_directory: "{{dank16.color14.default.hex}}"
    shape_external: "{{dank16.color13.default.hex}}"
    shape_external_resolved: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    shape_externalarg: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_filepath: "{{dank16.color13.default.hex}}"
    shape_flag: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_float: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    shape_garbage: { fg: "{{dank16.color15.default.hex}}" bg: "{{dank16.color1.default.hex}}" attr: "b" }
    shape_glob_interpolation: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    shape_globpattern: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    shape_int: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_internalcall: { fg: "{{dank16.color12.default.hex}}" attr: "b" }
    shape_keyword: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_list: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_literal: "{{dank16.color13.default.hex}}"
    shape_match_pattern: "{{dank16.color14.default.hex}}"
    shape_matching_brackets: { attr: "u" }
    shape_nothing: "{{dank16.color8.default.hex}}"
    shape_operator: "{{dank16.color7.default.hex}}"
    shape_or: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_pipe: { fg: "{{dank16.color7.default.hex}}" attr: "b" }
    shape_range: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_raw_string: "{{dank16.color6.default.hex}}"
    shape_record: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    shape_redirection: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    shape_signature: { fg: "{{dank16.color12.default.hex}}" attr: "b" }
    shape_string: "{{dank16.color6.default.hex}}"
    shape_string_interpolation: { fg: "{{dank16.color14.default.hex}}" attr: "b" }
    shape_table: { fg: "{{dank16.color13.default.hex}}" attr: "b" }
    shape_vardecl: "{{dank16.color14.default.hex}}"
    shape_variable: "{{dank16.color13.default.hex}}"
    string: "{{dank16.color6.default.hex}}"
}

$env.raw_theme = {
   <* for name, value in colors *>
   {{name}}: "{{value.default.hex}}"
   <* endfor *>
}
