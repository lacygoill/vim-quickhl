"=============================================================================
" File: quickhl.vim
" Author: t9md <taqumd@gmail.com>
" WebPage: http://github.com/t9md/vim-quickhl
" License: BSD
" Version: 0.5
"=============================================================================

" GUARD: {{{
"============================================================
" if exists('g:quickhl_dev')
  " unlet! g:loaded_quickhl
" endif

" if !exists('g:quickhl_debug')
  let g:quickhl_debug = 0
" endif

" if exists('g:loaded_quickhl')
  " finish
" endif
let g:loaded_quickhl = 1

let s:old_cpo = &cpo
set cpo&vim

if !hlexists("QuickhlTag")
  highlight QuickhlTag gui=underline cterm=underline term=underline
endif
"}}}

" GlobalVar: {{{
if !exists("g:quickhl_colors")
  let g:quickhl_colors = [
        \ "gui=bold ctermfg=16  ctermbg=153 guifg=#ffffff guibg=#0a7383",
        \ "gui=bold ctermfg=7   ctermbg=1   guibg=#a07040 guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=2   guibg=#4070a0 guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=3   guibg=#40a070 guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=4   guibg=#70a040 guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=5   guibg=#0070e0 guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=6   guibg=#007020 guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=21  guibg=#d4a00d guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=22  guibg=#06287e guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=45  guibg=#5b3674 guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=16  guibg=#4c8f2f guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=50  guibg=#1060a0 guifg=#ffffff",
        \ "gui=bold ctermfg=7   ctermbg=56  guibg=#a0b0c0 guifg=black",
        \ ]
  let g:quickhl_match_color = "term=underline cterm=underline guibg=#293739"
endif

if !exists("g:quickhl_keywords")
  let g:quickhl_keywords = []
endif
"}}}

" Keymap: {{{
nnoremap <silent> <Plug>(quickhl-toggle) :call quickhl#toggle('n')<CR>
vnoremap <silent> <Plug>(quickhl-toggle) :call quickhl#toggle('v')<CR>

nnoremap <silent> <Plug>(quickhl-reset)  :call quickhl#reset()<CR>
vnoremap <silent> <Plug>(quickhl-reset)  :call quickhl#reset()<CR>

nnoremap <silent> <Plug>(quickhl-match) :call quickhl#match("toggle")<CR>
nnoremap <silent> <Plug>(quickhl-match-auto-toggle) :call quickhl#match_auto("toggle")<CR>

nnoremap <silent> <Plug>(quickhl-tag-toggle) :call quickhl#tag_toggle()<CR>
nnoremap <silent> <Plug>(quickhl-tag-on)     :call quickhl#tag_enable()<CR>
nnoremap <silent> <Plug>(quickhl-tag-off)    :call quickhl#tag_disable()<CR>
"}}}

" Command: {{{
command!                QuickhlList           :call quickhl#list()
command!                QuickhlDump           :call quickhl#dump()
command!                QuickhlReset          :call quickhl#reset()
command!                QuickhlColors         :call quickhl#colors()
command!                QuickhlReloadColors   :call quickhl#init_highlight()
command! -bang -nargs=1 QuickhlAdd            :call quickhl#add(<q-args>,<bang>0)
command! -bang -nargs=* QuickhlDel            :call quickhl#del(<q-args>,<bang>0)
command!                QuickhlLock           :call quickhl#lock()
command!                QuickhlUnLock         :call quickhl#unlock()

command! QuickhlMatch       :call quickhl#match("on")
command! QuickhlMatchClear  :call quickhl#match("clear")
command! QuickhlMatchAuto   :call <SID>quickhl_match_auto("on")
command! QuickhlMatchNoAuto :call <SID>quickhl_match_auto("off")
command! QuickhlMatchAutoToggle :call quickhl#match_auto("toggle")

command! QuickhlTagToggle   :call quickhl#tag_toggle()
command! QuickhlTagEnable   :call quickhl#tag_enable()
command! QuickhlTagDisable  :call quickhl#tag_disable()
"}}}

" AutoCmd: {{{
augroup QuickhlHL
  autocmd!
  autocmd VimEnter * call quickhl#refresh()
  autocmd WinEnter * call quickhl#refresh()
  autocmd TabEnter *
        \   if exists(':Tcolorscheme')
        \ |   call quickhl#init_highlight()
        \ | endif
  autocmd! ColorScheme * call quickhl#init_highlight()
augroup END
"}}}

" FINISH: {{{
let &cpo = s:old_cpo
"}}}
" vim: set fdm=marker:
