# Fixit

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

When you edit the buffer, the Fixit list is not updated automatically.
Execute `:Fixit` to update the list if necessary.

Every comment with a token ('TODO', 'XXX', 'FIXME') will be picked up by Fixit, but only the part _AFTER_ is taken into consideration.
Fixit only picks up 1 line.
If you just write comments like:

    # TODO Extract fixamathingie
    # FIXME This only works for more than 2 elements
    # etc...

All should be fine ;-)
