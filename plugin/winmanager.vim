"=============================================================================
" File: winmanager.vim
" Author: Srinath Avadhanula (srinath@eecs.berkeley.edu)
"   (this plugin utilizes the bufexplorer.vim made by Jeff Lanzarotta
"   and the file explorer made by M A Aziz Ahmed  and Mark Waggoner)
" Help:
" winmanager.vim is a plugin which implements a classical windows type IDE in
" Vim-6.0.  When you open up a new file, simply type in :WManager. This will
" start up the file explorer.
" ============================================================================
" Commands:
" WManager : (re)starts the Windows manager
" WMClose : closes the file and buffer explorer areas
" GotoBufExplorerWindow : directly takes you to the buffer list window.
"   its useful to put the following mapping in your .vimrc if you frequently
"   travel back and forth between file editing and the buffer list
"
"   map <c-w><c-b> :GotoBufExplorerWindow<cr>
"
" GotoFileExplorerWindow : directly takes you to the file explorer window.
"   its useful to put the following mapping in your .vimrc if you frequently
"   travel back and forth...
"
"   map <c-w><c-f> :GotoFileExplorerWindow<cr>
" ============================================================================
" Options:
" the values of the following global variables should be set in your .vimrc
" file if you want a different value than the default:
"
" g:persistentBehaviour: if set to 0, then as soon as you quit all the files
"    and only the explorer windows are the ones left, vim will quit. the
"    default is 1.
" g:bufExplorerWidth: the width of the file and buffer explorer areas.
"    (default 25)
" g:bufExplorerMaxHeight: the buffer list window dynamicall rescales itself to
"    occupy only the minimum space required to display all the windows. you
"    can set a maximum number of lines for this window. (defualt 15)
"
" =============================================================================
" Detailed Help:
" when winmanager starts up, it divides the whole vim window into
" 3 ''regions'', shown below. The mappings which work in each area
" are explained below
"
"              +----+-------------------+
"              |    |                   |
"              |    |      3(i)         |
"              | 1  |                   |
"              |    +-------------------+
"              |    |                   |
"              +----+      3(ii)        |
"              | 2  |                   |
"              +----+-------------------+
"
" 1: File Explorer Area
" it displays the current directory structure. its a modification of the
" standard explorer.vim which ships with vim6.0. the following actions can be
" taken in this area
" <enter> : if on a directory, enters it and displays it in the same area. If
"           on a file, then opens it in the File Editing Area. Attempts to open in the
"           same window as the one visited before, otherwise split open a new window
"           horizontally.
" <tab> : open the file or directory in a new window in the FileEditing area.
" c : change the pwd to the directory currently displayed
" C : change the currently displayed directory to pwd (converse of c)
" s : select sort field (size, date, name)
" r : reverse direction of sort
" R : rename file
" D : delete file
" - : move up one level
"
" 2. Buffer Explorer Area
" <enter> : Attempts to open the file in the same window as the one visited
"           before, otherwise split open a new window horizontally.
" <tab> : open the file in a new window in the FileEditing area.
" s : select sort field (name, buffer number)
" r : reverse direction of sort
" <up>/<down>/i/j : echoes the full file name of the buffer under the cursor.
"       this enables only the last part of the file name to displayed in the
"       explorer window itself so that it can be kept narrow.
"
" This window is dynamically rescaled and re-displayed. i.e, when a new window
" opens somehwere, the buffer list is automatically updated. also, it tries to
" occupy the minimum possible space required to display the files.
"
" 3.
" File Editing Area The area where normal editing takes place. The commands in
" the File Explorer and Buffer Explorer shouldnt affect the layout of the
" windows here. Two mappings which I find useful (which should be placed in
" your .vimrc if you plan on using WManager often) is:
"
" map <c-w><c-b> :GotoBufExplorerWindow<cr>
" map <c-w><c-f> :GotoFileExplorerWindow<cr>
"
" Pressing CTRL-W-B should then take you directly to the buffer list area
" where you can switch easily between buffers. Similarly pressing
" CTRL-W-Fshould take you to the File explorer area.
"
" Last Modification: Dec 13 2001
"===============================================================================

" Has this already been loaded?
if exists("loaded_winmanager")
    finish
endif
let loaded_winmanager = 1

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

"========================Anubhav Adds================================
fun! Explore_Dir(dir)
        if !exists('s:winManagerVisible')
		let curdir=getcwd()
		exec "cd ".a:dir
		call <SID>StartWindowsManager()
		let s:winManagerVisible = 1
	elseif !s:winManagerVisible
		let curdir=getcwd()
		exec "cd ".a:dir
		call <SID>StartWindowsManager()
		let s:winManagerVisible = 1
	else
	 	exec "GotoFileExplorerWindow"
		let curdir=getcwd()
		exec "cd ".a:dir
		exec "normal C"
        endif
endfun	
"=====================End Anubhav Adds=============

if !exists("g:bufExplorerWidth")
	let g:bufExplorerWidth = 25
end
if !exists("g:bufExplorerMaxHeight")
	let g:bufExplorerMaxHeight = 15
end
if !exists("g:persistentBehaviour")
	let g:persistentBehaviour = 1
end

let loaded_winmanager = 1

if !exists(':GotoBufExplorerWindow')
	com -nargs=0 GotoBufExplorerWindow :silent call <SID>GotoBufExplorerWindowFunc()
end
if !exists(':GotoFileExplorerWindow')
	com -nargs=0 GotoFileExplorerWindow :silent call <SID>GotoFileExplorerWindowFunc()
end
if !exists(':WManager')
	command -nargs=0 WManager :silent call <SID>StartWindowsManager()
end
if !exists(':WMClose')
	command -nargs=0 WMClose :silent call <SID>CloseExplorerWindows()
end
if !exists(':WMToggle')
	command -nargs=0 WMToggle :silent call <SID>ToggleWindowsManager()
end
map <unique> <script> <Plug>StartWinManager :call <SID>StartWindowsManager()<cr>

let s:firstTime = 1
let s:debug = 0

" function for toggling between the open and close status of winmanager.
function! <SID>ToggleWindowsManager()
	if !exists('s:winManagerVisible')
		call <SID>StartWindowsManager()
		let s:winManagerVisible = 1
	elseif !s:winManagerVisible
		call <SID>StartWindowsManager()
		let s:winManagerVisible = 1
	else
		call <SID>CloseExplorerWindows()
		let s:winManagerVisible = 0
	end
endfunction

function! <SID>StartWindowsManager()

	" open explorer window
	if s:firstTime
		let s:currentBufferNumber = bufnr("%")
		let s:alternateBufferNumber = bufnr("#")
	end
	if !exists('s:MRUlist')
		call <SID>InitializeMRUList()
	end

	" dumbness check: user does WMa even though he can see the fricking
	" things. actually not so dumb... maybe user only closed one of the
	" explorer windows... i.e only fileexplorer. then might do WMa by
	" instinct.
	
	let s:commandRunning = 1
	" call s:PrintError('setting command running...')

	" START setting up window layout..
	if !exists('s:bufExplorerBufNum') || bufwinnr(s:bufExplorerBufNum) == -1
		" if bufexplorer window is not visible, then open it again, but do the
		" vsplit thing only if the fileexplorer window is also invisible.
		let save_split = &splitbelow
		if (!exists('s:fileExplorerBufNum') || bufwinnr(s:fileExplorerBufNum) == -1)
			" spliting with	a file name elegantly fixes the problem of
			" different buffer windows using different buffer numbers.
			vspl [Buf List]
			" move the explorer area to the extreme left
			wincmd H
		else
			call <SID>GotoWindow(bufwinnr(s:fileExplorerBufNum))
			set splitbelow
			spl [Buf List]
		end
		let &splitbelow = save_split
		setlocal nowrap
		setlocal noswapfile
		
		" fix the width of the explorer area
		exec g:bufExplorerWidth.' wincmd |'
		let g:BufExplorerVisible = 1
	else
		call <SID>GotoWindow(bufwinnr(s:bufExplorerBufNum))
		call s:PrintError('here 1 pres winnum = '.bufwinnr(""))
	end

	if !exists('s:fileExplorerBufNum') || bufwinnr(s:fileExplorerBufNum) == -1
		" open the File Explorer Area
		call s:PrintError('here 2 pres winnum :'.bufwinnr(""))
		let savesplit = &splitbelow
		set nosplitbelow
		25spl [File List]
		let &splitbelow = savesplit
		let g:FileExplorerVisible = 1
	else
		call <SID>GotoWindow(bufwinnr(s:fileExplorerBufNum))
	end
	" END setting up window layout.

	let w:completePath = s:Path(getcwd())
	if !exists("s:numFileBuffers")
		call s:DisplayFileList(getcwd())
		let w:completePath = s:Path(getcwd())
		let saverega = @a
		normal! ggVG"ay
		let s:numFileBuffers = 1
		call s:PrintError('setting s:dir_'.s:numFileBuffers)
		exec 'let s:dir_'.s:numFileBuffers.' = w:completePath'
		exec 'let s:FileList_'.s:numFileBuffers.' = @a'
		let s:currentFileNumberDisplayed = 1
		let @a = saverega
		0
		/^"=/+1
	else
		call s:PrintError('WMa: calling redisplay')
		call s:ReDisplayFileList(getcwd())
	end

	" escape special characters for exec commands
	let w:completePathEsc=escape(w:completePath,s:escfilename)
	let b:parentDirEsc=substitute(w:completePathEsc, '/[^/]*/$', '/', 'g')
	

	setlocal nobuflisted
	setlocal nowrap
	setlocal noswapfile
	let s:fileExplorerBufNum = bufnr("%")
	let s:fileExplorerWinNum = bufwinnr("")

	wincmd j
	let s:bufExplorerBufNum = bufnr("%")
	let s:bufExplorerWinNum = bufwinnr("")
	setlocal nobuflisted
	nnoremap <buffer> <cr> silent call <SID>GotoFile_LsExplore(0)<cr>
	call <SID>DisplayBuffers()
	call <SID>ResizeBufExplorerWin()
	0

	call <SID>GotoWindow(bufwinnr(s:currentBufferNumber))
	call <SID>RefreshBufferList("1winEnter")

	let s:lastFileAreaWinNum = bufwinnr("")

	if s:firstTime
		au BufEnter * silent call <SID>RefreshBufferList("2bufEnter")
	end

	let s:firstTime = 0
	call s:PrintError('StartWindowsManager: command running = 0')
	let s:commandRunning = 0
