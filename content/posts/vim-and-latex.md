+++
title = "VIM and Latex"
date = 2019-03-27
slug = "vim-and-latex"

[taxonomies]
categories =  ["Post"]
tags = [
  "vim",
  "lsp",
  "latex",
  "coc.nvim",
  "texlab"
]
+++

# 起源

起源是在群里看到了有人分享的关于一个人用 `vim` 写 `latex` 的文章，但是它的做法是用了一个 `vimtex` 的独立插件。
我是个 language server 的狂热使用者，所以我就在找一个用 language server 的处理方案。回忆起来另一次在另一个群里看到的，一个叫做 [texlab](https://github.com/latex-lsp/texlab) 的项目，就在 vim 里搞个配合。

# vim 里的插件选择

vim 里的 language client 的实现用好几种：

- [vim-lsp](https://github.com/prabirshrestha/vim-lsp)
- [coc.nvim](https://github.com/neoclide/coc.nvim)
- [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)

用来用去还是 `coc.nvim` 在这里面不论是流畅度还是 feature 的丰富程度都是比较好的。所以我也一直在用。

# Install

install `coc.nvim`:

```vim
call dein#add('neoclide/coc.nvim', {'build': 'yarn install'})
```

install `texlab`:

```bash
git clone https://github.com/latex-lsp/texlab
yarn install && yarn build
```

# config

config in coc.nvim
```json
"texlab": {
  "command": "node",
  "args": [
    "/path/to/texlab/dist/texlab.js", "--stdio"
  ],
  "filetypes": ["tex", "plaintex"],
  "trace.server": "verbose"
}
```