" SearchInRange.vim: Limit search to range when jumping to the next search result.
"
" DEPENDENCIES:
"   - ingo/avoidprompt.vim autoload script
"   - ingo/err.vim autoload script
"   - ingo/msg.vim autoload script
"   - SearchRepeat.vim autoload script (optional integration)
"
" Copyright: (C) 2008-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.019	29-May-2014	Use
"				ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord()
"				to also allow :[range]SearchInRange /{pattern}/
"				argument syntax with literal whole word search.
"	018	26-May-2014	Adapt <Plug>-mapping naming.
"	017	26-Apr-2014	Split off autoload script.
"				Use ingo#err#Set() to abort on errors.
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

function! s:WrapMessage( message )
    if &shortmess !~# 's'
	call ingo#msg#WarningMsg(a:message)
    else
	call ingo#avoidprompt#EchoAsSingleLine(':' . b:startLine . ',' . b:endLine . '/' . @/)
    endif
endfunction

function! s:MoveToRangeStart()
    call cursor(b:startLine, 1)
endfunction
function! s:MoveToRangeEnd()
    call cursor(b:endLine, 1)
    call cursor(b:endLine, col('$'))
endfunction
function! SearchInRange#SearchInRange( isBackward )
    if ! exists('b:startLine') || ! exists('b:endLine')
	call ingo#err#Set('Define range with :SearchInRange first!')
	return 0
    endif

    let l:count = v:count1
    let l:save_view = winsaveview()
    let l:message = ['echo', ':' . b:startLine . ',' . b:endLine . '/' . ingo#avoidprompt#TranslateLineBreaks(@/)]

    while l:count > 0 && l:message[0] !=# 'error'
	let [l:prevLine, l:prevCol] = [line('.'), col('.')]

	if l:prevLine < b:startLine
	    call s:MoveToRangeStart()
	elseif l:prevLine > b:endLine
	    call s:MoveToRangeEnd()
	endif

	let l:line = search( @/, (a:isBackward ? 'b' : '') )
	if l:line == 0
	    " No match, not even outside the range.
	    let l:message = ['error', 'Pattern not found: ' . @/]
	else
	    if ! a:isBackward && (l:line < b:startLine || l:line > b:endLine)
		" We moved outside the range, restart at start of range.
		call s:MoveToRangeStart()
		let l:line = search( @/, '' )

		if l:line > b:endLine
		    " Only matches outside of range.
		    let l:message = ['error', 'Pattern not found in range ' . b:startLine . ',' . b:endLine . ': ' . @/]
		else
		    if l:prevLine > b:endLine
			let l:message = ['wrap', 'skipping to TOP of range']
		    else
			let l:message = ['wrap', 'search hit BOTTOM of range, continuing at TOP']
		    endif
		endif
	    elseif a:isBackward && (l:line < b:startLine || l:line > b:endLine)
		" We moved outside the range, restart at end of range.
		call s:MoveToRangeEnd()
		let l:line = search( @/, 'b' )

		if l:line < b:startLine
		    " Only matches outside of range.
		    let l:message = ['error', 'Pattern not found in range ' . b:startLine . ',' . b:endLine . ': ' . @/]
		else
		    if l:prevLine < b:startLine
			let l:message = ['wrap', 'skipping to BOTTOM of range']
		    else
			let l:message = ['wrap', 'search hit TOP of range, continuing at BOTTOM']
		    endif
		endif
	    else
		" We're inside the range, check for movements from outside the range
		" and for wrapping inside the range (which can lead to here if all
		" matches are inside the range).
		if l:prevLine < b:startLine || l:prevLine > b:endLine
		    let l:message = ['wrap', (a:isBackward ? 'skipping to BOTTOM of range' : 'skipping to TOP of range')]
		elseif ! a:isBackward && l:line < l:prevLine
		    let l:message = ['wrap', 'search hit BOTTOM, continuing at TOP']
		elseif a:isBackward && l:line > l:prevLine
		    let l:message = ['wrap', 'search hit TOP, continuing at BOTTOM']
		endif
	    endif
	endif
	let l:count -= 1
    endwhile

    if l:message[0] ==# 'error'
	call ingo#err#Set('E486: ' . l:message[1])
	call cursor(l:prevLine, l:prevCol)
	return 0
    endif

    let l:matchPosition = getpos('.')

    " Open fold at the search result, like the built-in commands.
    normal! zv

    " Add the original cursor position to the jump list, like the [/?*#nN]
    " commands.
    " Implementation: Memorize the match position, restore the view to the state
    " before the search, then jump straight back to the match position. This
    " also allows us to set a jump only if a match was found. (:call
    " setpos("''", ...) doesn't work in Vim 7.2)
    call winrestview(l:save_view)
    normal! m'
    call setpos('.', l:matchPosition)

    if l:message[0] ==# 'wrap'
	call s:WrapMessage(l:message[1])
    elseif l:message[0] ==# 'echo'
	call ingo#avoidprompt#Echo(l:message[1])
    endif

    return 1
endfunction

function! SearchInRange#SetAndSearchInRange( startLine, endLine, pattern )
    let l:pattern = ingo#cmdargs#pattern#ParseUnescapedWithLiteralWholeWord(a:pattern)
    let b:startLine = a:startLine
    let b:endLine = a:endLine
    if ! empty(l:pattern)
	let @/ = l:pattern
    endif

    " Integration into SearchRepeat.vim
    silent! call SearchRepeat#Set("\<Plug>(SearchInRangeNext)", "\<Plug>(SearchInRangePrev)", 2)<CR>

    return SearchInRange#SearchInRange(0)
endfunction


function! SearchInRange#Operator( type )
    call SearchInRange#SetAndSearchInRange(line("'["), line("']"), '')
endfunction
function! SearchInRange#OperatorExpr()
    set opfunc=SearchInRange#Operator
    return 'g@'
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
