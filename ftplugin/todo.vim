" File:          simple-todo.vim
" Author:        Juan Carlos Arocha
" Description:   Add functions and maps to handle todo lists

" TODO: take into account the 80's column rule
" TODO: Add mentions and markdown formatting

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

" Tab size for indentation level
if !exists('g:todo_tab_size')
    let g:todo_tab_size = 4
endif

if !exists('g:todo_max_int')
    let g:todo_max_int = 1000
endif

if !exists('g:number_of_priorities')
    let g:number_of_priorities = 26
endif

if !exists('g:todo_sorting_precedence')
    let g:todo_sorting_precedence = { "done" : g:todo_max_int,  "undone" : g:number_of_priorities + 1 }
endif


" Setting the folding method. 
" The foldexpr was taken from: 
" http://vim.wikia.com/wiki/Folding_for_plain_text_files_based_on_indentation
setlocal foldmethod=expr
setlocal foldexpr=(getline(v:lnum)=~'^$')?-1:((indent(v:lnum)<indent(v:lnum+1))?('>'.indent(v:lnum+1)):indent(v:lnum))
set fillchars=fold:\ "(there's a space after that \)


" Function that returns the string to show in the folded item
fu! CollapsedItemText()
    let l:itemsno         = 0
    let l:completed_items = 0

    let l:curr_indent = indent(v:foldstart)

    for lnum in range(v:foldstart + 1, v:foldend)
        " The item is direct subitem
        if indent(lnum) == l:curr_indent + 4
            let l:itemsno += 1
            " the item is marked 
            if getline(lnum) =~ '^\s*- \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
                let l:completed_items += 1
            endif
        endif
    endfor

    return getline(v:foldstart).' ('.l:completed_items.'/'.l:itemsno.')'
endfu
set foldtext=CollapsedItemText()

" Subitems tree
let s:subitems_tree = {}
" Item's attached lines
let s:attached_lines = {}

" }}}

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


" Inserts a new item in the current line. 
" If there's already an item, moves the item to the next line
fu! s:insert_new_item(lineno)
    exe 'normal '.a:lineno.'G'
    let l:spaces = repeat(' ', g:todo_tab_size)
    if ContainsItem(getline(a:lineno))
        let l:indentation_level = IndentationLevel(getline(a:lineno), g:todo_tab_size)
        let l:spaces .= repeat(' ', (l:indentation_level - 1) * g:todo_tab_size)
    endif
    put! = l:spaces.'- [ ]' 
endfu

" Inserts a new subitem for the item in the current line. 
" If there's already a subitem, moves it to the next line
fu! s:insert_new_subitem(item_lineno)
    let l:item = getline(a:item_lineno)
    
    if ContainsItem(l:item)
        let l:indentation_level = IndentationLevel(l:item, g:todo_tab_size)

        let l:spaces = repeat(' ', (l:indentation_level + 1) * g:todo_tab_size)

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
    let l:curr_indentation = IndentationLevel(getline(a:lineno), g:todo_tab_size)
    let l:next_indentation = IndentationLevel(getline(l:next_item), g:todo_tab_size)

    while l:next_indentation > l:curr_indentation && l:next_item <= line('$')
        let l:marked_items = s:mark_item_as_done(l:next_item)
        let l:next_item += l:marked_items + 1
        let l:next_indentation = IndentationLevel(getline(l:next_item), g:todo_tab_size)
    endwhile
endfu

" Unmarks the item and removes the date
fu! s:mark_item_as_undone(lineno)
    let l:checkbox_regex='^\(\s*[-+*]\?\s*\)\[x\]\s'
    let l:date_regex='(\d\{4}-\d\{2}-\d\{2}\s\d\{2}:\d\{2}:\d\{2})'
    :call s:preserve(':silent! :'.a:lineno.'s/'.l:checkbox_regex.l:date_regex.'/\1[ ]/')

    " We need to check for subitems
    let l:next_item        = a:lineno + 1
    let l:curr_indentation = IndentationLevel(getline(a:lineno), g:todo_tab_size)
    let l:next_indentation = IndentationLevel(getline(l:next_item), g:todo_tab_size)

    while l:next_indentation > l:curr_indentation && l:next_item <= line('$')
        let l:unmarked_items = s:mark_item_as_undone(l:next_item)
        let l:next_item += l:unmarked_items + 1
        let l:next_indentation = IndentationLevel(getline(l:next_item), g:todo_tab_size)
    endwhile
endfu

" Checks if an item has a priority
fu! s:has_priority(item)
    return match(a:item, '(A-Z)$') != -1
endfu

" Tags the item with a priority (TODO: check if there was a priority before)
fu! s:prioritize_item(lineno, priority)

    let line_text = getline(a:lineno)
    if match(l:line_text, '([A-Z])$') != -1
        let l:new_priority = substitute(l:line_text, '([A-Z])$', '('.a:priority.')', '')
        call setline(a:lineno, l:new_priority)
    else
        :call s:preserve('norm! '.a:lineno.'GA ('.a:priority.')')
    endif
endfu

