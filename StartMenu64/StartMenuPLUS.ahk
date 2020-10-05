#NoEnv
#persistent
;#Warn
;#NoTrayIcon
#SingleInstance force
#Include PUM_API.ahk
#Include PUM.ahk
#KeyHistory 0
SendMode Input
SetBatchLines -1
ListLines Off

Send, {LWin Up}
Menu, Tray, NoStandard
Menu, Tray, Add, Exit
 
SysGet, $GetIconSz, 49
SetWorkingDir, %A_ScriptDir%
tooltip "SMP Status: Loading.."

global $Opts:=IniParse(".\StartMenu.ini","Options")
if !$Opts["IconSize"]
  $Opts["IconSize"]:=$GetIconSz

global $MenuOpts:={"Iconssize":$Opts["IconSize"],"xmargin":2,"ymargin":2,"textMargin":0}
global $MenuGen:={"Iconssize":$Opts["IconSize"],"xmargin":2,"ymargin":2,"textMargin":0,"gen":1}
global pm := new PUM({"oninit":"PUM_out","onrbutton":"PUM_out","onmbutton":"PUM_out","onrun":"PUM_out","onselect":"PUM_out"})
global navi, RecF := pm.CreateMenu($MenuGen), RecD := pm.CreateMenu($MenuGen), $oRecD:={}, $oRecF:={}
global IconPUM := (new PUM()).CreateMenu($MenuOpts), $HCache:={"?":IconPum.add({"name":"?","icon":"Shell32.dll:3"}).GetIconHandle()}

WinGet, SharpID, list,ahk_class TSharpBarMainForm ;sharpbar to top

FileInstall Autohotkey.dll, %A_Temp%\Thread.dll
hModule:=DllCall("LoadLibrary","Str",A_Temp "\Thread.dll")

;------------------------------------------
;Iterate available control panel items
;------------------------------------------
CP:={}, $CPIndex:=0, $COM:=ComObjCreate("Shell.Application").Namespace(0x0003).Items

;Some Icons Cannot be gotten from registry. Load from INI.
$Icon:=IniParse(".\StartMenu.ini","CPLIcons")

