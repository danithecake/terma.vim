function! terma#utils#echo(msg, hl)
  execute 'echohl '
        \ .(empty(a:hl) ? 'None' : a:hl)
        \ .' | echomsg "[terma.vim]: '
        \ .a:msg
        \ .'" | echohl None'
endfunction

function! terma#utils#echoerr(msg)
  call terma#utils#echo(a:msg, 'ErrorMsg')
endfunction
