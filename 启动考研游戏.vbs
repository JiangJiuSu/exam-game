Set WshShell = CreateObject("WScript.Shell")
' 自动获取 .vbs 文件所在目录
WshShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
WshShell.Run "cmd /c npx electron .", 0, False
