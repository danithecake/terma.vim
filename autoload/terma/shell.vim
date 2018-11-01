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
