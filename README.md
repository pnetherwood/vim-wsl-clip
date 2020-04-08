vim-wsl-clip
============

vim-wsl-clip provides access to the Windows system clipboard for terminal Vim without clipboard support which is the default in WSL. Similar to
setting `clipboard=unnamed` it automatically puts any yanked text into the system clipboard and the contents of the system clipboard are
automatically available for putting using the normal put commands. No special keys are required. There is no requirement to install vim on
WSL with clipboard support (i.e installing vim-gnome) or installing an X server.

It relies on a new feature of vim so it requires Vim with patch 8.0.1394. `echo has('patch-8.0.1394')` should return 1. The current default
install of Vim on Ubuntu 18.04 for WSL has this patch.

Installation
------------

Install using your favourite plugin manager. For example for Vim Plug use:

```vim
Plug 'pnetherwood/vim-wsl-clip'
```

Dependencies
------------

### Plugins

For the automatic paste feature to work it requires a terminal that supports Focus Reporting as it relies on capturing `FocusLost` and
`FocusGained` events. Terminal vim does not support these events by default. In order to get focus event support in terminal Vim install
[https://github.com/pnetherwood/vim-term-focus](https://github.com/pnetherwood/vim-term-focus). This plugin describes how to check whether
your terminal supports Focus Reporting. On Windows [WSLtty](https://github.com/mintty/wsltty) is your best option for a terminal emulator
that supports Focus Reporting as the default terminals do not.
Install using:
```vim
Plug 'pnetherwood/vim-term-focus'
```
### Executables

vim-wsl-clip uses external programs to write and read from the system clipboard. The default for writing to the clipboard is `clip.exe`.
Powershell is used to read from the system clipboard. Both commands need to be in your path. For faster reading and writing to the system
clipboard you may wish to install [win32yank](https://github.com/equalsraf/win32yank). Install by copying a release build into your path.

Configuration
-------------

The following variables can be added to your vimrc to change the behaviour:

|                            Option | Description                                     |                                                            Default |
|                               --- | ---                                             |                                                                --- |
|          g:wsl_clip_clipboard_set | The command used to update the system clipboard |                            `clip.exe` or `win32yank.exe -i --crlf` |
|          g:wsl_clip_clipboard_get | The command used to get the system clipboard    | `powershell.exe -Command Get-Clipboard` or `win32yank.exe -o --lf` |
| g:wsl_clip_default_paste_register | The register that receives the system clipboard |                                                                  " |

Operation
---------

### Yank

Any yank operation will put the yank register in the system clipboard. When yanking to a numbered or named register the system clipboard
will not be updated.

### Put

If the system clipboard is modified outside of Vim then the system clipboard is put into the unnamed " register. This differs from the
behaviour of the option `clipboard=unnamed` which places the system clipboard in the * register. However the behaviour appears to be the
same in that if you copy something into the system clipboard outside of your terminal it is immediately available for pasting with the put
command. The unnamed register has to be used to maintain this behaviour in Vim with no clipboard as there is no * and + registers.

If you shift focus out of the terminal and the system clipboard does not change then the existing content of the unnamed register is
retained. If you do not like the unnamed register being used you change change the register by setting `g:wsl_clip_default_paste_register`
e.g.:

```vim
let g:wsl_clip_default_paste_register = '0'
```

Use `"0p` order to put from this register.

How it Works Under the Covers
-----------------------------

Yanking into the system clipboard uses the `TextYankPost` auto command event which is triggered after a yank operation. The contents of the
yank register are then sent to the system clipboard using the clipboard program set in `g:wsl_clip_clipboard_set`. `TextYankPost` is a new
feature only available since patch 8.0.1394.

When focus is lost in the terminal the assumption is made that you are interacting with programs outside of the terminal such as a web
browser for example. When the focus is lost the current system clipboard is stored using the clipboard program set in
`g:wsl_clip_clipboard_get`. When focus is regained the system clipboard contents are compared to the one on focus lost. If they are
different then the unnamed register is set to the clipboard contents. The `FocusLost` and `FocusGained` auto command events are used to
detect entering and leaving the terminal. The terminal has to have Focus Reporting capability. See [https://github.com/pnetherwood/vim-term-focus](https://github.com/pnetherwood/vim-term-focus) for more details of supported terminals.



License
-------

MIT/X11
