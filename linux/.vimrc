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
set foldmethod=syntax
set foldlevelstart=10

if has('win32')
  let &shell = executable('pwsh') ? 'pwsh' : 'powershell'
  let &shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
  let &shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait'
  let &shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  set shellquote= shellxquote=
else
  set shell=bash
endif

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
    if has('win32')
      let s:editor_root=expand('~/AppData/Local/nvim')
    else
      let s:editor_root=expand('~/.config/nvim')
    endif
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

let plug_path=s:editor_root . '/autoload/plug.vim'
if empty(glob(plug_path))
  autocmd VimEnter * echom 'Downloading and installing vim-plug...'
  let plug_url='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  if has('win32')
    silent execute '!New-Item -Type Directory -Force -Path ([System.IO.FileInfo]"' . plug_path . '").Directory'
    silent execute '!Invoke-WebRequest -UseBasicParsing -Uri "' . plug_url . '" -OutFile "' . plug_path . '"'
  else
    silent execute '!curl -fLo ' . plug_path . ' --create-dirs ' . plug_url
  endif
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
Plug 'base16-project/base16-vim'
Plug 'preservim/nerdtree', { 'on': ['NERDTree', 'NERDTreeToggle', 'NERDTreeFind'] } | Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'preservim/nerdcommenter'
"Plug 'junegunn/vim-slash'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' } | Plug 'junegunn/fzf.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'powerline/powerline-fonts', { 'do': './install.sh' }
Plug 'groenewege/vim-less', { 'for': 'less' }
Plug 'janko-m/vim-test'
Plug 'machakann/vim-highlightedyank'

" Language support
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
nmap yp :let @+ = expand("%")<CR>
nmap yP :let @+ = expand("%:p")<CR>
nmap <silent> <leader>t :TestNearest<CR>
nmap <silent> <leader>tf :TestFile<CR>
nmap <silent> <leader>ta :TestSuite<CR>
nmap <silent> <leader>tl :TestLast<CR>
nmap <silent> <leader>tg :TestVisit<CR>
map <leader>m :call ToggleMouse()<CR>
map <leader>ln :NumbersToggle<CR>
nmap <C-_> <Plug>NERDCommenterToggle
vmap <C-_> <Plug>NERDCommenterToggle<CR>gv

"let g:fzf_nvim_statusline = 0
nnoremap <silent> <C-P> :Files<CR>
let $FZF_DEFAULT_COMMAND = 'ag -g ""'

" NERDCommenter
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
function! JsonCompress()
  execute "%!jq --compact-output ."
endfunction
noremap <Leader>jf :call JsonFormat(2)<CR>
noremap <Leader>jF :call JsonCompress()<CR>

" Syntax highlighting for weird files
autocmd BufReadPost *.ipynb set syntax=json " Synapse Analytics notebooks
autocmd BufReadPost *.bim set syntax=json " Analysis Services model files
autocmd BufReadPost *.keymap set syntax=c " ZMK keymap files

noremap J <Nop>
noremap K <Nop>
