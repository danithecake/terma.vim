let s:providers = {}

function! terma#providers#names()
  return keys(s:providers)
endfunction

function! terma#providers#get(provider)
  return get(s:providers, a:provider, {})
endfunction

function! terma#providers#add(provider, config)
  let s:providers[a:provider] = a:config
endfunction
