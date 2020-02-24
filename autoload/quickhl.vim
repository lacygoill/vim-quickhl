if exists('g:autoloaded_quickhl')
    finish
endif
let g:autoloaded_quickhl = 1

let s:manual = {
    \ 'name': 'QuickhlManual\d',
    \ 'enabled': 0,
    \ 'locked': 0,
    \ }

fu s:manual.init() abort "{{{1
    let self.colors = self.read_colors(g:quickhl_manual_colors)
    let self.history = range(len(g:quickhl_manual_colors))
    call self.init_highlight()
endfu

fu s:manual.read_colors(list) abort "{{{1
    return map(copy(a:list), {i,v -> {
        \ 'name': 'QuickhlManual'..i,
        \ 'val': v,
        \ 'pat': '',
        \ 'escaped': 0,
        \ }})
endfu

fu s:manual.init_highlight() abort "{{{1
    call map(copy(self.colors), 'execute("hi "..v:val.name.." "..v:val.val)')
endfu

fu s:manual.set() abort "{{{1
    let view = winsaveview()

    for color in self.colors
        " avoid `E35` when @/ is empty
        " TODO: is it the right fix?{{{
        "
        " What about this instead?:
        "
        "     for color in filter(deepcopy(self.colors), {_,v -> v.pat != ''})
        "}}}
        if color.pat is# '' | continue | endif
        call s:highlight(color.pat, color.name)
    endfor
    call winrestview(view)

    augroup quickhl_persist_after_reload
        au!
        au BufReadPost <buffer> call s:manual.refresh()
    augroup END


    "     if !has('nvim')
    "         fu! Func(name, pat) abort
    "             if a:pat is# '' | return | endif
    "             let bufnr = bufnr('%')
    "             sil! call prop_type_add(a:name, {'highlight': a:name, 'bufnr': bufnr})
    "             call cursor(1, 1)
    "             while search(a:pat, 'W')
    "                 let [end_lnum, end_col] = searchpos(a:pat, 'cn')
    "                 call prop_add(line('.'), col('.'), {
    "                     \ 'end_lnum': end_lnum,
    "                     \ 'end_col': end_col,
    "                     \ 'type': a:name,
    "                     \ })
    "             endwhile
    "         endfu
    "         call map(copy(self.colors), {_,v -> Func(v.name, v.pat)})
    "     else
    "         let id = nvim_create_namespace(v.name)
    "         call cursor(1, 1)
    "         while search(v.pat, 'W')
    "             call nvim_buf_add_highlight(0, id, v.name,
    "                 \ line('.')-1, col('.'), searchpos(v.pat, 'cn')[1]-1)
    "         endwhile
    "     endif
endfu

fu s:manual.clear() abort "{{{1
    " TODO: Support Nvim.{{{
    "
    " Make sure  it correctly  removes all highlighting  when there  are several
    " highlighted texts on the same line.
    " A good  test is to highlight  just a space  on a line with  several spaces
    " (`M-m l`); make sure `M-m C` gets rid of all highlighted spaces.
    "}}}
    " TODO: try to get rid of `sil!`; how to check a text property exists?
    " TODO: This clears all highlights.  How about clearing only the highlight under the cursor? (`m-*`, `x_m-`)
    sil! call map(range(len(g:quickhl_manual_colors)),
        \ {_,v -> prop_remove({'type': 'QuickhlManual'..v, 'all': v:true})})
endfu

fu s:manual.reset() abort "{{{1
    call self.init()
    call s:manual.refresh()
endfu

fu s:manual.is_locked() abort "{{{1
    return self.locked
endfu

fu s:manual.refresh() abort "{{{1
    call self.clear()
    if self.locked || ( exists('w:quickhl_manual_lock') && w:quickhl_manual_lock )
        return
    endif
    call self.set()
endfu

fu s:manual.show_colors() abort "{{{1
    call map(copy(self.colors), "execute('hi '..v:val.name, '')")
endfu

fu s:manual.add(pat, escaped) abort "{{{1
    let pat = a:escaped ? a:pat : s:escape(a:pat)
    if  s:manual.index_of(pat) >= 0 | return | endif
    let i = self.next_index()
    let self.colors[i].pat = pat
    call add(self.history, i)
endfu

fu s:manual.next_index() abort "{{{1
    " let index = self.index_of('')
    " return ( index != -1 ? index : remove(self.history, 0) )
    return remove(self.history, 0)
endfu

