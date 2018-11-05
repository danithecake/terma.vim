function! terma#shell#setuppid(cmd, job)
  let a:job['pid_file'] = tempname()

  return 'echo $$ >'.a:job['pid_file'].'; '.a:cmd
endfunction

function! terma#shell#setupredir(cmd, opts, job)
  let l:cmd = a:cmd

  if get(a:opts, 'stdout', 1)
    let l:cmd = l:cmd.' 1>'.a:job['stdout_file']
  endif

  if get(a:opts, 'stderr', 1)
    let l:cmd = l:cmd.' 2>'.a:job['stderr_file']
  endif

  return l:cmd
endfunction

function! terma#shell#killjob(job)
  let l:pid_file = get(a:job, 'pid_file', '')

  try
    call system('kill '.readfile(l:pid_file)[0])
  finally
    call delete(l:pid_file)
  endtry
endfunction