endfunction

function! <SID>RefreshBufferList(eventName)

	" while processing the commands here, the bufEnter even is triggered quite
	" a few times. dont want to be calling ourselves.
	if exists("s:commandRunning") && s:commandRunning
		return
	end
	" set commandRunning so we never get through again while in this function
	let s:commandRunning = 1

	" proceed only if BufExplorerArea is open

	" only do refreshing if the bufExplorer window is visible.
	if !exists(":vsplit") || bufwinnr(s:bufExplorerBufNum) == -1 || !exists("s:bufExplorerBufNum")
		return
	end

	if s:debug == 1
		if !exists("g:numEvents")
			let g:numEvents = 0
			let g:eventNames = " "
		end
		let g:numEvents = g:numEvents + 1
		let g:eventNames = g:eventNames . a:eventName[0]
		call <SID>PrintError("proceeding with event ".a:eventName)
	end

	let _buf = @"

	let s:currentWindowNumber = bufwinnr("")
	let s:callingBufferNumber = bufnr("%")

	" change the current and alternate buffer numbers but only if we are
	" changing into a different listed buffer... this helps by making help
	" files not creep into the # & % registers.
	if buflisted(bufnr("%")) &&	s:currentBufferNumber != bufnr("%")
		let s:alternateBufferNumber = s:currentBufferNumber
		let s:currentBufferNumber = bufnr("%")
		call <SID>PushToFront()
	end

	" remember the last window which we visited in the FileExplorer area
	let thisWinNum = bufwinnr("")
	if	thisWinNum != s:fileExplorerWinNum && thisWinNum != s:bufExplorerWinNum
		let s:lastFileAreaWinNum = thisWinNum
	end

	if <SID>IsOnlyOtherBufferVisible(bufnr("%")) && !buflisted(bufnr("%")) && !g:persistentBehaviour
		qall
	end

	" if this is a listed buffer and we do not have any adjacent (right or
	" left) neighbours, (happens when we try to open a new buffer with only
	" the file and bufer explorers visible) then create the original explorer
	" layout.
	if buflisted(bufnr("%")) && winwidth(0) == &columns
		wincmd L
		call <SID>GotoWindow(bufwinnr(s:bufExplorerBufNum))
		exec g:bufExplorerWidth.'wincmd |'
		if bufwinnr(s:fileExplorerBufNum) == -1
			25spl [File List]
			call <SID>ReDisplayFileList(getcwd())
		end
	end

	" move to the explorer window. the if statement is actually
	" just a precaution. the parent if statement in which this block is nested
	" should automatically make this always evaluate to 1.
 	if !<SID>GotoWindow(bufwinnr(s:bufExplorerBufNum))
 		let v:errmsg = "At last Count: explorer window *not* found"
 		return
 	end
	" let s:fileMaxLen = 15

	call <SID>DisplayBuffers()
	0
" 	call <SID>PrintError("Calling resize function")
	call <SID>ResizeBufExplorerWin()

	if !exists("s:lastBufPosition")
		let s:lastBufPosition = 4
	end
	if s:lastBufPosition > line('$')
		let s:lastBufPosition = line('$')
	end
	exec s:lastBufPosition

	" return to the original window
	call <SID>GotoWindow(bufwinnr(s:callingBufferNumber))
	" call <SID>GotoWindow(bufwinnr(s:currentBufferNumber))

	" protect the # if we are leaving fileExplorer or bufExplorer
	if buflisted(bufnr("%"))
		call <SID>EditFile(s:currentBufferNumber, '')
	end

	" reset registers value and free temp variables
	let @" = _buf
	unlet _buf
	let s:commandRunning = 0

endfunction

function! <SID>ResizeBufExplorerWin()
	" modify window height so that it's not more or less than
	" max(#lines in buffer, maximum height set) but only when theres
	" another window above this to take the heat...
	let thisWinNum = bufwinnr("")
	wincmd k
	if thisWinNum != bufwinnr("")
		wincmd j
		let targetNLines = line("$")
		if g:bufExplorerMaxHeight =~ '[0-9]\+' && targetNLines > g:bufExplorerMaxHeight
			let targetNLines = g:bufExplorerMaxHeight
		end
		exec targetNLines.' wincmd _'
		normal! 0
	end
endfunction

function! <SID>EditFile(bufNum,bufName)
	" quickly edit the alternate buffer previously being edited in the
	" FileExplorer area so that the % and # registers are not scrwed with.
	" this is important especially when opening files from the FileExplorer
	" or BufExplorer areas.

	let _hidden = &hidden
	set hidden
 	if s:alternateBufferNumber != bufnr("#") && s:alternateBufferNumber != -1 && buflisted(s:alternateBufferNumber)
 		exec 'b! '.s:alternateBufferNumber
 	end
 	" now edit the current file number under consideration.
 	if a:bufNum != -1 && a:bufNum != bufnr("%")
 		exec 'b! '.a:bufNum
 	elseif a:bufNum != bufnr("%")
		exec('silent e '.escape(a:bufName,s:escfilename))
 	end
	let &hidden = _hidden
endfunction

function! <SID>GotoFile_LsExplore(split)
	let l = getline(".")
	if l =~ '^"'
		return
	endif

	" extract the buffer number
	let presLine = getline('.')
	let s:lastBufPosition = line('.')
	let s:commandRunning = 1

	" extract the file number under the cursor.
	" slightly different when opened from FileExplorer or
	" BufferExplorer.
	if bufnr("%") == s:fileExplorerBufNum
		normal! 0
		let bufName = s:GetFullFileName()
		let bufNum = bufnr(bufName)
		if expand("#".bufNum.":p") != bufName
			let bufNum = -1
		end
	else
		let bufNum = <SID>ExtractFileNumber(presLine)
		let bufName = bufname(bufNum)
	end
	" window number incase the file is already open in some window
	let winNum = bufwinnr(bufNum)

	" if file in question is already visible in some window, just go there.
	" otherwise goto last file visited in FileEditing area.
 	if winNum != -1
 		call <SID>GotoWindow(winNum)
 	else
 		" move to the fileEditing Area when either
 		" 1. we are in the buffer Explorer Area
 		" 2. the user has requested an explicit split while in the
		"	fileExplorer Area
 		" 3. we are currently on a file name in the fileExplorer area.
 		if !(bufName =~ '[\\/]$') || a:split || bufnr("%") == s:bufExplorerBufNum
 			let currentWindowNumber = bufwinnr("")
			call <SID>GotoWindow(bufwinnr(s:currentBufferNumber))
			if bufwinnr("") == currentWindowNumber && bufnr("%") == s:bufExplorerBufNum
				" the user pressed <return> while in the buffer explorer area and
				" there was no window to the right.
				let s:currentBufferNumber = bufNum
				call <SID>RedoBufferList()
				exec 'vspl '.bufname(bufNum)
				call <SID>EditFile(bufNum, bufName)
				wincmd L
				wincmd p
				exe g:bufExplorerWidth.'wincmd |'
				0
				wincmd p
				return
			end
 			"if expand("<cfile>") =~ '[\\/]$'
 			if a:split || (&modified && &hidden == 0)
 				new
 			end
 		else
 			" the user is on a directory and has pressed <cr>
 			" therefore display the new directory in the same window.
			" let w:completePath = s:Path(bufName)
			" call <SID>PrintError("bufname = ".bufName." setting path to ".w:completePath)
 			call <SID>ReDisplayFileList(bufName)
 			return
 		end
 	end

	call <SID>EditFile(bufNum, bufName)
	let s:commandRunning = 0
	call <SID>RefreshBufferList("2bufEnter")
endfunction

" should be called only when in the bufExplorer buffer
function! <SID>RedoBufferList()
	setlocal modifiable
	1,$d _
	call <SID>BufEx_AddHeader()
	$ d _
	call <SID>ShowBuffers()
	normal! zz
	setlocal nomodifiable
	exec g:bufExplorerWidth.'wincmd |'
endfunction

