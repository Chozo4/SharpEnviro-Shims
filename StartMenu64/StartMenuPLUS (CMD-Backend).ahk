#NoEnv
#persistent
#SingleInstance force
#Include PUM_API.ahk
#Include PUM.ahk
#KeyHistory 0
SendMode Input
;Thread, interrupt, 0
SetBatchLines -1
ListLines Off
Send, {LWin Up}


global ticks, navi, $MenuOpts:={"Iconssize":16}, activity, $CPIndex:=0, obj_test
global pm := new PUM({"oninit":"PUM_out","onrbutton":"PUM_out","onmbutton":"PUM_out","onrun":"PUM_out","onselect":"PUM_out","onshow" : "PUM_out"})

WinGet, SharpID, list,ahk_class TSharpBarMainForm ;sharpbar to top


StdOut("chcp 10000") ;intialize backend

process, exist ;get external doubleclick handling
Run, % ".\autohotkey.exe dbclicktest.ahk " DllCall("GetCurrentProcessId")

;------------------------------------------
;Offset for directory listings [XP/Vista]
;------------------------------------------
GetOffset()
{
  stdout("  ^DEBUG: locating cmd offset...",1)
  stdout("  ^DEBUG: offset found @ " ($ofs:=substr(StdOut("dir /X """ A_ScriptFullPath """|find """ A_ScriptName """"),19,1)!=" "?3:0),1)
  return $ofs
}

;------------------------------------------
;Iterate available control panel items
;------------------------------------------
$COM:=ComObjCreate("Shell.Application").Namespace(0x0003).Items
For $CplItem In $COM
{
  $CPIndex++
  RegExMatch($CplItem.Path, "({.+}).*", $CP_Path,35)
  RegRead, $out, HKCR\CLSID\%$CP_Path1%\DefaultIcon

  if !$out
    Loop, Reg, HKLM\Software\Microsoft\Windows\CurrentVersion\Control Panel\Extended Properties\System.Software.AppId\, KVR
    {
      RegRead, $value
      if trim($value)=trim($CP_Path1)
        if !InStr($Out:=StrReplace(StrReplace(A_LoopRegName,"@i",""), "%systemroot%\system32\",""),",")
      $out:=$out ":0"
    }
  CP%$CPIndex%:={"name" : $CplItem.Name,"submenu":control,"path":"explorer.exe "$CplItem.Path,"literal":1,"icon":StrReplace($out,",",":")}
}
;END Interate

;------------------------------------------
;Handle Std-Out and backend functionality
;------------------------------------------
StdOut($cmd="",$echo=0,$sleep=0)
{
  static exec,$pid,$DBGOut,$DBGIn,$DBGErr

  if !$pid || exec.status
  {
    if !$pid & 1
    {
      Run, % comspec " /D /Q /K @echo off",,Hide,$pid
      process, wait, %$pid%
      DllCall("AttachConsole", "UInt", $pid)
    }

    $pid:=(exec:=ComObjCreate("WScript.Shell").Exec(ComSpec " /D /Q /K prompt *$_")).ProcessID
    while (exec.StdOut.ReadLine()!="*")
      continue

    DllCall("AttachConsole", "UInt", $pid) && DllCall("SetConsoleOutputCP","UInt",10000)
    $DBGOut:=FileOpen(DllCall("GetStdHandle", "int", -11, "ptr"), "h `n")
    $DBGIn :=FileOpen(DllCall("GetStdHandle", "int", -10, "ptr"), "h `n")
  }
  if $echo
    return DllCall("WriteConsoleW", "UPtr",$DBGOut.__Handle ,"Str",$cmd "`n","UInt",strlen($cmd)+1)

  exec.StdIn.WriteLine($cmd)
  sleep $sleep
  while ( $line := exec.StdOut.ReadLine())!="*"
    $output .= $line "`n"
  return %$output%
}

;------------------------------------------
;Generate directory listings and item cache
;------------------------------------------
GenList(ByRef targ,path=0,rec=0,fold=1)
{
  static HPUM:=new PUM(), IconPUM := HPUM.CreateMenu({"Iconssize":16})
  static x:=0,cache:={"*":"shell32.dll:0",".exe":"%1",".lnk":"*",".msc":"*"}
  static $DIcon:={"Unknown":6,"Removable":7,"Fixed":8,"Network":9,"CDROM":11,"RAMDisk":12}, $ofs:=GetOffset()
  static $HCache:={"?":IconPum.add({"name":"?","icon":"Shell32.dll:3"}).GetIconHandle()}

  ;StdOut("Building: " path,1)
 ; tooltip % "Building: " path

  if !path
    DriveGet, list, list
  Loop, parse, % !path?list:StdOut("dir /X /OGN /A-H """ path """|find "":"""),% !path?"":"`n",`r
  {
    if !path
    {
      DriveGet, label, label, %A_LoopField%:
      DriveGet, type, type, %A_LoopField%:
      A_FileName:=A_LoopField
    }
    else if !A_LoopField
      break
    else if substr(A_LoopField,1,1)==" " || !(A_FileName:=substr(A_LoopField,50+$ofs)) || SubStr(A_FileName,0,1)=="."
      continue ;Ignore entries

    ;StdOut("  +Parse " A_LoopField,1)
    ;StdOut("  +~Adding: " A_FileName,1)
    ;StdOut("  -DEBUG: " substr(A_LoopField,,1),1)

    if Fold && Fold:=(!path || substr(A_LoopField,22+$ofs,5)=="<DIR>")
    {
      x++
      temp:=targ.Add( { "name" : path?A_FileName "\":"(" A_FileName ":) " label
                , "submenu" : (M_%x% := pm.CreateMenu($MenuOpts))
                , "root" : !path
                , "icon" : path?$HCache["?"]:("shell32.dll:" $DIcon[type])
                , "path" : path?path:A_FileName ":\"} )

      ;if (rec > 0) ;unused as of the moment
      ;  GenList(M_%x%,path A_FileName,0)
    }
    else
    {
      if ($e:=InStr(A_FileName,".",,-1)) && !($out:=cache[$ext:=($ext:=SubStr(A_FileName,$e))?$ext:"*"])
      {
        RegRead, $out, HKCR\%$out%\DefaultIcon
        $out:=cache[$ext]:=StrReplace($out?$out:"shell32.dll,0", ",", ":" )
        $HCache[$ext]:=IconPum.add({"name":$ext,"icon": ($out=="%1")?path A_FileName ":0":$out}).GetIconHandle()

        StdOut("  +Cache: " $ext " -> " $out " (" $HCache[$ext] ")",1)
      }
      else if $ext=.lnk ;need to recurse to get file icon per ext if no files exist
      {
        FileGetShortcut, % path A_FileName,file,,,,$out,$Outnum
        if $out && fileexist($out)
          $out.=":" $Outnum
        else $out:=(fileexist(file)?file:"shell32.dll") ":0"
          StdOut(" DEBUG_LNK: " A_FileName " @ " $out,1)
      }

      if $ext ~= ".exe|.lnk|.msc|.cur|.ani"
      {
        temp:=targ.Add({"name":A_FileName,"icon": ($out=="%1")?path A_FileName ":0":$out,"path": path})
      }
      else
      {
        temp:=targ.Add({"name":A_FileName,"icon": $HCache[$ext],"path": path})
      }
    }
  }

   temp?0:targ.add({"name":" ---EMPTY--- "})
 ; tooltip    ;Clear the notification if there is one.
  return 1
}

;------------------------------------------
;Handle user actions with the menu
;------------------------------------------
PUM_out( msg, ByRef obj )
{
  static ThisObj

  if( msg="onselect" )
    ThisObj:=obj

  if ( ThisObj && msg = "oninit" && !ThisObj.Gen)
  {
    ThisObj.Gen:=GenList(ThisObj.submenu,(ThisObj.path (ThisObj.root?"":ThisObj.name))) 
    testme:=obj.GetItems()
   ; for i, item in obj.GetItems()
   ; {
   ; item.icon:=item.iconpath
   ;   tooltip % hmm.=item.icon "`n"
   ; } 
  }
  
  if ( msg = "onrbutton" )
  {
    coordmode, mouse, screen
    MouseGetPos, mx, my
    menuc.Show(mx,my, "Context AnimBT") ;CONTEXT! FUCK YEAH!
    ;runwait, % "..\AutoHotkeyU32.exe hmm.ahk " obj.path "\" obj.name
  }

  if ( msg ~= "onmbutton|onrun" )
  {
    navi.EndMenu()
    if ThisObj.literal
    {
      run, % ThisObj.path
      stdout("! Exec: """ ThisObj.path """",1)
      return
    }
    else
    stdout("! Exec: " ThisObj.path (ThisObj.root?"":ThisObj.name),1)
    StdOut("start """" /B /D""" ThisObj.path """ """ (ThisObj.root?"":ThisObj.name) """",,500)
    ;if ThisObj.submenu
    ;  StdOut("start /b """" """ ThisObj.path (ThisObj.root?"":ThisObj.name) """",,1000)
    ;else StdOut("start """" /B /D""" ThisObj.path """ """ ThisObj.name """",,1000)

  }
}

return

;------------------------------------------
;Replace WinKey functionality
;------------------------------------------
$LWin::
  KeyWait, LWin, T0.1
  If ErrorLevel ;allow modifier keys
  {
    Send, {LWin Down} 
    KeyWait, LWin
    Send, {LWin Up} 
    return
  }

  Loop, %SharpID%
    WinActivate, % "ahk_id " SharpID%A_Index%
  pm := new PUM({"oninit":"PUM_out","onrbutton":"PUM_out","onmbutton":"PUM_out","onrun":"PUM_out","onselect":"PUM_out","onshow" : "PUM_out"})
  control := pm.CreateMenu({"Iconssize":16})
  GenList(navi  := pm.CreateMenu({"Iconssize":16}))

  ;Integration of start menu
  navi.add()
  GenList(navi,A_StartMenu "\")
  navi.Add( {"name":"&Settings","submenu":control,"icon":"Shell32.dll:21","path":"control","literal":1} )
  navi.Add( {"name":"Sear&ch...", "icon":"Shell32.dll:22","path":"Z:\Find\PDFind.exe","literal":1} )
  navi.Add( {"name":"&Run", "icon":"Shell32.dll:24","path":"rundll32.exe shell32.dll,#61","literal":1} )
  navi.Add()
  navi.Add( {"name":"Sh&utdown", "icon":"Shell32.dll:27","path":"C:\NewCore\Shutdown.exe","literal":1} )
  loop %$CPIndex%  ;SImply add previous lookups
    control.add(CP%A_INDEX%)

  DriveGet, list, list
  if !($drvlist=list)
  {
    stdout("  ^DEBUG: Drive list changed!",1)
    stdout("  ^DEBUG: " strlen($drvlist) " -> " strlen(list),1)
    $cmp:=(strlen(list) > strlen($drvlist))?{0:list,1:$drvlist}:{0:$drvlist,1:list}
    Loop, parse, % $cmp[0] ,,`r
      if !InStr($cmp[1],A_LoopField)
        stdout("  ^DEBUG: " A_LoopField " Added",1)
    stdout("  ^DEBUG: " $cmp[0],1)

    Loop, parse, % $cmp[1] ,,`r
      if !InStr($cmp[0],A_LoopField)
        stdout("  ^DEBUG: " A_LoopField " Removed",1)
    $drvlist:=list
  }
  navi.Show(20,20,"NOANIM")
  navi.destroy()
return

#Z::
IconPUM.Show(20,20,"NOANIM")
return

