Set WshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strPath

' Set npm registry to China mirror for faster downloads
WshShell.Run "cmd /c npm config set registry https://registry.npmmirror.com", 0, True

If Not objFSO.FolderExists(strPath & "\node_modules") Then
    WshShell.Run "cmd /c cd /d """ & strPath & """ && npm install", 1, True
    ' Check if install succeeded
    If Not objFSO.FolderExists(strPath & "\node_modules") Then
        MsgBox "Install failed. Please install Node.js first:" & vbCrLf & "https://nodejs.org/", vbCritical, "Exam Game"
        WScript.Quit
    End If
End If

WshShell.Run "cmd /c cd /d """ & strPath & """ && npm run electron:dev", 1, True
