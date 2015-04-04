" File:          simple-todo.vim
" Author:        Vital Kudzelka
" Modifications: Juan Carlos Arocha
" Description:   Add some useful mappings to manage simple TODO list


" Guard {{{

if exists('g:loaded_fancy_todo') || &cp
    finish
endif
let g:fancy_simple_todo = 1

" }}}

" Config options {{{

" Do map key bindings? (yes)
if !exists('g:fancy_todo_map_keys')
    let g:fancy_todo_map_keys = 1
endif

" }}}

" Private functions {{{
fu! s:preserve(command)
    let _s=@/
    let l = line(".")
    let c = col(".")

    execute a:command

    let @/=_s
    :call cursor(l, c)
endfu


fu! s:get_list_marker(linenr) " {{{
    return substitute(getline(a:linenr), '^\s*\([-+*]\?\s*\).*', '\1', '')
endfu " }}}

fu! s:insert_new_item()
    if mode() == "n"
        execute 'a    [ ]'
    else
        execute '    [ ]'
    endif
endfu

" Adds the date and hour when the item was marked as done
fu! s:mark_item_as_done() " {{{
    let date=strftime("%Y-%m-%d %H:%M:%S")
    :call s:preserve(':silent! :s/^\(\s*[-+*]\?\s*\)\[ \]/\1[x]\ ('.date.')/')

endfu "}}}

" Unmarks the item and removes the date
fu! s:mark_item_as_undone()
    let checkbox_regex='^\(\s*[-+*]\?\s*\)\[x\]\s'
    let date_regex='(\d\{4}-\d\{2}-\d\{2}\s\d\{2}:\d\{2}:\d\{2})'
    :call s:preserve(':silent! :s/'.checkbox_regex.date_regex.'/\1[ ]/')
endfu

" Tags the item with a priority (TODO: check if there was a priority before)
fu! s:tag_item_with_priority(priority)
    :call s:preserve('norm! A ('.a:priority.')')
endfu

" This will serve to decrement or increment the priority
:set nf=octal,hex,alpha
fu! s:increase_item_priority()
    normal! $F(l\<C-x>
endfu

fu! s:decrease_item_priority()
    normal! $F(l\<C-a>
endfu
" }}}

" Public API {{{

" Create a new item
"
nnore <Plug>(simple-todo-new) a    [ ]<space>
inore <Plug>(simple-todo-new) [ ]<space>

" Create a new item below
nnore <Plug>(simple-todo-below) o<c-r>=<SID>get_list_marker(line('.')-1)<cr>[ ]<space>
inore <Plug>(simple-todo-below) <Esc>o<c-r>=<SID>get_list_marker(line('.')-1)<cr>[ ]<space>

" Create a new item above
nnore <Plug>(simple-todo-above) O<c-r>=<SID>get_list_marker(line('.')+1)<cr>[ ]<space>
inore <Plug>(simple-todo-above) <Esc>O<c-r>=<SID>get_list_marker(line('.')+1)<cr>[ ]<space>

" Mark item under cursor as done
nnore <Plug>(simple-todo-mark-as-done) :call <SID>mark_item_as_done()<cr>
vnore <Plug>(simple-todo-mark-as-done) :call <SID>mark_item_as_done()<cr>
inore <Plug>(simple-todo-mark-as-done) <Esc>:call <SID>mark_item_as_done()<cr>

" Mark as undone
nnore <Plug>(simple-todo-mark-as-undone) :call <SID>mark_item_as_undone()<cr>
vnore <Plug>(simple-todo-mark-as-undone) :call <SID>mark_item_as_undone()<cr>
inore <Plug>(simple-todo-mark-as-undone) <Esc>:call <SID>mark_item_as_undone()<cr>

" Tag priority
nnore <Plug>(fancy-todo-tag-a) :call <SID>tag_item_with_priority('A')<cr>
nnore <Plug>(fancy-todo-tag-b) :call <SID>tag_item_with_priority('B')<cr>
nnore <Plug>(fancy-todo-tag-c) :call <SID>tag_item_with_priority('C')<cr>

" Sort priorities (keeps items without priority at the beginning)
nnore <Plug>(fancy-todo-sort) :sort /.\{-}\ze([A-Z])/<cr>

" Increase the current item priority
nnore <Plug>(fancy-todo-increase-priority) :call <SID>increase_item_priority()<cr>
" Decrease the current item priority
nnore <Plug>(fancy-todo-decrease-priority) :call <SID>decrease_item_priority()<cr>
    

" }}}
" Key bindings {{{ 

if g:fancy_todo_map_keys
    nmap <silent> <Leader>i <Plug>(simple-todo-new)
    imap <silent> <Leader>i <Plug>(simple-todo-new)
    nmap <silent> <Leader>o <Plug>(simple-todo-below)
    imap <silent> <Leader>o <Plug>(simple-todo-below)
    nmap <silent> <Leader>O <Plug>(simple-todo-above)
    imap <silent> <Leader>O <Plug>(simple-todo-above)
    nmap <silent> <Leader>x <Plug>(simple-todo-mark-as-done)
    vmap <silent> <Leader>x <Plug>(simple-todo-mark-as-done)
    imap <silent> <Leader>x <Plug>(simple-todo-mark-as-done)
    nmap <silent> <Leader>X <Plug>(simple-todo-mark-as-undone)
    vmap <silent> <Leader>X <Plug>(simple-todo-mark-as-undone)
    imap <silent> <Leader>X <Plug>(simple-todo-mark-as-undone)

    nmap <silent> <Leader>a <Plug>(fancy-todo-tag-a)
    nmap <silent> <Leader>b <Plug>(fancy-todo-tag-b)
    nmap <silent> <Leader>c <Plug>(fancy-todo-tag-c)
    nmap <silent> <buffer> <Leader>s <Plug>(fancy-todo-sort)
    nmap <silent> <buffer> <Leader>u <Plug>(fancy-todo-increase-priority)
    nmap <silent> <buffer> <Leader>d <Plug>(fancy-todo-decrease-priority)
endif

" }}}
