fu s:decho(msg) abort "{{{1
    if g:quickhl_debug
        echom "[debug] ". a:msg
    endif
endfu

fu s:is_cmdwin() abort "{{{1
    return bufname('%') is# '[Command Line]'
endfu

fu s:exe(cmd) abort "{{{1
    call s:decho("[cmd] " . a:cmd)
    exe a:cmd
endfu
"}}}1

let s:manual = {
\ 'name': 'QuickhlManual\d',
\ 'enabled': 0,
\ 'locked': 0,
\ }

fu s:manual.dump() abort "{{{1
    if !exists("*PP")
        echoerr "need prettyprint.vim"
        return
    endif
    echo PP(self.history)
endfu

fu s:manual.init() abort "{{{1
    let self.colors = self.read_colors(g:quickhl_manual_colors)
    let self.history = range(len(g:quickhl_manual_colors))
    call self.init_highlight()
endfu

fu s:manual.read_colors(list) abort "{{{1
    return map(copy(a:list), '{
    \ "name": "QuickhlManual" . v:key,
    \ "val": v:val,
    \ "pattern": "",
    \ "escaped": 0,
    \ }')
endfu

fu s:manual.init_highlight() abort "{{{1
    for color in self.colors
        exe 'highlight ' . color.name . ' ' . color.val
    endfor
endfu

fu s:manual.set() abort "{{{1
    " call map(copy(self.colors), 'matchadd(v:val.name, v:val.pattern)')
    for color in self.colors
        call matchadd(color.name, color.pattern, 10)
    endfor
endfu

