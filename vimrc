" URL: http://vim.wikia.com/wiki/Example_vimrc
" Authors: http://vim.wikia.com/wiki/Vim_on_Freenode
" Description: A minimal, but feature rich, example .vimrc. If you are a
"              newbie, basing your first .vimrc on this file is a good choice.
"              If you're a more advanced user, building your own .vimrc based
"              on this file is still a good idea.
 
"------------------------------------------------------------
set nocompatible              " required
filetype off                  " required

let g:NERDTreeDirArrows = 1

if !empty($MYSHELLCONFIG_VIM_PLUGINS)
  let pluginrepopath=$MYSHELLCONFIG_VIM_PLUGINS . '/'
  let pluginextension='.git'
else
  let pluginrepopath=''
  let pluginextension=''
endif

if !empty(glob("~/.vim/bundle/Vundle.vim"))
  " set the runtime path to include Vundle and initialize
  set rtp+=~/.vim/bundle/Vundle.vim
  call vundle#begin()

  " alternatively, pass a path where Vundle should install plugins
  "call vundle#begin('~/some/path/here')

  " let Vundle manage Vundle, required
  
  Plugin pluginrepopath . 'gmarik/Vundle.vim' . pluginextension
  Plugin pluginrepopath . 'vim-scripts/Zenburn' . pluginextension
"  Plugin pluginrepopath . 'Solarized' . pluginextension
  Plugin pluginrepopath . 'altercation/vim-colors-solarized' . pluginextension
  Plugin pluginrepopath . 'vim-scripts/indentpython.vim' . pluginextension
  Plugin pluginrepopath . 'tmhedberg/SimpylFold' . pluginextension
  Plugin pluginrepopath . 'vim-syntastic/syntastic' . pluginextension
  Plugin pluginrepopath . 'ctrlpvim/ctrlp.vim' . pluginextension
  Plugin pluginrepopath . 'preservim/nerdtree' . pluginextension
  Plugin pluginrepopath . 'Xuyuanp/nerdtree-git-plugin' . pluginextension
  Plugin pluginrepopath . 'jistr/vim-nerdtree-tabs' . pluginextension
  Plugin pluginrepopath . 'tpope/vim-fugitive' . pluginextension
  Plugin pluginrepopath . 'Lokaltog/powerline' . pluginextension, {'rtp': 'powerline/bindings/vim/'}
  Plugin pluginrepopath . 'rakr/vim-togglebg' . pluginextension
  Plugin pluginrepopath . 'ConradIrwin/vim-bracketed-paste' . pluginextension
"  Plugin pluginrepopath . 'ryanpcmcquen/fix-vim-pasting' . pluginextension
"  Plugin pluginrepopath . 'Valloric/YouCompleteMe' . pluginextension
  
  
   
  "Plugin 'gmarik/Vundle.vim'
  "Plugin 'Zenburn'
  "Plugin 'Solarized'
  "Plugin 'altercation/vim-colors-solarized.git'
  "Plugin 'vim-scripts/indentpython.vim'
  "Plugin 'tmhedberg/SimpylFold'
  "Plugin 'vim-syntastic/syntastic'
  "Plugin 'ctrlpvim/ctrlp.vim'
  "Plugin 'scrooloose/nerdtree'
  "Plugin 'Xuyuanp/nerdtree-git-plugin'
  "Plugin 'jistr/vim-nerdtree-tabs'
  "Plugin 'tpope/vim-fugitive'
  "Plugin 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
  "Plugin 'rakr/vim-togglebg'
  "Plugin 'ConradIrwin/vim-bracketed-paste'
  "Plugin 'ryanpcmcquen/fix-vim-pasting'
  "Plugin 'Valloric/YouCompleteMe'

"  Plugin 'https://git.schuerz.at/public/Vim/Vundle.vim.git'
"  Plugin 'https://git.schuerz.at/public/Vim/Zenburn.git'
"  Plugin 'https://git.schuerz.at/public/Vim/vim-colors-solarized.git'
"  Plugin 'https://git.schuerz.at/public/Vim/indentpython.vim.git'
"  Plugin 'https://git.schuerz.at/public/Vim/SimpylFold.git'
"  Plugin 'https://git.schuerz.at/public/Vim/syntastic.git'
"  Plugin 'https://git.schuerz.at/public/Vim/ctrlp.vim.git'
"  Plugin 'https://git.schuerz.at/public/Vim/scrooloose/nerdtree'
"  Plugin 'https://git.schuerz.at/public/Vim/Xuyuanp/nerdtree-git-plugin'
"  Plugin 'https://git.schuerz.at/public/Vim/vim-nerdtree-tabs.git'
"  Plugin 'https://git.schuerz.at/public/Vim/vim-fugitive.git'
"  Plugin 'https://git.schuerz.at/public/Vim/powerline.git', {'rtp': 'powerline/bindings/vim/'}
"  Plugin 'https://git.schuerz.at/public/Vim/vim-togglebg.git'
"  Plugin 'https://git.schuerz.at/public/Vim/vim-bracketed-paste.git'
"  "Plugin 'https://git.schuerz.at/public/Vim/ryanpcmcquen/fix-vim-pasting'
"  "Plugin 'https://git.schuerz.at/public/Vim/Valloric/YouCompleteMe'

  " add all your plugins here (note older versions of Vundle
  " used Bundle instead of Plugin)

  " ...

  " All of your Plugins must be added before the following line
  call vundle#end()            " required