function! <SID>EchoFileName()
	let bufNum = <SID>ExtractFileNumber(getline('.'))
	if bufNum
		echo expand("#".bufNum.":p")
	else
		echo ""
	end
endfunction

function! <SID>GetBufNumFromWinNum(winNum)
	let _NBuffers = bufnr("$")	" Get the number of the last buffer.
	let _i = 0					" Set the buffer index to zero.

	" Loop through every buffer less than the total number of buffers.
	while(_i <= _NBuffers)
		let _i = _i + 1
		if bufwinnr(_i) == a:winNum
			return _i
		endif
	endwhile
	return 0
endfunction

" is this the only buffer apart from the file and buffer explorer which is
" visible?
function! <SID>IsOnlyOtherBufferVisible(bufNumber)
	let _NBuffers = bufnr("$")	" Get the number of the last buffer.
	let _i = 0					" Set the buffer index to zero.
	while(_i <= _NBuffers)
		let _i = _i + 1
		if bufwinnr(_i) != -1 && _i != a:bufNumber && buflisted(_i)
			return 0
		end
	endwhile
	return 1
endfunction

function! <SID>GotoWindow(reqdWinNum)
	let startWinNum = bufwinnr("")
	while bufwinnr("") != a:reqdWinNum
		wincmd w
		if bufwinnr("") == startWinNum
			let v:errmsg = "Couldn't find window ".a:reqdWinNum
			return 0
		endif
	endwhile
	return 1
endfunction

function! <SID>GotoBufExplorerWindowFunc()
	if bufwinnr(s:bufExplorerBufNum) != -1
		let s:commandRunning = 1
 		call <SID>GotoWindow(bufwinnr(s:bufExplorerBufNum))
		let s:commandRunning = 0
	endif
endfunction

function! <SID>GotoFileExplorerWindowFunc()
	if bufwinnr(s:fileExplorerBufNum) != -1
		let s:commandRunning = 1
 		call <SID>GotoWindow(bufwinnr(s:fileExplorerBufNum))
		let s:commandRunning = 0
	endif
endfunction

function! <SID>PrintError(eline)
	if !s:debug
		return
	end
	if !exists("g:myerror")
		let g:myerror = ""
	end
	let g:myerror = g:myerror . "\n" . a:eline
endfunction

function! <SID>GetBufferNumber(fname)
	let _NBuffers = bufnr("$")	" Get the number of the last buffer.
	let _i = 0					" Set the buffer index to zero.
	while(_i < _NBuffers)
		let _i = _i + 1
		if bufname(_i) =~ a:fname
			return _i
		end
	endwhile
	return -1
endfunction


function! <SID>CloseExplorerWindows()
	if exists("g:BufExplorerVisible")
		let s:commandRunning = 1
		let bufwinnum = bufwinnr(s:GetBufferNumber('\[Buf List\]'))
		" call s:PrintError('trying to get to win# '.bufwinnum.' corresponding to buf# '.s:GetBufferNumber('[Buf List]'))
		call <SID>GotoWindow(bufwinnum)
		let s:commandRunning = 0
		if bufnr('%') == s:bufExplorerBufNum
			call s:PrintError('WMC: closing buffer explorer')
			q
		else
			call s:PrintError('WMC: error closing buf explorer, reached '.bufname('%').' instead')
		end
		let g:BufExplorerVisible = 0
	end
	if exists("g:FileExplorerVisible")
		call <SID>GotoWindow(bufwinnr(s:GetBufferNumber('\[File List\]')))
		if bufnr('%') == s:fileExplorerBufNum
			q
		end
		let g:fileExplorervisible = 0
	end
endfunction


"=============================================================================
"   Copyright: Copyright (C) 2001 Jeff Lanzarotta
"              Permission is hereby granted to use and distribute this code,
"              with or without modifications, provided that this copyright
"              notice is copied with it. Like anything else that's free,
"              bufexplorer.vim is provided *as is* and comes with no
"              warranty of any kind, either expressed or implied. In no
"              event will the copyright holder be liable for any damamges
"              resulting from the use of this software.
"	Name Of File: bufexplorer.vim
"	Description: Buffer Explorer Vim Plugin
"	Maintainer: Jeff Lanzarotta (frizbeefanatic@yahoo.com)
"	Last Change: Friday, August 24, 2001
"	Version: 6.0.6
"=============================================================================

"
" Show detailed help?
"
if !exists("g:bufExplorerDetailedHelp")
	let g:bufExplorerDetailedHelp = 0
endif

" Field to sort by
if !exists("g:bufExplorerSortBy")
	let g:bufExplorerSortBy = 'number'
endif

" When opening a new windows, split the new windows below or above the
" current window?  1 = below, 0 = above.
if !exists("g:bufExplSplitBelow")
	let g:bufExplSplitBelow = &splitbelow
endif

if !exists("g:bufExplorerSortDirection")
	let g:bufExplorerSortDirection = 1
	let s:sortDirLabel = ""
else
	let s:sortDirLabel = "reverse"
endif

" Characters that must be escaped for a regular expression.
let s:escregexp = '/*^$.~\'

"
" StartBufExplorer
"
function! <SID>StartBufExplorer(split)
	" Save the user's settings.
	let saveSplitBelow = &splitbelow

	" Save current and alternate buffer numbers for later.
	let s:currentBufferNumber = bufnr("%")
	let s:alternateBufferNumber = bufnr("#")

	" Set to our new values.
	let &splitbelow = g:bufExplSplitBelow

	if a:split || (&modified && &hidden == 0)
		sp [BufExplorer]
		let s:bufExplorerSplitWindow = 1
	else
		e [BufExplorer]
		let s:bufExplorerSplitWindow = 0
	endif

	call <SID>DisplayBuffers()

	" Restore the user's settings.
	let &splitbelow = saveSplitBelow

	unlet saveSplitBelow
endfunction

"
" DisplayBuffers.
"
function! <SID>DisplayBuffers()
	" Turn off the swapfile, set the buffer type so that it won't get written,
	" and so that it will get deleted when it gets hidden.
	setlocal modifiable
	setlocal noswapfile
	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal nowrap

"	let tmp = s:sortDirLabel
"	return

	" Prevent a report of our actions from showing up.
	let oldRep = &report
	let save_sc = &showcmd
	let &report = 10000
	set noshowcmd

	if has("syntax")
		syn match bufExplorerHelp	"^\"[ -].*"
		syn match bufExplorerHelpEnd "^\"=.*$"
		syn match bufExplorerSortBy	"^\" Sorted by .*$"

		if !exists("g:did_bufexplorer_syntax_inits")
			let g:did_bufexplorer_syntax_inits = 1
			hi def link bufExplorerHelp Special
			hi def link bufExplorerHelpEnd Special
			hi def link bufExplorerSortBy String
		endif
	endif

	if exists("s:longHelp")
		let w:longHelp = s:longHelp
	else
		let w:longHelp = g:bufExplorerDetailedHelp
	endif

	nnoremap <buffer> <cr> :call <SID>GotoFile_LsExplore(0)<cr>
	nnoremap <buffer> <tab> :call <SID>GotoFile_LsExplore(1)<cr>
	nnoremap <buffer> j j:call <SID>EchoFileName()<cr>
	nnoremap <buffer> k k:call <SID>EchoFileName()<cr>
	nnoremap <buffer> <down> j:call <SID>EchoFileName()<cr>
	nnoremap <buffer> <up> k:call <SID>EchoFileName()<cr>
	nnoremap <buffer> d :call <SID>DeleteBuffer()<cr>
	nnoremap <buffer> q :q<cr>
	nnoremap <buffer> s :call <SID>BufEx_SortSelect()<cr>
	nnoremap <buffer> r :call <SID>BufEx_SortReverse()<cr>
	nnoremap <buffer> ? :call <SID>BufEx_ToggleHelp()<cr>
	nnoremap <buffer> <2-leftmouse> :call <SID>GotoFile_LsExplore(0)<cr>

	" Delete all lines in buffer.
	1,$d _

	call <SID>BufEx_AddHeader()
	$ d _
	call <SID>ShowBuffers()

	normal! zz

	let &report = oldRep
	let &showcmd = save_sc

	unlet oldRep save_sc

	" Prevent the buffer from being modified.
	setlocal nomodifiable
endfunction

"
" AddHeader.
"
function! <SID>BufEx_AddHeader()
	1
	if w:longHelp == 1
		let header = "\" Buffer Explorer\n"
		let header = header."\" ----------------\n"
		let header = header."\" <enter> or Mouse-Double-Click : open buffer under cursor\n"
		let header = header."\" <tab> open buffer under cursor in split window\n"
		let header = header."\" d : delete buffer.\n"
		let header = header."\" q : quit the Buffer Explorer\n"
		let header = header."\" s : select sort field\n"
		let header = header."\" r : reverse sort\n"
		let header = header."\" ? : toggle this help\n"
		let header = header."\" :help winmanager for details\n"
	else
		let header = "\" Press ? for Help\n"
	endif

	if g:bufExplorerSortDirection == 1
		let header = header."\" Sort: ".'+ '.g:bufExplorerSortBy."\n"
	else
		let header = header."\" Sort: ".'- '.g:bufExplorerSortBy."\n"
	end
	let header = header."\"=\n"

	put! =header

	unlet header
endfunction

