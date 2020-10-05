Work in progress<br><br>

Being as SharpEnviro was written for Win7 at most, it works to a very limited extent in Windows 10.<br>
Unfortunately this means to remedy some issues the explorer shell must also be running in the background.<br><br>

<B><I>Issue:</I></B> Folder windows do not refresh whe files are created,destroyed,renamed<br>
<B><I>Resolution:</I></B> Explorer must remain resident in background.<br><br>

<B><I>Issue:</I></B> When explorer is loaded, SharpCore cannot hook systray or track application tasks<br>
<B><I>Resolution:</I></B> Kill the ShellTray thread from within explorer.exe prior to loading SharpCore<br><br>

<B><I>Issue:</I></B> UWP/"new" Control Panel applications are broken<br>
<B><I>Resolution:</I></B> Kill SharpCore, Reload Explorer.exe, launch UWP application, reload SharpCore after killing ShellTray task<br><br>

Being as I cannot figure out at the moment how to script disabling the "Shell" service in Sharpcore at the moment, killing Sharpcore as<br>
  needed is the only current yet crude solution as needed.
