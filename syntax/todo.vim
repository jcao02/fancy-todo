" File:          fancy-todo.vim
" Author:        Juan Carlos Arocha
" Description:   Syntax highlight for .todo files


if exists("b:current_syntax")
    finish
endif

" Priorities
syn match ItemPriorA '.\+([A])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorB '.\+([B])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorC '.\+([C])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorD '.\+([D])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorE '.\+([E])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorF '.\+([F])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorG '.\+([G])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorH '.\+([H])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorI '.\+([I])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorJ '.\+([J])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorK '.\+([K])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorL '.\+([L])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorM '.\+([M])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorN '.\+([N])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorO '.\+([O])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorP '.\+([P])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorQ '.\+([Q])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorR '.\+([R])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorS '.\+([S])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorT '.\+([T])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorU '.\+([U])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorV '.\+([V])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorW '.\+([W])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorX '.\+([X])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorY '.\+([Y])$' contains=ItemDate,ItemCheckBox
syn match ItemPriorZ '.\+([Z])$' contains=ItemDate,ItemCheckBox

syn match ItemDate '(\d\{4}-\d\{2}-\d\{2}\s\d\{2}:\d\{2}:\d\{2})' contains=NONE
syn match ItemCheckBox '\s*\[x\ \]' contains=NONE
syn match ItemDone '\s*\[x\].\+$' contains=ItemDate,ItemCheckBox

syn match TodoComment '#.\+$' contains=ALL

let b:current_syntax = "todo"

hi def link ItemCheckBox Statement
hi def link ItemDate Identifier
hi def link ItemDone Comment
hi def link TodoComment Comment
" We only define 3 priorities colors
hi def link ItemPriorA Constant
hi def link ItemPriorB PreProc
hi def link ItemPriorC Special


