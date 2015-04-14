runtime! ftplugin/todo.vim 


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
        put! = '    - [ ]'
    end

    it 'should tag an item with priority X, by adding (X) at the end of the item'

        call PrioritizeItem(1, 'A')

        Expect getline(1) == '    - [ ] (A)'
    end

    it 'should change the priority of the current item if it already has one'
        normal! 1Gdd

        put! = '    - [ ] Item description (A)'
        call PrioritizeItem(1, 'B')
        Expect getline(1) == '    - [ ] Item description (B)'
    end
end
