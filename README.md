# Fixit

A Neovim plugin to handle basic tasks in a code file.

## Install
Via your favorite package manager, for example Packer:

    use 'dubgeiser/nvim-fixit'

## Usage
Add 'FIXME', 'XXX' and 'TODO' in a code comment, followed by some text.
Run `:FixitList` to show the tasks in `qflist` with the text following the token.
Navigate `qflist` to jump to the corresponding place in the code file.

## Configuration