fu s:manual.clear() abort "{{{1
    call map(map(quickhl#our_match(self.name), 'v:val.id'), 'matchdelete(v:val)')
endfu

fu s:manual.reset() abort "{{{1
    call self.init()
    call quickhl#manual#refresh()
endfu

fu s:manual.is_locked() abort "{{{1
    return self.locked
endfu

fu s:manual.refresh() abort "{{{1
    call self.clear()
    if self.locked || ( exists("w:quickhl_manual_lock") && w:quickhl_manual_lock )
        return
    endif
    call self.set()
endfu

fu s:manual.show_colors() abort "{{{1
    for color in self.colors
        call s:exe("highlight " . color.name)
    endfor
endfu

fu s:manual.add(pattern, escaped) abort "{{{1
    let pattern = a:escaped ? a:pattern : quickhl#escape(a:pattern)
    if ( s:manual.index_of(pattern) >= 0 )
        call s:decho("duplicate: " . pattern)
        return
    endif
    call s:decho("new: " . pattern)
    let i = self.next_index()
    let self.colors[i].pattern = pattern
    call add(self.history, i)
endfu

fu s:manual.next_index() abort "{{{1
    " let index = self.index_of('')
    " return ( index != -1 ? index : remove(self.history, 0) )
    return remove(self.history, 0)
endfu

fu s:manual.index_of(pattern) abort "{{{1
    for n in range(len(self.colors))
        if self.colors[n].pattern is# a:pattern
            return n
        endif
    endfor
    return -1
endfu

fu s:manual.del(pattern, escaped) abort "{{{1
    let pattern = a:escaped ? a:pattern : quickhl#escape(a:pattern)

    let index = self.index_of(pattern)
    call s:decho("[del ]: " . index)
    if index == -1
        call s:decho("Can't find for '" . pattern . "'" )
        return
    endif
    call self.del_by_index(index)
endfu

fu s:manual.del_by_index(idx) abort "{{{1
    if a:idx >= len(self.colors) | return | endif
    let self.colors[a:idx].pattern = ''
    call remove(self.history, index(self.history, a:idx))
    call insert(self.history, a:idx, 0 )
endfu

fu s:manual.list() abort "{{{1
    for idx in range(len(self.colors))
        let color = self.colors[idx]
        exe "echohl " . color.name
        echo printf("%2d: ", idx) . color.pattern
        echohl None
    endfor
endfu
" }}}1

fu quickhl#manual#this(mode) abort "{{{1
    if !s:manual.enabled | call quickhl#manual#enable() | endif
    let pattern =
    \ a:mode == 'n' ? expand('<cword>') :
    \ a:mode == 'v' ? quickhl#get_selected_text() :
    \ ""
    if pattern == '' | return | endif
    " call s:decho("[toggle] " . pattern)
    call quickhl#manual#add_or_del(pattern, 0)
endfu

fu quickhl#manual#this_whole_word() abort "{{{1
    if !s:manual.enabled | call quickhl#manual#enable() | endif
    let pattern = expand('<cword>')
    call quickhl#manual#add_or_del('\<'..quickhl#escape(pattern)..'\>', 1)
endfu

fu quickhl#manual#clear_this(mode) abort "{{{1
    if !s:manual.enabled | call quickhl#manual#enable() | endif
    let pattern =
        \ a:mode is# 'n' ? expand('<cword>') :
        \ a:mode is# 'v' ? quickhl#get_selected_text() :
        \ ''
    if pattern is# '' | return | endif
    let pattern_et = quickhl#escape(pattern)
    let pattern_ew = '\<'..quickhl#escape(pattern)..'\>'
    if s:manual.index_of(pattern_et) != -1
        call s:manual.del(pattern_et, 1)
    elseif s:manual.index_of(pattern_ew) != -1
        call s:manual.del(pattern_ew, 1)
    endif
    call quickhl#manual#refresh()
endfunction

fu quickhl#manual#add_or_del(pattern, escaped) abort "{{{1
    if !s:manual.enabled | call quickhl#manual#enable() | endif

    if s:manual.index_of(a:escaped ? a:pattern : quickhl#escape(a:pattern)) == -1
        call s:manual.add(a:pattern, a:escaped)
    else
        call s:manual.del(a:pattern, a:escaped)
    endif
    call quickhl#manual#refresh()
endfu

fu quickhl#manual#reset() abort "{{{1
    call s:manual.reset()
    call quickhl#manual#refresh()
endfu

fu quickhl#manual#list() abort "{{{1
    call s:manual.list()
endfu

fu quickhl#manual#lock_window() abort "{{{1
    let w:quickhl_manual_lock = 1
    call s:manual.clear()
endfu

fu quickhl#manual#unlock_window() abort "{{{1
    let w:quickhl_manual_lock = 0
    call quickhl#manual#refresh()
endfu

fu quickhl#manual#lock_window_toggle() abort "{{{1
    if !exists("w:quickhl_manual_lock")
        let w:quickhl_manual_lock = 0
    endif
    let w:quickhl_manual_lock = !w:quickhl_manual_lock
    call s:manual.refresh()
endfu

fu quickhl#manual#lock() abort "{{{1
    let s:manual.locked = 1
    call quickhl#manual#refresh()
endfu

fu quickhl#manual#unlock() abort "{{{1
    let s:manual.locked = 0
    call quickhl#manual#refresh()
endfu

fu quickhl#manual#lock_toggle() abort "{{{1
    let s:manual.locked = !s:manual.locked
    echo s:manual.locked ? '[quickhl] Locked' : '[quickhl] Unlocked'
    call quickhl#manual#refresh()
endfu

fu quickhl#manual#add(pattern, escaped) abort "{{{1
    if !s:manual.enabled | call quickhl#manual#enable() | endif
    call s:manual.add(a:pattern, a:escaped)
    call quickhl#manual#refresh()
endfu

fu quickhl#manual#del(pattern, escaped) abort "{{{1
    if empty(a:pattern)
        call s:manual.list()
        let index = input("index to delete: ")
        if empty(index) | return | endif
        call s:manual.del_by_index(index)
    else
        call s:manual.del(a:pattern, a:escaped)
    endif
    call quickhl#manual#refresh()
endfu

fu quickhl#manual#colors() abort "{{{1
    call s:manual.show_colors()
endfu

fu quickhl#manual#enable() abort "{{{1
    call s:manual.init()
    let  s:manual.enabled = 1

    augroup QuickhlManual
        au!
        au VimEnter,WinEnter * call quickhl#manual#refresh()
        au! ColorScheme * call quickhl#manual#init_highlight()
    augroup END
    call quickhl#manual#init_highlight()
    call quickhl#manual#refresh()
endfu

fu quickhl#manual#disable() abort "{{{1
    let s:manual.enabled = 0
    augroup QuickhlManual
        au!
    augroup END
    au! QuickhlManual
    call quickhl#manual#reset()
endfu

fu quickhl#manual#refresh() abort "{{{1
    call quickhl#windo(s:manual.refresh, s:manual)
endfu

fu quickhl#manual#status() abort "{{{1
    echo s:manual.enabled
endfu

fu quickhl#manual#init_highlight() abort "{{{1
    call s:manual.init_highlight()
endfu

fu quickhl#manual#this_motion(type) abort "{{{1
    let cb_save  = &cb
    let sel_save = &sel

    try
        let lnum_beg = line("'[")
        let lnum_end = line("']")
        for n in range(lnum_beg, lnum_end)
            let _s = getline(n)
            let s = {
            \  'all':     _s,
            \  'between': _s[col("'[")-1 : col("']")-1],
            \  'pos2end': _s[col("'[")-1 : -1],
            \  'beg2pos': _s[ : col("']")-1],
            \  }

            if a:type is# 'char'
                let str =
                \ lnum_beg == lnum_end ? s.between :
                \ n        == lnum_beg ? s.pos2end :
                \ n        == lnum_end ? s.beg2pos :
                \                        s.all
            elseif a:type is# 'line'  | let str = s.all
            elseif a:type is# 'block' | let str = s.between
            endif

            call quickhl#manual#add_or_del(str, 0)
        endfor
    catch
        return lg#catch_error()
    finally
        let &cb  = cb_save
        let &sel = sel_save
    endtry
endfu

call s:manual.init()
