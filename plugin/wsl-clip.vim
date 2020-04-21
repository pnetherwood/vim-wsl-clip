" wsl-clip.vim - Clipboard for vim on WSL with no compiled in clipboard support
" 
" Maintainer:	Paul Netherwood <paul@netherwood.me.uk>
" Version:	0.0.1
" License:	MIT License
" Location:	plugin/wsl-clip.vim
" Website:	https://github.com/pnetherwood/vim-wsl-clip

if exists("g:loaded_wsl_clip")
  finish
endif
let g:loaded_wsl_clip = 1

if !has('patch-8.0.1394') || has("clipboard") || !has('unix') || system('uname -a') !~ 'Microsoft' || &compatible
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

let win32Path = split(system('grep "C:" /etc/mtab'))[1] . '/Windows/System32/'

let default_set_cmd = win32Path . 'clip.exe'
let default_get_cmd = win32Path . 'WindowsPowerShell/v1.0/powershell.exe -Command Get-Clipboard'
let default_strip_last_CRLF = 1
if executable('win32yank.exe')
  let default_set_cmd = 'win32yank.exe -i --crlf'
  let default_get_cmd = 'win32yank.exe -o --lf'
  let default_strip_last_CRLF  = 0
endif

let g:wsl_clip_clipboard_set = get(g:, 'wsl_clip_clipboard_set', default_set_cmd)
let g:wsl_clip_clipboard_get = get(g:, 'wsl_clip_clipboard_get', default_get_cmd)
let g:wsl_clip_strip_last_CRLF = get(g:, 'wsl_clip_strip_last_CRLF', default_strip_last_CRLF)

" By default set the " register so that the default put command works
let g:wsl_clip_default_paste_register = '"'

if !executable(split(g:wsl_clip_clipboard_get)[0])   
  echom "Clipboard get command missing, not in path or not executable: " . g:wsl_clip_clipboard_get
  finish
endif

if !executable(split(g:wsl_clip_clipboard_set)[0])   
  echom "Clipboard set command missing, not in path or not executable: " . g:wsl_clip_clipboard_set
  finish
endif

function! s:ClipboardSet(regname, regcontents)
  if a:regname == '0' || a:regname == '"' || a:regname == ''
    let r = system(g:wsl_clip_clipboard_set, a:regcontents)
  endif
endfunction

augroup WSLYank
  autocmd!
  autocmd TextYankPost * call <SID>ClipboardSet(v:event.regname, v:event.regcontents)
augroup END

let s:last_clipboard = ""

function! s:SaveClipboard()
  " Get the current system clip board to see if its changed when focus is regained
  let s:last_clipboard = system(g:wsl_clip_clipboard_get)
endfunction

function! s:UpdateClipboard()
  let clipboard = system(g:wsl_clip_clipboard_get)
  " Only set the clipboard if its changed. Its likely that if the system clipboard hasn't changed then 
  " you'll want to keep the contents of the paste register as is
  if clipboard !=# s:last_clipboard
    if g:wsl_clip_strip_last_CRLF
      let clipboard = substitute(clipboard, '\r\n$', '', '')
    endif
    let clipboard = substitute(clipboard, '\r', '', 'g')
    call setreg(g:wsl_clip_default_paste_register, clipboard)    
  endif
endfunction

augroup WSLPut
  autocmd!
  autocmd FocusLost * call <SID>SaveClipboard()
  autocmd FocusGained * call <SID>UpdateClipboard()
augroup END

let &cpo = s:save_cpo
