Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\Users\17223\Desktop\cursor_project\exam-game"
WshShell.Run "cmd /c npx electron .", 0, False
