runtime! ftplugin/todo.vim 

fu! InvokePrivate(function, arguments)
    echo call(substitute(a:function, '^s:', SID(), ''), a:arguments)
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
        Expect IndentationLevel(getline(1), 4) == 1
    end

    it 'should return 2 as indentation level'
        normal! dd
        put! = '        - [ ]'  
        Expect IndentationLevel(getline(1), 4) == 2
    end

    it 'should return 3 as indentation level'
        normal! dd
        put! = '            - [ ]'  
        Expect IndentationLevel(getline(1), 4) == 3
    end

    it 'should detect an item in the line 1'
        Expect ContainsItem(getline(1)) == 1
    end

    it 'should not detect an item in the line 1'
        normal dd
        put! = 'noitem'
        Expect ContainsItem(getline(1)) == 0
    end
end

describe 'items insertion'
    before
        new 
        put! = '    - [ ]'  
    end

    after
        close! 
    end

    it 'adds a new item on empty line'
        normal! dd " Remove the first line
        call InsertItem(1)
        Expect getline(1) == '    - [ ]'
    end

    it 'adds an item above an existing item'
        call InsertItem(1)
        Expect getline(2) == '    - [ ]'
    end

    it 'adds a subitem to an existing item'
        call InsertSubItem(1)
        Expect getline(1) == '    - [ ]'
        Expect getline(2) == '        - [ ]'

    end

    it 'adds an item at the same level that a subitem'
        call InsertSubItem(1)
        call InsertItem(2)

        Expect getline(2) == '        - [ ]'
        Expect getline(3) == '        - [ ]'
    end

    it 'tries to add a subitem in an empty line and echoes a message'
        TODO
    end
end

