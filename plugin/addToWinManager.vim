"========================Win Manager Add in=============================
" Instructions:
" This file need to be sourced from your .vimrc file
" Will help user in easy navigation between directories
" user can use Dir-shortcut menu to:
"			Add a new directory shortcut
"			Jump to directory 
"
" All menu shortcuts created for user are placed in $HOME/.menu1.vim
" Hence $HOME need to be declared. Also, for sys-adm type people this allows 
" different users to use the same plugin
" Users confident enough can edit the file directly
"=======================================================================
" Changes:
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
  let ShrtcutName=inputdialog("Enter name of menu item")
  let ShrtcutName=escape(ShrtcutName," ")
  let Dirname=inputdialog("Enter Full Path to directory")
  if ( ShrtcutName == "" || Dirname == "") 
  echo "Value not entered for one of Menu item name or path"
  else
  exec "redir >> ".$HOME."/.menu1.vim"
  echo "amenu 8888.7 Dir-shortcuts.".ShrtcutName."	:call Explore_Dir(\"".Dirname."\")<CR>"
  exec "redir END"
  exec "so ".$HOME."/.menu1.vim"
  endif
endfun



amenu 8888.1 Dir-shortcuts.Add\ Shortcut	:call Add_ShortCut_Dir()<CR>
amenu 8888.4 Dir-shortcuts.Sweet-Home	:call Explore_Dir("~") <CR>
amenu 8888.3 Dir-shortcuts.-sep-	<nul>

so $HOME/.menu1.vim