fu s:manual.index_of(pat) abort "{{{1
    for color in self.colors
        if color.pat is# a:pat
            return index(self.colors, color)
        endif
    endfor
    return -1
endfu

fu s:manual.del(pat, escaped) abort "{{{1
    let pat = a:escaped ? a:pat : s:escape(a:pat)

    let index = self.index_of(pat)
    if index == -1 | return | endif
    call self.del_by_index(index)
endfu

fu s:manual.del_by_index(idx) abort "{{{1
    if a:idx >= len(self.colors) | return | endif
    let self.colors[a:idx].pat = ''
    call remove(self.history, index(self.history, a:idx))
    call insert(self.history, a:idx, 0 )
endfu

fu s:manual.list() abort "{{{1
    for idx in range(len(self.colors))
        let color = self.colors[idx]
        exe 'echohl '..color.name
        echo printf('%2d: ', idx)..color.pat
        echohl None
    endfor
endfu
" }}}1

" Interface {{{1
fu quickhl#word(mode) abort "{{{2
    if !s:manual.enabled | call quickhl#enable() | endif
    let pat =
        \ a:mode == 'n' ? expand('<cword>') :
        \ a:mode == 'v' ? s:get_selected_text() :
        \ ''
    if pat == '' | return | endif
    call s:add_or_del(pat, 0)
endfu

fu quickhl#whole_word() abort "{{{2
    if !s:manual.enabled | call quickhl#enable() | endif
    let pat = expand('<cword>')
    call s:add_or_del('\<'..s:escape(pat)..'\>', 1)
endfu

fu quickhl#clear_this(mode) abort "{{{2
    if !s:manual.enabled | call quickhl#enable() | endif
    let pat =
        \ a:mode is# 'n' ? expand('<cword>') :
        \ a:mode is# 'v' ? s:get_selected_text() :
        \ ''
    if pat is# '' | return | endif
    let pat_et = s:escape(pat)
    let pat_ew = '\<'..s:escape(pat)..'\>'
    if s:manual.index_of(pat_et) != -1
        call s:manual.del(pat_et, 1)
    elseif s:manual.index_of(pat_ew) != -1
        call s:manual.del(pat_ew, 1)
    endif
    call s:manual.refresh()
endfunction

fu quickhl#reset() abort "{{{2
    call s:manual.reset()
endfu

fu quickhl#list() abort "{{{2
    call s:manual.list()
endfu

fu quickhl#lock_window() abort "{{{2
    let w:quickhl_manual_lock = 1
    call s:manual.clear()
endfu

fu quickhl#unlock_window() abort "{{{2
    let w:quickhl_manual_lock = 0
    call s:manual.refresh()
endfu

fu quickhl#lock_window_toggle() abort "{{{2
    if !exists('w:quickhl_manual_lock')
        let w:quickhl_manual_lock = 0
    endif
    let w:quickhl_manual_lock = !w:quickhl_manual_lock
    call s:manual.refresh()
endfu

fu quickhl#lock() abort "{{{2
    let s:manual.locked = 1
    call s:manual.refresh()
endfu

fu quickhl#unlock() abort "{{{2
    let s:manual.locked = 0
    call s:manual.refresh()
endfu

fu quickhl#lock_toggle() abort "{{{2
    let s:manual.locked = !s:manual.locked
    echo s:manual.locked ? '[quickhl] Locked' : '[quickhl] Unlocked'
    call s:manual.refresh()
endfu

fu quickhl#add(pat, escaped) abort "{{{2
    if !s:manual.enabled | call quickhl#enable() | endif
    call s:manual.add(a:pat, a:escaped)
    call s:manual.refresh()
endfu

fu quickhl#del(pat, escaped) abort "{{{2
    if empty(a:pat)
        call s:manual.list()
        let index = input('index to delete: ')
        if empty(index) | return | endif
        call s:manual.del_by_index(index)
    else
        call s:manual.del(a:pat, a:escaped)
    endif
    call s:manual.refresh()
endfu

fu quickhl#colors() abort "{{{2
    call s:manual.show_colors()
endfu

fu quickhl#enable() abort "{{{2
    call s:manual.init()
    let s:manual.enabled = 1

    augroup QuickhlManual
        au!
        " TODO: Why `VimEnter`?
        au VimEnter * call s:manual.refresh()
        au ColorScheme * call s:init_highlight()
    augroup END
    call s:init_highlight()
    call s:manual.refresh()
endfu

