"========================Win Manager Add in=============================
" 	File: addToWinManager.vim v 1.01
"      Author: anubhav47@hotmail.com
" Last Change: Sat, Jan 19th 2001,3:30 pm IST
"  Dependency: This plugin will work only if you already have installed  
"              winmanager plugin(vimscript#95).
"              
" NOTE: To install simply drop it in your plugin directory. 
" 
"
" See ":help winmanager" for details on winmanager .
" ========================================================================
" Instructions:
" Will help user in easy navigation between directories
" user can use Dir-shortcut menu to:
"			Add a new directory shortcut
"			Jump to directory 
"
" All menu shortcuts created for user are placed in $HOME/.menu1.vim
" Hence $HOME need to be declared. Also, for sys-adm type people this allows 
" different users to use the same plugin
" Users can edit the generated file ($HOME/.menu1.vim) directly.
" See ":help menu" for details on menu command.
"=======================================================================
" Changes:
" v1.01
" -----
" 	The prime aim of this release is to be in sync with winmanager plugin,
" release 2.0 was made on 18th Jan.
" 	1). Now you don't need to source this file just drop in your plugin
"	    directory. so installation is much easier.
"	2). A new command to add current directory to Dir-shortcut menu is added.
"	3). There was little problem on windows machines, / were not escaped properly,
"	    this has been rectified.
"	4). A direct access to .menu1.vim is provided through the Dir-shortcut menu
"	
" v1.0
" ----
" A little change has been made to winmanager script as well (hardly 10 lines)
" User can easy identify them and paste in their winmanager if they want to 
" stick to their old winmanager script. If script is older than version 1.0.9,
" to use this, user need to upgrade.
"=======================================================================
" Bugs and Suggestions:
" Send any bugs or suggestions for the script to me directly at 
" anubhav47@hotmail.com. For any issues with winmanager as such contact
" Srinath
"=======================================================================
" Known issues:
" 		1). Actually uses the same number for all menu-items added 
"   		    which is not very elegent way for doing it, but for ease
"		    of implementation it has been done that way, suggestions 
"		    welcome
"		2). You may get a warning that file $HOME/.menu1.vim doesnot
"		    exist, at vim startup this is normal behaviour, as soon
"		    as you create a Directory shortcut , that warning will stop
"		    bothering.
"========================================================================
" Thanks to:
"	Srinath for the wonderful script he has created.
"	All those who helped me learn vim
"========================================================================

fun! Add_ShortCut_Dir()
  let Shrtcut=inputdialog("Enter name of menu item")
  let Shrtcut=escape(Shrtcut," ")
  let Dir=inputdialog("Enter Full Path to directory")
  let Dir=escape(Dir," ")
  let Dir=escape(Dir,"\\")
  call Add_to_File(Shrtcut,Dir)
endfun

fun! Add_to_File(ShrtcutName,Dirname)
  if ( a:ShrtcutName == "" || a:Dirname == "")
  	echo "Value not entered for one of Menu item name or path"
  else
  	exec "redir >> ".$HOME."/.menu1.vim"
  	echo "amenu 8888.7 Dir-shortcuts.".a:ShrtcutName."	:call Explore_Dir(\"".a:Dirname."\")<CR>"
  	exec "redir END"
  	exec "so ".$HOME."/.menu1.vim"
  endif
endfun

fun! Explore_Dir(dir)
  	exec "WManager"	
	exec "cd ".a:dir
	exec "FirstExplorerWindow"
	exec "normal C"
endfun

fun! Add_Curr_Dir()
	exec "FirstExplorerWindow"
	exec "normal c"
	let Dir=getcwd()
  	let Dir=escape(Dir," ")
  	let Dir=escape(Dir,"\\")
  	let Name=inputdialog("Enter name of menu item")
  	let Name=escape(Name," ")
	call Add_to_File(Name,Dir)
endfun	

fun! Edit_Menu_file()
	exec "normal "
	exec "sp $HOME/.menu1.vim"
endfun	

amenu 8888.1 Dir-shortcuts.Add\ Shortcut	:call Add_ShortCut_Dir()<CR>
amenu 8888.2 Dir-shortcuts.Add\ \CurrentDir\ to\ Shortcut	:call Add_Curr_Dir()<CR>
amenu 8888.2 Dir-shortcuts.Edit\ Shortcuts\ File 	:call Edit_Menu_file()<CR>
amenu 8888.5 Dir-shortcuts.Sweet-Home	:call Explore_Dir("~") <CR>
amenu 8888.4 Dir-shortcuts.-sep-	<nul>

so $HOME/.menu1.vim


