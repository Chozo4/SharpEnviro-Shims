#NoEnv
#persistent
#Warn
#KeyHistory 0
#SingleInstance force
SetBatchLines -1
ListLines Off
CoordMode,Mouse,Screen
Menu, Tray, NoStandard
Menu, Tray, Add, Open Volume Mixer, Open
Menu, Tray, Add
Menu, Tray, Add, Playback Devices, PDev
Menu, Tray, Add, Recording Devices, RDev
Menu, Tray, Add, Sounds, Sounds
Menu, Tray, Add
Menu, Tray, Add, Exit
Menu, Tray, Icon, SndVolSSO.dll,2
dllcall("psapi.dll\EmptyWorkingSet", "UInt", -1)

Global X,Y,SND:=0,CHK:=0, DCT:=DllCall("GetDoubleClickTime")/1000

OnMessage(0x404, "AHK_NotifyIcon")
Settimer,CheckVol,50
return

MAKELONG($A,$B)
{
  return ($A * 65536 + $B)
}

AHK_NOTIFYICON($wParam,$lParam)
{

  if $lParam = 0x202            ; WM_LBUTTONUP
  {
    MouseGetPos, X, Y
    KeyWait, LButton, D T%DCT%
    Run, % "sndvol " . (ErrorLevel?"-f ":"-m ") . MAKELONG(Y,X)
    CHK:=1
    Settimer,CheckVol,500
  }
  else if $lParam = 0x205 
    MouseGetPos, X, Y
}

~Volume_Up::
~Volume_Down::
~Volume_Mute::
  Settimer,CheckVol,500
return

CheckVol:
  SoundGet, V
  SoundGet, M,, mute

  if (SND!=(V:=(M="On")?-1:V))
    Menu, Tray, Icon, SndVolSSO.dll, % (SND:=V)>=66?6:(V>=33?5:(V>0?4:(V<0?2:3)))
  if CHK
    CHK:=WinExist("ahk_exe SndVol.exe")
  Settimer,CheckVol,% (CHK?500:5000)
return
Open:
    Run, % "sndvol -m " . MAKELONG(Y,X)
return
PDev:
    Run, % "RunDll32 shell32.dll,Control_RunDLL mmsys.cpl,,0"
return
RDev:
    Run, % "RunDll32 shell32.dll,Control_RunDLL mmsys.cpl,,1"
return
Sounds:
    Run, % "RunDll32 shell32.dll,Control_RunDLL mmsys.cpl,,2"
return
Exit:
  ExitApp 