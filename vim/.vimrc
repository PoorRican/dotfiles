"           ██
"          ░░
"  ██    ██ ██ ██████████  ██████  █████
" ░██   ░██░██░░██░░██░░██░░██░░█ ██░░░██
" ░░██ ░██ ░██ ░██ ░██ ░██ ░██ ░ ░██  ░░
"  ░░████  ░██ ░██ ░██ ░██ ░██   ░██   ██
"   ░░██   ░██ ███ ░██ ░██░███   ░░█████
"    ░░    ░░ ░░░  ░░  ░░ ░░░     ░░░░░
"
" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" set leader key to comma
let mapleader=","

colorscheme sourcerer

" Turn off swap files
set noswapfile
set nobackup
set nowb

" fuzzy find
set path+=**

" ignore files vim doesnt use
set wildignore+=.git,.hg,.svn
set wildignore+=*.aux,*.out,*.toc
set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest,*.rbc,*.class
set wildignore+=*.ai,*.bmp,*.gif,*.ico,*.jpg,*.jpeg,*.png,*.psd,*.webp
set wildignore+=*.avi,*.divx,*.mp4,*.webm,*.mov,*.m2ts,*.mkv,*.vob,*.mpg,*.mpeg
set wildignore+=*.mp3,*.oga,*.ogg,*.wav,*.flac
set wildignore+=*.eot,*.otf,*.ttf,*.woff
set wildignore+=*.doc,*.pdf,*.cbr,*.cbz
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz,*.kgb
set wildignore+=*.swp,.lock,.DS_Store,._*

" Completion
set wildmode=list:longest
set wildmenu                " enable ctrl-n and ctrl-p to scroll thru matches

" make backspace behave in a sane manner
set backspace=indent,eol,start

" searching
set hlsearch				" highlight searches
set incsearch				" find match while typing

set ignorecase				" ignore case
set smartcase
set infercase

" use indents of 4 spaces
set shiftwidth=4

" tabs are tabs
set expandtab

" an indentation every four columns
set tabstop=4

" let backspace delete indent
set softtabstop=4

" enable auto indentation
set autoindent

" remove trailing whitespaces and ^M chars
augroup ws
  au!
  autocmd FileType c,cpp,java,php,js,json,css,scss,sass,py,rb,coffee,python,twig,xml,yml autocmd BufWritePre <buffer> :call setline(1,map(getline(1,"$"),'substitute(v:val,"\\s\\+$","","")'))
augroup end

" show matching brackets/parenthesis
set showmatch

" disable startup message
set shortmess+=I

" syntax highlighting
syntax on
set synmaxcol=512
filetype plugin on

" highlight cursor
set cursorline

" Scrolling
set scrolloff=8			" Start scrolling when 8 lines away from margins
set sidescrolloff=15
set sidescroll=1

" show line numbers
set number


set nowrap			" No line wrapping
set linebreak			" Wrap lines at convenient points

" show invisibles
set list
set listchars=
set listchars+=tab:·\
set listchars+=trail:·
set listchars+=extends:»
set listchars+=precedes:«
set listchars+=nbsp:░

" split style
set fillchars=vert:▒

set autoread                    " Reload files changed outside vim

set textwidth=80

" Remaps ; to : for easy commands
: nmap ; :

" Run pathogen package manager
execute pathogen#infect()


" Config for vimwiki
let g:vimwiki_list = [{'path': '~/vimwiki/',
                     \ 'syntax': 'markdown', 'ext': '.md'}]

" Stuff for Prose
map <F10> :Goyo <CR>

" Config for VimPencil
augroup pencil
  autocmd!
  autocmd FileType markdown,mkd,vimwiki call pencil#init({'wrap': 'soft'})
  autocmd FileType txt        call pencil#init({'textwidth': 74})
augroup END

func! AsciiMode()
  syntax off
  setlocal virtualedit=all
  setlocal cc=80
  hi ColorColumn ctermbg=8 guibg=8
  autocmd BufWritePre * :%s/\s\+$//e
endfu
com! ASC call AsciiMode()

" ASCII Art Helpers
" This basically manually types Unicode characters
map .\ i<C-v>u2572<Esc>
map ./ i<C-v>u2571<Esc>
map .l i<C-v>u2502<Esc>
map .- i<C-v>u2500<Esc>
map .z i<C-v>u2581<Esc>

