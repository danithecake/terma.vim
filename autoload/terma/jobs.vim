let s:jobs = {}
let s:job_id = 0

function! terma#jobs#ids()
  return map(keys(s:jobs), {i, val -> str2nr(val)})
endfunction

function! terma#jobs#create(cmd_opts)
  return {
        \ 'stdout_file': tempname(),
        \ 'stderr_file': tempname(),
        \ 'on_exit': get(a:cmd_opts, 'on_exit'),
        \ 'on_stdout': get(a:cmd_opts, 'on_stdout'),
        \ 'on_stderr': get(a:cmd_opts, 'on_stderr'),
        \ }
endfunction

function! terma#jobs#get(id)
  return get(s:jobs, a:id)
endfunction

function! terma#jobs#add(job)
  let s:jobs[s:job_id] = a:job

  let s:job_id += 1

  return s:job_id - 1
endfunction

function! terma#jobs#remove(id)
  if has_key(s:jobs, a:id)
    call remove(s:jobs, a:id)

    let s:job_id = a:id
  endif
endfunction

function! terma#jobs#onexit(job_id, exit_code, ...)
  let l:job = terma#jobs#get(a:job_id)

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

  call terma#jobs#remove(a:job_id)

  redraw
endfunction
