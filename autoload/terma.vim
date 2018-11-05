function! s:run(cmd, ...)
  let l:opts = get(a:, 1, {})
  let l:cmd_type = get(l:opts, 'type', 'run')
  let l:providers = get(
        \ a:,
        \ 2,
        \ extend(
          \ [get(l:opts, 'provider', g:terma_provider)],
          \ terma#providers#names()
          \ )
        \ )

  if !len(l:providers)
    call terma#utils#echoerr('No available <terma#'.l:cmd_type.'> providers')

    return
  endif

  let l:provider = l:providers[0]
  let l:job = terma#jobs#create(a:cmd, l:provider, l:opts)

  try
    call call(
          \ get(terma#providers#get(l:provider), l:cmd_type),
          \ [l:job, l:opts]
          \ )
  catch
    call terma#utils#echoerr(v:exception)
    call terma#jobs#remove(l:job['id'])
    call s:run(
          \ a:cmd,
          \ l:opts,
          \ filter(
            \ extend([l:provider], l:providers),
            \ {idx, val -> val != l:provider}
            \ )
          \ )
  endtry
endfunction

function! terma#split(cmd, ...)
  call s:run(a:cmd, extend(get(a:, 1, {}), {'type': 'split'}))
endfunction

function! terma#window(cmd, ...)
  call s:run(a:cmd, extend(get(a:, 1, {}), {'type': 'window'}))
endfunction

function! terma#run(cmd, ...)
  call s:run(a:cmd, extend(get(a:, 1, {}), {'type': 'run'}))
endfunction

function! terma#shell(cmd, ...)
  call s:run(a:cmd, get(a:, 1, {}))
endfunction

function! terma#stop(job_id)
  let l:job = terma#jobs#get(a:job_id)
  let l:provider = terma#providers#get(get(l:job, 'provider'))

  try
    call l:provider['stop'](l:job)
  catch /\(E716\|E718\)/
    call terma#utils#echoerr("<".a:job_id."> provider doesn't have a <stop> handler")
  catch
    call terma#jobs#remove(a:job_id)
  endtry
endfunction
