" File:          simple-todo.vim
" Author:        Juan Carlos Arocha
" Description:   Add functions and maps to handle todo lists

" TODO: take into account the 80's column rule

" Guard {{{

if exists('g:loaded_fancy_todo') || &cp
    finish
endif
let g:loaded_fancy_todo = 1

" }}}

" Config options {{{

" TODO: take into account the max_nested_items variable
if !exists('g:max_nested_items')
    let g:max_nested_items = 4
endif

if !exists('g:tab_size_for_indentation_level')
    let g:tab_size_for_indentation_level = 4
endif

" }}}

" We will use a dictionary to handle subitems with the form
" item_lineno -> [ subitem1_lineno, subitem2_lineno, ... ]

" Private functions {{{

" Preserves the cursor and last search
fu! s:preserve(command)
    let _s=@/
    let l = line(".")
    let c = col(".")

    execute a:command

    let @/=_s
    :call cursor(l, c)
endfu


" Checks if the string string contains a todo item
fu! ContainsItem(string)
    let l:item = matchstr(a:string, '    - \[[x\ ]\]')
    return l:item != ""
endfu



" Returns the indentation level of an item (lineno)
fu! IndentationLevel(item, tab)
    let l:char   = a:item[0]
    let l:spaces = 0
    let l:index  = 1

    while (l:char != '-' && l:index < len(a:item))
        let l:char = a:item[l:index]
        let l:spaces += 1
        let l:index += 1
    endwhile

    return l:spaces / a:tab
endfu

" Inserts a new item in the current line. 
" If there's already an item, moves the item to the next line
fu! s:insert_new_item(lineno)
    exe 'normal '.a:lineno.'G'
    let l:spaces = repeat(' ', g:tab_size_for_indentation_level)
    if ContainsItem(getline(a:lineno))
        let l:indentation_level = IndentationLevel(getline(a:lineno), g:tab_size_for_indentation_level)
        let l:spaces .= repeat(' ', (l:indentation_level - 1) * g:tab_size_for_indentation_level)
    endif
    put! = l:spaces.'- [ ]' 
endfu

" Inserts a new subitem for the item in the current line. 
" If there's already a subitem, moves it to the next line
fu! s:insert_new_subitem(item_lineno)
    let l:item = getline(a:item_lineno)
    
    if ContainsItem(l:item)
        let l:indentation_level = IndentationLevel(l:item, g:tab_size_for_indentation_level)

        let l:spaces = repeat(' ', (l:indentation_level + 1) * g:tab_size_for_indentation_level)

        exe 'normal! '.a:item_lineno.'G'
        put = l:spaces.'- [ ]'
    else
        echom "There's no item under cursor"
    endif
endfu


" Marks an item and adds the current date an hour 
" Returns the amount of items marked
fu! s:mark_item_as_done(lineno) 
    let l:date=strftime("%Y-%m-%d %H:%M:%S")
    :call <SID>preserve(':silent! :'.a:lineno.'s/^\(\s*- [-+*]\?\s*\)\[ \]/\1[x]\ ('.l:date.')/')

    " We need to check for subitems
    let l:next_item        = a:lineno + 1
    let l:curr_indentation = IndentationLevel(getline(a:lineno), g:tab_size_for_indentation_level)
    let l:next_indentation = IndentationLevel(getline(l:next_item), g:tab_size_for_indentation_level)

    echom l:curr_indentation 
    echom l:next_indentation 

    while l:next_indentation > l:curr_indentation && l:next_item <= line('$')
        let l:marked_items = s:mark_item_as_done(l:next_item)
        let l:next_item += l:marked_items + 1
        let l:next_indentation = IndentationLevel(getline(l:next_item), g:tab_size_for_indentation_level)
    endwhile
endfu

" Unmarks the item and removes the date
fu! s:mark_item_as_undone(lineno)
    let l:checkbox_regex='^\(\s*[-+*]\?\s*\)\[x\]\s'
    let l:date_regex='(\d\{4}-\d\{2}-\d\{2}\s\d\{2}:\d\{2}:\d\{2})'
    :call s:preserve(':silent! :'.a:lineno.'s/'.l:checkbox_regex.l:date_regex.'/\1[ ]/')

    " We need to check for subitems
    let l:next_item        = a:lineno + 1
    let l:curr_indentation = IndentationLevel(getline(a:lineno), g:tab_size_for_indentation_level)
    let l:next_indentation = IndentationLevel(getline(l:next_item), g:tab_size_for_indentation_level)

    echom l:curr_indentation 
    echom l:next_indentation 

    while l:next_indentation > l:curr_indentation && l:next_item <= line('$')
        let l:unmarked_items = s:mark_item_as_undone(l:next_item)
        let l:next_item += l:unmarked_items + 1
        let l:next_indentation = IndentationLevel(getline(l:next_item), g:tab_size_for_indentation_level)
    endwhile
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

fu! InsertItem(lineno)
    call <SID>insert_new_item(a:lineno)
endfu

fu! InsertSubItem(lineno)
    call <SID>insert_new_subitem(a:lineno)
endfu

fu! MarkItemAsDone(lineno)
    call <SID>mark_item_as_done(a:lineno)
endfu

fu! MarkItemAsUndone(lineno)
    call <SID>mark_item_as_undone(a:lineno)
endfu

" }}}