"
" ShowBuffers.
"
function! <SID>ShowBuffers()
	let oldRep = &report
	let save_sc = &showcmd
	let &report = 10000
	set noshowcmd
	let _NBuffers = bufnr("$")		" Get the number of the last buffer.
	let _i = 0						" Set the buffer index to zero.
	let fileNames = ""

	" Loop through every buffer less than the total number of buffers.
	while(_i <= _NBuffers)
		let _i = _i + 1

		" Make sure the buffer in question is listed.
		if(getbufvar(_i, '&buflisted') == 1)
			" Get the name of the buffer.
			let _BufName = bufname(_i)
			let _BufName = expand("#" ._i . ":t")
			let _isdirectory = isdirectory(bufname(_i))

			" Check to see if the buffer is a blank or not. If the buffer does have
			" a name, process it.
			if(strlen(_BufName)) && !_isdirectory
				if(matchstr(_BufName, "BufExplorer\]") == "")
					let len = strlen(_BufName)

					if(_i == s:currentBufferNumber)
						let fileNames = fileNames.'%'
					else
						if(_i == s:alternateBufferNumber)
							let fileNames = fileNames.'#'
						else
							let fileNames = fileNames.' '
						endif
					endif

					if(getbufvar(_i, '&hidden') == 1)
						let fileNames = fileNames.'h'
					else
						let fileNames = fileNames.' '
					endif

					if(getbufvar(_i, '&readonly') == 1)
						let fileNames = fileNames.'='
					else
						if(getbufvar(_i, '&modified') == 1)
							let fileNames = fileNames.'+'
						else
							if(getbufvar(_i, '&modifiable') == 0)
								let fileNames = fileNames.'-'
							else
								let fileNames = fileNames.' '
							endif
						endif
					endif

					let fileNames = fileNames.' '
					let fileNames = fileNames. _i. " " . _BufName . "\n"
				endif
			endif
		endif
	endwhile
	put =fileNames
	call <SID>BufEx_SortListing("")
	let &report = oldRep
	let &showcmd = save_sc
	unlet! fileNames _NBuffers _i oldRep save_sc _BufName
endfunction


"
" Delete selected buffer from list.
"
function! <SID>DeleteBuffer()
	let oldRep = &report
	let &report = 10000
	let save_sc = &showcmd
	set noshowcmd

	setlocal modifiable

	let bufNum = <SID>ExtractFileNumber(getline('.'))
	if bufNum
		exec("bd ".bufNum)
		" Delete the buffer's name from the list.
		d _
	end

	setlocal nomodifiable
	call <SID>ResizeBufExplorerWin()

	let &report = oldRep
	let &showcmd = save_sc

	unlet oldRep save_sc
endfunction


"
" Toggle between short and long help
"
function! <SID>BufEx_ToggleHelp()
	if exists("w:longHelp") && w:longHelp==0
		let w:longHelp=1
		let s:longHelp=1
	else
		let w:longHelp=0
		let s:longHelp=0
	endif

	" Allow modification
	setlocal modifiable

	call <SID>BufEx_UpdateHeader()
	call <SID>ResizeBufExplorerWin()

	" Disallow modification
	setlocal nomodifiable
endfunction