describe 'marking items'
    before
        new 
        put! = '    - [ ]'
    end

    after
        close! 
    end

    it 'marks a item without subitems as done and adds the current date'
        call MarkItemAsDone(1)
        let l:item = getline(1)
        Expect getline(1) =~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
    end

    it 'marks an item subitem and it does not mark the super item'
        normal 1G
        put = '        - [ ]'
        call MarkItemAsDone(2)
        Expect getline(1) !~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(2) =~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
    end

    it 'marks an item with one subitem as done and marks every subitem'
        call InsertSubItem(1)
        call MarkItemAsDone(1)
        Expect getline(1) =~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(2) =~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
    end

    it 'marks an item with nested subitems as done and marks every nested subitem'
        "1    - [ ] Item 1
        "2        - [ ] SubItem 1.1
        "3            - [ ] SubSubItem 1.1.1
        "4            - [ ] SubSubItem 1.1.1
        "5        - [ ] SubItem 1.2
        "6            - [ ] SubSubItem 1.2.1

        call InsertSubItem(1)
        call InsertSubItem(1)
        call InsertSubItem(2)
        call InsertSubItem(2)
        call InsertSubItem(5)

        Expect getline(1) == '    - [ ]'
        Expect getline(2) == '        - [ ]'
        Expect getline(3) == '            - [ ]'
        Expect getline(4) == '            - [ ]'
        Expect getline(5) == '        - [ ]'
        Expect getline(6) == '            - [ ]'


        call MarkItemAsDone(1)
        Expect getline(1) =~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(2) =~ '        - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(3) =~ '            - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(4) =~ '            - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(5) =~ '        - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(6) =~ '            - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
    end

    it 'marks an item with nested subitems as done and it wont mark an item on the same level'
        " 1    - [ ] 1
        " 2        - [ ] 1.1
        " 3    - [ ] 2 

        call InsertItem(1)
        call InsertSubItem(1)

        call MarkItemAsDone(1)
        Expect getline(1) =~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(2) =~ '        - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(3) !~ '            - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
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
        put! = '    - [x] (2015-12-12 12:12:12)'
    end

    after
        close!
    end

    it 'unmarks a marked item'
        call MarkItemAsUndone(1)
        Expect getline(1) !~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
    end

    it 'unmarks a marked item and all its subitems'
        "1    - [x] (date time)
        "2        - [x] (date time)
        "3        - [x] (date time)
        "
        put = '        - [x] (2015-12-12 12:12:12)'
        put = '        - [x] (2015-12-12 12:12:12)'
        call MarkItemAsUndone(1)
        Expect getline(1) !~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(2) !~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(3) !~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
    end

    it 'unmarks a marked items and all its subitems, but no the marked item on the same level'
        "1    - [x] (date time)
        "2        - [x] (date time)
        "3        - [x] (date time)
        "4    - [x] (date time)
        
        put = '        - [x] (2015-12-12 12:12:12)'
        put = '        - [x] (2015-12-12 12:12:12)'
        put = '    - [x] (2015-12-12 12:12:12)'


        call MarkItemAsUndone(1)
        Expect getline(1) !~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(2) !~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(3) !~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
        Expect getline(4) =~ '    - \[[x]\] (\d\{4}-\d\{2}-\d\{2} \d\{2}:\d\{2}:\d\{2})'
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
        call PrioritizeItem(1, 'A')
        Expect getline(1) == '    - [ ] (A)'
    end

    it 'should change the priority of the current item if it already has one'
        call setline(1, '    - [ ] Item description (A)')
        call PrioritizeItem(1, 'B')
        Expect getline(1) == '    - [ ] Item description (B)'
    end

    it 'should increase the item priority'
        call setline(1, '    - [ ] (B)')
        call IncreaseItemPriority(1)
        Expect getline(1) == '    - [ ] (A)'
    end

    it 'should decrease the item priority'
        call setline(1, '    - [ ] (A)')
        call DecreaseItemPriority(1)
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

    it 'should build the subitems tree having 1 -> 1, 2 -> 0'
        " 1    - [ ]
        " 2        - [ ]

        call setline(1, '    - [ ]')
        call setline(2, '        - [ ]')
        let [l:subitems, l:attached_lines] = BuildSubItemTree()

        Expect get(l:subitems, 0, []) == [1]
        Expect get(l:subitems, 1, []) == [2]
        Expect get(l:subitems, 2, []) == []

        Expect get(l:attached_lines, 0, -1) == 2
        Expect get(l:attached_lines, 1, -1) == 1
        Expect get(l:attached_lines, 2, -1) == 0
    end


    it 'should build the subitems tree storing line -> number_of_subitems'
        "1    - [ ]
        "2        - [ ]
        "3        - [ ]
        "4            - [ ]
        "5            - [ ]
        "6                - [ ]
        "7                - [ ]
        "8            - [ ]
        "9        - [ ]

        call setline(1, '    - [ ]')
        call setline(2, '        - [ ]')
        call setline(3, '        - [ ]')
        call setline(4, '            - [ ]')
        call setline(5, '            - [ ]')
        call setline(6, '                - [ ]')
        call setline(7, '                - [ ]')
        call setline(8, '            - [ ]')
        call setline(9, '        - [ ]')
        let [l:subitems, l:attached_lines] = BuildSubItemTree()

        Expect get(l:subitems, 0, []) == [1]
        Expect get(l:subitems, 1, []) == [2,3,9]
        Expect get(l:subitems, 2, []) == []
        Expect get(l:subitems, 3, []) == [4,5,8]
        Expect get(l:subitems, 4, []) == []
        Expect get(l:subitems, 5, []) == [6,7]
        Expect get(l:subitems, 6, []) == []
        Expect get(l:subitems, 7, []) == []
        Expect get(l:subitems, 8, []) == []
        Expect get(l:subitems, 9, []) == []

        Expect get(l:attached_lines, 0, -1) == 9
        Expect get(l:attached_lines, 1, -1) == 8
        Expect get(l:attached_lines, 2, -1) == 0
        Expect get(l:attached_lines, 3, -1) == 5
        Expect get(l:attached_lines, 4, -1) == 0
        Expect get(l:attached_lines, 5, -1) == 2
        Expect get(l:attached_lines, 6, -1) == 0
        Expect get(l:attached_lines, 7, -1) == 0
        Expect get(l:attached_lines, 8, -1) == 0
        Expect get(l:attached_lines, 9, -1) == 0
    end

    it 'should get priorty from A to Z, done or undone'

        let l:item_priority = GetItemPriority('    - [ ] Item 1')
        Expect l:item_priority == '@'

        let l:item_priority = GetItemPriority('    - [x] Item 1')
        Expect l:item_priority == '~'

        let l:item_priority = GetItemPriority('    - [x] Item 1 (A)')
        Expect l:item_priority == "A"
    end

    it 'should say that done is greater than undone priority'
        Expect ItemComparison(['    - [ ]', 1],['    - [x]', 2]) ==  -1
    end

    it 'should say that B is greater than A priority'
        Expect ItemComparison(['    - [ ] (A)', 1],['    - [x] (B)', 2]) ==  -1
    end
    it 'should sort the list of pairs [line text, line number] by priority'
        "1    - [x] (date time)         -> - [ ] Item 2
        "2    - [ ] Item 2              -> - [ ] Item 4
        "3    - [x] Item 3(date time)   -> - [x] Item 1
        "4    - [ ] Item 4              -> - [x] Item 3
        
        call setline(1, '    - [x] Item 1 (2015-12-12 12:12:12)')
        call setline(2, '    - [ ] Item 2')
        call setline(3, '    - [x] Item 3 (2015-12-12 12:12:12)')
        call setline(4, '    - [ ] Item 4')

        let l:list = [ 1, 2, 3, 4 ]

        call map(l:list, '[getline(v:val), v:val]')

        Expect l:list[0] == [ getline(1), 1 ]
        Expect l:list[1] == [ getline(2), 2 ]
        Expect l:list[2] == [ getline(3), 3 ]
        Expect l:list[3] == [ getline(4), 4 ]

        call sort(l:list, 'ItemComparison')
        Expect l:list[0] == [ getline(2), 2 ]
        Expect l:list[1] == [ getline(4), 4 ]
        Expect l:list[2] == [ getline(1), 1 ]
        Expect l:list[3] == [ getline(3), 3 ]

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

        call SortItems()
        Expect getline(1) == '    - [ ] Item 2'
        Expect getline(2) == '    - [ ] Item 4'
        Expect getline(3) == '    - [x] Item 1 (2015-12-12 12:12:12)'
        Expect getline(4) == '    - [x] Item 3 (2015-12-12 12:12:12)'
    end

    it 'should sort a simple list with priority'
        "1    - [x] Item 1 (date time) (C)  -> - [x] Item 3
        "2    - [ ] Item 2      (B)         -> - [ ] Item 2
        "3    - [x] Item 3 (date time) (A)  -> - [x] Item 1
        "4    - [ ] Item 4      (D)         -> - [ ] Item 4

        call setline(1, '    - [x] Item 1 (2015-12-12 12:12:12)(C)')
        call setline(2, '    - [ ] Item 2                      (B)')
        call setline(3, '    - [x] Item 3 (2015-12-12 12:12:12)(A)')
        call setline(4, '    - [ ] Item 4                      (D)')

        call SortItems()
        Expect getline(1) == '    - [x] Item 3 (2015-12-12 12:12:12)(A)'
        Expect getline(2) == '    - [ ] Item 2                      (B)'
        Expect getline(3) == '    - [x] Item 1 (2015-12-12 12:12:12)(C)'
        Expect getline(4) == '    - [ ] Item 4                      (D)'
    end

    it 'should sort an average list with subitems, priority and no priority'
        TODO
    end

end
