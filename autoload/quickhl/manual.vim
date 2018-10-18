function! s:decho(msg) abort "{{{1
  if g:quickhl_debug
    echom "[debug] ". a:msg
  endif
endfunction

function! s:is_cmdwin() abort "{{{1
  return bufname('%') ==# '[Command Line]'
endfunction

function! s:exe(cmd) abort "{{{1
  call s:decho("[cmd] " . a:cmd)
  exe a:cmd
endfunction

"}}}1

let s:manual = {
      \ 'name': 'QuickhlManual\d',
      \ 'enabled': g:quickhl_manual_enable_at_startup,
      \ 'locked': 0,
      \ }

function! s:manual.dump() abort "{{{1
  if !exists("*PP")
    echoerr "need prettyprint.vim"
    return
  endif
  echo PP(self.history)
endfunction

function! s:manual.init() abort "{{{1
  let self.colors = self.read_colors(g:quickhl_manual_colors)
  let self.history = range(len(g:quickhl_manual_colors))
  call self.init_highlight()
endfunction

function! s:manual.read_colors(list) abort "{{{1
  return map(copy(a:list), '{
        \ "name": "QuickhlManual" . v:key,
        \ "val": v:val,
        \ "pattern": "",
        \ "escaped": 0,
        \ }')
endfunction

function! s:manual.init_highlight() abort "{{{1
  for color in self.colors
    exe 'highlight ' . color.name . ' ' . color.val
  endfor
endfunction

function! s:manual.inject_keywords() abort "{{{1
  call self._inject_keywords( g:quickhl_manual_keywords )
endfunction

function! s:manual._inject_keywords(keywords) abort "{{{1
  for keyword in a:keywords
    if type(keyword) == type("")
      call self.add(keyword, 0)
    elseif type(keyword) == type({})
      call self.add(keyword.pattern, get(keyword, "regexp", 0))
    endif
    unlet keyword
  endfor
endfunction

function! s:manual.set() abort "{{{1
  " call map(copy(self.colors), 'matchadd(v:val.name, v:val.pattern)')
  for color in self.colors
    call matchadd(color.name, color.pattern, g:quickhl_manual_hl_priority)
  endfor
endfunction

