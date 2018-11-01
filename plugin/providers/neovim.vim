function! s:on_exit(term_type, job_id, nvim_job_id, exit_code, event_type)
  if a:term_type == 'split' || a:term_type == 'window'
    quit
  endif

  call terma#jobs#onexit(a:job_id, a:exit_code)
endfunction

function! s:execute(func, cmd, opts)
  if !exists('*termopen') || !exists('*jobstart')
    throw 'Neovim provider is unavailable'
  endif

  let l:job = terma#jobs#create(a:opts)
  let l:job_id = terma#jobs#add(l:job)

  let l:OnExit = function('s:on_exit', [get(a:opts, 'type'), l:job_id])

  try
    let l:job['nvim_job_id'] = call(a:func, [
          \ terma#shell#setupredir(a:cmd, a:opts, l:job),
          \ {'on_exit': l:OnExit}
          \ ])
  catch
    call delete(l:job['stdout_file'])
    call delete(l:job['stderr_file'])

    call terma#jobs#remove(l:job_id)
  endtry

  return l:job_id
endfunction

function! s:window(cmd, opts)
  tabnew

  return s:execute(function('termopen'), a:cmd, a:opts)
endfunction

function! s:split(cmd, opts)
  let l:win_cmd = !get(a:opts, 'mirrored') ? 'belowright ' : ''

  let l:size = get(a:opts, 'size', &lines * 50 / 100)

  if get(a:opts, 'size_unit', 'l') == 'p'
    let l:size = &lines * l:size / 100
  endif

  if get(a:opts, 'vertical')
    execute l:win_cmd.'vnew | vertical resize '.l:size
  else
    execute l:win_cmd.'new | resize '.l:size
  endif

  return s:execute(function('termopen'), a:cmd, a:opts)
endfunction

function! s:run(cmd, opts)
  return s:execute(function('jobstart'), a:cmd, a:opts)
endfunction

call terma#providers#add('neovim', {
      \ 'split': function('s:split'),
      \ 'window': function('s:window'),
      \ 'run': function('s:run'),
      \ })
