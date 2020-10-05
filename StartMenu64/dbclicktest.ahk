#NoEnv
;#Warn
#SingleInstance force
#KeyHistory 0
#NoTrayIcon
ListLines Off
Send, {LWin Up}
SetBatchLines -1

PID=%1%
DCT:=DllCall("GetDoubleClickTime")
MouseOnMenu(PID) 
{
  MouseGetPos,,, ID
  WinGet, ID, PID, ahk_id %ID%
  return ID==PID
}
#if MouseOnMenu(PID)
~LButton::
  MouseGetPos, X, Y
  If(Lx==X && Ly==Y && A_PriorHotKey = A_ThisHotKey && A_TimeSincePriorHotkey < DCT)
  {
    MouseClick, Middle
    Lx=0
    Ly=0
    return
  }

  Lx:=X
  Ly:=Y

return