function! s:manual.clear() abort "{{{1
  call map(map(quickhl#our_match(self.name), 'v:val.id'), 'matchdelete(v:val)')
endfunction

function! s:manual.reset() abort "{{{1
  call self.init()
  call quickhl#manual#refresh()
  if self.enabled | call self.inject_keywords() | endif
endfunction

function! s:manual.is_locked() abort "{{{1
  return self.locked
endfunction

function! s:manual.refresh() abort "{{{1
  call self.clear()
  if self.locked || ( exists("w:quickhl_manual_lock") && w:quickhl_manual_lock )
    return
  endif
  call self.set()
endfunction

function! s:manual.show_colors() abort "{{{1
  for color in self.colors
    call s:exe("highlight " . color.name)
  endfor
endfunction

function! s:manual.add(pattern, escaped) abort "{{{1
  let pattern = a:escaped ? a:pattern : quickhl#escape(a:pattern)
  if ( s:manual.index_of(pattern) >= 0 )
    call s:decho("duplicate: " . pattern)
    return
  endif
  call s:decho("new: " . pattern)
  let i = self.next_index()
  let self.colors[i].pattern = pattern
  call add(self.history, i)
endfunction

function! s:manual.next_index() abort "{{{1
  " let index = self.index_of('')
  " return ( index != -1 ? index : remove(self.history, 0) )
  return remove(self.history, 0)
endfunction

function! s:manual.index_of(pattern) abort "{{{1
  for n in range(len(self.colors))
    if self.colors[n].pattern ==# a:pattern
      return n
    endif
  endfor
  return -1
endfunction

function! s:manual.del(pattern, escaped) abort "{{{1
  let pattern = a:escaped ? a:pattern : quickhl#escape(a:pattern)

  let index = self.index_of(pattern)
  call s:decho("[del ]: " . index)
  if index == -1
    call s:decho("Can't find for '" . pattern . "'" )
    return
  endif
  call self.del_by_index(index)
endfunction

function! s:manual.del_by_index(idx) abort "{{{1
  if a:idx >= len(self.colors) | return | endif
  let self.colors[a:idx].pattern = ''
  call remove(self.history, index(self.history, a:idx))
  call insert(self.history, a:idx, 0 )
endfunction

function! s:manual.list() abort "{{{1
  for idx in range(len(self.colors))
    let color = self.colors[idx]
    exe "echohl " . color.name
    echo printf("%2d: ", idx) . color.pattern
    echohl None
  endfor
endfunction

" }}}1

function! quickhl#manual#this(mode) abort "{{{1
  if !s:manual.enabled | call quickhl#manual#enable() | endif
  let pattern =
        \ a:mode == 'n' ? expand('<cword>') :
        \ a:mode == 'v' ? quickhl#get_selected_text() :
        \ ""
  if pattern == '' | return | endif
  " call s:decho("[toggle] " . pattern)
  call quickhl#manual#add_or_del(pattern, 0)
endfunction

function! quickhl#manual#this_whole_word(mode) abort "{{{1
  if !s:manual.enabled | call quickhl#manual#enable() | endif
  let pattern =
        \ a:mode == 'n' ? expand('<cword>') :
        \ a:mode == 'v' ? quickhl#get_selected_text() :
        \ ""
  if pattern == '' | return | endif
  call quickhl#manual#add_or_del('\<'. quickhl#escape(pattern).'\>', 1)
endfunction

function! quickhl#manual#clear_this(mode) abort "{{{1
  if !s:manual.enabled | call quickhl#manual#enable() | endif
  let pattern =
        \ a:mode == 'n' ? expand('<cword>') :
        \ a:mode == 'v' ? quickhl#get_selected_text() :
        \ ""
  if pattern == '' | return | endif
  let l:pattern_et = quickhl#escape(pattern)
  let l:pattern_ew = '\<' . quickhl#escape(pattern) . '\>'
  if s:manual.index_of(l:pattern_et) != -1
    call s:manual.del(l:pattern_et, 1)
  elseif s:manual.index_of(l:pattern_ew) != -1
    call s:manual.del(l:pattern_ew, 1)
  endif
  call quickhl#manual#refresh()
endfunction "

function! quickhl#manual#add_or_del(pattern, escaped) abort "{{{1
  if !s:manual.enabled | call quickhl#manual#enable() | endif

  if s:manual.index_of(a:escaped ? a:pattern : quickhl#escape(a:pattern)) == -1
    call s:manual.add(a:pattern, a:escaped)
  else
    call s:manual.del(a:pattern, a:escaped)
  endif
  call quickhl#manual#refresh()
endfunction

function! quickhl#manual#reset() abort "{{{1
  call s:manual.reset()
  call quickhl#manual#refresh()
endfunction

function! quickhl#manual#list() abort "{{{1
  call s:manual.list()
endfunction

function! quickhl#manual#lock_window() abort "{{{1
  let w:quickhl_manual_lock = 1
  call s:manual.clear()
endfunction

function! quickhl#manual#unlock_window() abort "{{{1
  let w:quickhl_manual_lock = 0
  call quickhl#manual#refresh()
endfunction

function! quickhl#manual#lock_window_toggle() abort "{{{1
  if !exists("w:quickhl_manual_lock")
    let w:quickhl_manual_lock = 0
  endif
  let w:quickhl_manual_lock = !w:quickhl_manual_lock
  call s:manual.refresh()
endfunction

function! quickhl#manual#lock() abort "{{{1
  let s:manual.locked = 1
  call quickhl#manual#refresh()
endfunction

function! quickhl#manual#unlock() abort "{{{1
  let s:manual.locked = 0
  call quickhl#manual#refresh()
endfunction

function! quickhl#manual#lock_toggle() abort "{{{1
  let s:manual.locked = !s:manual.locked
  call quickhl#manual#refresh()
endfunction

function! quickhl#manual#dump() abort "{{{1
  call s:manual.dump()
  " echo s:manual.history
endfunction

function! quickhl#manual#add(pattern, escaped) abort "{{{1
  if !s:manual.enabled | call quickhl#manual#enable() | endif
  call s:manual.add(a:pattern, a:escaped)
  call quickhl#manual#refresh()
endfunction

function! quickhl#manual#del(pattern, escaped) abort "{{{1
  if empty(a:pattern)
    call s:manual.list()
    let index = input("index to delete: ")
    if empty(index) | return | endif
    call s:manual.del_by_index(index)
  else
    call s:manual.del(a:pattern, a:escaped)
  endif
  call quickhl#manual#refresh()
endfunction

function! quickhl#manual#colors() abort "{{{1
  call s:manual.show_colors()
endfunction

function! quickhl#manual#enable() abort "{{{1
  call s:manual.init()
  let  s:manual.enabled = 1
  call s:manual.inject_keywords()

  augroup QuickhlManual
    autocmd!
    autocmd VimEnter,WinEnter * call quickhl#manual#refresh()
    autocmd! ColorScheme * call quickhl#manual#init_highlight()
  augroup END
  call quickhl#manual#init_highlight()
  call quickhl#manual#refresh()
endfunction

function! quickhl#manual#disable() abort "{{{1
  let s:manual.enabled = 0
  augroup QuickhlManual
    autocmd!
  augroup END
  autocmd! QuickhlManual
  call quickhl#manual#reset()
endfunction

function! quickhl#manual#refresh() abort "{{{1
  call quickhl#windo(s:manual.refresh, s:manual)
endfunction

function! quickhl#manual#status() abort "{{{1
  echo s:manual.enabled
endfunction

function! quickhl#manual#init_highlight() abort "{{{1
  call s:manual.init_highlight()
endfunction

function! quickhl#manual#this_motion(type) abort "{{{1
  let cb_save  = &cb
  let sel_save = &sel

  try
      let lnum_beg = line("'[")
      let lnum_end = line("']")
      for n in range(lnum_beg, lnum_end)
        let _s = getline(n)
        let s = {
              \  "all":     _s,
              \  "between": _s[col("'[")-1 : col("']")-1],
              \  "pos2end": _s[col("'[")-1 : -1],
              \  "beg2pos": _s[ : col("']")-1],
              \  }

        if a:type == 'char'
          let str =
                \ lnum_beg == lnum_end ?            s.between :
                \ n        == lnum_beg ?            s.pos2end :
                \ n        == lnum_end ?            s.beg2pos :
                \                                   s.all
        elseif a:type == 'line'  | let str = s.all
        elseif a:type == 'block' | let str = s.between
        endif

        call quickhl#manual#add_or_del(str, 0)
      endfor
  catch
      return lg#catch_error()
  finally
      let &cb  = cb_save
      let &sel = sel_save
  endtry
endfunction

call s:manual.init()
