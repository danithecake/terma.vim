function! s:execute(cmd, opts)
  let l:tmux_cmd = get(a:opts, 'tmux_cmd', 'tmux')

  if !exists('$TMUX') || !executable(l:tmux_cmd)
    throw 'Tmux provider is unavailable'
  endif

  let l:type = get(a:opts, 'type', 'run')

  if l:type == 'split'
    let l:cmd = l:tmux_cmd
          \ .' split-window '
          \ .(get(a:opts, 'vertical') ? '-h' : '-v')

    if has_key(a:opts, 'size')
      let l:cmd = l:cmd.' -'.get(a:opts, 'size_unit', 'l').a:opts['size']
    endif
  elseif l:type == 'window'
    let l:cmd = l:tmux_cmd.' new-window'
  elseif l:type == 'run'
    let l:cmd = l:tmux_cmd.' run-shell -b'
  endif

  if get(a:opts, 'dispatch')
    call system(l:cmd.' '.shellescape(a:cmd))

    return
  endif

  let l:job = terma#jobs#create(a:opts)
  let l:job_id = terma#jobs#add(l:job)

  let l:cmd = terma#shell#setupredir(l:cmd.' <cmd>'.a:cmd, a:opts, l:job)
        \ .'; '
        \ .l:tmux_cmd
        \ .' send-keys -t:'
        \ .systemlist(l:tmux_cmd.' display -p "#I"')[0]
        \ .'.'
        \ .systemlist(l:tmux_cmd.' display -p "#P"')[0]
        \ .' ":call '
        \ .string(function('terma#jobs#onexit', [l:job_id]))
        \ .'($?) | call histdel(\":\", -1)" C-m</cmd>'

  let l:cmd = substitute(l:cmd, '<cmd>\(.*\)<\/cmd>', {m -> shellescape(m[1])}, '')

  if get(a:opts, 'maximize')
    let l:cmd = l:cmd.'\; resize-pane -Z'
  endif

  try
    call system(l:cmd)
  catch
    call delete(l:job['stdout_file'])
    call delete(l:job['stderr_file'])

    call terma#jobs#remove(l:job_id)
  endtry

  return l:job_id
endfunction

call terma#providers#add('tmux', {
      \ 'split': function('s:execute'),
      \ 'window': function('s:execute'),
      \ 'run': function('s:execute'),
      \ })
