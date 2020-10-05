;--------------------------------------------------------------
;EXPLORERFIX.AHK - Chozo4 [Chozo@juno.com]
;Restores context menu on Explorer Window Icon RightClick
;Restores backspace functionality to advance to parent folder
;--------------------------------------------------------------
#Include ShellContextMenu.ahk ;https://autohotkey.com/board/topic/89281-ahk-l-shell-context-menu/
#NoEnv
#SingleInstance FORCE
#NoTrayIcon
#KeyHistory 0
ListLines Off

global Last, path, CTextSZ, mX, mY, ID
SysGet, CTextSZ, 31
SysGet, BorderSZ, 33
CTextSZ+=BorderSZ
coordmode, mouse, screen

CanContext(ID) ;cleanup
{
  if !path
    return 0

  WinGetPos, wX, wY,,,ahk_id %ID%
  return  ((mX-wX) <= CTextSZ && (mY-wY) <= CTextSZ)
}


IsCabinetW(ID)
{
  mousegetpos,mX,mY,ID

  if (ID==Last) 
    return ID

  WinGetClass, cID, ahk_id %ID%
  if path:=(cID == "CabinetWClass")
  {
    WinGetText, test, ahk_id %ID%
    RegExMatch(test, "Address: (.+?)\r", test)
    ;path:=(InStr((test1:=test1 "\"),":",,2) && FileExist(test1))?test1:0
    path:=FileExist(test1)?test1:0
  }
  return Last:=ID
}

dllcall("psapi.dll\EmptyWorkingSet", "UInt", -1)
return

#If CanContext(ID:=IsCabinetW(ID))
RButton::
  WinActivate, ahk_id %ID%
  ShellContextMenu(path)
return
#If

#IfWinActive, ahk_class CabinetWClass
Backspace::
   ControlGet renamestatus,Visible,,Edit1,A
   if(renamestatus!=1)
     SendInput {Alt Down}{Up}{Alt Up}
   else
     Send {Backspace}
#IfWinActive

