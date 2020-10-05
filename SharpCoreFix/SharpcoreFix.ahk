;--------------------------------------------------------------
;SHARPECOREFIX.AHK - Chozo4 [Chozo@juno.com]
;Restores File Browser auto refresh
;Fixes Allows hooking of TaskBar/Systray
;--------------------------------------------------------------
#NoEnv
#Persistent
#SingleInstance FORCE
#KeyHistory 0
ListLines Off
SetTimer, CoreMon, 1000


ProcessExist($Proc)
{
  Process, Exist, % $Proc
  return errorlevel
}

KillExplorerTray()
{
  ;--- Should add a sanity check - step thread term if not successful first time
  while ProcessExist("explorer.exe")
    Process, Close, explorer.exe

  Run, C:\windows\explorer.exe

  while !$Y
    WinGetPos,, $Y,,, ahk_class Shell_TrayWnd

  for $Q in ComObjGet("winmgmts:").ExecQuery("Select CommandLine,Handle from Win32_Process WHERE Name = ""explorer.exe""")
    if !inStr($Q.CommandLine, "/factory")
    {
      while !$T.Handle   
       for $T in ComObjGet("winmgmts:").ExecQuery("Select handle from Win32_Thread WHERE ProcessHandle = " $Q.Handle " AND PriorityBase = 9")
         break
    }

    $h := DllCall("OpenThread", "uint", 0x0001, "int", 0, "uint", $T.Handle, "ptr")
    DllCall("TerminateThread", "ptr", $h), DllCall("CloseThread", "ptr", $h)

   ;---SANITYCHECK
    WinGetPos,, $Y,,, ahk_class Shell_TrayWnd
    if $Y
      msgbox % "OOPS! WRONG THREAD!"
}
return

;C:\Windows\explorer.exe" /factory,{682159d9-c321-47ca-b3f1-30e36b2ec8b9} -Embedding
;C:\Windows\explorer.exe /factory,{75dff2b7-6936-4c06-a8bb-676a7b00b24b} -Embedding
CoreMon:
  if WinExist("ahk_class Shell_TrayWnd")
  {
    if ProcessExist("SharpCore.exe")
     return

   msgbox % "Found Tray"
   KillExplorerTray()
   Run Z:\Newcore\Sharpcore.exe
  }
return
;msgbox END
;Run Z:\Newcore\Sharpcore.exe
return
      

;-------------- MUST ADD PROCES ID MONITORING HERE
;-------------- TO RESTART THE PROCESS IF ONE DIES
