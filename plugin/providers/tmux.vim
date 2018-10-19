let s:jobs = {}

function! s:job_id()
  let l:job_ids = sort(
        \ map(keys(s:jobs), {i, val -> str2nr(val)}),
        \ {i1, i2 -> i1 == i2 ? 0 : i1 > i2 ? 1 : -1}
        \ )
  let l:job_id = 1

  while l:job_id < len(l:job_ids) + 1
    if index(l:job_ids, l:job_id) < 0
      return l:job_id
    endif

    let l:job_id += 1
  endwhile

  return len(l:job_ids) > 0 ? max(l:job_ids) : l:job_id
endfunction

function! s:on_exit(job_id, exit_code)
  let l:job = get(s:jobs, a:job_id, {})

  try
    let l:stdout = readfile(l:job['stdout_file'])
  catch
    let l:stdout = []
  finally
    call delete(l:job['stdout_file'])
  endtry

  try
    let l:stderr = readfile(l:job['stderr_file'])
  catch
    let l:stderr = []
  finally
    call delete(l:job['stderr_file'])
  endtry

  sleep 100m

  let l:OnExit = get(l:job, 'on_exit')
  let l:OnStdOut = get(l:job, 'on_stdout')
  let l:OnStdErr = get(l:job, 'on_stderr')

  if type(l:OnExit) == 2
    call l:OnExit(l:stdout, l:stderr, a:exit_code)
  elseif type(l:OnStdOut) == 2 && a:exit_code == 0
    call l:OnStdOut(l:stdout)
  elseif type(l:OnStdErr) == 2 && a:exit_code == 1
    call l:OnStdErr(l:stderr)
  endif

  call remove(s:jobs, a:job_id)

  redraw
endfunction

function! s:run(cmd, opts)
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

  let l:job = {
        \ 'stdout_file': tempname(),
        \ 'stderr_file': tempname(),
        \ 'on_exit': get(a:opts, 'on_exit'),
        \ 'on_stdout': get(a:opts, 'on_stdout'),
        \ 'on_stderr': get(a:opts, 'on_stderr'),
        \ }
  let l:job_id = s:job_id()
  let s:jobs[l:job_id] = l:job

  let l:cmd = l:cmd.' <cmd>'.a:cmd

  if get(a:opts, 'stdout', 1)
    let l:cmd = l:cmd.' 1>'.l:job['stdout_file']
  endif

  if get(a:opts, 'stderr', 1)
    let l:cmd = l:cmd.' 2>'.l:job['stderr_file']
  endif

  let l:cmd = l:cmd
        \ .'; '
        \ .l:tmux_cmd
        \ .' send-keys -t:'
        \ .systemlist(l:tmux_cmd.' display -p "#I"')[0]
        \ .'.'
        \ .systemlist(l:tmux_cmd.' display -p "#P"')[0]
        \ .' ":call '
        \ .string(function('s:on_exit', [l:job_id]))
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

    call remove(l:job, 'stdout_file')
    call remove(l:job, 'stderr_file')
    call remove(s:jobs, l:job_id)
  endtry

  return l:job_id
endfunction

call terma#providers#add('tmux', {
      \ 'split': function('s:run'),
      \ 'window': function('s:run'),
      \ 'run': function('s:run'),
      \ })
