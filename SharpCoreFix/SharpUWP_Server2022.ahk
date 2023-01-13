;--------------------------------------------------------------
;SHARPECOREFIX.AHK - Chozo4 [Chozo@juno.com]
;Intercepts the calls to ms-settings to preload explorer
;--------------------------------------------------------------
#NoEnv
#KeyHistory 0
#NoTrayIcon
ListLines Off
SetBatchLines, -1
setworkingdir, %A_WinDir%
Process, Priority,, R

ProcessExist($Proc)
{
  Process, Exist, % $Proc
  return errorlevel
}

CheckPerm()
{
  tooltip, % "Checking Permissions..."
  RegWrite, REG_SZ, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, test, 1234
  RegRead, $HasPerm, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, test
  RegDelete, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, test

  return $HasPerm
}

Process_Resume(pid)
{
    If (h:=DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", pid))
    {
      DllCall("ntdll.dll\NtResumeProcess", "Int", h)
      DllCall("CloseHandle", "Int", h)
    }
}

Process_Suspend(pid){
    If (h:=DllCall("OpenProcess", "uInt", 0x1F0FFF, "Int", 0, "Int", pid))
    {
      DllCall("ntdll.dll\NtSuspendProcess", "Int", h)
      DllCall("CloseHandle", "Int", h)
    }
}

if (ProcessExist("SystemSettings.exe"))
{
  msgbox, 49,Settings Redirector, Settings Panel is already running.`n`nReload?
  IfMsgBox Ok
    Process, Close, SystemSettings.exe
  else exitapp
}

if %1%
{

  ;return to default delegation to call the settings panel normally now on explorer reload. Also fallback on script failure.
  tooltip, % "Reverting to Default Delegate..."
  RegDelete, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, AHK_DEFAULT
  RegWrite, REG_SZ, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, DelegateExecute, {4ed3a719-cea8-4bd9-910d-e252f997afc2}

  if (!ProcessExist("sharpcore.exe") && !ProcessExist("sharpbar.exe"))  ;called without active SharpEnviro - assume self disable
  {
   ; run, C:\Windows\explorer.exe,,,$PID
    tooltip, % "Waiting for Shell_TrayWnd to exist..."
    while !WinExist("ahk_class Shell_TrayWnd")
      sleep 10
    tooltip, % "Running settings..."
    run, explorer %1%
    tooltip
    exitapp
  }

  tooltip, % "Closing instances of explorer.exe"
  ;query, kill, suspend
  for $Q2 in ComObjGet("winmgmts:").ExecQuery("Select Name,CommandLine,Handle,ExecutablePath from Win32_Process WHERE Name = ""sharpbar.exe"" OR Name = ""explorer.exe""")
   {
     if ($Q2.Name = "sharpbar.exe") ;resume before suspending 'just in case' [bugfix]
     {
       RegExMatch($Q2.CommandLine,"i)(.*)\\.*:(.*)",$sub,2)                                                             
       $path := $sub1 "\Settings\User\" A_UserName "\SharpBar\Bars\" $sub2 "\Bar.xml"
       $CorePath := $sub1 "\sharpcore.exe"
       $cont := (($fh:=FileOpen($path, "r-d")).read(1024)), $fh.close()
       if InStr($cont,"<Name>Systray</Name>")
         Process_Suspend($SystrayID := $Q2.Handle)
     }
     else if (($Q2.Name = "explorer.exe") && !inStr($Q2.CommandLine, "-Embedding")) ;Must use taskkill - "Process, Close" just causes it to restart
       runwait, % "taskkill /f /PID " $Q2.Handle,,hide
   }

  Process, Close, sharpcore.exe
  run, C:\Windows\explorer.exe,,,$PID
  ;Process, Priority, $PID, Low

  ;Split off into another EXE ;need to try and integrate this and somehow still work
  ;run, % A_ScriptDir . "\hidedesk.exe"

  tooltip, % "Waiting for Shell_TrayWnd to exist..."
  while !WinExist("ahk_class Shell_TrayWnd")
    sleep 0
  WinHide
  WinHide, ahk_class Progman,,5


  tooltip, % "Running settings..."
  run, explorer %1%

  ;Hunt down the taskbar thread.
  ;This usually seems to be the first thread to appear with a Base Priority of 9 within explorer.exe.
  tooltip, % "Searching for taskbar thread..."
  SetTimer, Timeout2, -5000
    while !$T.Handle && !$Timeout  
      for $T in ComObjGet("winmgmts:").ExecQuery("Select handle from Win32_Thread WHERE ProcessHandle = " $PID " AND PriorityBase = 9")
        break
  SetTimer, Timeout2, Delete

  ;Process, Wait, SystemSettings.exe , 5

  ;Wait for the ApplicationFrameWindow to confirm the settings opened.
  tooltip, % "Waiting for Application frame window"
  SetTimer, Timeout, -5000
  while !hCtl
    ControlGet, hCtl, Hwnd, , Windows.UI.Core.CoreWindow1, ahk_class ApplicationFrameWindow
;winhide
  SetTimer, Timeout, Delete


  ;kill taskbar thread AFTER loading in the settings panel - it won't work otherwise
  $h := DllCall("OpenThread", "uint", 0x0001, "int", 0, "uint", $T.Handle, "ptr")
  DllCall("TerminateThread", "ptr", $h), DllCall("CloseThread", "ptr", $h)

  ;Reload Sharpcore now
  run, % $CorePath

  ;resume SharpBar Process (needed to hide the sharpbar relorad)
  ;for $Q in ComObjGet("winmgmts:").ExecQuery("Select CommandLine,Handle from Win32_Process WHERE Name = ""sharpbar.exe""")
    Process_Resume($SystrayID)

tooltip, % "Waiting for AFW"
WinWait, % "ahk_pid " $PID " ahk_class ApplicationFrameWindow"
Winhide
WinHide, % ahk_exe ShellExperienceHost.exe

 ;;DISABLED: We really don't need to close it soooooo.......
 ;tooltip, % "Waiting for settings to close to close AFH..."
 ; while hCtl
 ; {
 ;   sleep 500
 ;   ControlGet, hCtl, Hwnd, , Windows.UI.Core.CoreWindow1, ahk_class ApplicationFrameWindow
 ; }
 ; Process, Close, ApplicationFrameHost.exe
}
else   ;This is a fucking mess - reassess this garbage
{
  if !CheckPerm()
  {
  tooltip, % "Redirecting MS-Settings calls..."
    ;Random, $Temp
    ;FileAppend, SUBINACL /keyreg HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command /setowner=%USERNAME% /grant=%USERNAME%=F\n\r, %$Temp%
    ;FileAppend, SUBINACL /keyreg HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command /grant=%USERNAME%=F, %$Temp%
    ;FileAppend, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command [1 5 7 11 17], %$Temp%
    ;RunWait, regini.exe %$Temp%
    RunWait, SUBINACL /keyreg HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command /setowner=Everyone /grant=Everyone=F
    ;FileDelete, %$Temp%
    if !CheckPerm()
      msgbox, "Failed to set permissions"
  }
}  ;END  fucking mess

;Reregister script as the intercept
RegWrite, REG_SZ, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command,, % A_ScriptFullPath " %1"
RegDelete, HKEY_CLASSES_ROOT\ms-settings\Shell\Open\Command, DelegateExecute

tooltip
exitapp

Timeout:
hCtl := 1
msgbox Thread timed out waiting for ApplicationFrameWindow
return

Timeout2:
$Timeout := 1
msgbox Thread timed out waiting for Taskbar Thread
return


