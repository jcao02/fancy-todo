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

if !exists('g:todo_dummy_item')
    let g:todo_dummy_item = ''
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
            if getline(lnum) =~ '^\s*- \[[x]\].\{-}'
                let l:completed_items += 1
            endif
        endif
    endfor

    return getline(v:foldstart).' ('.l:completed_items.'/'.l:itemsno.')'
endfu
set foldtext=CollapsedItemText()

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
    let l:spaces = ''
    if <SID>contains_item(getline(a:lineno))
        let l:indentation_level = <SID>indentation_level(a:lineno)
        let l:spaces = repeat(' ', l:indentation_level * g:todo_tab_size)
    endif
    put! = l:spaces.'- [ ] ' 
    exe 'normal! A'.g:todo_dummy_item
    :startinsert!
endfu

" Inserts a new subitem for the item in the current line. 
" If there's already a subitem, moves it to the next line
fu! s:insert_new_subitem(item_lineno)
    let l:item = getline(a:item_lineno)
    
    if <SID>contains_item(l:item)
        let l:indentation_level = <SID>indentation_level(a:item_lineno)
        
        " If the max number of nested items is reached, then it will add it in
        " the same level
        if l:indentation_level == g:max_nested_items
            let l:indentation_level -= 1
        endif

        let l:spaces = repeat(' ', (l:indentation_level + 1) * g:todo_tab_size)

        call cursor(a:item_lineno, 1)
        put = l:spaces.'- [ ] '
        exe 'normal! A'.g:todo_dummy_item
        :startinsert!
    else
        echom "There's no item under cursor"
    endif
endfu


" Marks an item and adds the current date an hour 
" Returns the amount of items marked
fu! s:mark_item_as_done(lineno) 

    if !<SID>contains_item(getline(a:lineno))
        echom "There's no item under cursor"
        return
    endif
    let l:date=strftime("%Y-%m-%d %H:%M:%S")
    :call <SID>preserve(':silent! :'.a:lineno.'s/^\(\s*- [-+*]\?\s*\)\[ \]/\1[x]\ on\ '.l:date.'\ |/')

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
    let l:date_regex='on\s\d\{4}-\d\{2}-\d\{2}\s\d\{2}:\d\{2}:\d\{2}\ |'
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
    if match(l:item, '^\s*-\ \[[\ ]\]') == -1 
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

" This function will get the next character of letter
fu! s:get_next_char(letter)
    return nr2char(char2nr(a:letter) + 1)
endfu

fu! s:build_tree()
    call cursor(1,1)
    return <SID>mix_branches('A', search('[\s]*-\ \[[x\ ]\]', 'c'), {}, {})
endfu

fu! s:mix_branches(root, curr, tree, superitem)
    if a:curr == 0
        return [a:tree, a:superitem]
    endif
    let [l:curr, l:tree, l:superitem] = <SID>build_subitems_branch(a:root, 
                                                                \ a:curr, 
                                                                \ a:tree, 
                                                                \ a:superitem)

    if l:curr > line('$')
        return [l:tree, l:superitem]
    endif

    call cursor(l:curr, 1)
    return <SID>mix_branches(<SID>get_next_char(a:root), 
                \ search('[\s]*-\ \[[x\ ]\]', 'c'), l:tree, l:superitem)
endfu

" This function builds a tree branch and returns [current_line, branch]
fu! s:build_subitems_branch(prev, curr, tree, superitem)

    " Base case: EOF or not an item
    if a:curr > line('$') || !<SID>contains_item(getline(a:curr))
        return [a:curr, a:tree, a:superitem]
    endif

    let l:prev_indent = <SID>indentation_level(a:prev) 
    let l:curr_indent = <SID>indentation_level(a:curr) 

    " Direct item descendant or prev is a character > '9'
    if char2nr(a:prev) > 57 || l:prev_indent < l:curr_indent
        if !has_key(a:tree, a:prev)
            let a:tree[a:prev] = []
        endif
        call add(a:tree[a:prev], a:curr)
        let a:superitem[a:curr] = a:prev

    else
        " Same item level or higher item level 
        let l:prev_super = <SID>super(a:prev, 
                    \ l:prev_indent - l:curr_indent, a:superitem)
        call add(a:tree[l:prev_super], a:curr)
        let a:superitem[a:curr] = l:prev_super

    endif

    return <SID>build_subitems_branch(a:curr, a:curr + 1, a:tree, a:superitem)
endfu

" Get the super item at level deepness
fu! s:super(item, deepness, superitem)
    if !has_key(a:superitem, a:item)
        return 0
    endif

    if a:deepness == 0
        return a:superitem[a:item]
    endif
    return <SID>super(a:superitem[a:item], a:deepness - 1, a:superitem)
endfu