;Pre-Parse the Control Panel
For $CplItem In $COM
{
  $CPIndex++, $SortID:=""

  RegExMatch($CplItem.Path, "({.+}).*", $CP_Path,35)
  RegRead, $out, HKCR\CLSID\%$CP_Path1%\DefaultIcon
  $out:=$Icon[$CplItem.Name]?$Icon[$CplItem.Name]:$out

  if !$out
    Loop, Reg, HKLM\Software\Microsoft\Windows\CurrentVersion\Control Panel\Extended Properties\System.Software.AppId\, KV
    {
      RegRead, $value
      if trim($value)=trim($CP_Path1)
        if !InStr($Out:=StrReplace(StrReplace(A_LoopRegName,"@i",""), "%systemroot%\system32\",""),",")
          $out.=",0"
    }
  $out:=!$out?"shell32.dll,2":$out
  ;Hacky way to sort arrays by name but it works for this purpose. Could use cleanup.
  StringUpper, $SortName, % $CplItem.Name
  loop 3
    $SortID.=StrPad(Asc(SubStr($SortName,A_INDEX,1)),3,0)

  CP[$CPIndex]:={"name" : $CplItem.Name,"sort":$SortID,"submenu":control,"path":"explorer.exe "$CplItem.Path,"root":1,"icon":StrReplace($out,",",":"),"Gen":1,"CPL":$CplItem}
}
CP:=SortRecent(CP,"sort",1)

;END Interate

;------------------------------------------
;Generate directory listings and item cache
;------------------------------------------
GenList(ByRef targ,path=0,fold=1)
{
  if targ.gen
    return

  critical
  static x:=0,cache:={"*":"shell32.dll:0",".exe":"%1",".lnk":"*",".msc":"*"}
  static $DIcon:={"Unknown":6,"Removable":7,"Fixed":8,"Network":9,"CDROM":11,"RAMDisk":12}

  tooltip % "Building: " path

  if !path
    DriveGet, list, list
  else
  {
    Loop, Files, %path%*, DF
    {
      if (!$Opts["ShowHidden"] && InStr(A_LoopFileAttrib,"H",1)) || A_LoopFileName="desktop.ini" ;hide hidden files
        continue
      $files .=(InStr(A_LoopFileAttrib,"D",1)?0:1) A_LoopFileName "`n"
    }
    Sort, $files

  }
  Loop, parse, % !path?list:$files,% !path?"":"`n",`r
  {
    if !path
    {
      DriveGet, label, label, %A_LoopField%:
      DriveGet, type, type, %A_LoopField%:
      A_FileName:=A_LoopField
    }
    else if !A_LoopField
      break
    else
     A_FileName:=substr(A_LoopField,2) ;shim

    ;tooltip % "~Adding: " A_FileName

    ;------------------------------------------------------
    ;TODO: Make names pretty or not with 'show ext' option?
    ;       - get from registry this option?
    ;------------------------------------------------------
    if Fold && Fold:=(!path || InStr(FileExist(path A_FileName),"D"))
    {
      x++
      temp:=targ.Add( { "name" : path?A_FileName "\":"(" A_FileName ":) " label
                , "submenu" : (M_%x% := pm.CreateMenu($MenuOpts))
                , "root" : !path
                , "icon" : path?$HCache["?"]:("shell32.dll:" $DIcon[type])
                , "path" : path?path:A_FileName ":\" } )
    }
    else
    {
      file:=
      if ($ext:=SubStr(A_FileName,$e:=InStr($Old:=A_FileName,".",,-1)))=.lnk
      {
        FileGetShortcut, % path A_FileName,file
        $ext:=SubStr(File,InStr(File,".",,-1))
        ;A_FileName:=SubStr($Old,1,$e-1)
        A_FileName:=$Old

      }
      if !($out:=cache[$ext:=$ext?$ext:"*"])
      {
        RegRead, $out, HKCR\%$ext%
        RegRead, $out, HKCR\%$out%\DefaultIcon

        $out:=cache[$ext]:=StrReplace($out?$out:"shell32.dll,0", ",", ":" )
        $HCache[$ext]:=IconPum.add({"name":$ext,"icon": ($out=="%1")?path "\" A_FileName ":0":$out}).GetIconHandle()
        ;tooltip, % "  +Cache: " $ext " -> " $out " (" $HCache[$ext] ")"
      }
        ;A_FileName:=SubStr($Old,1,$e-1)
      if file
        $out:=(fileexist(file)?file:"Shell32.dll") ":0"

      $icon:= ($ext ~= ".exe|.cur|.ani|.ico")?(($out=="%1")?path A_FileName ":0":$out):$HCache[$ext]
      temp:=targ.Add({"name":A_FileName,"icon": $icon,"path": path, "IconUseHandle":1})
    }
  }
  temp?0:targ.add({"name":"No files found","Disabled":1}) ;populate empty menus
  tooltip
  return 1
}

;------------------------------------------
;Handle user actions with the menu
;------------------------------------------
PUM_out( msg, ByRef obj )
{
  static ThisObj, $RecDIndex:=0, $RecFIndex:=0

  if( msg="onselect" )
    ThisObj:=obj

  if ( ThisObj && msg = "oninit" && !ThisObj.Gen)
    ThisObj.Gen:=GenList(ThisObj.submenu,(ThisObj.path (ThisObj.root?"":ThisObj.name))) 

  if ( msg ~= "onmbutton|onrun" && ThisObj.path)
  {
    navi.EndMenu()
    tooltip % "! Exec: " ThisObj.path (ThisObj.root?"":ThisObj.name)
    SetTimer, NoTooltip, -1500

    if ThisObj.CPL 
      ThisObj.CPL.InvokeVerb(0)
    else if ThisObj.root || fileexist(ThisObj.path ThisObj.name)
      Run, % ThisObj.path (ThisObj.root?"":ThisObj.name), % ThisObj.path?substr(ThisObj.path,1,InStr(ThisObj.path,"\",,0)):A_ScriptDir, UseErrorLevel

    if  A_LastError
      Tooltip % "!! Error Launching @ " ThisObj.path (ThisObj.root?"":ThisObj.name)

    for k, v in $oRecD
      if v.name=ThisObj.name
        $skipD:=$oRecD[k].time:=A_TickCount
    for k, v in $oRecF
      if v.name=ThisObj.path
        $skipF:=$oRecF[k].time:=A_TickCount

    if !$SkipD && !ThisObj.root
      $oRecD[++$RecDIndex]:={"time":A_TickCount, "name":ThisObj.name,"submenu":RecD,"icon":ThisObj.Icon,"path":ThisObj.path (ThisObj.root?"":ThisObj.name),"root":1}
    if !$SkipF && !ThisObj.root
      $oRecF[++$RecFIndex]:={"time":A_TickCount, "name":ThisObj.path,"submenu":RecF,"icon":$HCache["?"],"path":ThisObj.path,"root":1}

    $oRecD:=SortRecent($oRecD,"time"), $oRecF:=SortRecent($oRecF,"time")

  }
}

SortRecent(obj,key,asc=0) ;numeric sorting by key value
{
  $sort:={}, $index:=0

  while obj.MaxIndex()
  {
    $found:=asc?4294963440:0, $index++
    for k, v in obj
     if asc?(v[key]<=$found):(v[key]>=$found)
       $lastmatch:=k, $found:=v[key]

    $sort[$index]:=obj[$lastmatch]
    obj.Remove($lastmatch)
  }
  return $sort
}

StrPad(str,len,char=" ") ;Pad String left/right - negative length pads left.
{
  loop % len*((len<0)?-1:1)-StrLen(str)
    (len<0)?(str:=char str):(str.=char)
  return str
}

IniParse(Path,Section) ;Parse Sections into Key/Value pairs
{
  $out:={}
  IniRead, In, %Path%, %Section%
  Loop, parse, In, `n, `r
    $Temp:=StrSplit(A_LoopField,"="), $out[$Temp[1]]:=$Temp[2]
  return $out
}

;--------------------------------------------------
; Multithread without using another executable
; Previously "SM_CLICK.EXE
;--------------------------------------------------
ThreadCode =
(%
  #NoEnv
  #NoTrayIcon
  #KeyHistory 0
  ListLines Off
  SendMode Input
  Send, {LWin Up}

  PID:=DllCall("GetCurrentProcessId")
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
      Lx:=Ly:=0
      return
    }

    Lx:=X, Ly:=Y
  return
)

DllCall(A_Temp "\Thread.dll\ahktextdll","Str",ThreadCode,"Str","","CDecl")
;--------------------------------------------------

$ready:=dllcall("psapi.dll\EmptyWorkingSet", "UInt", -1)
tooltip, "SMP Status: Ready"
SetTimer, NoTooltip, -500

return

;-------------------------------------------------------
;TODO: Consider saving the recent sections into INI here
;-------------------------------------------------------
Exit:
  DllCall("FreeLibrary", "Ptr", hModule)
  FileDelete, %A_Temp%\Thread.dll
  ExitApp 

;------------------------------------------
;Replace WinKey functionality
;------------------------------------------
#if $ready ;Prevent Race condition opening menu before populated
$LWin::
  KeyWait, LWin, T0.1
  If ErrorLevel ;allow modifier keys
  {
    Send, {LWin Down} 
    KeyWait, LWin
    Send, {LWin Up} 
    return
  }

  Loop, % SharpID?SharpID:1
    WinActivate, % "ahk_id " SharpID%A_Index%

  control := pm.CreateMenu($MenuGen), RecD := pm.CreateMenu($MenuGen), RecF := pm.CreateMenu($MenuGen)
  GenList(navi := pm.CreateMenu($MenuOpts))
  Start := pm.CreateMenu($MenuOpts)

  ;Integration of start menu
  navi.add()
  ; FIXME: Check for unique items and re-order
  navi.Add( {"name":"&Programs","submenu":Start,"icon":"Shell32.dll:19","path":A_StartMenuCommon "\Programs\","root":1} )
  GenList(Start,A_StartMenu "\Programs\")
  navi.Add( {"name":"&Recent","submenu":RecD,"icon":"Shell32.dll:20"} )
  RecD.Add( {"name":"&Parent","submenu":RecF,"icon":"Shell32.dll:19"} )
  navi.Add( {"name":"&Settings","submenu":control,"icon":"Shell32.dll:21","path":"control","root":1} )
  navi.Add( {"name":"Sear&ch...", "icon":"Shell32.dll:22","path":$Opts["SharpCore"]?"Z:\Find\PDFind.exe":"search-ms:","root":1} )
  navi.Add( {"name":"&Run", "icon":"Shell32.dll:24","path":"rundll32.exe shell32.dll,#61","root":1} )
  navi.Add()
  if $Opts["SharpCore"]
  {
    ;navi.Add( {"name":"&Log Off", "icon":"Shell32.dll:27","path":"shutdown -l","root":1} )
    navi.Add( {"name":"Sh&utdown", "icon":"Shell32.dll:27","path":A_ScriptDir "\shutdown.exe","root":1} )
  }
  else
  {
    Shutdown := pm.CreateMenu($MenuGen)
    navi.Add( {"name":"Sh&utdown","Submenu":Shutdown,"icon":"Shell32.dll:27","path":"%windir%\System32\shutdown.exe -i","root":1} )
    Shutdown.Add( {"name":"Logoff", "path":"%windir%\System32\shutdown.exe -l","root":1} )
    Shutdown.Add( {"name":"Lock", "path":"rundll32.exe user32.dll,LockWorkStation","root":1} )
    Shutdown.Add()
    Shutdown.Add( {"name":"Shut Down", "path":"%windir%\System32\Shutdown -s -t 0","root":1} )
    Shutdown.Add( {"name":"Restart", "path":"%windir%\System32\Shutdown -r -t 0","root":1} )
    Shutdown.Add()
    Shutdown.Add( {"name":"Sleep", "path":"rundll32.exe powrprof.dll,SetSuspendState 0,1,0","root":1} )
    Shutdown.Add( {"name":"Hibernate", "path":"rundll32.exe PowrProf.dll,SetSuspendState","root":1} )
  }
  RecD.Add()

  loop % $oRecD.MaxIndex()
    RecD.add($oRecD[A_INDEX])
  loop % $oRecF.MaxIndex()
    RecF.add($oRecF[A_INDEX])

  loop %$CPIndex%  ;Simply add cached lookups
    control.add(CP[A_INDEX])

  navi.Show(20,20,"NOANIM")
  navi.destroy()

  ;if sharpbar was reloaded, pick up the new PID's.
  Loop, % SharpID?SharpID:1
    if !WinExist("ahk_id " SharpID%A_Index%)
      WinGet, SharpID, list,ahk_class TSharpBarMainForm
return

NoTooltip:
tooltip
return

   
