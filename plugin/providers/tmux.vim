let s:has_tmux = {}

function! s:has_tmux.session() dict
  if !exists('$TMUX')
    throw "[tmux]: Not running inside Tmux session"
  endif
endfunction

function! s:has_tmux.executable(tmux) dict
  if !executable(a:tmux)
    throw "[tmux]: <".a:tmux."> can't be executed"
  endif
endfunction

function! s:execute(cmd, job, opts)
  let l:tmux_cmd = get(a:opts, 'tmux_cmd', 'tmux')

  call s:has_tmux.session()
  call s:has_tmux.executable(l:tmux_cmd)

  let l:job_id = a:job['id']

  let l:cmd = l:tmux_cmd
        \ .a:cmd
        \ .' <cmd>'
        \ .terma#shell#setupredir(
          \ terma#shell#setuppid(get(a:job, 'cmd', ''), a:job), a:opts, a:job
          \ )
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
    call terma#jobs#remove(l:job_id)
  endtry

  return l:job_id
endfunction

function! s:split(job, opts)
  let l:cmd = ' split-window '.(get(a:opts, 'vertical') ? '-h' : '-v')

  if has_key(a:opts, 'size')
    let l:cmd = l:cmd.' -'.get(a:opts, 'size_unit', 'l').a:opts['size']
  endif

  call s:execute(l:cmd, a:job, a:opts)
endfunction

function! s:window(job, opts)
  let l:cmd = ' new-window'

  call s:execute(l:cmd, a:job, a:opts)
endfunction

function! s:run(job, opts)
  let l:cmd = ' run-shell -b'

  call s:execute(l:cmd, a:job, a:opts)
endfunction

function! s:stop(job)
  try
    call terma#shell#killjob(a:job)
    call terma#jobs#onexit(a:job['id'], 1)
  finally
    call terma#jobs#remove(a:job['id'])
  endtry
endfunction

call terma#providers#add('tmux', {
      \ 'split': function('s:split'),
      \ 'window': function('s:window'),
      \ 'run': function('s:run'),
      \ 'stop': function('s:stop'),
      \ })
