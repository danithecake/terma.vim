function! s:run(cmd, ...)
  let l:opts = get(a:, 1, {})
  let l:provider = get(l:opts, 'provider', g:terma_provider)
  let l:Runner = get(terma#providers#get(l:provider), get(l:opts, 'type', 'run'))

  try
    call l:Runner(a:cmd, l:opts)
  catch
    let l:providers = filter(
          \ extend([l:provider], get(a:, 2, terma#providers#names())),
          \ {idx, val -> val != l:provider}
          \ )

    if !len(l:providers)
      throw 'No available terma.vim providers'
    endif

    let l:opts['provider'] = l:providers[0]

    call s:run(a:cmd, l:opts, l:providers)
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