endif
filetype plugin indent on    " required
"------------------------------------------------------------
set encoding=utf-8

" Features {{{1
"
" These options and commands enable some very useful features in Vim, that
" no user should have to live without.
 
" Set 'nocompatible' to ward off unexpected things that your distro might
" have made, as well as sanely reset options when re-sourcing .vimrc
set nocompatible
 
" Attempt to determine the type of a file based on its name and possibly its
" contents. Use this to allow intelligent auto-indenting for each filetype,
" and for plugins that are filetype specific.
"filetype indent plugin on
filetype on
filetype plugin on
filetype indent on
 
" Enable syntax highlighting
syntax on
 
" Set Highlight-Color of marked text reverse:
"hi Visual term=reverse cterm=reverse guibg=Grey
hi Visual term=underline ctermbg=Grey cterm=underline guibg=Grey gui=underline
 
"------------------------------------------------------------
" Must have options {{{1
"
" These are highly recommended options.
 
" Vim with default settings does not allow easy switching between multiple files
" in the same editor window. Users can use multiple split windows or multiple
" tab pages to edit multiple files, but it is still best to enable an option to
" allow easier switching between files.
"
" One such option is the 'hidden' option, which allows you to re-use the same
" window and switch from an unsaved buffer without saving it first. Also allows
" you to keep an undo history for multiple files when re-using the same window
" in this way. Note that using persistent undo also lets you undo in multiple
" files even in the same window, but is less efficient and is actually designed
" for keeping undo history after closing Vim entirely. Vim will complain if you
" try to quit without saving, and swap files will keep you safe if your computer
" crashes.
set hidden
 
" Note that not everyone likes working this way (with the hidden option).
" Alternatives include using tabs or split windows instead of re-using the same
" window as mentioned above, and/or either of the following options:
" set confirm
" set autowriteall
 
" Better command-line completion
set wildmenu
 
" Show partial commands in the last line of the screen
set showcmd
 
" Highlight searches (use <C-L> to temporarily turn off highlighting; see the
" mapping of <C-L> below)
set hlsearch
 
" Modelines have historically been a source of security vulnerabilities. As
" such, it may be a good idea to disable them and use the securemodelines
" script, <http://www.vim.org/scripts/script.php?script_id=1876>.
" set nomodeline
 
 
"------------------------------------------------------------
" Usability options {{{1
"
" These are options that users frequently set in their .vimrc. Some of them
" change Vim's behaviour in ways which deviate from the true Vi way, but
" which are considered to add usability. Which, if any, of these options to
" use is very much a personal preference, but they are harmless.
 
" Use case insensitive search, except when using capital letters
set ignorecase
set smartcase

" Set title in terminal-window
set title
 
" Allow backspacing over autoindent, line breaks and start of insert action
set backspace=indent,eol,start
 
" When opening a new line and no filetype-specific indenting is enabled, keep
" the same indent as the line you're currently on. Useful for READMEs, etc.
set autoindent
 
" Stop certain movements from always going to the first character of a line.
" While this behaviour deviates from that of Vi, it does what most users
" coming from other editors would expect.
set nostartofline
 
" Display the cursor position on the last line of the screen or in the status
" line of a window
set ruler
 
" Always display the status line, even if only one window is displayed
set laststatus=2
 
" Instead of failing a command because of unsaved changes, instead raise a
" dialogue asking if you wish to save changed files.
set confirm
 
" Use visual bell instead of beeping when doing something wrong
set visualbell
 
" And reset the terminal code for the visual bell. If visualbell is set, and
" this line is also included, vim will neither flash nor beep. If visualbell
" is unset, this does nothing.
set t_vb=

" check if mouse is enabled
" Disabled, because mark and paste outside vim is not working correctly
"if has('mouse')
"    " Enable use of the mouse for all modes
"    set mouse=a
"endif 
 
" Set the command window height to 2 lines, to avoid many cases of having to
" "press <Enter> to continue"
set cmdheight=2
 
