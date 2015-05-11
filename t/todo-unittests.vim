runtime! ftplugin/todo.vim 

let g:marked_item_regex = '\s*-\ \[[x]\]\ on\ \d\{4}-\d\{2}-\d\{2}\ \d\{2}:\d\{2}:\d\{2}\ |'

" Function to inkove a private function
fu! InvokePrivate(function, arguments)
    return call(substitute(a:function, '^s:', SID(), ''), a:arguments)
endfu


describe 'auxiliar functions'
    before 
        new
        put! = '    - [ ]'  
    end

    after 
        close!
    end

    it 'should return 1 as indentation level'
        Expect InvokePrivate('s:indentation_level', [1]) == 1
    end

    it 'should return 2 as indentation level'
        normal! dd
        put! = '        - [ ]'  
        Expect InvokePrivate('s:indentation_level', [1]) == 2
    end

    it 'should return 3 as indentation level'
        normal! dd
        put! = '            - [ ]'  
        Expect InvokePrivate('s:indentation_level', [1]) == 3
    end

    it 'should detect an item in the line 1'
        Expect InvokePrivate('s:contains_item', [getline(1)]) == 1
    end

    it 'should not detect an item in the line 1'
        normal dd
        put! = 'noitem'
        Expect InvokePrivate('s:contains_item', [getline(1)]) == 0
    end

    it 'should get the next character according to ascii table'
        Expect InvokePrivate('s:get_next_char', ['A']) == 'B'
    end

    it 'should get the inmediate super item of an item'
        Expect InvokePrivate('s:super', [ 2, 0, { 2 : 1 } ] ) == 1
    end

    it 'should get the 2nd level super item of an item'
        Expect InvokePrivate('s:super', [ 4, 2, { 4 : 3, 3 : 2, 2 : 1 } ] ) == 1
    end

    it 'should downgrade item indentation level'
        call InvokePrivate('s:downgrade_item', [1])
        Expect getline(1) == '        - [ ]'
    end
end

describe 'items insertion'
    before
        new 
        let g:todo_dummy_item = ''
        put! = '- [ ]'  
    end

    after
        close! 
    end

    it 'adds a new item on empty line and inserts dummy phrase as item'
        " Remove the first line
        normal! ggdd 
        let g:todo_dummy_item = 'Item description'
        call InvokePrivate('s:insert_new_item', [1])
        Expect getline(1) == '- [ ] Item description'
    end

    it 'adds a new item on empty line'
        " Remove the first line
        normal! ggdd 
        call InvokePrivate('s:insert_new_item', [1])
        Expect getline(1) == '- [ ] '
        Expect col('.') == 7
        Expect line('.') == 1
    end

    it 'adds an item above an existing item'
        call InvokePrivate('s:insert_new_item', [1])
        Expect getline(2) == '- [ ]'
    end

    it 'adds a subitem to an existing item'
        call InvokePrivate('s:insert_new_subitem', [1])
        Expect getline(1) == '- [ ]'
        Expect getline(2) == '    - [ ] '
    end

    it 'adds a subitem to an existing item reaching max_nested_items and adding a normal item'
        call setline(2, '    - [ ]')
        call setline(3, '        - [ ]')
        call setline(4, '            - [ ]')
        call setline(5, '                - [ ]')
        call InvokePrivate('s:insert_new_subitem', [5])
        Expect getline(6) == '                - [ ] '

    end

    it 'adds an item at the same level that a subitem'
        call InvokePrivate('s:insert_new_subitem', [1])
        call InvokePrivate('s:insert_new_item', [2])

        Expect getline(1) == '- [ ]'
        Expect getline(2) == '    - [ ] '
        Expect getline(3) == '    - [ ] '
    end

    it 'tries to add a subitem in an empty line and echoes a message'
        TODO
    end
end