" This will serve to decrement or increment the priority
fu! s:increase_item_priority(lineno)
    set nf=octal,hex,alpha
    exe ':normal! '.a:lineno.'G$h'."\<C-X>"
    set nf=octal,hex
endfu

fu! s:decrease_item_priority(lineno)
    set nf=octal,hex,alpha
    exe ':normal! '.a:lineno.'G$h'."\<C-A>"
    set nf=octal,hex
endfu

" This function returns the number of items checked
fu! s:build_subitems_tree(curr_line, indentation_level)

    let l:curr_attached_lines = 0

    for l:line in range(a:curr_line + 1, line('$'))
        let l:next_indentation = IndentationLevel(getline(l:line), g:todo_tab_size)

        " It's the next indentation level, add subitem and make recursive call
        if l:next_indentation == a:indentation_level + 1
            if !has_key(s:subitems_tree, a:curr_line)
                let s:subitems_tree[a:curr_line] = []
            endif
            call add(s:subitems_tree[a:curr_line], l:line)

            let l:curr_attached_lines += <SID>build_subitems_tree(l:line, l:next_indentation) + 1

        elseif l:next_indentation <= a:indentation_level 
            break

        endif
    endfor

    let s:attached_lines[a:curr_line] = l:curr_attached_lines

    return l:curr_attached_lines
endfu


" This function gets the super item of an item by checking the 
" closest item bottom-up that has indentation level - 1
fu! s:get_super_item(line)
    return <SID>search_super_in_file(a:line, IndentationLevel(getline(a:line), g:todo_tab_size))
endfu

" Helper function for get_super_item
fu! s:search_super_in_file(line, indentation)
    if a:line == 1
        return 0
    endif
    let l:next_line        = a:line - 1
    let l:next_indentation = IndentationLevel(getline(l:next_line), g:todo_tab_size)

    if l:next_indentation == a:indentation + 1
        return l:next_line
    endif

    return <SID>search_super_in_file(l:next_line, l:next_indentation)
endfu

" Returns the item priority. If it's not tagged, then it returns done or
" undone
fu! GetItemPriority(item)
    let l:priority = matchstr(a:item , '([A-Z])$')
    return l:priority != "" ? l:priority[1] : match(a:item, '\s*-\s\[[\ ]\]') != -1 ? '@' : '~'
endfu

" Comparison for the sort() function
fu! ItemComparison(i1,i2)
    let l:i1_prior = GetItemPriority(a:i1[0])
    let l:i2_prior = GetItemPriority(a:i2[0])

    return l:i1_prior == l:i2_prior ? 0 : l:i1_prior < l:i2_prior ? -1 : 1
endfu


" Sorts the items keeping the subitems attached to their superitems
" XXX: Make the sort on the whole file
fu! s:sort_items() range
    let s:subitems_tree  = {}
    let s:attached_lines = {}
    call <SID>build_subitems_tree(0, 0)


    " Gets super item of the first line
    let l:superitem = <SID>get_super_item(a:firstline)

    " Gets all the line numbers to take into account for sorting
    let l:elements_to_sort = s:subitems_tree[l:superitem]

    " Converts the line number into tuples (line, line number)
    call map(l:elements_to_sort, '[getline(v:val), v:val]')

    " Sorts the lines according to their priority and status (done or undone)
    let l:sorted_elements = sort(copy(l:elements_to_sort), 'ItemComparison')

    let l:sorted_list = []


    for l:elem in l:sorted_elements 
        let l:elem_line           = l:elem[1]
        let l:elem_attached_lines = s:attached_lines[l:elem[1]]

        let l:curr_elem = getline(l:elem_line, l:elem_line + l:elem_attached_lines)
        let l:sorted_list += l:curr_elem
    endfor

    call setline(l:superitem + 1, l:sorted_list)

    " Cleaning the environment
    unlet s:subitems_tree
    unlet s:attached_lines
endfu
" }}}

" Public API {{{
"
" Checks if the string string contains a todo item
fu! ContainsItem(string)
    let l:item = matchstr(a:string, '    - \[[x\ ]\]')
    return l:item != ""
endfu

" Returns the indentation level of an item (lineno)
" TODO: Replace this for indent()
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

fu! PrioritizeItem(lineno, priority)
    call <SID>prioritize_item(a:lineno, a:priority)
endfu

fu! IncreaseItemPriority(lineno)
    call <SID>increase_item_priority(a:lineno)
endfu

fu! DecreaseItemPriority(lineno)
    call <SID>decrease_item_priority(a:lineno)
endfu

fu! BuildSubItemTree()
    let s:subitems_tree = {}
    call <SID>build_subitems_tree(0, 0)
    return [s:subitems_tree, s:attached_lines]
endfu

fu! SortItems() range
    call <SID>sort_items()
endfu

" Scope to access s:* variables
fu! Scope()
    return s:
endfu

fu! SID()
    return maparg('<SID>', 'n')
endfu

nnoremap <SID> <SID>

" }}}

" Maps {{{

" Folding maps:
nnoremap <buffer> <S-Left> zo
inoremap <buffer> <S-Left> <C-O>zo
nnoremap <buffer> <S-Right> zc
inoremap <buffer> <S-Right> <C-O>zc

" }}}
