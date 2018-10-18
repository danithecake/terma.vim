if exists('g:terma_loaded') && g:terma_loaded
  exit
endif

let g:terma_loaded = 1

if !exists('g:terma_provider') || empty(g:terma_provider)
  let g:terma_provider = 'tmux'
endif
