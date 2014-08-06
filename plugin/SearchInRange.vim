" SearchInRange.vim: Limit search to range when jumping to the next search result.
"
" DEPENDENCIES:
"   - SearchInRange.vim autoload script
"   - ingo/err.vim autoload script
"   - SearchRepeat.vim autoload script (optional integration)
"
" Copyright: (C) 2008-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.019	29-May-2014	Also allow :[range]SearchInRange /{pattern}/
"				argument syntax with literal whole word search.
"   1.00.018	26-May-2014	Adapt <Plug>-mapping naming.
"				Make go... mappings configurable.
"				Adapt to polished SearchRepeat interface.
"	017	26-Apr-2014	Split off autoload script.
"				Abort on errors.
"				Use :map-expr for the operator to also allow a
"				[count] before it.
"   	016	07-Jun-2013	Move EchoWithoutScrolling.vim into ingo-library.
"				Use ingo#msg#WarningMsg().
"	015	24-May-2013	Change <Leader>/ to <Leader>n; / implies
"				entering a new pattern, whereas n is related to
"				the last search pattern, also in [n.
"	014	24-Jun-2012	Don't define the <Leader>/ default mapping in
"				select mode, just visual mode.
"	013	14-Mar-2012	Split off documentation.
"	012	30-Sep-2011	Use <silent> for <Plug> mapping instead of
"				default mapping.
"	011	13-Jul-2010	ENH: Now handling [count].
"				BUG: Fixed mixed up "skipping to TOP/BOTTOM of
"				range" message when the search wraps around.
"				Make s:startLine a buffer variable, so that the
"				range is remembered for each buffer separately.
"				(Linking this to the window doesn't make sense,
"				as the fixed range probably won't apply to a
"				different buffer shown in the same window, and
"				one can easily re-set the range for any new
"				buffer.)
"	010	13-Jul-2010	Refactored so that error / wrap / echo message
"				output is done at the end of the script, not
"				inside the logic.
"				ENH: The search adds the original cursor
"				position to the jump list, like the built-in
"				[/?*#nN] commands.
"	009	17-Aug-2009	BF: Checking for undefined range to avoid "E121:
"				Undefined variable: b:startLine".
"	008	17-Aug-2009	Added a:description to SearchRepeat#Register().
"	007	29-May-2009	Added "go once" mappings that do not integrate
"				into SearchRepeat.vim.
"	006	15-May-2009	BF: Translating line breaks in search pattern
"				via EchoWithoutScrolling#TranslateLineBreaks()
"				to avoid echoing only the last part of the
"				search pattern when it contains line breaks.
"	005	06-May-2009	Added a:relatedCommands to
"				SearchRepeat#Register().
"	004	11-Feb-2009	Now setting v:warningmsg on warnings.
"	003	03-Feb-2009	Added activation mapping to SearchRepeat
"				registration.
"	002	16-Jan-2009	Now setting v:errmsg on errors.
"	001	07-Aug-2008	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_SearchInRange') || (v:version < 700)
    finish
endif
let g:loaded_SearchInRange = 1
let s:save_cpo = &cpo
set cpo&vim

"- commands -------------------------------------------------------------------

command! -nargs=? -range SearchInRange if SearchInRange#SetAndSearchInRange(<line1>,<line2>,<q-args>) | if &hlsearch | set hlsearch | endif | else | echoerr ingo#err#Get() | endif


"- mappings -------------------------------------------------------------------

vnoremap <silent> <Plug>(SearchInRange) :SearchInRange<CR>
if ! hasmapto('<Plug>(SearchInRange)', 'x')
    xmap <Leader>n <Plug>(SearchInRange)
endif

nnoremap <expr> <Plug>(SearchInRangeOperator) SearchInRange#OperatorExpr()
if ! hasmapto('<Plug>(SearchInRangeOperator)', 'n')
    nmap <Leader>n <Plug>(SearchInRangeOperator)
endif

nnoremap <silent> <Plug>(SearchInRangeNext) :<C-u>if SearchInRange#SearchInRange(0)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar>else<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>(SearchInRangePrev) :<C-u>if SearchInRange#SearchInRange(1)<Bar>if &hlsearch<Bar>set hlsearch<Bar>endif<Bar>else<Bar>echoerr ingo#err#Get()<Bar>endif<CR>

if ! hasmapto('<Plug>(SearchInRangeNext)', 'n')
    nmap gor <Plug>(SearchInRangeNext)
endif
if ! hasmapto('<Plug>(SearchInRangePrev)', 'n')
    nmap goR <Plug>(SearchInRangePrev)
endif


"- Integration into SearchRepeat.vim -------------------------------------------

try
    " The user might have mapped these to something else; the only way to be
    " sure would be to grep the :map output. We just include the mapping if it's
    " the default one; the user could re-register, anyway.
    let s:mapping = (exists('mapleader') ? mapleader : '\') . '/'
    let s:mapping = (maparg(s:mapping, 'n') ==# '<Plug>(SearchInRangeOperator)' ? s:mapping : '')

    call SearchRepeat#Define(
    \   '<Plug>(SearchInRangeNext)', s:mapping, 'r', '/range/', 'Search forward in range', ':[range]SearchInRange [/][{pattern}][/]',
    \   '<Plug>(SearchInRangePrev)', '',        'R', '?range?', 'Search backward in range', '',
    \   2
    \)
catch /^Vim\%((\a\+)\)\=:E117/	" catch error E117: Unknown function
finally
    unlet! s:mapping
endtry

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