"
" Update the header
"
function! <SID>BufEx_UpdateHeader()
	let oldRep = &report
	let save_sc = &showcmd
	let &report = 10000
	set noshowcmd

	" Save position
	normal! mt

	" Remove old header
	0
	1,/^"=/ d _

	" Add new header
	call <SID>BufEx_AddHeader()

	" Go back where we came from if possible.
	0
	if line("'t") != 0
		normal! `t
	endif

	let &report = oldRep
	let &showcmd = save_sc

	unlet oldRep save_sc
endfunction

"
" <SID>BufEx_ExtractFileName
"
function! <SID>BufEx_ExtractFileName(line)
	let firsto = match(a:line, '[0-9]', 0)
	let lasto = match(a:line, '[0-9]', firsto + 1)
	if lasto == -1 | let len = 1 | else | let len = lasto-firsto+1 | endif
	let bufNum = strpart(a:line, firsto, len) + 0
	return expand("#" . bufNum . ":t")
endfunction

function! <SID>ExtractFileNumber(line)
	let firsto = match(a:line, '[0-9]', 0)
	if firsto == -1 | return 0 | endif
	let lasto = match(a:line, '[0-9]', firsto + 1)
	if lasto == -1 | let len = 1 | else | let len = lasto-firsto+1 | endif
	let bufNum = strpart(a:line, firsto, len) + 0
	return bufNum
endfunction

"
" FileNameCmp
"
function! <SID>BufEx_FileNameCmp(line1, line2, direction)
	let f1 = bufnr(<SID>BufEx_ExtractFileName(a:line1))
	let f2 = bufnr(<SID>BufEx_ExtractFileName(a:line2))

	return <SID>StrCmp(f1, f2, a:direction)
endfunction

"
" BufferNumberCmp
"
function! <SID>BufferNumberCmp(line1, line2, direction)
	let n1 = <SID>ExtractFileNumber(a:line1)
	let n2 = <SID>ExtractFileNumber(a:line2)

	return a:direction*(n1-n2)
endfunction

"
" StrCmp - General string comparison function
"
function! <SID>StrCmp(line1, line2, direction)
	if a:line1 < a:line2
		return -a:direction
	elseif a:line1 > a:line2
		return a:direction
	else
		return 0
	endif
endfunction

"
" MRUCmp - comparision by last access
"
function! <SID>MRUCmp(line1, line2, direction)
	let n1 = <SID>ExtractFileNumber(a:line1)
	let n2 = <SID>ExtractFileNumber(a:line2)

	" delmiting on both sides by "," helps to take care of cases where one
	" buffer number is 'contained' in another.
	let lu1 = stridx(s:MRUlist, ','.n1.',')
	let lu2 = stridx(s:MRUlist, ','.n2.',')

	return a:direction*(lu1 - lu2)
endfunction

"
" SortR() is called recursively.
"
function! <SID>BufEx_SortR(start, end, cmp, direction)
	" Bottom of the recursion if start reaches end
	if a:start >= a:end
		return
	endif

	let partition = a:start - 1
	let middle = partition
	let partStr = getline((a:start + a:end) / 2)

	let i = a:start

	while (i <= a:end)
		let str = getline(i)

		exec "let result = " . a:cmp . "(str, partStr, " . a:direction . ")"

		if result <= 0
			" Need to put it before the partition.	Swap lines i and partition.
			let partition = partition + 1

			if result == 0
				let middle = partition
			endif

			if i != partition
				let str2 = getline(partition)
				call setline(i, str2)
				call setline(partition, str)
			endif
		endif

		let i = i + 1
	endwhile

	" Now we have a pointer to the "middle" element, as far as partitioning
	" goes, which could be anywhere before the partition.	Make sure it is at
	" the end of the partition.
	if middle != partition
		let str = getline(middle)
		let str2 = getline(partition)
		call setline(middle, str2)
		call setline(partition, str)
	endif

	call <SID>BufEx_SortR(a:start, partition - 1, a:cmp, a:direction)
	call <SID>BufEx_SortR(partition + 1, a:end, a:cmp, a:direction)
endfunction

"
" Sort
"
function! <SID>BufEx_Sort(cmp, direction) range
	call <SID>BufEx_SortR(a:firstline, a:lastline, a:cmp, a:direction)
endfunction

"
" SortReverse
"
function! <SID>BufEx_SortReverse()
	if g:bufExplorerSortDirection == -1
		let g:bufExplorerSortDirection = 1
		let s:sortDirLabel = ""
	else
		let g:bufExplorerSortDirection = -1
		let s:sortDirLabel = "reverse "
	endif

	call <SID>BufEx_SortListing("")
endfunction

"
" SortSelect
"
function! <SID>BufEx_SortSelect()
	" Select the next sort option
	if !exists("g:bufExplorerSortBy")
		let g:bufExplorerSortBy = "number"

	elseif g:bufExplorerSortBy == "number"
		let g:bufExplorerSortBy = "name"

	elseif g:bufExplorerSortBy == "name"
		let g:bufExplorerSortBy = "MRU"

	elseif g:bufExplorerSortBy == "MRU"
		let g:bufExplorerSortBy = "number"
	endif

	call <SID>BufEx_SortListing("")
endfunction

"
" SortListing
"
function! <SID>BufEx_SortListing(msg)
	" Save the line we start on so we can go back there when done sorting.
	let startline = getline(".")
	let col = col(".")
	let lin = line(".")

	" Allow modification
	setlocal modifiable

	" Do the sort.
	0
	if g:bufExplorerSortBy == "number"
		let cmpFunction = "<SID>BufferNumberCmp"
	elseif g:bufExplorerSortBy == "name"
		let cmpFunction = "<SID>BufEx_FileNameCmp"
	elseif g:bufExplorerSortBy == "MRU"
		let cmpFunction = "<SID>MRUCmp"
	endif

	/^"=/+1,$call <SID>BufEx_Sort(cmpFunction, g:bufExplorerSortDirection)

	" Replace the header with updated information.
	call <SID>BufEx_UpdateHeader()

	" Return to the position we started at.
	0
	if search('\m^'.escape(startline, s:escregexp), 'W') <= 0
		execute lin
	endif

	execute "normal!" col . "|"

	" Disallow modification.
	setlocal nomodified
	setlocal nomodifiable

	unlet startline col lin cmpFunction
endfunction

"
" PushToFront: push the current buffer to the top of the MRU list
"
function! <SID>PushToFront()
	let bufNum = bufnr('%')
	" do this only for listed buffers. dont want help files, etc creeping into
	" the MRU list.
	if !buflisted(bufnr('%'))
		return
	end
	" suppose the list is ",1,3,19,4," and % is 19
	" first remove the "19," part of the MRUlist, so that it becomes
	" ",1,3,4,"
	let listNoBuf = substitute(s:MRUlist, ','.bufNum.',', ',', '')
	" then append it at the beginning. the list will now become
	" ",19,1,3,4,"
	let s:MRUlist = ','.bufNum.listNoBuf
	" TODO: for debugging... remove later.
	let g:MRUlist = s:MRUlist
endfunction

" 
" InitializeMRUList 
"
" initialize the MRU list. initially this will be just the buffers in the
" order of their buffer numbers. The MRU list consists of a string of the
" following form: ",1,2,3,4,"
" NOTE: there are commas at the beginning and the end. this is to make
" identifying the position of buffers in the list easier even if they occur in
" the beginning or end and in situations where one buffer number is part of
" another. i.e the string "9" is part of the string "19"
" 
function! <SID>InitializeMRUList()
	let nBufs = bufnr('$')
	let _i = 1

	" put the % and the # numbers at the beginning if they are listed.
	let s:MRUlist = ''
	if buflisted(bufnr("%"))
		let s:MRUlist = ','.bufnr("%")
	end
	if buflisted(bufnr("#"))
		let s:MRUlist = s:MRUlist.','.bufnr("#")
	end
	let s:MRUlist = s:MRUlist.','
	
	" then proceed with the rest of the buffers
	while _i <= nBufs
		" dont keep unlisted buffers in the MRU list.
		if buflisted(_i) && bufnr("%") != _i && bufnr("#") != _i
			let s:MRUlist = s:MRUlist._i.','
		end
		let _i = _i + 1
	endwhile
	" TODO: for debugging... remove later.
	let g:MRUlist = s:MRUlist
endfunction

"=============================================================================
" File: explorer.vim
" Author: M A Aziz Ahmed (aziz@123india.com)
" Last Change:	Thu, 21 Jun 2001 07:42:08
" Version: 2.5
" Additions by Mark Waggoner (waggoner@aracnet.com) et al.
"=============================================================================

"---
" Default settings for global configuration variables

" Split vertically instead of horizontally?
if !exists("g:explVertical")
	let g:explVertical=0
endif

" How big to make the window? Set to "" to avoid resizing
if !exists("g:explWinSize")
	let g:explWinSize=15
endif

" When opening a new file/directory, split below current window (or
" above)?	1 = below, 0 = to above
if !exists("g:explSplitBelow")
	let g:explSplitBelow = &splitbelow
endif

" Split to right of current window (or to left)?
" 1 = to right, 0 = to left
if !exists("g:explSplitRight")
	let g:explSplitRight = &splitright
endif

" Start the first explorer window...
" Defaults to be the same as explSplitBelow
if !exists("g:explStartBelow")
	let g:explStartBelow = g:explSplitBelow
endif

" Start the first explorer window...
" Defaults to be the same as explSplitRight
if !exists("g:explStartRight")
	let g:explStartRight = g:explSplitRight
endif

" Show detailed help?
if !exists("g:explDetailedHelp")
	let g:explDetailedHelp=0
endif

" Show file size and dates?
if !exists("g:explDetailedList")
	let g:explDetailedList=0
endif

" Format for the date
if !exists("g:explDateFormat")
	let g:explDateFormat="%d %b %Y %H:%M"
endif

" Files to hide
if !exists("g:explHideFiles")
	let g:explHideFiles=''
endif

" Field to sort by
if !exists("g:explSortBy")
	let g:explSortBy='name'
endif

" Segregate directories? 1, 0, or -1
if !exists("g:explDirsFirst")
	let g:explDirsFirst=1
endif

" Segregate items in suffixes option? 1, 0, or -1
if !exists("g:explSuffixesLast")
	let g:explSuffixesLast=1
endif

" Include separator lines between directories, files, and suffixes?
if !exists("g:explUseSeparators")
	let g:explUseSeparators=0
endif

"---
" script variables - these are the same across all
" explorer windows

" characters that must be escaped for a regular expression
let s:escregexp = '/*^$.~\'

" characters that must be escaped for filenames
if has("dos16") || has("dos32") || has("win16") || has("win32") || has("os2")
	let s:escfilename = ' %#'
else
	let s:escfilename = ' \%#'
endif


" A line to use for separating sections
let s:separator='"---------------------------------------------------'
"

function! s:ReDisplayFileList(dirname)
	" Turn off the swapfile, set the buffer type so that it won't get
	" written, and so that it will get deleted when it gets hidden.
	setlocal modifiable
	setlocal noswapfile
	setlocal buftype=nowrite
	setlocal bufhidden=delete
	" Don't wrap around long lines
	setlocal nowrap
	setlocal nobuflisted

	" No need for any insertmode abbreviations, since we don't allow
	" insertions anyway!
	iabc <buffer>

	" Long or short listing?	Use the global variable the first time
	" explorer is called, after that use the script variable as set by
	" the interactive user.
	if exists("s:longlist")
		let w:longlist = s:longlist
	else
		let w:longlist = g:explDetailedList
	endif

	" Get the complete path to the directory to look at with a slash at
	" the end
	"call <SID>PrintError("a:dirname = ".a:dirname)
	let w:completePath = s:Path(a:dirname)
	if w:completePath == ""
		return
	end

	" escape special characters for exec commands
	let w:completePathEsc=escape(w:completePath,s:escfilename)
	let b:parentDirEsc=substitute(w:completePathEsc, '/[^/]*/$', '/', 'g')

	" Set filter for hiding files
	let b:filterFormula=substitute(g:explHideFiles, '\([^\\]\),', '\1\\|', 'g')
	if b:filterFormula != ''
		let b:filtering="\nNot showing: " . b:filterFormula
	else
		let b:filtering=""
	endif

	" Show the files
" 	if !exists("s:numFileBuffers")
" 		let s:numFileBuffers = 0
" 	endif
	let i = 1
	let alreadyDisplayed = 0
	while i <= s:numFileBuffers
		exec 'let diri = s:dir_'.i
		if diri == w:completePath
			1,$d _
			exec 'put =s:FileList_'.i
			exec 'let g:lastFilePut = s:FileList_'.i
			0d
			0
			/^"=/+1
			call s:PrintError('getting an already displayed d#'.i.' dir = '.diri)
			let s:currentFileNumberDisplayed = i
			let alreadyDisplayed = 1
			break
		endif
		let i = i+1	
	endwhile

	if !alreadyDisplayed
		call s:ShowDirectory()
		let s:numFileBuffers = s:numFileBuffers + 1
		
		let saverega = @a
		normal! ggVG"ay
		call s:PrintError('setting s:dir_'.s:numFileBuffers)
		exec 'let s:dir_'.s:numFileBuffers.' = w:completePath'
		exec 'let s:FileList_'.s:numFileBuffers.' = @a'
		let @a = saverega
		let s:currentFileNumberDisplayed = s:numFileBuffers
		0
		/^"=/+1
	end

	if has("syntax") && !has("syntax_items")
		if exists("s:sortby")
			let sortby=s:sortby
		else
			let sortby=g:explSortBy
		endif
		if sortby =~ "reverse"
			let s:sortdirection_WM=-1
			let s:sortdirlabel_WM = "reverse "
		endif
		if sortby =~ "date"
			let s:sorttype_WM = "date"
		elseif sortby =~ "size"
			let s:sorttype_WM = "size"
		else
			let s:sorttype_WM = "name"
		endif
		call s:SetSuffixesLast()

		syn match browseSynopsis	"^\"[ -].*"
		syn match browseDirectory	 "[^\"].*/ "
		syn match browseDirectory	 "[^\"].*/$"
		syn match browseCurDir	"^\"= .*$"
		syn match browseSortBy	"^\" Sorted by .*$" contains=browseSuffixInfo
		syn match browseSuffixInfo	"(.*)$" contained
		syn match browseFilter	"^\" Not Showing:.*$"
		syn match browseFiletime	"«\d\+$"
		exec('syn match browseSuffixes	"' . b:suffixesHighlight . '"')

		"hi def link browseSynopsis	PreProc
		hi def link browseSynopsis	Special
		hi def link browseDirectory	 Directory
		hi def link browseCurDir	Statement
		hi def link browseSortBy	String
		hi def link browseSuffixInfo	Type
		hi def link browseFilter	String
		hi def link browseFiletime	Ignore
		hi def link browseSuffixes	Type
		call s:PrintError('redisplay: creating syntax items ...')
	else
		call s:PrintError('redisplay: '.bufnr('%').' already has syntax items')
	end

	" prevent the buffer from being modified
	setlocal nomodifiable
endfunction


function! s:RestoreFileDisplay()
	let oldRep=&report
	let save_sc = &sc
	set report=10000 nosc
	let presLine = line('.')

	let saverega = @a
	normal! ggVG"ay
	call s:PrintError('setting s:dir_'.s:currentFileNumberDisplayed)
	exec 'let s:FileList_'.s:currentFileNumberDisplayed.' = @a'
	let @a = saverega

	let &report=oldRep
	let &sc = save_sc
	exe presLine
" 	0
" 	/^"=/+1
endfunction


function! s:DisplayFileList(dirname)
	" Turn off the swapfile, set the buffer type so that it won't get
	" written, and so that it will get deleted when it gets hidden.
	setlocal modifiable
	setlocal noswapfile
	setlocal buftype=nowrite
	setlocal bufhidden=delete
	" Don't wrap around long lines
	setlocal nowrap

	" No need for any insertmode abbreviations, since we don't allow
	" insertions anyway!
	iabc <buffer>

	" Long or short listing?	Use the global variable the first time
	" explorer is called, after that use the script variable as set by
	" the interactive user.
	if exists("s:longlist")
		let w:longlist = s:longlist
	else
		let w:longlist = g:explDetailedList
	endif

	" Show keyboard shortcuts?
	if exists("s:longhelp")
		let s:longhelp_WM = s:longhelp
	else
		let s:longhelp_WM = g:explDetailedHelp
	endif

	" Set the sort based on the global variables the first time.	If you
	" later change the sort order, it will be retained in the s:sortby
	" variable for the next time you open explorer
	let s:sortdirection_WM=1
	let s:sortdirlabel_WM = ""
	let s:sorttype_WM = ""
	if exists("s:sortby")
		let sortby=s:sortby
	else
		let sortby=g:explSortBy
	endif
	if sortby =~ "reverse"
		let s:sortdirection_WM=-1
		let s:sortdirlabel_WM = "reverse "
	endif
	if sortby =~ "date"
		let s:sorttype_WM = "date"
	elseif sortby =~ "size"
		let s:sorttype_WM = "size"
	else
		let s:sorttype_WM = "name"
	endif
	call s:SetSuffixesLast()

	" Get the complete path to the directory to look at with a slash at
	" the end
	"call <SID>PrintError("a:dirname = ".a:dirname)
	let w:completePath = s:Path(a:dirname)
	if w:completePath == ""
		return
	end

"	 " Save the directory we are currently in and chdir to the directory
"	 " we are editing so that we can get a real path to the directory,
"	 " eliminating things like ".."
"	 let origdir= s:Path(getcwd())
"	 exe "chdir" escape(w:completePath,s:escfilename)
"	 let w:completePath = s:Path(getcwd())
"	 exe "chdir" escape(origdir,s:escfilename)

"	 " Add a slash at the end
"	 if w:completePath !~ '/$'
"		let w:completePath = w:completePath . '/'
"	 endif

	" escape special characters for exec commands
	let w:completePathEsc=escape(w:completePath,s:escfilename)
	let b:parentDirEsc=substitute(w:completePathEsc, '/[^/]*/$', '/', 'g')

	" Set up syntax highlighting
	" Something wrong with the evaluation of the conditional though...
	if has("syntax") && !has("syntax_items")
		syn match browseSynopsis	"^\"[ -].*"
		syn match browseDirectory	 "[^\"].*/ "
		syn match browseDirectory	 "[^\"].*/$"
		syn match browseCurDir	"^\"= .*$"
		syn match browseSortBy	"^\" Sorted by .*$" contains=browseSuffixInfo
		syn match browseSuffixInfo	"(.*)$" contained
		syn match browseFilter	"^\" Not Showing:.*$"
		syn match browseFiletime	"«\d\+$"
		exec('syn match browseSuffixes	"' . b:suffixesHighlight . '"')

		"hi def link browseSynopsis	PreProc
		hi def link browseSynopsis	Special
		hi def link browseDirectory	 Directory
		hi def link browseCurDir	Statement
		hi def link browseSortBy	String
		hi def link browseSuffixInfo	Type
		hi def link browseFilter	String
		hi def link browseFiletime	Ignore
		hi def link browseSuffixes	Type
	endif

	" Set filter for hiding files
	let b:filterFormula=substitute(g:explHideFiles, '\([^\\]\),', '\1\\|', 'g')
	if b:filterFormula != ''
		let b:filtering="\nNot showing: " . b:filterFormula
	else
		let b:filtering=""
	endif

	" Show the files
	call s:ShowDirectory()

	" Set up mappings for this buffer
	nnoremap <buffer> <cr> :call <SID>GotoFile_LsExplore(0)<cr>
	nnoremap <buffer> <tab> :call <SID>GotoFile_LsExplore(1)<cr>
	nnoremap <buffer> -	:call <SID>ReDisplayFileList(b:parentDirEsc)<cr>
	nnoremap <buffer> ?	:call <SID>ToggleHelp()<cr>
	nnoremap <buffer> a	:call <SID>ShowAllFiles()<cr>:call <SID>RestoreFileDisplay()<cr>
	nnoremap <buffer> R	:call <SID>RenameFile()<cr>
	nnoremap <buffer> D	:. call <SID>DeleteFile()<cr>:call <SID>RestoreFileDisplay()<cr>
	vnoremap <buffer> D	:call <SID>DeleteFile()<cr>:call <SID>RestoreFileDisplay()<cr>
	nnoremap <buffer> i	:call <SID>ToggleLongList()<cr>:call <SID>RestoreFileDisplay()<cr>
	nnoremap <buffer> s	:call <SID>SortSelect()<cr>:call <SID>RestoreFileDisplay()<cr>
	nnoremap <buffer> r	:call <SID>SortReverse()<cr>:call <SID>RestoreFileDisplay()<cr>
	"nnoremap <buffer> r	:call <SID>SortReverse()<cr>
	nnoremap <buffer> c	:exec "cd ".w:completePathEsc<cr>:pwd<cr>
	nnoremap <buffer> C	:call <SID>DisplayFileList(getcwd())<cr>:call <SID>RestoreFileDisplay()<cr>
	nnoremap <buffer> <F5> :call <SID>DisplayFileList(w:completePath)<cr>:call <SID>RestoreFileDisplay()<cr>
	nnoremap <buffer> <2-leftmouse> :call <SID>GotoFile_LsExplore(0)<cr>

	" prevent the buffer from being modified
	setlocal nomodifiable
endfunction



"---
" Open a file or directory in a new window.
" Use g:explSplitBelow and g:explSplitRight to decide where to put the
" split window, and resize the original explorer window if it is
" larger than g:explWinSize
"
function! s:OpenEntry(split)
	" Are we on a line with a file name?

	" Get the file name
	let fn=s:GetFullFileName()

	if isdirectory(fn)
		let origdir= s:Path(getcwd())
		exe "chdir" escape(fn,s:escfilename)
		let fn = s:Path(getcwd())
		exe "chdir" escape(origdir,s:escfilename)
	else
		call <SID>GotoFile_LsExplore(0)
	endif

endfunction

"---
" Double click with the mouse
"
function s:DoubleClick()
	if expand("<cfile>") =~ '[\\/]$'
		call s:EditEntry("","edit")		" directory: open in this window
	else
		" call s:OpenEntryPrevWindow()	" file: open in another window
		call <SID>GotoFile_LsExplore(0)
	endif
endfun


"---
" Create a regular expression out of the suffixes option for sorting
" and set a string to indicate whether we are sorting with the
" suffixes at the end (or the beginning)
"
function! s:SetSuffixesLast()
	let b:suffixesRegexp = '\(' . substitute(escape(&suffixes,s:escregexp),',','\\|','g') . '\)$'
	let b:suffixesHighlight = '^[^"].*\(' . substitute(escape(&suffixes,s:escregexp),',','\\|','g') . '\)\( \|$\)'
	if has("fname_case")
		let b:suffixesRegexp = '\C' . b:suffixesRegexp
		let b:suffixesHighlight = '\C' . b:suffixesHighlight
	else
		let b:suffixesRegexp = '\c' . b:suffixesRegexp
		let b:suffixesHighlight = '\c' . b:suffixesHighlight
	endif
	if g:explSuffixesLast > 0 && &suffixes != ""
		let b:suffixeslast=" (" . &suffixes . " at end of list)"
	elseif g:explSuffixesLast < 0 && &suffixes != ""
		let b:suffixeslast=" (" . &suffixes . " at start of list)"
	else
		let b:suffixeslast=" ('suffixes' mixed with files)"
	endif
endfunction

"---
" Show the header and contents of the directory
"
function! s:ShowDirectory()
	"Delete all lines
	1,$d _
	" Prevent a report of our actions from showing up
	let oldRep=&report
	let save_sc = &sc
	set report=10000 nosc

	" Add the header
	call s:AddHeader()
	$d _

	" Display the files

	" Get a list of all the files
	let files = s:Path(glob(w:completePath."*"))
	if files != "" && files !~ '\n$'
		let files = files . "\n"
	endif

	" Add the dot files now, making sure "." is not included!
	let files = files . substitute(s:Path(glob(w:completePath.".*")), "[^\n]*/./\\=\n", '' , '')
	if files != "" && files !~ '\n$'
		let files = files . "\n"
	endif

	" Are there any files left after filtering?
	if files != ""
		normal! mt
		put =files
		let s:maxFileLen_WM = 0
		0
		/^"=/+1,$g/^/call s:MarkDirs()
		normal! `t
		call s:AddFileInfo()
	endif

	normal! zz

	" Move to first directory in the listing
	0
	/^"=/+1

	" Do the sort
	call s:SortListing("Loaded contents of ".w:completePath.". ")

	" Move to first directory in the listing
	0
	/^"=/+1

	let &report=oldRep
	let &sc = save_sc
