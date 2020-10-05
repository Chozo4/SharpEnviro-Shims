#NoEnv
#SingleInstance FORCE
#NoTrayIcon
#KeyHistory 0
ListLines Off

OnMessage(0x219, "MsgHandler")

global $DevUnin,$DevInst,$DevFail
RegRead, $DevUnin, HKEY_CURRENT_USER\AppEvents\Schemes\Apps\.Default\DeviceDisconnect\.Current
RegRead, $DevInst, HKEY_CURRENT_USER\AppEvents\Schemes\Apps\.Default\DeviceConnect\.Current
RegRead, $DevFail, HKEY_CURRENT_USER\AppEvents\Schemes\Apps\.Default\DeviceFail\.Current


;Prepare for receiving messages
;Source: Shaun4477 @ https://autohotkey.com/board/topic/70334-detecting-hardware-changes-for-example-new-usb-devices/
Gui +LastFound
VarSetCapacity(DevHdr, 32, 0)
NumPut(32, DevHdr, 0, "UInt"), NumPut(0x00000005, DevHdr, 4, "UInt")
DllCall("RegisterDeviceNotification", "UInt", WinExist(), "UInt", &DevHdr, "UInt", 0x00000004)
;------------------------------
Return 

MsgHandler(wParam, lParam, msg, hwnd) 
{
 static $ChkFail := 1

 if (wParam == 0x0007)
   return

 if NumGet(lParam+15, 6, "UChar") != 0x1F
   return $ChkFail := 0

 if ($DA := (wParam == 0x8000))
   $ChkFail := 1

 SoundPlay, % ($DA?$DevInst:($ChkFail?$DevFail:$DevUnin))
}