describe 'marking items'
    before
        new 
        put! = '- [ ]'
    end

    after
        close! 
    end

    it 'marks a item without subitems as done and adds the current date'
        call InvokePrivate('s:mark_item_as_done', [1])
        let l:item = getline(1)
        Expect getline(1) =~ g:marked_item_regex
    end

    it 'marks an item subitem and it does not mark the super item'
        normal 1G
        put = '    - [ ]'
        call InvokePrivate('s:mark_item_as_done', [2])
        Expect getline(1) !~ g:marked_item_regex
        Expect getline(2) =~ g:marked_item_regex
    end

    it 'marks an item with one subitem as done and marks every subitem'
        call InvokePrivate('s:insert_new_subitem', [1])
        call InvokePrivate('s:mark_item_as_done', [1])
        Expect getline(1) =~ g:marked_item_regex
        Expect getline(2) =~ g:marked_item_regex
    end

    it 'marks an item with nested subitems as done and marks every nested subitem'
        "1    - [ ] Item 1
        "2        - [ ] SubItem 1.1
        "3            - [ ] SubSubItem 1.1.1
        "4            - [ ] SubSubItem 1.1.1
        "5        - [ ] SubItem 1.2
        "6            - [ ] SubSubItem 1.2.1

        call InvokePrivate('s:insert_new_subitem', [1])
        call InvokePrivate('s:insert_new_subitem', [1])
        call InvokePrivate('s:insert_new_subitem', [2])
        call InvokePrivate('s:insert_new_subitem', [2])
        call InvokePrivate('s:insert_new_subitem', [5])

        Expect getline(1) == '- [ ]'
        Expect getline(2) == '    - [ ] '
        Expect getline(3) == '        - [ ] '
        Expect getline(4) == '        - [ ] '
        Expect getline(5) == '    - [ ] '
        Expect getline(6) == '        - [ ] '


        call InvokePrivate('s:mark_item_as_done', [1])
        Expect getline(1) =~ g:marked_item_regex
        Expect getline(2) =~ g:marked_item_regex
        Expect getline(3) =~ g:marked_item_regex
        Expect getline(4) =~ g:marked_item_regex
        Expect getline(5) =~ g:marked_item_regex
        Expect getline(6) =~ g:marked_item_regex
    end

    it 'marks an item with nested subitems as done and it wont mark an item on the same level'
        " 1    - [ ] 1
        " 2        - [ ] 1.1
        " 3    - [ ] 2 

        call InvokePrivate('s:insert_new_item', [1])
        call InvokePrivate('s:insert_new_subitem', [1])

        call InvokePrivate('s:mark_item_as_done', [1])
        Expect getline(1) =~ g:marked_item_regex
        Expect getline(2) =~ g:marked_item_regex
        Expect getline(3) !~ g:marked_item_regex
    end

    it 'tries to mark an item in an empty line and echoes a message'
        TODO
    end

    it 'tries to mark an item already marked and echoes a message'
        TODO
    end
end
describe 'unmarking items'
    before
        new
        put! = '    - [x] on 2015-12-12 12:12:12 \| '
    end

    after
        close!
    end

    it 'unmarks a marked item'
        call InvokePrivate('s:mark_item_as_undone', [1])
        Expect getline(1) !~ g:marked_item_regex
    end

    it 'unmarks a marked item and all its subitems'
        "1    - [x] (date time)
        "2        - [x] (date time)
        "3        - [x] (date time)
        "
        put = '        - [x] (2015-12-12 12:12:12)'
        put = '        - [x] (2015-12-12 12:12:12)'
        call InvokePrivate('s:mark_item_as_undone', [1])
        Expect getline(1) !~ g:marked_item_regex
        Expect getline(2) !~ g:marked_item_regex
        Expect getline(3) !~ g:marked_item_regex
    end

    it 'unmarks a marked items and all its subitems, but no the marked item on the same level'
        "1    - [x] (date time)
        "2        - [x] (date time)
        "3        - [x] (date time)
        "4    - [x] (date time)
        
        put = '        - [x] on 2015-12-12 12:12:12 \| '
        put = '        - [x] on 2015-12-12 12:12:12 \| '
        put = '    - [x] on 2015-12-12 12:12:12 \| '


        call InvokePrivate('s:mark_item_as_undone', [1])
        Expect getline(1) !~ g:marked_item_regex
        Expect getline(2) !~ g:marked_item_regex
        Expect getline(3) !~ g:marked_item_regex
        Expect getline(4) =~ g:marked_item_regex
    end

    it 'tries to mark an item in an empty line and echoes a message'
        TODO
    end

    it 'tries to mark an item already marked and echoes a message'
        TODO
    end
end

describe 'tagging items'

    before
        new
        put! = '    - [ ]'
    end

    after 
        close!
    end

    it 'should tag an item with priority X, by adding (X) at the end of the item'
        call InvokePrivate('s:prioritize_item', [1, 'A'])
        Expect getline(1) == '    - [ ] (A)'
    end

    it 'should change the priority of the current item if it already has one'
        call setline(1, '    - [ ] Item description (A)')
        call InvokePrivate('s:prioritize_item', [1, 'B'])
        Expect getline(1) == '    - [ ] Item description (B)'
    end

    it 'should increase the item priority'
        call setline(1, '    - [ ] (B)')
        call InvokePrivate('s:increase_item_priority', [1])
        Expect getline(1) == '    - [ ] (A)'
    end

    it 'should decrease the item priority'
        call setline(1, '    - [ ] (A)')
        call InvokePrivate('s:decrease_item_priority', [1])
        Expect getline(1) == '    - [ ] (B)'
    end
