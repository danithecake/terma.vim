let s:jobs = {}
let s:job_id = 0

function! terma#jobs#ids()
  return map(keys(s:jobs), {i, val -> str2nr(val)})
endfunction

function! terma#jobs#create(cmd, provider, opts)
  let l:job = {
        \ 'id': s:job_id,
        \ 'cmd': a:cmd,
        \ 'provider': a:provider,
        \ 'stdout_file': tempname(),
        \ 'stderr_file': tempname(),
        \ 'on_exit': get(a:opts, 'on_exit'),
        \ 'on_stdout': get(a:opts, 'on_stdout'),
        \ 'on_stderr': get(a:opts, 'on_stderr'),
        \ }
  let s:jobs[s:job_id] = l:job

  let s:job_id += 1

  return l:job
endfunction

function! terma#jobs#get(id)
  return get(s:jobs, a:id, {})
endfunction

function! terma#jobs#remove(id)
  if has_key(s:jobs, a:id)
    let l:job = terma#jobs#get(a:id)

    call delete(l:job['stdout_file'])
    call delete(l:job['stderr_file'])

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
  endtry

  try
    let l:stderr = readfile(l:job['stderr_file'])
  catch
    let l:stderr = []
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
