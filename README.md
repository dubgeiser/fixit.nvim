# Fixit

A Neovim plugin to handle basic tasks in a code file.

## Install
Via your favorite package manager, for example Packer:

    use 'dubgeiser/nvim-fixit'

## Configuration
After Fixit is installed, you need to set it up:

    require("nvim-fixit").setup()

## Usage
Add 'FIXME', 'XXX' and 'TODO' in a code comment, followed by some text.
Run `:FixitList` to show the tasks in `qflist` with the text following the token.
Navigate `qflist` to jump to the corresponding place in the code file.

When you edit the buffer, the Fixit list is not updated automatically.
Execute `:FixitList` to update the list if necessary.
