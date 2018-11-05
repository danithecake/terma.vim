if exists('g:terma_loaded') && g:terma_loaded
  exit
endif

let g:terma_loaded = 1

if !exists('g:terma_provider') || empty(g:terma_provider)
  let g:terma_provider = 'tmux'
endif

function! s:cleanup()
  for l:job_id in terma#jobs#ids()
    call terma#stop(l:job_id)
  endfor
endfunction

augroup terma
  autocmd!

  autocmd VimLeavePre * call s:cleanup()
augroup end