endfunction

"---
" Mark which items are directories - called once for each file name
" must be used only when size/date is not displayed
"
function! s:MarkDirs()
	let oldRep=&report
	set report=1000
	"Remove slashes if added
	s;/$;;e
	"Removes all the leading slashes and adds slashes at the end of directories
	s;^.*\\\([^\\]*\)$;\1;e
	s;^.*/\([^/]*\)$;\1;e
	"normal! ^
	let currLine=getline(".")
	if isdirectory(w:completePath . currLine)
		s;$;/;
		let fileLen=strlen(currLine)+1
	else
		let fileLen=strlen(currLine)
		if (b:filterFormula!="") && (currLine =~? b:filterFormula)
			" Don't show the file if it is to be filtered.
			d _
		endif
	endif
	if fileLen > s:maxFileLen_WM
		let s:maxFileLen_WM=fileLen
	endif
	let &report=oldRep
endfunction

"---
" Make sure a path has proper form
"
function! s:Path(p)
	let _p = a:p
	if a:p =~ '//$'
		"call <SID>PrintError("called path with ".a:p)
	return ""
	end
	if isdirectory(_p)
		let origdir= getcwd()
		exe "chdir" _p
		let _p = getcwd()
		exe "chdir" origdir
	end
	if has("dos16") || has("dos32") || has("win16") || has("win32") || has("os2")
		let _p = substitute(_p,'\\','/','g')
	endif
	if _p !~ '/$'
		let _p = _p.'/'
	endif
	return _p
