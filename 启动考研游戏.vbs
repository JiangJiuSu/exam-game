Set WshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strPath

' Debug log
Dim logFile
Set logFile = objFSO.CreateTextFile(strPath & "\debug.log", True)
logFile.WriteLine "=== " & Now & " ==="

' ============================================
' Step 1: Check if Node.js is installed
' ============================================
logFile.WriteLine "[1] Checking node..."
Dim nodeExists
nodeExists = False

On Error Resume Next
Dim execObj, nodeOutput
nodeOutput = ""
Set execObj = WshShell.Exec("cmd /c node --version")
If Err.Number = 0 Then
    nodeOutput = execObj.StdOut.ReadAll()
    logFile.WriteLine "  node output: " & Trim(nodeOutput)
    If Len(Trim(nodeOutput)) > 0 Then nodeExists = True
Else
    logFile.WriteLine "  exec error: " & Err.Description
    Err.Clear
End If
On Error GoTo 0

logFile.WriteLine "  nodeExists=" & nodeExists

If Not nodeExists Then
    logFile.WriteLine "[1] Node not found, installing..."
    Dim nodeVer, nodeUrl, nodeMsi, psCmd
    nodeVer = "v20.18.1"
    nodeUrl = "https://nodejs.org/dist/" & nodeVer & "/node-" & nodeVer & "-x64.msi"
    nodeMsi = objFSO.GetSpecialFolder(2) & "\node-install.msi"

    psCmd = "powershell -Command ""$ProgressPreference='SilentlyContinue'; " & _
            "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " & _
            "Invoke-WebRequest -Uri '" & nodeUrl & "' -OutFile '" & nodeMsi & "'"""
    logFile.WriteLine "  downloading: " & nodeUrl
    WshShell.Run psCmd, 0, True

    If objFSO.FileExists(nodeMsi) Then
        logFile.WriteLine "  download OK, installing..."
        WshShell.Run "msiexec /i """ & nodeMsi & """ /passive /norestart", 1, True
        On Error Resume Next
        objFSO.DeleteFile nodeMsi, True
        On Error GoTo 0

        ' Refresh PATH
        On Error Resume Next
        Dim regPath
        regPath = WshShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\Path")
        WshShell.Environment("Process")("Path") = regPath
        On Error GoTo 0

        ' Re-check
        On Error Resume Next
        Set execObj = WshShell.Exec("cmd /c node --version")
        nodeOutput = execObj.StdOut.ReadAll()
        If Len(Trim(nodeOutput)) > 0 Then nodeExists = True
        On Error GoTo 0
        logFile.WriteLine "  post-install nodeExists=" & nodeExists
    Else
        logFile.WriteLine "  download FAILED"
    End If

    If Not nodeExists Then
        MsgBox "Node.js install failed." & vbCrLf & "Please install manually:" & vbCrLf & "https://nodejs.org/", vbCritical, "Exam Game"
        logFile.Close
        WScript.Quit
    End If
End If

' ============================================
' Step 2: Set npm mirror
' ============================================
logFile.WriteLine "[2] Setting npm mirror..."
WshShell.Run "cmd /c npm config set registry https://registry.npmmirror.com", 0, True
logFile.WriteLine "  done."

' ============================================
' Step 3: Install dependencies
' ============================================
logFile.WriteLine "[3] Checking node_modules..."
If Not objFSO.FolderExists(strPath & "\node_modules") Then
    logFile.WriteLine "  running npm install..."
    WshShell.Run "cmd /c cd /d """ & strPath & """ && npm install", 1, True
    If objFSO.FolderExists(strPath & "\node_modules") Then
        logFile.WriteLine "  npm install OK"
    Else
        logFile.WriteLine "  npm install FAILED"
        MsgBox "npm install failed! Check network.", vbCritical, "Exam Game"
        logFile.Close
        WScript.Quit
    End If
Else
    logFile.WriteLine "  node_modules exists."
End If

' ============================================
' Step 4: Start the app
' ============================================
logFile.WriteLine "[4] Starting app..."
WshShell.Run "cmd /c cd /d """ & strPath & """ && npm run electron:dev", 1, True
logFile.WriteLine "  app launched."

logFile.WriteLine "=== Done ==="
logFile.Close