" Undone with priority    : Keeps same letter
" Undone without priority : ^ 
" Done with priority      : tolowercase (A -> a)
" Done without priority   : ~
fu! s:get_item_priority(item)
    let l:priority = matchstr(a:item , '([A-Z])$')
    let is_done    = match(a:item, '^\s*-\s\[[\ ]\]') == -1

    return !is_done && l:priority != "" ? char2nr(l:priority[1]) : 
         \ !is_done && l:priority == "" ? char2nr('^') :
         \ is_done && l:priority != "" ? char2nr(tolower(l:priority[1])) : char2nr('~')
endfu



" Comparison for the sort() function
fu! s:todo_item_comparison(i1,i2)
    let l:i1_prior = <SID>get_item_priority(getline(a:i1))
    let l:i2_prior = <SID>get_item_priority(getline(a:i2))
    let l:dnr = char2nr('D')

    "" Taking (D) priority as 'doing' so is better and needs to sort before
    "" but if the item is done, then it is taken as D priority 
    if l:i1_prior == l:dnr && l:i2_prior != l:dnr 
        return -1
    elseif l:i2_prior == l:dnr && l:i1_prior != l:dnr 
        return 1
    else
        return l:i1_prior - l:i2_prior 
    endif
endfu



fu! s:todo_item_block(line)
    let l:block = []

    call add(l:block, getline(a:line))
    let l:curr_indentation = <SID>indentation_level(a:line)

    let l:next = a:line + 1
    while <SID>indentation_level(l:next) > l:curr_indentation
        call add(l:block, getline(l:next))
        let l:next += 1
    endwhile

    return l:block
endfu

fu! s:todo_sort()
    " Save cursor position and last search
    let _s = @/
    let l  = line(".")
    let c  = col(".")

    let [l:tree, l:superitems] = <SID>build_tree()

    " Sort the items

    let l:sorted_items = []
    " In case there are several lists on the file
    for l:super in keys(l:tree)
        " Only take the super items A,B,C,...
        if char2nr(l:super) > 57
            let l:sorted_items += <SID>sort_items(l:tree, l:super, l:superitems)
        endif
    endfor

    " Recover cursor position and last search
    let @/ = _s
    :call cursor(l, c)

    return l:sorted_items 
endfu

" Sorts the items keeping the subitems attached to their superitems
fu! s:sort_items(tree, superitem, superitems) range

    if !has_key(a:tree, a:superitem)
        return []
    endif

    let l:list = copy(a:tree[a:superitem])
    " We iterate over superitem's childrens in order to recur on them
    for l:elem in l:list
        call <SID>sort_items(a:tree, l:elem, a:superitems)
    endfor

    let l:sorted_list  = sort(l:list, 's:todo_item_comparison')
    let l:position     = a:superitem + 1
    let l:sorted_lines = []

    for l:item in l:sorted_list
        let l:sorted_lines += <SID>todo_item_block(l:item)
    endfor

    let l:min_line = min(a:tree[a:superitem])
    call setline(l:min_line, l:sorted_lines)

    return l:sorted_lines
endfu

" Returns the indentation level of an item (lineno)
fu! s:indentation_level(lineno)
    return indent(a:lineno) / g:todo_tab_size
endfu

" Checks if the string string contains a todo item
fu! s:contains_item(string)
    return matchstr(a:string, '^\s*-\ \[[x\ ]\].\{-}') != ""
endfu
" }}}

" Public API {{{

" Scope to access s:* variables
fu! SScope()
    return s:
endfu

" External accesor to s: scope functions
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
inore <buffer> <silent> <Plug>(fancy-todo-insert-item) <Esc>:NewItem<cr>
vnore <buffer> <silent> <Plug>(fancy-todo-insert-item) <Esc>:NewItem<cr>

nnore <buffer> <silent> <Plug>(fancy-todo-insert-subitem) :NewSubItem<cr>
inore <buffer> <silent> <Plug>(fancy-todo-insert-subitem) <Esc>:NewSubItem<cr>
vnore <buffer> <silent> <Plug>(fancy-todo-insert-subitem) <Esc>:NewSubItem<cr>

" Marking maps
nnore <buffer> <silent> <Plug>(fancy-todo-mark) :MarkItem<cr>
inore <buffer> <silent> <Plug>(fancy-todo-mark) <Esc>:MarkItem<cr>
vnore <buffer> <silent> <Plug>(fancy-todo-mark) <Esc>:MarkItem<cr>

" Sorting maps
nnore <buffer> <silent> <Plug>(fancy-todo-sort) :SortItems<cr>
inore <buffer> <silent> <Plug>(fancy-todo-sort) <Esc>:SortItems<cr>
vnore <buffer> <silent> <Plug>(fancy-todo-sort) <Esc>:SortItems<cr>

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
