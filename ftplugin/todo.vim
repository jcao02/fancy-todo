" File:          todo.vim
" Author:        Juan Carlos Arocha
" Description:   Add functions and maps to handle todo lists

" TODO: Add mentions and markdown formatting

" Guard {{{

if exists('g:loaded_fancy_todo') || &cp
    finish
endif
let g:loaded_fancy_todo = 1

" }}}

" Config options {{{

if !exists('g:max_nested_items')
    let g:max_nested_items = 4
endif

" Tab size for indentation level
if !exists('g:todo_tab_size')
    let g:todo_tab_size = 4
endif

" Setting the folding method. 
" The foldexpr was taken from: 
" http://vim.wikia.com/wiki/Folding_for_plain_text_files_based_on_indentation
setlocal foldmethod=expr

fu! FoldingFunction(line)
    return getline(a:line)=~'^$'? -1:
                \ ((indent(a:line) < indent(a:line + 1)) ? 
                \ ('>'.indent(a:line+1)): indent(a:line))
endfu
setlocal foldexpr=FoldingFunction(v:lnum)
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
    if <SID>contains_item(getline(a:lineno))
        let l:indentation_level = <SID>indentation_level(a:lineno)
        let l:spaces .= repeat(' ', (l:indentation_level - 1) * g:todo_tab_size)
    endif
    put! = l:spaces.'- [ ]' 
endfu

" Inserts a new subitem for the item in the current line. 
" If there's already a subitem, moves it to the next line
fu! s:insert_new_subitem(item_lineno)
    let l:item = getline(a:item_lineno)
    
    if <SID>contains_item(l:item)
        let l:indentation_level = <SID>indentation_level(a:item_lineno)
        
        " If the max number of nested items is reached, then it will add it in
        " the same level
        if l:indentation_level == g:max_nested_items + 1
            let l:indentation_level -= 1
        endif

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
    let l:curr_indentation = <SID>indentation_level(a:lineno)
    let l:next_indentation = <SID>indentation_level(l:next_item)

    while l:next_indentation > l:curr_indentation && l:next_item <= line('$')
        let l:marked_items = s:mark_item_as_done(l:next_item)
        let l:next_item += l:marked_items + 1
        let l:next_indentation = <SID>indentation_level(l:next_item)
    endwhile
endfu

" Unmarks the item and removes the date
fu! s:mark_item_as_undone(lineno)
    let l:checkbox_regex='^\(\s*[-+*]\?\s*\)\[x\]\s'
    let l:date_regex='(\d\{4}-\d\{2}-\d\{2}\s\d\{2}:\d\{2}:\d\{2})'
    :call s:preserve(':silent! :'.a:lineno.'s/'.l:checkbox_regex.l:date_regex.'/\1[ ]/')

    " We need to check for subitems
    let l:next_item        = a:lineno + 1
    let l:curr_indentation = <SID>indentation_level(a:lineno)
    let l:next_indentation = <SID>indentation_level(l:next_item)

    while l:next_indentation > l:curr_indentation && l:next_item <= line('$')
        let l:unmarked_items = s:mark_item_as_undone(l:next_item)
        let l:next_item += l:unmarked_items + 1
        let l:next_indentation = <SID>indentation_level(l:next_item)
    endwhile
endfu

" Toggle mark
fu! s:mark_item()
    let l:item = getline(line('.'))
    if match(l:item, '\s*-\s\[[\ ]\]') == -1 
        call <SID>mark_item_as_undone(line('.'))
    else
        call <SID>mark_item_as_done(line('.'))
    endif
endfu

" Checks if an item has a priority
fu! s:has_priority(item)
    return match(a:item, '([A-Z])$') != -1
endfu

" Tags the item with a priority 
fu! s:prioritize_item(lineno, priority)

    let l:line_text = getline(a:lineno)
    if <SID>has_priority(l:line_text)
        let l:new_priority = substitute(l:line_text, '([A-Z])$', 
                                        \ '('.a:priority.')', '')
        call setline(a:lineno, l:new_priority)
    else
        :call s:preserve('norm! '.a:lineno.'GA ('.a:priority.')')
    endif
endfu

" This will serve to increment the priority
fu! s:increase_item_priority(lineno)
    set nf=octal,hex,alpha
    exe ':normal! '.a:lineno.'G$h'."\<C-X>"
    set nf=octal,hex
endfu

" This will serve to decrement the priority
fu! s:decrease_item_priority(lineno)
    set nf=octal,hex,alpha
    exe ':normal! '.a:lineno.'G$h'."\<C-A>"
    set nf=octal,hex
endfu

" This function returns the number of items checked
fu! s:build_subitems_tree(curr_line, indentation_level)

    let l:curr_attached_lines = 0

    for l:line in range(a:curr_line + 1, line('$'))
        let l:next_indentation = <SID>indentation_level(l:line)

        " It's the next indentation level, add subitem and make recursive call
        if l:next_indentation == a:indentation_level + 1
            if !has_key(s:subitems_tree, a:curr_line)
                let s:subitems_tree[a:curr_line] = []
            endif
            call add(s:subitems_tree[a:curr_line], l:line)

            let l:curr_attached_lines += <SID>build_subitems_tree(
                                                    \ l:line, 
                                                    \ l:next_indentation) + 1
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
    return <SID>search_super_in_file(a:line, <SID>indentation_level(a:line))
endfu