end

describe 'sorting items'

    before
        new
    end

   after
       close!
   end

    it 'should build the subitems tree having A -> 1, 1 -> 2 without no-item lines'
        " 1 - [ ]
        " 2     - [ ]

        call setline(1, '- [ ]')
        call setline(2, '    - [ ]')

        let [l:line, l:tree, l:superitem] = InvokePrivate('s:build_subitems_branch', ['A', 1, {}, {}])
        Expect l:line == 3
        Expect l:tree == { 'A' : [1], 1 : [2] }
    end

    it 'should build the subitems tree having A -> 1, 1 -> 2 with no-item lines'
        " 1 - [ ]
        " 2     - [ ]
        " 3 # Comment
        " 4 - [ ]

        call setline(1, '- [ ]')
        call setline(2, '    - [ ]')
        call setline(3, '# Comment')
        call setline(4, '- [ ]')

        let [l:line, l:tree, l:superitem] = InvokePrivate('s:build_subitems_branch', ['A', 1, {}, {}])
        Expect l:line == 3
        Expect l:tree == { 'A' : [1], 1 : [2] }

        let [l:line, l:tree, l:superitem] = InvokePrivate('s:build_subitems_branch', ['A', 4, {}, {}])
        Expect l:line == 5
        Expect l:tree == { 'A' : [4] }
    end

    it 'should build the subitems tree having A -> 1, 1 -> [2,6], 2 -> [3,4], 4 -> 5 with no-item lines'
        " 1 - [ ]
        " 2     - [ ]
        " 3         - [ ]
        " 4         - [ ]
        " 5             - [ ]
        " 6     - [ ]
        " 7 # Comment
        " 8 - [ ]

        call setline(1, '- [ ]')
        call setline(2, '    - [ ]')
        call setline(3, '        - [ ]')
        call setline(4, '        - [ ]')
        call setline(5, '            - [ ]')
        call setline(6, '    - [ ]')
        call setline(7, ' # Comment')
        call setline(8, '- [ ]')

        let [l:line, l:tree, l:superitem] = InvokePrivate('s:build_subitems_branch', ['A', 1, {}, {}])
        Expect l:line == 7
        Expect l:tree == { 'A' : [1], 1 : [2,6], 2 : [3,4], 4 : [5] }
    end

    it 'should build the subitems tree having A -> 1, 1 -> [2,6], 2 -> [3,4], 4 -> 5, B -> 8 with no-item lines'
        " 1 # Comment
        " 2 - [ ]
        " 3     - [ ]
        " 4         - [ ]
        " 5         - [ ]
        " 6             - [ ]
        " 7     - [ ]
        " 8 # Comment
        " 9 - [ ]

        call setline(1, ' # Comment ')
        call setline(2, '- [ ]')
        call setline(3, '    - [ ]')
        call setline(4, '        - [ ]')
        call setline(5, '        - [ ]')
        call setline(6, '            - [ ]')
        call setline(7, '    - [ ]')
        call setline(8, ' # Comment')
        call setline(9, '- [ ]')

        let [l:tree, l:superitem] = InvokePrivate('s:build_tree', [])
        Expect l:tree == { 'A' : [2], 2 : [3,7], 3 : [4,5], 5 : [6], 'B' : [9] }
    end


    it 'should get priorty from A to Z, done or undone'

        let l:item_priority = InvokePrivate('s:get_item_priority', ['- [ ] Item 1'])
        Expect l:item_priority == char2nr('^')

        let l:item_priority = InvokePrivate('s:get_item_priority', ['- [ ] Item 1 (A)'])
        Expect l:item_priority == char2nr('A')

        let l:item_priority = InvokePrivate('s:get_item_priority', ['- [x] Item 1'])
        Expect l:item_priority == char2nr('~')

        let l:item_priority = InvokePrivate('s:get_item_priority', ['- [x] Item 1 (A)'])
        Expect l:item_priority == char2nr('a')
    end

    it 'should say that done is greater than undone priority'
        call setline(1, '- [ ]')
        call setline(2, '- [x]')
        Expect InvokePrivate('s:todo_item_comparison', [ 1, 2 ]) < 0
    end

    it 'should say that B is greater than A priority'
        call setline(1, '- [ ] (A)')
        call setline(2, '- [ ] (B)')
        Expect InvokePrivate('s:todo_item_comparison', [ 1, 2 ]) < 0
    end

    it 'should say that A is greater than B priority due the A status'
        call setline(1, '- [x] (A)')
        call setline(2, '- [ ] (B)')
        Expect InvokePrivate('s:todo_item_comparison', [ 1, 2 ]) > 0 
    end

    it 'should get the subitem in a list'
        call setline(1, '- [ ] Item1')
        call setline(2, '    - [ ] Item1.1')
        Expect InvokePrivate('s:todo_item_block', [ 1 ]) == getline(1,2)
    end

    it 'should get the subitem tree in a list'
        call setline(1, '- [ ] Item1')
        call setline(2, '    - [ ] Item1.1')
        call setline(3, '    - [ ] Item1.2')
        call setline(4, '        - [ ] Item1.2.1')
        call setline(5, '    - [ ] Item1.3')
        Expect InvokePrivate('s:todo_item_block', [ 1 ]) == getline(1,5)
    end

    it 'should sort a 2-item list'
        "1 - [ ] Item1 (B) -> 1 - [ ] Item1 (A)
        "2 - [ ] Item2 (A) -> 2 - [ ] Item2 (B)
        call setline(1, '- [ ] Item1 (B)')
        call setline(2, '- [ ] Item2 (A)')

        call cursor(1,1)
        call InvokePrivate('s:todo_sort', [])

        Expect getline(1) == '- [ ] Item2 (A)' 
        Expect getline(2) == '- [ ] Item1 (B)' 
    end

    it 'should sort subitems list'
        "1 - [ ] Item1 (B)     -> 1 - [ ] Item1 (B)
        "2     - [ ] Item2 (B) -> 2     - [ ] Item3 (A)
        "3     - [ ] Item3 (A) -> 3     - [ ] Item2 (B)

        call setline(1, '- [ ] Item1 (B)')
        call setline(2, '    - [ ] Item2 (B)')
        call setline(3, '    - [ ] Item3 (A)')

        call cursor(1,1)
        call InvokePrivate('s:todo_sort', [])

        Expect getline(1) == '- [ ] Item1 (B)' 
        Expect getline(2) == '    - [ ] Item3 (A)' 
        Expect getline(3) == '    - [ ] Item2 (B)' 
    end

    it 'should sort superitem and subitem lists'
        "1 - [ ] Item1 (B)     -> 1 - [ ] Item4 (A)
        "2     - [ ] Item2 (B) -> 2 - [ ] Item1 (B)
        "3     - [ ] Item3 (A) -> 3     - [ ] Item2 (B)
        "4 - [ ] Item4 (A)     -> 4     - [ ] Item3 (A)

        call setline(1, '- [ ] Item1 (B)')
        call setline(2, '    - [ ] Item2 (B)')
        call setline(3, '    - [ ] Item3 (A)')
        call setline(4, '- [ ] Item4 (A)')

        call cursor(1,1)
        call InvokePrivate('s:todo_sort', [])

        Expect getline(1) == '- [ ] Item4 (A)' 
        Expect getline(2) == '- [ ] Item1 (B)' 
        Expect getline(3) == '    - [ ] Item3 (A)' 
        Expect getline(4) == '    - [ ] Item2 (B)' 
    end

    it 'should recursively sort lines'
        "1 - [ ] Item1 (B)         
        "2     - [ ] Item2 (B)     
        "3         - [ ] Item3 (B) 
        "4     - [ ] Item4 (A)     
        "5 - [ ] Item5 (A)         
        "6     - [ ] Item6 (B)     
        "7     - [ ] Item7 (C) 
        "8     - [ ] Item8 (A)     
        
        call setline(1, '- [ ] Item1 (B)')
        call setline(2, '    - [ ] Item2 (B)')
        call setline(3, '        - [ ] Item3 (B)')
        call setline(4, '    - [ ] Item4 (A)')
        call setline(5, '- [ ] Item5 (A)')
        call setline(6, '    - [ ] Item6 (B)')
        call setline(7, '    - [ ] Item7 (C)')
        call setline(8, '    - [ ] Item8 (A)')

        call cursor(1,1)
        call InvokePrivate('s:todo_sort', [])

        Expect getline(1) == '- [ ] Item5 (A)'
        Expect getline(2) == '    - [ ] Item8 (A)'
        Expect getline(3) == '    - [ ] Item6 (B)'
        Expect getline(4) == '    - [ ] Item7 (C)'
        Expect getline(5) == '- [ ] Item1 (B)'
        Expect getline(6) == '    - [ ] Item4 (A)'
        Expect getline(7) == '    - [ ] Item2 (B)'
        Expect getline(8) == '        - [ ] Item3 (B)'
    end

    it 'should sort a simple list without priority keeping completed items at the end'
        "1    - [x] (date time)   -> - [ ] Item 2
        "2    - [ ] Item 1        -> - [ ] Item 4
        "3    - [x] (date time)   -> - [x] Item 1
        "4    - [ ]               -> - [x] Item 3
        
        call setline(1, '    - [x] Item 1 (2015-12-12 12:12:12)')
        call setline(2, '    - [ ] Item 2')
        call setline(3, '    - [x] Item 3 (2015-12-12 12:12:12)')
        call setline(4, '    - [ ] Item 4')

        call cursor(1,1)
        call InvokePrivate('s:todo_sort', [])

        Expect getline(1) == '    - [ ] Item 2'
        Expect getline(2) == '    - [ ] Item 4'
        Expect getline(3) == '    - [x] Item 1 (2015-12-12 12:12:12)'
        Expect getline(4) == '    - [x] Item 3 (2015-12-12 12:12:12)'
    end

    it 'should sort a simple list with priority having status more precedence'
        "1    - [x] Item 1 (date time) (C)  -> - [x] Item 3
        "2    - [ ] Item 2      (B)         -> - [ ] Item 2
        "3    - [x] Item 3 (date time) (A)  -> - [x] Item 1
        "4    - [ ] Item 4      (D)         -> - [ ] Item 4

        call setline(1, '    - [x] Item 1 (2015-12-12 12:12:12)(C)')
        call setline(2, '    - [ ] Item 2                      (B)')
        call setline(3, '    - [x] Item 3 (2015-12-12 12:12:12)(A)')
        call setline(4, '    - [ ] Item 4                      (D)')

        call cursor(1,1)
        call InvokePrivate('s:todo_sort', [])

        Expect getline(1) == '    - [ ] Item 4                      (D)'
        Expect getline(2) == '    - [ ] Item 2                      (B)'
        Expect getline(3) == '    - [x] Item 3 (2015-12-12 12:12:12)(A)'
        Expect getline(4) == '    - [x] Item 1 (2015-12-12 12:12:12)(C)'
    end

    it 'should sort a list in which all super item has priority but subitems dont'
        "1    - [ ] Item 1 (C)     ->     - [ ] Item 3 (A)
        "2        - [ ] Item 1.1   ->         - [ ] Item 3.1
        "3        - [ ] Item 1.2   ->     - [ ] Item 2 (B)
        "4    - [ ] Item 2 (B)     ->         - [ ] Item 2.1
        "5        - [ ] Item 2.1   ->     - [ ] Item 1 (C)
        "6    - [ ] Item 3 (A)     ->         - [ ] Item 1.1
        "7        - [ ] Item 3.1   ->         - [ ] Item 1.2  
        
        call setline(1, '    - [ ] Item 1 (C)')
        call setline(2, '        - [ ] Item 1.1')
        call setline(3, '        - [ ] Item 1.2')
        call setline(4, '    - [ ] Item 2 (B)')
        call setline(5, '        - [ ] Item 2.1')
        call setline(6, '    - [ ] Item 3 (A)')
        call setline(7, '        - [ ] Item 3.1')


        call cursor(1,1)
        call InvokePrivate('s:todo_sort', [])

        Expect getline(1) == '    - [ ] Item 3 (A)'
        Expect getline(2) == '        - [ ] Item 3.1'
        Expect getline(3) == '    - [ ] Item 2 (B)'
        Expect getline(4) == '        - [ ] Item 2.1'
        Expect getline(5) == '    - [ ] Item 1 (C)'
        Expect getline(6) == '        - [ ] Item 1.1'
        Expect getline(7) == '        - [ ] Item 1.2'
    end

    it 'should sort only the items and not the comments'
        call setline(1, '# Comment here')
        call setline(2, '- [ ] SuperItem 1')
        call setline(3, '- [ ] SuperItem 2 (B)')
        call setline(4, '- [ ] SuperItem 3 (A)')

        call cursor(1,1)
        call InvokePrivate('s:todo_sort', [])

        Expect getline(1) == '# Comment here'
        Expect getline(2) == '- [ ] SuperItem 3 (A)'
        Expect getline(3) == '- [ ] SuperItem 2 (B)'
        Expect getline(4) == '- [ ] SuperItem 1'
    end
end
