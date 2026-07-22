Set WshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strPath

If Not objFSO.FolderExists(strPath & "\node_modules") Then
    MsgBox "First run: installing dependencies..." & vbCrLf & "Please wait 1-2 minutes.", vbInformation, "Exam Game"
    WshShell.Run "cmd /c cd /d """ & strPath & """ && npm install", 1, True
End If

WshShell.Run "cmd /c cd /d """ & strPath & """ && npm run electron:dev", 1, True