" Helper function for get_super_item
fu! s:search_super_in_file(line, indentation)
    if a:line == 1
        return 0
    endif
    let l:next_line        = a:line - 1
    let l:next_indentation = <SID>indentation_level(l:next_line)

    if l:next_indentation == a:indentation - 1
        return l:next_line
    endif

    return <SID>search_super_in_file(l:next_line, l:next_indentation)
endfu

" Undone with priority    : Keeps same letter
" Undone without priority : ^ 
" Done with priority      : tolowercase (A -> a)
" Done without priority   : ~
fu! GetItemPriority(item)
    let l:priority = matchstr(a:item , '([A-Z])$')
    let is_done    = match(a:item, '\s*-\s\[[\ ]\]') == -1

    return !is_done && l:priority != "" ? l:priority[1] : 
         \ !is_done && l:priority == "" ? '^' :
         \ is_done && l:priority != "" ? tolower(l:priority[1]) : "~"

    return l:priority != "" ? 
                \ l:priority[1] : match(a:item, '\s*-\s\[[\ ]\]') != -1 ? '@' : '~'
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

        let l:curr_elem = getline(
                    \ l:elem_line, 
                    \ l:elem_line + l:elem_attached_lines)
        let l:sorted_list += l:curr_elem
    endfor

    call setline(l:superitem + 1, l:sorted_list)

    " Cleaning the environment
    unlet s:subitems_tree
    unlet s:attached_lines
endfu

" Returns the indentation level of an item (lineno)
fu! s:indentation_level(lineno)
    return indent(a:lineno) / g:todo_tab_size
endfu

" Checks if the string string contains a todo item
fu! s:contains_item(string)
    let l:item = matchstr(a:string, '    - \[[x\ ]\]')
    return l:item != ""
endfu
" }}}

" Public API {{{

" Init required variables
fu! SetEnv()
    let s:subitems_tree  = {}
    let s:attached_lines = {}
endfu

" Clean the environment
fu! CleanEnv()
    unlet s:subitems_tree
    unlet s:attached_lines
endfu

" Scope to access s:* variables
fu! SScope()
    return s:
endfu

" External accesor to s: scope
fu! SID()
    return maparg('<SID>', 'n')
endfu
nnoremap <SID> <SID>

" }}}

" Commands {{{

command! SortItems call <SID>sort_items()
command! MarkItem  call <SID>mark_item()
command! NewItem call <SID>insert_new_item(line('.'))
command! NewSubItem call <SID>insert_new_subitem(line('.'))

" }}}

" Maps {{{

" Folding maps:
nnore <buffer> <silent> <S-Left> zo
inore <buffer> <silent> <S-Left> <C-O>zo
nnore <buffer> <silent> <S-Right> zc
inore <buffer> <silent> <S-Right> <C-O>zc

" Items maps
nnore <buffer> <silent> <Plug>(fancy-todo-insert-item) :NewItem<cr>
inore <buffer> <silent> <Plug>(fancy-todo-insert-item) :NewItem<cr>
vnore <buffer> <silent> <Plug>(fancy-todo-insert-item) :NewItem<cr>

nnore <buffer> <silent> <Plug>(fancy-todo-insert-subitem) :NewSubItem<cr>
inore <buffer> <silent> <Plug>(fancy-todo-insert-subitem) :NewSubItem<cr>
vnore <buffer> <silent> <Plug>(fancy-todo-insert-subitem) :NewSubItem<cr>

" Marking maps
nnore <buffer> <silent> <Plug>(fancy-todo-mark) :MarkItem<cr>
inore <buffer> <silent> <Plug>(fancy-todo-mark) :MarkItem<cr>
vnore <buffer> <silent> <Plug>(fancy-todo-mark) :MarkItem<cr>

" Sorting maps
nnore <buffer> <silent> <Plug>(fancy-todo-sort) :SortItems<cr>
inore <buffer> <silent> <Plug>(fancy-todo-sort) :SortItems<cr>
vnore <buffer> <silent> <Plug>(fancy-todo-sort) :SortItems<cr>

" User's maps 
" Sorting
if !hasmapto('<Leader>s', 'n')
    nmap <Leader>s <Plug>(fancy-todo-sort)
endif
if !hasmapto('<Leader>s', 'v')
    vmap <Leader>s <Plug>(fancy-todo-sort)
endif
if !hasmapto('<Leader>s', 'i')
    imap <Leader>s <Plug>(fancy-todo-sort)
endif

" Marking
if !hasmapto('<Leader>x', 'n')
    nmap <Leader>x <Plug>(fancy-todo-mark)
endif
if !hasmapto('<Leader>x', 'v')
    vmap <Leader>x <Plug>(fancy-todo-mark)
endif
if !hasmapto('<Leader>x', 'i')
    imap <Leader>x <Plug>(fancy-todo-mark)
endif

" Inserting item
if !hasmapto('<Leader>i', 'n')
    nmap <Leader>i <Plug>(fancy-todo-insert-item)
endif
if !hasmapto('<Leader>i', 'v')
    vmap <Leader>i <Plug>(fancy-todo-insert-item)
endif
if !hasmapto('<Leader>i', 'i')
    imap <Leader>i <Plug>(fancy-todo-insert-item)
endif

" Inserting subitem
if !hasmapto('<Leader>o', 'n')
    nmap <Leader>o <Plug>(fancy-todo-insert-subitem)
endif
if !hasmapto('<Leader>o', 'v')
    vmap <Leader>o <Plug>(fancy-todo-insert-subitem)
endif
if !hasmapto('<Leader>o', 'i')
    imap <Leader>o <Plug>(fancy-todo-insert-subitem)
endif
" }}}
