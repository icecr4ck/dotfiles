set ruler
set cursorline
set encoding=utf-8
execute pathogen#infect()
syntax on
filetype plugin indent on

syntax enable
let g:solarized_termtrans = 1
set background=dark
colorscheme solarized

set backspace=indent,eol,start

set laststatus=2
let g:airline_theme='solarized'
let g:airline_powerline_fonts = 1

set relativenumber