" Display line numbers on the left
"set number
 
" Quickly time out on keycodes, but never time out on mappings
set notimeout ttimeout ttimeoutlen=200
 
" Use <F11> to toggle between 'paste' and 'nopaste'
set pastetoggle=<F2>
 
 
"------------------------------------------------------------
" Indentation options {{{1
"
" Indentation settings according to personal preference.
 
" Indentation settings for using 4 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
set shiftwidth=4
set softtabstop=4
set expandtab
 
" Indentation settings for using hard tabs for indent. Display tabs as
" four characters wide.
"set shiftwidth=4
"set tabstop=4
 
" Enable folding
set foldmethod=indent
set foldlevel=99
 
"------------------------------------------------------------
" Mappings {{{1
"
" Useful mappings
 
" Map Y to act like D and C, i.e. to yank until EOL, rather than act as yy,
" which is the default
map Y y$
 
" Map <C-L> (redraw screen) to also turn off search highlighting until the
" next search
nnoremap <C-L> :nohl<CR><C-L>

" Enable folding with the spacebar
nnoremap <space> za

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
 
" Map :next to <C-TAB> 
nmap <C-Tab> :next<CR>
nmap <C-S-Tab> :prev<CR>
nmap <C-t> :tabnew<CR>
"------------------------------------------------------------
let g:SimplyFold_docstring_preview=1

let g:ycm_autoclose_preview_window_after_completion=1
map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

"python with virtualenv support
"py << EOF
"import os
"import sys
"if 'VIRTUAL_ENV' in os.environ:
"  project_base_dir = os.environ['VIRTUAL_ENV']
"  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
"  execfile(activate_this, dict(__file__=activate_this))
"EOF
"=================================================================================
set background=light

if has('gui_running')
  set grepprg=grep\ -nH\ $*
  filetype indent on
  let g:tex_flavor='latex'
endif

au BufEnter *.tex set autowrite
let g:Tex_DefaultTargetFormat = 'pdf'
let g:Tex_MultipleCompileFormats = 'pdf'
let g:Tex_CompileRule_pdf = 'pdflatex -interaction=nonstopmode $*'
" Um alle Ausgabe-Pdfs von LaTeX in einem Verzeichnis zu sammeln oben de- und unten aktivieren.
"let g:Tex_CompileRule_pdf = 'mkdir -p out && pdflatex -output-directory=out -interaction=nonstopmode $* && mv out/$*.pdf .'
let g:Tex_GotoError = 0
let g:Tex_ViewRule_pdf = 'evince'
let g:Tex_ViewRule_dvi = 'xdvi -editor "gvim --servername xdvi --remote +\%l \%f" $* &'
let g:Tex_ViewRuleComplete_dvi = 'xdvi -editor "gvim --servername xdvi --remote +\%l \%f" $* &'


"set nospell
set spelllang=de

" mutt-Einstellungen
:hi mailHeader      ctermfg=Grey
:hi mailSubject     ctermfg=Green
:hi mailEmail       ctermfg=Blue
:hi mailSignature   ctermfg=Grey
:hi mailQuoted1     ctermfg=Darkyellow
:hi mailQuoted2     ctermfg=Green

" CSV syntax
au BufNewFile,BufRead *.csv
    \ set fileformat=unix 

" Javascript and Java syntax
au BufNewFile,BufRead *.js,*.java
    \ set tabstop=2 |
    \ set softtabstop=2 |
    \ set shiftwidth=2 |
    \ set textwidth=79 |
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix 

" Python syntax
au BufNewFile,BufRead *.py,*pyw,*.c,*.h
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4 |
    \ set textwidth=79 |
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix 

au BufNewFile,BufRead *.yml,*yaml
    \ set tabstop=2 |
    \ set softtabstop=2 |
    \ set shiftwidth=2 |
    \ set textwidth=79 |
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix 

"Use the below highlight group when displaying bad whitespace is desired.
highlight BadWhitespace ctermbg=red guibg=red

" Display tabs at the beginning of a line in Python mode as bad.
au BufRead,BufNewFile *.py,*.pyw match BadWhitespace /^\t\+/
" Make trailing whitespaces be flagged as bad.
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

" yaml syntax
" https://www.vim.org/scripts/script.php?script_id=739
" wget https://www.vim.org/scripts/download_script.php?src_id=2249 -O ~/.vim/yaml.vim
"au BufNewFile,BufRead *.yaml,*.yml so $MYSHELLCONFIG_BASE/.vim/yaml.vim

autocmd BufRead,BufNewFile /etc/exim* set filetype=exim
autocmd BufRead,BufNewFile *.yaml,*.yml  set filetype=yaml

