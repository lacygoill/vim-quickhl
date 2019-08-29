fu! quickhl#show_help() abort "{{{1
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

fu! quickhl#get_selected_text() abort "{{{1
    let save_z = getreg('z', 1)
    let save_z_type = getregtype('z')
    try
        sil norm! gv"zy
        return substitute(@z,"\n.*",'','')
    finally
        call setreg('z', save_z, save_z_type)
    endtry
endfu

fu! quickhl#warn(error) abort "{{{1
    echohl WarningMsg
    echom 'quickhl:  '..a:error
    echohl None
endfu

fu! quickhl#escape(pattern) abort "{{{1
    return escape(a:pattern, '\/~ .*^[''$')
endfu

fu! quickhl#our_match(pattern) abort "{{{1
    return filter(getmatches(), {_,v -> v.group =~# a:pattern})
endfu

fu! quickhl#windo(func, obj) abort "{{{1
    let winnum = winnr()
    let pwinnum = winnr('#')
    " echo [pwinnum, winnum]
    " echo PP(a:func)
    " echo PP(a:obj)
    noa windo call call(a:func, [], a:obj)

    if pwinnum != 0
        exe pwinnum..'wincmd w'
    endif
    exe winnum..'wincmd w'
endfu