fu quickhl#disable() abort "{{{2
    let s:manual.enabled = 0
    augroup QuickhlManual
        au!
    augroup END
    au! QuickhlManual
    call quickhl#reset()
endfu

fu quickhl#op(type) abort "{{{2
    let [cb_save, sel_save] = [&cb, &sel]
    let reg_save = ['"', getreg('"'), getregtype('"')]
    try
        set cb-=unnamed cb-=unnamedplus sel=inclusive
        if a:type is# 'char'
            sil norm! `[v`]y
        elseif a:type is# 'line'
            sil norm! '[V']y
        elseif a:type is# 'block'
            sil exe "norm! `[\<c-v>`]y"
        else
            return
        endif
        " If we operate on a line, don't highlight the first character of the next line.
        let @" = substitute(@", '\n$', '', '')
        call s:add_or_del(@", 0)
    catch
        return lg#catch_error()
    finally
        let [&cb, &sel]  = [cb_save, sel_save]
        call call('setreg', reg_save)
    endtry
endfu

call s:manual.init()
fu quickhl#show_help() abort "{{{2
    " TODO: Include help about Ex commands, and show help in a scratch buffer.
    " Take inspiration from vim-cheat40 for the scratch buffer.
    let help =<< trim END
        M-m *     highlight word under cursor        N
        M-m g*    highlight unbounded word           N
        M-m       highlight motion or text-object    N
        M-m c     clear highlighting under cursor    N
        M-m C     clear all highlighting             N
        co M-m    toggle global lock                 N

        M-m       highlight selection                X
        m M-m     clear highlighting on selection    X
    END
    echo join(help, "\n")
endfu
"}}}1
" Core {{{1
fu s:add_or_del(pat, escaped) abort "{{{2
    if !s:manual.enabled | call quickhl#enable() | endif

    if s:manual.index_of(a:escaped ? a:pat : s:escape(a:pat)) == -1
        call s:manual.add(a:pat, a:escaped)
    else
        call s:manual.del(a:pat, a:escaped)
    endif
    call s:manual.refresh()
endfu

fu s:init_highlight() abort "{{{2
    call s:manual.init_highlight()
endfu

fu s:highlight(pat, name) abort "{{{2
    if has('nvim')
        let id = nvim_create_namespace('quickhl')
        let flags = 'cW'
        while search(a:pat, flags)
            let [lnum, col] = getcurpos()[1:2]
            let [end_lnum, end_col] = searchpos(a:pat..'\zs', 'cn')
            let flags = 'W'
            if a:pat !~# '\\n'
                call nvim_buf_add_highlight(0, id, a:name,
                    \ lnum-1, col-1, searchpos(a:pat..'\zs', 'cn')[1]-1)
            else
                let lines = split(a:pat, '\\n')
                for i in range(len(lines))
                    let col_start = i == 0 ? col-1 : 0
                    let col_end = i == len(lines) - 1 ? end_col : col([lnum+i, '$'])
                    call nvim_buf_add_highlight(0, id, a:name,
                        \ lnum-1+i, col_start, col_end)
                endfor
            endif
        endwhile
    else
        sil! call prop_type_add(a:name, {'highlight': a:name, 'bufnr': bufnr('%')})
        call cursor(1, 1)
        let flags = 'cW'
        while search(a:pat, flags)
            let [lnum, col] = getcurpos()[1:2]
            let [end_lnum, end_col] = searchpos(a:pat..'\zs', 'cn')
            let flags = 'W'
            call prop_add(lnum, col, {
                \ 'end_lnum': end_lnum,
                \ 'end_col': end_col,
                \ 'type': a:name,
                \ })
        endwhile
    endif
endfu
"}}}1
" Util {{{1
fu s:get_selected_text() abort "{{{2
    let [cb_save, sel_save] = [&cb, &sel]
    let reg_save = ['"', getreg('"'), getregtype('"')]
    try
        set cb-=unnamed cb-=unnamedplus sel=inclusive
        sil norm! gvy
        return @"
    catch
        return lg#catch_error()
    finally
        let [&cb, &sel]  = [cb_save, sel_save]
        call call('setreg', reg_save)
    endtry
endfu

fu s:escape(pat) abort "{{{2
    return '\V'..substitute(escape(a:pat, '\'), "\n", '\\n', 'g')
endfu

fu s:is_cmdwin() abort "{{{2
    return bufname('%') is# '[Command Line]'
endfu
"}}}1