"------
" in makefiles, dont't expand tabs to spaces, since actual tab characters are
" needed, and have indentation at 8 chars to be sure that all indents are tabs
" (despite the mappings later):
autocmd FileType make set noexpandtab shiftwidth=8 softtabstop=0

" two space indentation for some files
autocmd FileType vim,lua,nginx set shiftwidth=2 softtabstop=2

augroup filetype
    autocmd BufNewFile,BufRead *.txt set filetype=human
augroup END

autocmd FileType human set formatoptions-=t textwidth=0 "disable wrapping in txt


autocmd BufRead,BufNewFile *.conf setf dosini

" to make comments better visible on dark backgrounds
:color desert

if has('gui_running')
  set background=dark
  colorscheme solarized
else
  if !empty(glob("~/vim//bundle/Zenburn/colors/zenburn.vim"))
    colorscheme zenburn
  endif
endif

if !empty(glob("~/.vim/bundle/vim-togglebg"))
  call togglebg#map("<F5>")
endif



" Commands

" Sample command W
 
command W :execute ':silent w !sudo tee % > /dev/null' | :edit!

let python_highlight_all=1
syntax on

let NERDTreeIgnore=['\.pyc$', '\~$'] "ignore files in NERDTree




" Code from:
" http://stackoverflow.com/questions/5585129/pasting-code-into-terminal-window-into-vim-on-mac-os-x
" then https://coderwall.com/p/if9mda
" and then https://github.com/aaronjensen/vimfiles/blob/59a7019b1f2d08c70c28a41ef4e2612470ea0549/plugin/terminaltweaks.vim
" to fix the escape time problem with insert mode.
"
" Docs on bracketed paste mode:
" http://www.xfree86.org/current/ctlseqs.html
" Docs on mapping fast escape codes in vim
" http://vim.wikia.com/wiki/Mapping_fast_keycodes_in_terminal_Vim

"if exists("g:loaded_bracketed_paste")
"  finish
"endif
"let g:loaded_bracketed_paste = 1

"function! WrapForTmux(s)
"  if !exists('$TMUX') || !exists('$SCREEN')
"    return a:s
"  endif
"
"  let tmux_start = "\<Esc>Ptmux;"
"  let tmux_end = "\<Esc>\\"
"
"  return tmux_start . substitute(a:s, "\<Esc>", "\<Esc>\<Esc>", 'g') . tmux_end
"endfunction
"
"let &t_SI .= WrapForTmux("\<Esc>[?2004h")
"let &t_EI .= WrapForTmux("\<Esc>[?2004l")
"
"inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()
"
"function! XTermPasteBegin()
"  set pastetoggle=<Esc>[201~
"  set paste
"  "return "a:ret"
"  return ""
"endfunction

" write .netrwhist to cache-dir instead of ~/.vim to prevent configcheckout
" problems
let g:netrw_home=$XDG_CACHE_HOME.'/vim'
"let g:nerdtree_tabs_open_on_console_startup=1
let g:nerdtree_tabs_open_on_console_startup=0

let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ 'Ignored'   : '☒',
    \ "Unknown"   : "?"
    \ }

" (a heavy feature may cost much more time)
"let g:NERDTreeShowIgnoredStatus = 1 

"If the {lhs} key sequence of a map command starts with the string "<Leader>", 
"then Vim replaces it with the key set in the 'mapleader' variable. 
"The default setting for the 'mapleader' variable is backslash ('\'). 
"Note that 'mapleader' is a Vim variable and not a Vim option. 
"The value of this variable can be changed using the 'let' command. For example, 
"to set it to '_' (underscore), you can use the following command in your vimrc file: 
let mapleader = "_"

map <Leader>n <plug>NERDTreeTabsToggle<CR>

" from https://vim.fandom.com/wiki/Modeline_magic
" Append modeline after last line in buffer.
" Use substitute() instead of printf() to handle '%%s' modeline in LaTeX
" files.
function! AppendModeline()
  let l:modeline = printf(" vim: set ts=%d sw=%d tw=%d %set :",
        \ &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
  let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
  call append(line("$"), l:modeline)
endfunction
nnoremap <silent> <Leader>ml :call AppendModeline()<CR>

" Tabhandling
set switchbuf=usetab
noremap <F8> :sbnext<CR>
noremap <S-F8> :sbprevious<CR>
noremap <C-S-Tab> :tabprevious<CR>
noremap <C-Tab> :tabnext<CR>
noremap <silent> <C-A-S-Tab> :execute 'silent! tabmove' . (tabpagenr()-2)<CR>
noremap <silent> <C-A-Tab> :execute 'silent! tabmove' . (tabpagenr()+1)<CR>
