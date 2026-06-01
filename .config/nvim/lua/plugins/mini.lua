return {
   {
      "nvim-mini/mini.ai",
      version = false,
      opts = {
         mappings = {
            around = "a",
            inside = "i",
            around_next = "an",
            inside_next = "in",
            around_last = "al",
            inside_last = "il",
            goto_left = "g[",
            goto_right = "g]",
         },
         n_lines = 500,
         search_method = "cover_or_next",
      },
   },
   { "nvim-mini/mini.surround", version = false, opts = {} },
   { "nvim-mini/mini.operators", version = false, opts = {} },
   { "nvim-mini/mini.pairs", version = false, opts = {} },
   { "nvim-mini/mini.bracketed", version = false, opts = {} },
}
