" Forked from: http://github.com/t9md/vim-quickhl

if exists('g:loaded_quickhl')
    finish
endif
let g:loaded_quickhl = 1

" TODO: Don't highlight *all* the matches.  Just the one under the cursor.
" TODO: Implement a "global" command which would extend the last highlighting to *all* the matches.{{{
"
" In fact, it should toggle between *all* the matches, and the single match under the cursor.
" `M-m M-m` would be a good fit as a mapping.
" But what would we use for highlighting a line?  `M-m _`?  `M-m M`?
"}}}
" TODO: Implement an "undo" command which would undo the last highlighting.
" FIXME: Press `M-m ^` on the first line of a file.
" Sometimes, nothing is highlighted; sometimes the second line is highlighted.

" TODO: We have no way to expand a match.{{{
"
" I.e. we can highlight a line:
"
"     M-m _
"
" We can highlight another:
"
"     M-m _
"
" But they will be colored differently.
"
" Find another prefix to add/remove a match to/from another?
"}}}
" TODO: Add a command to populate the loclist with the positions matching the first character of all the matches.{{{
"
" It would  be handy to jump  from one to another  if they are far  away, and to
" find a subset of matches we want to clear.
"
" Also, try to save the loclists across Vim restarts, and use the location lists
" created by the quickhl plugin to save the matches/highlights.
" Install a command  which would be local  to a location window  and which would
" restore the highlights  (use the context key  of each entry in  the loclist to
" distinguish a match/highlight from another).
" This way, we could restore our highlights even after quitting Vim.
"
" Update: The location  list is unreliable,  because it doesn't follow  the text
" after an edit.  Try to use text properties in Vim.
"}}}
" TODO: Make `<m-m>c` dot repeatable.{{{
"
" It may look like it already is, but it's not.
" Press `<m-m>iw` on 3 different words, then delete a line by pressing `dd`.
" Press `<m-m>c` on a highlighted word, then press dot on another one.
" The highlight on the second word is not removed; instead a line is removed.
"}}}
" TODO: Allow the user to choose the color used for the next highlight.{{{
"
" In mappings, we could use a count.
" For example, if we press `2<m-m>_`, the current line would be highlighted in blue.
" But if we had pressed `3<m-m>_`, the current line would have been highlighted in green.
"}}}

" Settings {{{1

let g:quickhl_manual_colors =<< trim END
    cterm=bold ctermfg=16 ctermbg=153 gui=bold guifg=#ffffff guibg=#0a7383
    cterm=bold ctermfg=7  ctermbg=1   gui=bold guibg=#a07040 guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=2   gui=bold guibg=#4070a0 guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=3   gui=bold guibg=#40a070 guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=4   gui=bold guibg=#70a040 guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=5   gui=bold guibg=#0070e0 guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=6   gui=bold guibg=#007020 guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=21  gui=bold guibg=#d4a00d guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=22  gui=bold guibg=#06287e guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=45  gui=bold guibg=#5b3674 guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=16  gui=bold guibg=#4c8f2f guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=50  gui=bold guibg=#1060a0 guifg=#ffffff
    cterm=bold ctermfg=7  ctermbg=56  gui=bold guibg=#a0b0c0 guifg=black
END

" Mappings {{{1

if has('gui_running') || &t_TI =~# "\e\\[>4;[12]m"
    " highlight:{{{
    "
    "    - word under cursor
    "    - word under cursor, adding boundaries (`\<word\>`)
    "    - visual selection
    "    - text covered by a motion or text-object
    "    - current line
    "}}}
    nno <silent><unique> <m-m>g* :<c-u>call quickhl#word('n')<cr>
    nno <silent><unique> <m-m>* :<c-u>call quickhl#whole_word()<cr>
    xno <silent><unique> <m-m> :<c-u>call quickhl#word('v')<cr>
    nno <expr><unique> <m-m> quickhl#op()
    nno <expr><unique> <m-m><m-m> quickhl#op() .. '_'

    " clear all highlights
    nno <silent><unique> <m-m>C :<c-u>call quickhl#reset()<cr>
    " clear highlight of the word under the cursor
    nno <silent><unique> <m-m>c :<c-u>call quickhl#clear_this('n')<cr>
    " clear highlight of the visual selection
    xno <silent><unique> m<m-m> :<c-u>call quickhl#clear_this('v')<cr>
    " TODO: I don't like this rhs (`m<m-m>`).
    " Besides, it seems the whole mapping is useless.
    " You can press `M-m` on the same visual selection to clear a highlight.
    " What's the point of `#clear_this()` in visual mode?

    " toggle global lock
    nno <silent><unique> co<m-m> :<c-u>call quickhl#lock_toggle()<cr>

    nno <silent><unique> <m-m>? :<c-u>call quickhl#show_help()<cr>
else
    " If you want to change `F24`, you'll need to update `autoload/lg/map.vim`.
    nno <silent><unique> <f24>g* :<c-u>call quickhl#word('n')<cr>
    nno <silent><unique> <f24>* :<c-u>call quickhl#whole_word()<cr>
    xno <silent><unique> <f24> :<c-u>call quickhl#word('v')<cr>
    nno <expr><unique> <f24> quickhl#op()
    nno <expr><unique> <f24><f24> quickhl#op() .. '_'
    nno <silent><unique> <f24>C :<c-u>call quickhl#reset()<cr>
    nno <silent><unique> <f24>c :<c-u>call quickhl#clear_this('n')<cr>
    xno <silent><unique> m<f24> :<c-u>call quickhl#clear_this('v')<cr>
    nno <silent><unique> co<f24> :<c-u>call quickhl#lock_toggle()<cr>
    nno <silent><unique> <f24>? :<c-u>call quickhl#show_help()<cr>
endif

" Commands {{{1

com -bar QuickhlManualEnable call quickhl#enable()
com -bar QuickhlManualDisable call quickhl#disable()

com -bar QuickhlManualList call quickhl#list()
com -bar QuickhlManualReset call quickhl#reset()
com -bar QuickhlManualColors call quickhl#colors()

com -bar -bang -nargs=1 QuickhlManualAdd call quickhl#add(<q-args>,<bang>0)
com -bar -bang -nargs=* QuickhlManualDelete call quickhl#del(<q-args>,<bang>0)
com -bar QuickhlManualLock call quickhl#lock()

com -bar QuickhlManualUnlock call quickhl#unlock()
com -bar QuickhlManualLockToggle call quickhl#lock_toggle()
com -bar QuickhlManualLockWindow call quickhl#lock_window()
com -bar QuickhlManualUnlockWindow call quickhl#unlock_window()
com -bar QuickhlManualLockWindowToggle call quickhl#lock_window_toggle()

