Gui +LastFound


global DEVICE_NOTIFY_WINDOW_HANDLE := 0x0 
global DBT_DEVTYP_DEVICEINTERFACE  := 5
global DEVICE_NOTIFY_ALL_INTERFACE_CLASSES := 0x00000004
global DBT_CONFIGCHANGECANCELED   := 0x0019
global DBT_DEVNODES_CHANGED       := 0x0007
global DBT_DEVICEREMOVECOMPLETE   := 0x8004
global DBT_DEVICEARRIVAL          := 0x8000
global DBT_DEVTYP_DEVICEINTERFACE := 0x00000005
global $DevUnin,$DevInst,$DevFail
; Monitor for WM_DEVICECHANGE 

OnMessage(0x219, "notify_change")

VarSetCapacity(DevHdr, 32, 0) ; Actual size is 29, but the function will fail with less than 32
NumPut(32, DevHdr, 0, "UInt") ; sizeof(_DEV_BROADCAST_DEVICEINTERFACE) (should be 29)
NumPut(DBT_DEVTYP_DEVICEINTERFACE, DevHdr, 4, "UInt") ; DBT_DEVTYP_DEVICEINTERFACE
Flags := DEVICE_NOTIFY_WINDOW_HANDLE|DEVICE_NOTIFY_ALL_INTERFACE_CLASSES
DllCall("RegisterDeviceNotification", "UInt", WinExist(), "UInt", &DevHdr, "UInt", Flags)


DIGCF_DEFAULT := 0x00000001  ; only valid with DIGCF_DEVICEINTERFACE; only the device that is associated with the system default device interface
DIGCF_PRESENT := 0x00000002   ; only devices that are currently present in a system
DIGCF_ALLCLASSES := 0x00000004   ; list of installed devices for all device setup classes or all device interface classes
DIGCF_PROFILE := 0x00000008   ; only devices that are a part of the current hardware profile
DIGCF_DEVICEINTERFACE := 0x00000010   ; devices that support device interfaces for the specified device interface classes.
DIGCF_INTERFACEDEVICE := DIGCF_DEVICEINTERFACE   ; obsolete, only for backwards compatibility
SPINT_ACTIVE  := 0x00000001
SPINT_DEFAULT := 0x00000002
SPINT_REMOVED := 0x00000004
SPDRP_FRIENDLYNAME := 0x0000000C
SPDRP_DEVICEDESC   := 0x00000000
SPDRP_CLASS        := 0x00000007
SPDRP_MFG          := 0x0000000B
SPDRP_ENUMERATOR_NAME := 0x00000016
SPDRP_SERVICE      := 0x00000004
SPDRP_PHYSICAL_DEVICE_OBJECT_NAME := 0x0000000E
SPDRP_LOCATION_INFORMATION := 0x0000000D

GetGuid(FromAddr)
{

    Guid := GetPaddedHex(FromAddr+0, "UInt", 8) . "-" . GetPaddedHex(FromAddr+4, "UShort", 4) . "-" . GetPaddedHex(FromAddr+6, "UShort", 4) . "-" 
            . GetPaddedHex(FromAddr+8, "UChar", 2) . GetPaddedHex(FromAddr+9, "UChar", 2) . "-" . GetPaddedHex(FromAddr+10, "UChar", 2) . GetPaddedHex(FromAddr+11, "UChar", 2) 
            . GetPaddedHex(FromAddr+12, "UChar", 2) . GetPaddedHex(FromAddr+13, "UChar", 2) . GetPaddedHex(FromAddr+14, "UChar", 2) . GetPaddedHex(FromAddr+15, "UChar", 2) 
    return Guid
}
 
; Get padded hex value from an address, pad with leading 0s up to 16 
GetPaddedHex(FromAddr, Type, PadLen)
{

    Old := A_FormatInteger 
    SetFormat, IntegerFast, Hex
    Pad := "0000000000000000"  
    ; Get the number in hex
    HexStr := NumGet(FromAddr+0, 0, Type) 
    ;MsgBox, %HexStr% %Type%
    ; Strip leading 0x 
    HexStr := SubStr(HexStr, 3, StrLen(HexStr) - 2)
    ; Pad 
    if (StrLen(HexStr) < PadLen)
      HexStr := SubStr(Pad, 1, PadLen - StrLen(HexStr)) . HexStr
    SetFormat, IntegerFast, %Old%
    return HexStr
}


RegRead, $DevUnin, HKEY_CURRENT_USER\AppEvents\Schemes\Apps\.Default\DeviceDisconnect\.Current
RegRead, $DevInst, HKEY_CURRENT_USER\AppEvents\Schemes\Apps\.Default\DeviceConnect\.Current
RegRead, $DevFail, HKEY_CURRENT_USER\AppEvents\Schemes\Apps\.Default\DeviceFail\.Current


DebugOutput($In,$clear=0)
{
  static $out := []
 

  if $clear
  {
    $out := []
    FileAppend, -------------------`n-------------------`n, .\device.log
  }  
  $Temp :=
  $In := $In . "`n"

  FileAppend, %$In%, .\device.log

  if $out.Length() >= 50
    $out.RemoveAt(1)
  $out.Push($In)
  for k, $v in $out
    $Temp .= $v

  tooltip % $Temp, 10, 200
}

Return 

notify_change(wParam, lParam, msg, hwnd) 
{

 static $test := 0
;32768=0x8000 32772=0x8004
 ;if NumGet(lParam+0, 4, "UInt") !== 5 && (NumGet(lParam+15, 6, "UChar") != 0x1F)
DebugOutput(wParam . " -- " . lParam . " -- " . NumGet(lParam+0, 4, "UInt") . " -- " . NumGet(lParam+15, 6, "UChar") . " -- " . GetGuid(lParam+12))
if (wParam == 0x8000)
{
DebugOutput("insert")
SoundPlay, % $DevInst
  if NumGet(lParam+15, 6, "UChar") == 0x1F
    $test := 1
  else $test := 0
}
if (wParam == 0x8004)
{
DebugOutput("remove")
  if NumGet(lParam+15, 6, "UChar") == 0x1F
    if $test
    {
      SoundPlay, % $DevFail
      $test :=0
    }
    else 
      SoundPlay, % $DevUnin
}

if NumGet(lParam+15, 6, "UChar") != 0x1F
  return
 



}

;4D1E55B2-F16F-11CF-88CB-001111000030 HID DEVICE (ignore?)
;A5DCBF10-6530-11D2-901F-00C04FB951ED USB DEVICE (ignore?)
;884B96C3-56EF-11D1-BC8C-00A0C91405DD DEV KEYBOARD
;53F56307-B6BF-11D0-94F2-00A0C91EFB8B DEV DISK
;F4481A0E-7B94-4F2F-96D2-9BABA1CCC680 ????PartitionMount????
;F33FDC04-D1AC-4E8E-9A30-19BBD4B108AE USB DEVBLOCK - Deny READ
;65A9A6CF-64CD-480B-843E-32C86E1BA19F ??????????????????????
;6AC27878-A6FA-4155-BA85-F98F491D4F33 GUID_DEVINTERFACE_WPD - DENY WRITE
