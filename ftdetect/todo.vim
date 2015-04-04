" File:          fancy-todo.vim
" Author:        Juan Carlos Arocha
" Description:   filetype detection for .todo, .td, .done, .dn


autocmd BufNewFile,BufRead *.todo set filetype=todo
autocmd BufNewFile,BufRead *.td set filetype=todo
autocmd BufNewFile,BufRead *.done set filetype=todo
autocmd BufNewFile,BufRead *.dn set filetype=todo
