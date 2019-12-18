fu quickhl#show_help() abort "{{{1
    " TODO: Include help about Ex commands, and show help in a scratch buffer.
    " Take inspiration from vim-cheat40 for the scratch buffer.
    let help =<< trim END
        -h*     highlight word under cursor        N
        -hg*    highlight unbounded word           N
        -h      highlight motion or text-object    N
        -hc     clear highlighting under cursor    N
        -hC     clear all highlighting             N
        coH     toggle global lock                 N

        -h      highlight selection                X
        -H      clear highlighting on selection    X
    END
    echo join(help, "\n")
endfu

fu quickhl#get_selected_text() abort "{{{1
    let save_z = getreg('z', 1)
    let save_z_type = getregtype('z')
    try
        sil norm! gv"zy
        return substitute(@z,"\n.*",'','')
    finally
        call setreg('z', save_z, save_z_type)
    endtry
endfu

fu quickhl#warn(error) abort "{{{1
    echohl WarningMsg
    echom 'quickhl:  '..a:error
    echohl None
endfu

fu quickhl#escape(pattern) abort "{{{1
    return escape(a:pattern, '\/~ .*^[''$')
endfu

fu quickhl#our_match(pattern) abort "{{{1
    return filter(getmatches(), {_,v -> v.group =~# a:pattern})
endfu

fu quickhl#windo(func, obj) abort "{{{1
    " [BUG] This function is invoked from WinEnter event.

    " Unexpectedly, this event is happen before buffer is not shown on window when invoke `pedit file`.
    " So here I will skip unxexisting buffer(which return `-1`) to avoid E994 error.
    if bufwinid('') ==# -1
      return
    endif

    " TODO: Refactor the plugin to avoid numbered functions so that we can eliminate these temporary global variables.{{{
    "
    " Once it's done, you should be able to eliminate the global variables, and just write:
    "
    "     call map(range(1, winnr('$')),
    "         \ {_,v -> lg#win_execute(win_getid(v),
    "         \ 'call call('..string(a:func)..', [], '..string(a:obj)..')')})
    "
    " ---
    "
    " These global variables did not exist in the original plugin:
    "
    "     let winnum = winnr()
    "     let pwinnum = winnr('#')
    "     noa windo call call(a:func, [], a:obj)
    "     if pwinnum != 0
    "         exe pwinnum..'wincmd w'
    "     endif
    "     exe winnum..'wincmd w'
    "
    " However, the old code causes an issue where the unfocused windows are *un*squashed.
    "
    " Worse, even if  you maximize the current window to  squash them, the issue
    " re-appears as soon as you focus another window.
    " This is due to an autocmd which invokes `quickhl#manual#refresh()` on `WinEnter`.
    " Note that to clear the autocmd, you can probably execute `:QuickhlManualDisable`.
    "
    " ---
    "
    " In any case, to avoid this issue we invoke `win_execute()` instead of `:windo`.
    " But we can't simply write this:
    "
    "     call map(range(1, winnr('$')),
    "         \ {_,v -> lg#win_execute(win_getid(v),
    "         \ 'call call(a:func, [], a:obj)')})
    "
    " It raises:
    "
    "     E121: Undefined variable: a:func~
    "     E116: Invalid arguments for function call~
    "
    " That's because the `:call call(...)` command  is not run in the context of
    " the current function; so it can't access the variables in the `a:` scope.
    "
    " We can't write this either:
    "
    "     call map(range(1, winnr('$')),
    "         \ {_,v -> lg#win_execute(win_getid(v),
    "         \ 'call call('..string(a:func)..', [], '..string(a:obj)..')')})
    "
    " It raises:
    "
    "     E129: Function name required~
    "     E475: Invalid argument: 18~
    "
    " That's because Vim can't eval a  string containing a dictionary with a key
    " whose value is a funcref referring to a numbered function.
    " For  example, capture the  dictionary `a:obj`  in a global  variable, then
    " execute this:
    "
    "     :echo eval(string(g:obj))
    "     E129: Function name required~
    "     E475: Invalid argument: 18~
    "     ...~
    "
    " On  a deeper  level, the  cause  of the  issue  is that  Vim represents  a
    " numbered function via `function('123')` inside `a:func` and `a:obj`.
    " However, you can't use the same notation when you manually invoke `function()`:
    "
    "     let a = function('123')
    "     E129: Function name required~
    "     E475: Invalid argument: 123~
    "
    " `function()` does not accept a string containing a number as argument.
    " It wants a "real" name; see `:h function()`:
    "
    " > {name}  can be  the  name of  a  user defined  function  or an  internal
    " > function.
    "
    " IOW,  you can  *read* `function('123')`  in some  command output,  but you
    " can't *write* it in an executed command.
    "}}}
    let [g:Quickhl_Funcref, g:quickhl_obj] = [a:func, a:obj]
    call map(range(1, winnr('$')),
        \ {_,v -> lg#win_execute(win_getid(v),
        \ 'call call(g:Quickhl_Funcref, [], g:quickhl_obj)')})
    unlet g:Quickhl_Funcref g:quickhl_obj
endfu

