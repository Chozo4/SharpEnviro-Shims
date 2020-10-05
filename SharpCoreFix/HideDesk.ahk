DetectHiddenWindows, ON
while !WinExist("ahk_class Progman")
  sleep 10
winhide, ahk_class Progman