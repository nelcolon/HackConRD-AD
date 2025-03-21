Set objShell = WScript.CreateObject("WScript.Shell")
strDesktop = objShell.SpecialFolders("Desktop")
Set objShortcut= objShell.CreateShortcut(strDesktop & "\SysAid.lnk")
With objShortcut
.TargetPath = "C:\Program Files\SysAid\IliTask.exe"
.Arguments = "-TaskType 1 -TaskParam Set None -TaskParamInt 200"
.WorkingDirectory = "C:\Program Files\SysAid\"
.Description = "SysAid."
.IconLocation = "C:\Program Files\SysAid\IliTask.exe"
.Save
End with


		