endfunction

"---
" Extract the file name from a line in several different forms
"
function! s:GetFullFileNameEsc()
	return s:EscapeFilename(s:GetFullFileName())
endfunction

function! s:GetFileNameEsc()
	return s:EscapeFilename(s:GetFileName())
endfunction

function! s:EscapeFilename(name)
	return escape(a:name,s:escfilename)
endfunction


function! s:GetFullFileName()
	return s:ExtractFullFileName(getline("."))
endfunction

function! s:GetFileName()
	return s:ExtractFileName(getline("."))
endfunction

function! s:ExtractFullFileName(line)
	let fn=s:ExtractFileName(a:line)
	if fn == '/'
		return w:completePath
	else
		return w:completePath . s:ExtractFileName(a:line)
	endif
endfunction

function! s:ExtractFileName(line)
	return substitute(strpart(a:line,0,s:maxFileLen_WM),'\s\+$','','')
endfunction

"---
" Get the size of the file
function! s:ExtractFileSize(line)
	if (w:longlist==0)
		return getfsize(s:ExtractFullFileName(a:line))
	else
		return strpart(a:line,s:maxFileLen_WM+2,b:maxFileSizeLen);
	endif
endfunction

"---
" Get the date of the file - dates must be displayed!
function! s:ExtractFileDate(line)
	if w:longlist==0
		return getftime(s:ExtractFullFileName(a:line))
	else
		return strpart(matchstr(strpart(a:line,s:maxFileLen_WM+b:maxFileSizeLen+4),"«.*"),1)
	endif
endfunction


"---
" Add the header with help information
"
function! s:AddHeader()
	let save_f=@f
	1
	if s:longhelp_WM==1
		let @f="\" <enter> : open file or directory\n"
		     \."\" <tab> : open new file or dir in adjacent window" 
			 \."\" o : open new window for file/directory\n"
			 \."\" i : toggle size/date listing\n"
			 \."\" s : select sort field\n"
			 \."\" r : reverse sort\n"
			 \."\" - : go up one level\n"
			 \."\" c : cd to this dir\n"
			 \."\" C : display pwd\n"
			 \."\" <F5> : redisplay currently displayed dir\n"
			 \."\" R : rename file\n"
			 \."\" D : delete file\n"
			 \."\" :help winmanager for detailed help\n"
	else
		let @f="\" Press ? for keyboard shortcuts\n"
	endif
	let @f=@f."\" Sorted by ".s:sortdirlabel_WM.s:sorttype_WM.b:suffixeslast.b:filtering."\n"
	let @f=@f."\"= ".w:completePath."\n"
	put! f
	let @f=save_f
endfunction


"---
" Show the size and date for each file
"
function! s:AddFileInfo()
	let save_sc = &sc
	set nosc

	" Mark our starting point
	normal! mt

	call s:RemoveSeparators()

	" Remove all info
	0
	/^"=/+1,$g/^/call setline(line("."),s:GetFileName())

	" Add info if requested
	if w:longlist==1
		" Add file size and calculate maximum length of file size field
		let b:maxFileSizeLen = 0
		0
		/^"=/+1,$g/^/let fn=s:GetFullFileName() |
							\let fileSize=getfsize(fn) |
							\let fileSizeLen=strlen(fileSize) |
							\if fileSizeLen > b:maxFileSizeLen |
							\let b:maxFileSizeLen = fileSizeLen |
							\endif |
							\exec "normal! ".(s:maxFileLen_WM-strlen(getline("."))+2)."A \<esc>" |
							\exec 's/$/'.fileSize.'/'

		" Right justify the file sizes and
		" add file modification date
		0
		/^"=/+1,$g/^/let fn=s:GetFullFileName() |
							\exec "normal! A \<esc>$b".(s:maxFileLen_WM+b:maxFileSizeLen-strlen(getline("."))+3)."i \<esc>\"_x" |
							\exec 's/$/ '.escape(s:FileModDate(fn), '/').'/'
		setlocal nomodified
	endif

	call s:AddSeparators()

	" return to start
	normal! `t

	let &sc = save_sc
endfunction


"----
" Get the modification time for a file
"
function! s:FileModDate(name)
	let filetime=getftime(a:name)
	if filetime > 0
		return strftime(g:explDateFormat,filetime) . " «" . filetime
	else
		return ""
	endif
endfunction

"---
" Delete a file or files
"
function! s:DeleteFile() range
	let oldRep = &report
	let &report = 1000

	let filesDeleted = 0
	let stopDel = 0
	let delAll = 0
	let currLine = a:firstline
	let lastLine = a:lastline
	setlocal modifiable

	while ((currLine <= lastLine) && (stopDel==0))
		exec(currLine)
		let fileName=s:GetFullFileName()
		if isdirectory(fileName)
			echo fileName." : Directory deletion not supported yet"
			let currLine = currLine + 1
		else
			if delAll == 0
				let sure=input("Delete ".fileName." (y/n/a/q)? ")
				if sure=="a"
					let delAll = 1
				endif
			endif
			if (sure=="y") || (sure=="a")
				let success=delete(fileName)
				if success!=0
					exec (" ")
					echo "\nCannot delete ".fileName
					let currLine = currLine + 1
				else
					d _
					let filesDeleted = filesDeleted + 1
					let lastLine = lastLine - 1
				endif
			elseif sure=="q"
				let stopDel = 1
			elseif sure=="n"
				let currLine = currLine + 1
			endif
		endif
	endwhile
	echo "\n".filesDeleted." files deleted"
	let &report = oldRep
	setlocal nomodified
	setlocal nomodifiable
endfunction

"---
" Rename a file
"
function! s:RenameFile()
	let fileName=s:GetFullFileName()
	setlocal modifiable
	if isdirectory(fileName)
		echo "Directory renaming not supported yet"
	elseif filereadable(fileName)
		let altName=input("Rename ".fileName." to : ")
		echo " "
		if altName==""
			return
		endif
		let success=rename(fileName, w:completePath.altName)
		if success!=0
			echo "Cannot rename ".fileName. " to ".altName
		else
			echo "Renamed ".fileName." to ".altName
			exe 'let nl = substitute(getline("."),"'.expand('<cfile>').'","'.altName.'","")'
			call setline(line('.'), nl)
		endif
	endif
	setlocal nomodified
	setlocal nomodifiable
	call <SID>RestoreFileDisplay()
endfunction

"---
" Toggle between short and long help
"
function! s:ToggleHelp()
	if exists("s:longhelp_WM") && s:longhelp_WM==0
		let s:longhelp_WM=1
		let s:longhelp=1
	else
		let s:longhelp_WM=0
		let s:longhelp=0
	endif
	" Allow modification
	setlocal modifiable
	call s:UpdateHeader()
	" Disallow modification
	setlocal nomodifiable
endfunction

"---
" Update the header
"
function! s:UpdateHeader()
	let oldRep=&report
	set report=10000
	" Save position
	normal! mt
	" Remove old header
	0
	1,/^"=/ d _
	" Add new header
	call s:AddHeader()
	" Go back where we came from if possible
	0
	if line("'t") != 0
		normal! `t
	endif

	let &report=oldRep
	setlocal nomodified
endfunction

"---
" Toggle long vs. short listing
"
function! s:ToggleLongList()
	setlocal modifiable
	if exists("w:longlist") && w:longlist==1
		let w:longlist=0
		let s:longlist=0
	else
		let w:longlist=1
		let s:longlist=1
	endif
	call s:AddFileInfo()
	setlocal nomodifiable
