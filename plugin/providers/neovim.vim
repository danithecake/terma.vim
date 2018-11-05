let s:has_nvim = {}

function! s:has_nvim.termopen() dict
  if !exists('*termopen')
    throw '[neovim]: <*termopen> is unavailable'
  endif
endfunction

function! s:has_nvim.jobstart() dict
  if !exists('*jobstart')
    throw '[neovim]: <*jobstart> is unavailable'
  endif
endfunction

function! s:has_nvim.jobstop() dict
  if !exists('*jobstop')
    throw '[neovim]: <*jobstop> is unavailable'
  endif
endfunction

function! s:on_exit(term_type, job_id, nvim_job_id, exit_code, event_type)
  if a:term_type == 'split' || a:term_type == 'window'
    quit
  endif

  call terma#jobs#onexit(a:job_id, a:exit_code)
endfunction

function! s:execute(func, job, opts)
  let l:job_id = a:job['id']

  let l:OnExit = function('s:on_exit', [get(a:opts, 'type'), l:job_id])

  try
    let a:job['nvim_job_id'] = call(a:func, [
          \ terma#shell#setupredir(a:job['cmd'], a:opts, a:job),
          \ {'on_exit': l:OnExit}
          \ ])
  catch
    call terma#jobs#remove(l:job_id)
  endtry

  return l:job_id
endfunction

function! s:window(job, opts)
  call s:has_nvim.termopen()

  tabnew

  return s:execute(function('termopen'), a:job, a:opts)
endfunction

function! s:split(job, opts)
  call s:has_nvim.termopen()

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

  return s:execute(function('termopen'), a:job, a:opts)
endfunction

function! s:run(job, opts)
  call s:has_nvim.jobstart()

  return s:execute(function('jobstart'), a:job, a:opts)
endfunction

function! s:stop(job)
  call s:has_nvim.jobstop()

  call jobstop(a:job['nvim_job_id'])
endfunction

call terma#providers#add('neovim', {
      \ 'split': function('s:split'),
      \ 'window': function('s:window'),
      \ 'run': function('s:run'),
      \ 'stop': function('s:stop'),
      \ })
