" File:          fancy-todo.vim
" Author:        Juan Carlos Arocha
" Description:   Syntax highlight for .todo files


if exists("b:current_syntax")
    finish
endif

" Priorities
syn match ItemPriorA '^\s*-\ \[[\ x]\].\{-}([A])$' contains=ItemDate,ItemCheckBox,ItemFileName 
syn match ItemPriorB '^\s*-\ \[[\ x]\].\{-}([B])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorC '^\s*-\ \[[\ x]\].\{-}([C])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorD '^\s*-\ \[[\ x]\].\{-}([D])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorE '^\s*-\ \[[\ x]\].\{-}([E])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorF '^\s*-\ \[[\ x]\].\{-}([F])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorG '^\s*-\ \[[\ x]\].\{-}([G])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorH '^\s*-\ \[[\ x]\].\{-}([H])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorI '^\s*-\ \[[\ x]\].\{-}([I])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorJ '^\s*-\ \[[\ x]\].\{-}([J])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorK '^\s*-\ \[[\ x]\].\{-}([K])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorL '^\s*-\ \[[\ x]\].\{-}([L])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorM '^\s*-\ \[[\ x]\].\{-}([M])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorN '^\s*-\ \[[\ x]\].\{-}([N])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorO '^\s*-\ \[[\ x]\].\{-}([O])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorP '^\s*-\ \[[\ x]\].\{-}([P])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorQ '^\s*-\ \[[\ x]\].\{-}([Q])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorR '^\s*-\ \[[\ x]\].\{-}([R])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorS '^\s*-\ \[[\ x]\].\{-}([S])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorT '^\s*-\ \[[\ x]\].\{-}([T])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorU '^\s*-\ \[[\ x]\].\{-}([U])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorV '^\s*-\ \[[\ x]\].\{-}([V])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorW '^\s*-\ \[[\ x]\].\{-}([W])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorX '^\s*-\ \[[\ x]\].\{-}([X])$' contains=ItemDateItemCheckBox,ItemFileName
syn match ItemPriorY '^\s*-\ \[[\ x]\].\{-}([Y])$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemPriorZ '^\s*-\ \[[\ x]\].\{-}([Z])$' contains=ItemDate,ItemCheckBox,ItemFileName

syn match ItemDate 'on\ \d\{4}-\d\{2}-\d\{2}\s\d\{2}:\d\{2}:\d\{2}\ |' contains=NONE
syn match ItemDone '\s*-\ \[[x]\].\{-}$' contains=ItemDate,ItemCheckBox,ItemFileName
syn match ItemFileName '([a-zA-Z_\-.\/]*:\d\+)' contains=NONE

syn match TodoHeader '#.\+$' contains=ALL

let b:current_syntax = "todo"

hi def link ItemFileName Special 
hi def link ItemDate Identifier
hi def link ItemDone Comment
hi def link ItemFilename Type

hi def link TodoHeader Comment
" We only define 3 priorities colors
hi def link ItemPriorA Constant
hi def link ItemPriorB PreProc
hi def link ItemPriorC Keyword
hi def link ItemPriorD Label
