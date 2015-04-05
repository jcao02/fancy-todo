" File:          fancy-todo.vim
" Author:        Juan Carlos Arocha
" Description:   Syntax highlight for .todo files


if exists("b:current_syntax")
    finish
endif

" Priorities
syn match ItemPriorA '.\+([A])$' contains=ItemDate,ItemCheckBox,ItemFileName 
syn match ItemPriorB '.\+([B])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorC '.\+([C])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorD '.\+([D])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorE '.\+([E])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorF '.\+([F])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorG '.\+([G])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorH '.\+([H])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorI '.\+([I])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorJ '.\+([J])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorK '.\+([K])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorL '.\+([L])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorM '.\+([M])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorN '.\+([N])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorO '.\+([O])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorP '.\+([P])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorQ '.\+([Q])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorR '.\+([R])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorS '.\+([S])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorT '.\+([T])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorU '.\+([U])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorV '.\+([V])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorW '.\+([W])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorX '.\+([X])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorY '.\+([Y])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorZ '.\+([Z])$' contains=ItemDate,ItemCheckBox,ItemFileName

syn match ItemDate '(\d\{4}-\d\{2}-\d\{2}\s\d\{2}:\d\{2}:\d\{2})' contains=NONE
syn match ItemCheckBox '\s*\[x\ \]' contains=NONE
syn match ItemDone '\s*\[x\].\+$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemFileName '(\w\+[./]*\w\+:\d\+)' contains=NONE

syn match TodoComment '#.\+$' contains=ALL

let b:current_syntax = "todo"

hi def link ItemCheckBox Statement
hi def link ItemFileName Special 
hi def link ItemDate Identifier
hi def link ItemDone Comment

hi def link TodoComment Comment
" We only define 3 priorities colors
hi def link ItemPriorA Constant
hi def link ItemPriorB PreProc
hi def link ItemPriorC Keyword


