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

if &compatible || !has('patch-8.0.1394') || has("clipboard")
  finish
endif

let s:isWSL = 0
if has("unix")
  let lines = readfile("/proc/version")
  if lines[0] =~ "Microsoft"
    let s:isWSL = 1
  endif
endif

if !s:isWSL
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

if executable('win32yank')
  let default_set_cmd = 'win32yank -i --crlf'
  let default_get_cmd = 'win32yank -o --lf'
  let default_strip_last_CRLF  = 0
else
  let win32Path = '/c/Windows/System32/'
  " Get the path to Windows executables from mtab in case user has overridden the default
  for  line in readfile('/etc/mtab')
    if line =~ 'path=C:'
      let win32Path = split(line, ' ')[1] . '/Windows/System32/'
    endif
  endfor

  let default_set_cmd = win32Path . 'clip.exe'
  let default_get_cmd = win32Path . 'WindowsPowerShell/v1.0/powershell.exe -Command Get-Clipboard'
endif

let default_strip_last_CRLF = 1

let g:wsl_clip_clipboard_set = get(g:, 'wsl_clip_clipboard_set', default_set_cmd)
let g:wsl_clip_clipboard_get = get(g:, 'wsl_clip_clipboard_get', default_get_cmd)
let g:wsl_clip_strip_last_CRLF = get(g:, 'wsl_clip_strip_last_CRLF', default_strip_last_CRLF)

" By default set the " register so that the default put command works
let g:wsl_clip_default_paste_register = get(g:, 'wsl_clip_default_paste_register', '"')
" Have an copy of the clipboard in extra register in case we accidentally override it with a delete
let g:wsl_clip_extra_paste_register = get(g:, 'wsl_clip_extra_paste_register', '1')

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

function! s:UpdateClipboard()
  let clipboard = system(g:wsl_clip_clipboard_get)
  if g:wsl_clip_strip_last_CRLF
    let clipboard = substitute(clipboard, '\r\n$', '', '')
  endif
  let clipboard = substitute(clipboard, '\r', '', 'g')
  call setreg(g:wsl_clip_default_paste_register, clipboard)    
  if g:wsl_clip_extra_paste_register != ''
    call setreg(g:wsl_clip_extra_paste_register, clipboard)    
  endif
endfunction

augroup WSLPut
  autocmd!
  autocmd FocusGained * call <SID>UpdateClipboard()
augroup END

let &cpo = s:save_cpo
