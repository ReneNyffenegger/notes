" vim: ft=vim
"
" This file is source by
"   $github_root/Bibelkommentare/mappings.vim
"   ~/.vim/ftplugin/notes.vim
"
call TQ84_log_indent(expand('<sfile>'))
try

" Use forward slashes
"
" TODO This is a global option. It should be
" reset when going to another buffer.
"
call TQ84_log('set shellslash, was ' . &shellslash)
setl shellslash

" http://vi.stackexchange.com/questions/7478/how-do-i-exclude-the-%E2%86%92-from-file-name-characters
call TQ84_log('set includeexpr, was ' . &includeexpr)
set includeexpr=substitute(v:fname,'^→','','')

call TQ84_log('set ff=unix, was ' . &ff)
set ff=unix

nnoremap <buffer> gf    :call tq84#notes#gotoFileUnderCursor(v:false)<CR>
nnoremap <buffer> gF    :call tq84#notes#gotoFileUnderCursor(v:true )<CR>
nnoremap <buffer> <TAB> :call tq84#notes#tabPressed()<CR>

catch

  call TQ84_log('caught: ' . v:exception)

endtry


setl omnifunc=tq84#notes#omnifunc
set  path=,,**

call TQ84_log_dedent()
