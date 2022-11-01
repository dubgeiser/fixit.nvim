# Fixit

## Note
The most up to date documentation can be found in Fixits help:

    :help fixit.txt

A Neovim plugin to handle basic tasks in a code file.

## Install
Via your favorite package manager, for example Packer:

    use 'dubgeiser/fixit.nvim'

## Configuration
After Fixit is installed, you need to set it up:

    require("fixit.nvim").setup()

## Usage
Add 'FIXME', 'XXX' and 'TODO' in a code comment, followed by some text.
Run `:Fixit` to show the tasks in `qflist` with the text following the token.
Navigate `qflist` to jump to the corresponding place in the code file.
