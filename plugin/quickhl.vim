" Forked from: http://github.com/t9md/vim-quickhl

if exists('g:loaded_quickhl')
    finish
endif
let g:loaded_quickhl = 1

" TODO: We have no way to expand a match.{{{
"
" I.e. we can highlight a line:
"
"     - h _
"
" We can highlight another:
"
"     - h _
"
" But they will be colored differently.
"
" Maybe we could use `- H` as another prefix to add/remove
" a match to/from another.
"}}}
" TODO: We can't highlight a multi-line visual selection:{{{
"
"     foo
"     bar
"     baz
"     qux
"     norf
"
" For the moment, we need to do:
"
"     QuickhlManualAdd! ^foo.*\n\_.\{-}\nnorf.*
"
" Which is not  really correct, because if there are  several matches, they will
" ALL be highlighted; not just the one we selected.
" Also, it could highlight matches where the lines are broken in different ways.
"
" Update: I think  text properties  could fix  this issue  because they  are not
" based on regexes but on positions.
"}}}
" TODO: I don't like the plugin highlighting all buffers.{{{
"
" I would prefer it to affect only the current buffer.
"
" Update: Text properties could fix this issue.
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
" Update: The   location  list   is  unreliable,   because  it   doesn't  follow
" the  text   after  an  edit.   Try   to  use  text  properties   in  Vim,  and
" `nvim_buf_set_extmark()` / `nvim_buf_get_extmark_by_id()` in Nvim.
"}}}
" TODO: Make `-hc` dot repeatable.{{{
"
" It may look like it already is, but it's not.
" Press `-hiw` on 3 different words, then delete a line by pressing `dd`.
" Press `-hc` on a highlighted word, then press dot on another one.
" The highlight on the second word is not removed; instead a line is removed.
"}}}
" TODO: Allow the user to choose the color used for the next highlight.{{{
"
" In mappings, we could use a count.
" For example, if we press `2-h_`, the current line would be highlighted in blue.
" But if we had pressed `3-h_`, the current line would have been highlighted in green.
"}}}

" Settings {{{1

let g:quickhl_debug = 0

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

" highlight:{{{
"
"    - word under cursor
"    - word under cursor, adding boundaries (`\<word\>`)
"    - visual selection
"    - area you {motion}ed or text-object
"    - current line
"}}}
nno <silent><unique> -hg* :<c-u>call quickhl#manual#this('n')<cr>
nno <silent><unique> -h*  :<c-u>call quickhl#manual#this_whole_word()<cr>
xno <silent><unique> -h   :<c-u>call quickhl#manual#this('v')<cr>
nno <silent><unique> -h   :<c-u>set opfunc=quickhl#manual#this_motion<cr>g@
nno <silent><unique> -hh  :<c-u>set opfunc=quickhl#manual#this_motion<bar>exe 'norm! '..v:count1..'g@_'<cr>
" This last feature relies on the 'vim-operator-user' plugin:
" https://github.com/kana/vim-operator-user

" clear all highlights
" clear highlight of the word under the cursor
" clear highlight of the visual selection
nno <silent><unique> -hC :<c-u>call quickhl#manual#reset()<cr>
nno <silent><unique> -hc :<c-u>call quickhl#manual#clear_this('n')<cr>
xno <silent><unique> -H  :<c-u>call quickhl#manual#clear_this('v')<cr>

" toggle global lock
nno <silent><unique> coH :<c-u>call quickhl#manual#lock_toggle()<cr>

nno <silent><unique> -h? :<c-u>call quickhl#show_help()<cr>

" Commands {{{1

com                QuickhlManualEnable  :call quickhl#manual#enable()
com                QuickhlManualDisable :call quickhl#manual#disable()

com                QuickhlManualList    :call quickhl#manual#list()
com                QuickhlManualReset   :call quickhl#manual#reset()
com                QuickhlManualColors  :call quickhl#manual#colors()
com -bang -nargs=1 QuickhlManualAdd     :call quickhl#manual#add(<q-args>,<bang>0)
com -bang -nargs=* QuickhlManualDelete  :call quickhl#manual#del(<q-args>,<bang>0)
com                QuickhlManualLock    :call quickhl#manual#lock()

com QuickhlManualUnlock                 :call quickhl#manual#unlock()
com QuickhlManualLockToggle             :call quickhl#manual#lock_toggle()
com QuickhlManualLockWindow             :call quickhl#manual#lock_window()
com QuickhlManualUnlockWindow           :call quickhl#manual#unlock_window()
com QuickhlManualLockWindowToggle       :call quickhl#manual#lock_window_toggle()

