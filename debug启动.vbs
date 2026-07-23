Set WshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strPath

' Log file for debugging
Dim logFile
Set logFile = objFSO.CreateTextFile(strPath & "\debug.log", True)
logFile.WriteLine "=== Debug Log " & Now & " ==="

' Step 1: Check Node.js
logFile.WriteLine "Step 1: Checking Node.js..."
Dim nodeExists
nodeExists = False
On Error Resume Next
Dim execObj
Set execObj = WshShell.Exec("cmd /c node --version 2>&1")
Dim nodeOutput
nodeOutput = ""
nodeOutput = execObj.StdOut.ReadAll()
logFile.WriteLine "  node output: [" & nodeOutput & "]"
If Len(Trim(nodeOutput)) > 0 Then nodeExists = True
logFile.WriteLine "  nodeExists: " & nodeExists
On Error GoTo 0

If Not nodeExists Then
    logFile.WriteLine "  Node.js NOT found. Would install..."
    MsgBox "Node.js not found. Please install from https://nodejs.org/", vbCritical, "Exam Game"
    logFile.Close
    WScript.Quit
End If

' Step 2: Set npm mirror
logFile.WriteLine "Step 2: Setting npm mirror..."
WshShell.Run "cmd /c npm config set registry https://registry.npmmirror.com", 0, True
logFile.WriteLine "  npm mirror set."

' Step 3: Install dependencies
logFile.WriteLine "Step 3: Checking node_modules..."
If Not objFSO.FolderExists(strPath & "\node_modules") Then
    logFile.WriteLine "  node_modules NOT found. Running npm install..."
    WshShell.Run "cmd /c cd /d """ & strPath & """ && npm install 2>&1", 1, True
    If Not objFSO.FolderExists(strPath & "\node_modules") Then
        logFile.WriteLine "  npm install FAILED!"
        MsgBox "npm install failed!", vbCritical, "Exam Game"
        logFile.Close
        WScript.Quit
    End If
    logFile.WriteLine "  npm install OK."
Else
    logFile.WriteLine "  node_modules exists."
End If

' Step 4: Start app
logFile.WriteLine "Step 4: Starting npm run electron:dev..."
WshShell.Run "cmd /c cd /d """ & strPath & """ && npm run electron:dev 2>&1", 1, True
logFile.WriteLine "  App launch command sent."

logFile.WriteLine "=== Done ==="
logFile.Close

MsgBox "Debug log saved to debug.log" & vbCrLf & "Please send this file to the developer.", vbInformation, "Exam Game"
