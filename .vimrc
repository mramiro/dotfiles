syntax on
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set smarttab
set hidden
set mouse=a
set showcmd
set updatetime=500
set number
set listchars=tab:▸\ ,eol:¬,space:·
set clipboard=unnamedplus
set shell=sh
set foldmethod=syntax

function! ToggleMouse()
  if !exists("s:old_mouse")
    let s:old_mouse = "a"
  endif

  if &mouse == ""
    let &mouse = s:old_mouse
    echo "Mouse is for Vim (" . &mouse . ")"
  else
    let s:old_mouse = &mouse
    let &mouse=""
    echo "Mouse is for terminal"
  endif
endfunction

if has('nvim')
  if empty($XDG_CONFIG_HOME)
    let s:editor_root=expand('~/.config/nvim')
  else
    let s:editor_root=expand($XDG_CONFIG_HOME . '/nvim')
  endif
  if empty($XDG_DATA_HOME)
    let s:data_root=expand('~/.local/share/nvim')
  else
    let s:data_root=expand($XDG_DATA_HOME . '/nvim')
  endif
else
  let s:editor_root=expand('~/.vim')
  let s:data_root=s:editor_root
endif

if empty(glob(s:editor_root . '/autoload/plug.vim'))
  autocmd VimEnter * echom 'Downloading and installing vim-plug...'
  silent execute '!curl -fLo ' . s:editor_root . '/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin(s:data_root . '/plugged')

Plug 'tpope/vim-surround'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-abolish'
Plug 'tommcdo/vim-fubitive' "Bitbucket support for fugitive
"Plug 'xolox/vim-session' | Plug 'xolox/vim-misc'
Plug 'mhinz/vim-startify'
Plug 'mattn/emmet-vim'
Plug 'airblade/vim-gitgutter'
Plug 'myusuf3/numbers.vim'
"Plug 'yggdroot/indentline'
Plug 'bronson/vim-visual-star-search'
Plug 'editorconfig/editorconfig-vim'
Plug 'Chiel92/vim-autoformat'
Plug 'chriskempson/base16-vim'
Plug 'scrooloose/nerdtree', { 'on': ['NERDTree', 'NERDTreeToggle', 'NERDTreeFind'] } | Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'scrooloose/nerdcommenter'
"Plug 'junegunn/vim-slash'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' } | Plug 'junegunn/fzf.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'powerline/powerline-fonts', { 'do': './install.sh' }
Plug 'groenewege/vim-less', { 'for': 'less' }
Plug 'janko-m/vim-test'
Plug 'machakann/vim-highlightedyank'

" Languague support
Plug 'nelsyeung/twig.vim'
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'elzr/vim-json', { 'for': 'json' }
Plug 'pedrohdz/vim-yaml-folds'
Plug 'PProvost/vim-ps1'
Plug 'dag/vim-fish'

if has('nvim')
  Plug 'w0rp/ale'
  let g:ale_sign_column_always = 1
  let g:ale_linters = { 'java': ['checkstyle'] }
  let g:ale_java_checkstyle_options = '-c tests/checkstyle.xml'
  Plug 'vimlab/split-term.vim'
  set splitbelow
else
  Plug 'scrooloose/syntastic'
  set statusline+=%#warningmsg#
  set statusline+=%{SyntasticStatuslineFlag()}
  set statusline+=%*
  let g:syntastic_always_populate_loc_list = 1
  let g:syntastic_auto_loc_list = 1
  let g:syntastic_check_on_open = 1
  let g:syntastic_check_on_wq = 0
  let g:syntastic_php_checkers = ['php']
endif

call plug#end()
let g:indentLine_leadingSpaceChar = '·'
let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

let g:gitgutter_realtime=1

if has('nvim')
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif
if has('termguicolors')
  set termguicolors
else
  set t_Co=256
endif
colorscheme base16-tomorrow-night
let g:airline_theme='base16_tomorrow'

let g:enable_numbers = 0

" Startify
let g:startify_bookmarks = [ {'v': '$MYVIMRC'} ]
let g:startify_change_to_dir = 0
let g:startify_session_dir = s:data_root . '/session'


noremap <leader>ne :NERDTreeToggle<CR>
noremap <leader>nf :NERDTreeFind<CR>
noremap <C-X> :bprev<bar>bd#<CR>
noremap <leader><C-X> :bprev<bar>bd!#<CR>
noremap <C-J> :bnext<CR>
noremap <C-K> :bprev<CR>
noremap <leader>i :set list!<CR>
nnoremap <esc><esc> :noh<CR>
nmap <silent> <leader>t :TestNearest<CR>
nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>ta :TestSuite<CR>
nmap <silent> <leader>tl :TestLast<CR>
nmap <silent> <leader>tg :TestVisit<CR>
map <leader>m :call ToggleMouse()<CR>
map <leader>ln :NumbersToggle<CR>

"let g:fzf_nvim_statusline = 0
nnoremap <silent> <C-P> :Files<CR>

" NERDCommenter"
let g:NERDDefaultAlign = 'left'
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDCustomDelimiters = {'python': { 'left': '#', 'right': '' }}

" NERDTree
let NERDTreeHijackNetrw=1
let NERDTreeMinimalUI=1
let NERDTreeDirArrows=1
let NERDTreeShowHidden=1
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" This opens NERDtree when opening a dir with vim
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif

" https://github.com/junegunn/fzf/issues/453 
autocmd FileType nerdtree let t:nerdtree_winnr = bufwinnr('%')
autocmd BufWinEnter * call PreventBuffersInNERDTree()
function! PreventBuffersInNERDTree()
  if bufname('#') =~ 'NERD_tree' && bufname('%') !~ 'NERD_tree'
    \ && exists('t:nerdtree_winnr') && bufwinnr('%') == t:nerdtree_winnr
    \ && &buftype == '' && !exists('g:launching_fzf')
    let bufnum = bufnr('%')
    close
    exe 'b ' . bufnum
    NERDTree
  endif
  if exists('g:launching_fzf') | unlet g:launching_fzf | endif
endfunction
" autocmd BufEnter * if bufname('#') =~ 'NERD_tree' && bufname('%') !~ 'NERD_tree' && winnr('$') > 1 | b# | exe "normal! \<c-w>\<c-w>" | :blast | endif

function! JsonFormat(spaces)
  execute "%!jq --indent " . a:spaces . " ."
endfunction
noremap <Leader>jf :call JsonFormat(2)<CR>