endfunction

"---
" Show all files - remove filtering
"
function! s:ShowAllFiles()
	setlocal modifiable
	let b:filterFormula=""
	let b:filtering=""
	call s:ShowDirectory()
	setlocal nomodifiable
endfunction

"---
" Figure out what section we are in
"
function! s:GetSection()
	let fn=s:GetFileName()
	let section="file"
	if fn =~ '/$'
		let section="directory"
	elseif fn =~ b:suffixesRegexp
		let section="suffixes"
	endif
	return section
endfunction

"---
" Remove section separators
"
function! s:RemoveSeparators()
	if !g:explUseSeparators
		return
	endif
	0
	silent! exec '/^"=/+1,$g/^' . s:separator . "/d _"
endfunction

"---
" Add section separators
"	 between directories and files if they are separated
"	 between files and 'suffixes' files if they are separated
function! s:AddSeparators()
	if !g:explUseSeparators
		return
	endif
	0
	/^"=/+1
	let lastsec=s:GetSection()
	+1
	.,$g/^/let sec=s:GetSection() |
							 \if g:explDirsFirst != 0 && sec != lastsec &&
							 \	 (lastsec == "directory" || sec == "directory") |
							 \	exec "normal! I" . s:separator . "\n\<esc>" |
							 \elseif g:explSuffixesLast != 0 && sec != lastsec &&
							 \	 (lastsec == "suffixes" || sec == "suffixes") |
							 \	exec "normal! I" . s:separator . "\n\<esc>" |
							 \endif |
							 \let lastsec=sec
endfunction


"---
" Function for use with Sort(), to compare the file names
" Default sort is to put in alphabetical order, but with all directory
" names before all file names
"
function! s:FileNameCmp(line1, line2, direction)
	let f1=s:ExtractFileName(a:line1)
	let f2=s:ExtractFileName(a:line2)

	" Put directory names before file names
	if (g:explDirsFirst != 0) && (f1 =~ '\/$') && (f2 !~ '\/$')
		return -g:explDirsFirst
	elseif (g:explDirsFirst != 0) && (f1 !~ '\/$') && (f2 =~ '\/$')
		return g:explDirsFirst
	elseif (g:explSuffixesLast != 0) && (f1 =~ b:suffixesRegexp) && (f2 !~ b:suffixesRegexp)
		return g:explSuffixesLast
	elseif (g:explSuffixesLast != 0) && (f1 !~ b:suffixesRegexp) && (f2 =~ b:suffixesRegexp)
		return -g:explSuffixesLast
	else
		let f1 = substitute(f1, "/$", "", "")
		let f2 = substitute(f2, "/$", "", "")
		return s:StrCmp(f1,f2,a:direction)
	endif

endfunction

"---
" Function for use with Sort(), to compare the file modification dates
" Default sort is to put NEWEST files first.	Reverse will put oldest
" files first
"
function! s:FileDateCmp(line1, line2, direction)
	let f1=s:ExtractFileName(a:line1)
	let f2=s:ExtractFileName(a:line2)
	let t1=s:ExtractFileDate(a:line1)
	let t2=s:ExtractFileDate(a:line2)

	" Put directory names before file names
	if (g:explDirsFirst != 0) && (f1 =~ '\/$') && (f2 !~ '\/$')
		return -g:explDirsFirst
	elseif (g:explDirsFirst != 0) && (f1 !~ '\/$') && (f2 =~ '\/$')
		return g:explDirsFirst
	elseif (g:explSuffixesLast != 0) && (f1 =~ b:suffixesRegexp) && (f2 !~ b:suffixesRegexp)
		return g:explSuffixesLast
	elseif (g:explSuffixesLast != 0) && (f1 !~ b:suffixesRegexp) && (f2 =~ b:suffixesRegexp)
		return -g:explSuffixesLast
	elseif t1 > t2
		return -a:direction
	elseif t1 < t2
		return a:direction
	else
		let f1 = substitute(f1, "/$", "", "")
		let f2 = substitute(f2, "/$", "", "")
		return s:StrCmp(f1,f2,1)
	endif
endfunction

"---
" Function for use with Sort(), to compare the file sizes
" Default sort is to put largest files first.	Reverse will put
" smallest files first
"
function! s:FileSizeCmp(line1, line2, direction)
	let f1=s:ExtractFileName(a:line1)
	let f2=s:ExtractFileName(a:line2)
	let s1=s:ExtractFileSize(a:line1)
	let s2=s:ExtractFileSize(a:line2)

	if (g:explDirsFirst != 0) && (f1 =~ '\/$') && (f2 !~ '\/$')
		return -g:explDirsFirst
	elseif (g:explDirsFirst != 0) && (f1 !~ '\/$') && (f2 =~ '\/$')
		return g:explDirsFirst
	elseif (g:explSuffixesLast != 0) && (f1 =~ b:suffixesRegexp) && (f2 !~ b:suffixesRegexp)
		return g:explSuffixesLast
	elseif (g:explSuffixesLast != 0) && (f1 !~ b:suffixesRegexp) && (f2 =~ b:suffixesRegexp)
		return -g:explSuffixesLast
	elseif s1 > s2
		return -a:direction
	elseif s1 < s2
		return a:direction
	else
		let f1 = substitute(f1, "/$", "", "")
		let f2 = substitute(f2, "/$", "", "")
		return s:StrCmp(f1,f2,1)
	endif
endfunction

"---
" Sort lines.	SortR() is called recursively.
"
function! s:SortR(start, end, cmp, direction)

	" Bottom of the recursion if start reaches end
	if a:start >= a:end
		return
	endif
	"
	let partition = a:start - 1
	let middle = partition
	let partStr = getline((a:start + a:end) / 2)
	let i = a:start
	while (i <= a:end)
		let str = getline(i)
		exec "let result = " . a:cmp . "(str, partStr, " . a:direction . ")"
		if result <= 0
			" Need to put it before the partition.	Swap lines i and partition.
			let partition = partition + 1
			if result == 0
				let middle = partition
			endif
			if i != partition
				let str2 = getline(partition)
				call setline(i, str2)
				call setline(partition, str)
			endif
		endif
		let i = i + 1
	endwhile

	" Now we have a pointer to the "middle" element, as far as partitioning
	" goes, which could be anywhere before the partition.	Make sure it is at
	" the end of the partition.
	if middle != partition
		let str = getline(middle)
		let str2 = getline(partition)
		call setline(middle, str2)
		call setline(partition, str)
	endif
	call s:SortR(a:start, partition - 1, a:cmp,a:direction)
	call s:SortR(partition + 1, a:end, a:cmp,a:direction)
endfunction

"---
" To Sort a range of lines, pass the range to Sort() along with the name of a
" function that will compare two lines.
"
function! s:Sort(cmp,direction) range
	call s:SortR(a:firstline, a:lastline, a:cmp, a:direction)
endfunction

"---
" Reverse the current sort order
"
function! s:SortReverse()
	if exists("s:sortdirection_WM") && s:sortdirection_WM == -1
		let s:sortdirection_WM = 1
		let s:sortdirlabel_WM	= ""
	else
		let s:sortdirection_WM = -1
		let s:sortdirlabel_WM	= "reverse "
	endif
	let s:sortby=s:sortdirlabel_WM . s:sorttype_WM
	call s:SortListing("")
endfunction

"---
" Toggle through the different sort orders
"
function! s:SortSelect()
	" Select the next sort option
	if !exists("s:sorttype_WM")
		let s:sorttype_WM="name"
	elseif s:sorttype_WM == "name"
		let s:sorttype_WM="size"
	elseif s:sorttype_WM == "size"
		let s:sorttype_WM="date"
	else
		let s:sorttype_WM="name"
	endif
	let s:sortby=s:sortdirlabel_WM . s:sorttype_WM
	call s:SortListing("")
endfunction

"---
" Sort the file listing
"
function! s:SortListing(msg)
	" Save the line we start on so we can go back there when done
	" sorting
	let startline = getline(".")
	let col=col(".")
	let lin=line(".")

	" Allow modification
	setlocal modifiable

	" Send a message about what we're doing
	" Don't really need this - it can cause hit return prompts
"	 echo a:msg . "Sorting by" . s:sortdirlabel_WM . s:sorttype_WM

	" Create a regular expression out of the suffixes option in case
	" we need it.
	call s:SetSuffixesLast()

	" Remove section separators
	call s:RemoveSeparators()

	" Do the sort
	0
	if s:sorttype_WM == "size"
		/^"=/+1,$call s:Sort("s:FileSizeCmp",s:sortdirection_WM)
	elseif s:sorttype_WM == "date"
		/^"=/+1,$call s:Sort("s:FileDateCmp",s:sortdirection_WM)
	else
		/^"=/+1,$call s:Sort("s:FileNameCmp",s:sortdirection_WM)
	endif

	" Replace the header with updated information
	call s:UpdateHeader()

	" Restore section separators
	call s:AddSeparators()

	" Return to the position we started on
	0
	if search('\m^'.escape(startline,s:escregexp),'W') <= 0
		execute lin
	endif
	execute "normal!" col . "|"

	" Disallow modification
	setlocal nomodified
	setlocal nomodifiable

endfunction

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save


