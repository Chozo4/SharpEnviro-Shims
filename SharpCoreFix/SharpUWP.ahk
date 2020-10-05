;--------------------------------------------------------------
;SHARPECOREFIX.AHK - Chozo4 [Chozo@juno.com]
;Intercepts the calls to ms-settings to preload explorer
;--------------------------------------------------------------
#NoEnv
#SingleInstance FORCE
#KeyHistory 0
ListLines Off
setworkingdir, %A_WinDir%

ProcessExist($Proc)
{
  Process, Exist, % $Proc
  return errorlevel
}

if %1%
{
  $CoreID := ProcessExist("sharpcore.exe")
  for $Q in ComObjGet("winmgmts:").ExecQuery("Select CommandLine,Handle from Win32_Process WHERE Handle = " $CoreID)
    $CorePath := $Q.CommandLine


  while ProcessExist("sharpbar.exe")
    Process, Close, sharpbar.exe
  Process, Close, sharpcore.exe
  Process, Close, systemsettings.exe
  RegDelete, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, AHK_DEFAULT
  RegWrite, REG_SZ, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, DelegateExecute, {4ed3a719-cea8-4bd9-910d-e252f997afc2}
  
  $KeepBar := WinExist("ahk_class Shell_TrayWnd")
  if !($KeepBar)
  {
   ; for $Q in ComObjGet("winmgmts:").ExecQuery("Select CommandLine,Handle from Win32_Process WHERE Name = ""explorer.exe""")
     ; if !inStr($Q.CommandLine, "{682159d9-c321-47ca-b3f1-30e36b2ec8b9}")
     ;   Process, Close, % $Q.Handle
    while ProcessExist("explorer.exe")
      Process, Close, explorer.exe

    run, % A_ScriptDir . "\hidedesk.exe"
    run, C:\Windows\explorer.exe,,,$PID

    while !WinExist("ahk_class Shell_TrayWnd")
      sleep 10
    WinHide, ahk_class Shell_TrayWnd
    run, HideDesk
    while !$T.Handle   
      for $T in ComObjGet("winmgmts:").ExecQuery("Select handle from Win32_Thread WHERE ProcessHandle = " $PID " AND PriorityBase = 9")
        break
  }

  run, explorer %1%

  ;Process, Wait, SystemSettings.exe , 5
  while !hCtl
    ControlGet, hCtl, Hwnd, , Windows.UI.Core.CoreWindow1, ahk_class ApplicationFrameWindow

  if !$KeepBar ;Likely sharpcore was active
  {


    $h := DllCall("OpenThread", "uint", 0x0001, "int", 0, "uint", $T.Handle, "ptr")
    DllCall("TerminateThread", "ptr", $h), DllCall("CloseThread", "ptr", $h)
    run, % $CorePath
  }
}
else
{
  RegWrite, REG_SZ, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, test, 1234
  RegRead, $HasPerm, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, test
  RegDelete, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, test
  if !$HasPerm
  {
    Random, $Temp
    FileAppend, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command [1 5 7 11 17], %$Temp%
    RunWait, regini.exe %$Temp%
    FileDelete, %$Temp%
  }
}
RegWrite, REG_SZ, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command,, % A_ScriptFullPath " %1"
RegDelete, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, DelegateExecute



