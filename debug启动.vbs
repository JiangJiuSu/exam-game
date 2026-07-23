Set WshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strPath

' Open log file
Dim logFile
Set logFile = objFSO.CreateTextFile(strPath & "\debug.log", True)
logFile.WriteLine "=== " & Now & " ==="

' ============================================
' Step 1: Check Node.js
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
    logFile.WriteLine "[1] Installing Node.js..."
    Dim nodeVer, nodeUrl, nodeMsi, psCmd
    nodeVer = "v20.18.1"
    nodeUrl = "https://nodejs.org/dist/" & nodeVer & "/node-" & nodeVer & "-x64.msi"
    nodeMsi = objFSO.GetSpecialFolder(2) & "\node-install.msi"

    psCmd = "powershell -Command ""$ProgressPreference='SilentlyContinue'; " & _
            "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " & _
            "Invoke-WebRequest -Uri '" & nodeUrl & "' -OutFile '" & nodeMsi & "'"""
    WshShell.Run psCmd, 0, True

    If objFSO.FileExists(nodeMsi) Then
        logFile.WriteLine "  download OK, installing..."
        WshShell.Run "msiexec /i """ & nodeMsi & """ /passive /norestart", 1, True
        On Error Resume Next
        objFSO.DeleteFile nodeMsi, True
        On Error GoTo 0

        On Error Resume Next
        Dim regPath
        regPath = WshShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\Path")
        WshShell.Environment("Process")("Path") = regPath
        On Error GoTo 0

        nodeExists = False
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
        MsgBox "Node.js install failed." & vbCrLf & "https://nodejs.org/", vbCritical, "Exam Game"
        logFile.Close
        WScript.Quit
    End If
End If

' ============================================
' Step 2: npm mirror
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
        MsgBox "npm install failed!", vbCritical, "Exam Game"
        logFile.Close
        WScript.Quit
    End If
Else
    logFile.WriteLine "  node_modules exists."
End If

' ============================================
' Step 4: Kill old processes
' ============================================
logFile.WriteLine "[4] Cleaning up..."
WshShell.Run "cmd /c taskkill /f /im electron.exe >nul 2>&1", 0, True
WshShell.Run "cmd /c for /f ""tokens=5"" %a in ('netstat -aon ^| findstr :5173 ^| findstr LISTENING') do taskkill /f /pid %a >nul 2>&1", 0, True
logFile.WriteLine "  done."

' ============================================
' Step 5: Start Vite
' ============================================
logFile.WriteLine "[5] Starting Vite..."
WshShell.Run "cmd /c cd /d """ & strPath & """ && npx vite", 0, False

Dim viteReady, waitCount
viteReady = False
waitCount = 0
Do While Not viteReady And waitCount < 30
    WScript.Sleep 1000
    waitCount = waitCount + 1
    On Error Resume Next
    Dim portCheck
    Set portCheck = WshShell.Exec("cmd /c netstat -an | findstr :5173 | findstr LISTENING")
    Dim portOutput
    portOutput = portCheck.StdOut.ReadAll()
    If Len(Trim(portOutput)) > 0 Then viteReady = True
    On Error GoTo 0
Loop
logFile.WriteLine "  Vite ready: " & viteReady & " (" & waitCount & "s)"

If Not viteReady Then
    MsgBox "Vite failed to start!", vbCritical, "Exam Game"
    logFile.Close
    WScript.Quit
End If

' ============================================
' Step 6: Start Electron
' ============================================
logFile.WriteLine "[6] Starting Electron..."
WshShell.Run "cmd /c cd /d """ & strPath & """ && npx electron .", 0, False

WScript.Sleep 5000
Dim electronRunning
electronRunning = False
On Error Resume Next
Dim checkObj
Set checkObj = WshShell.Exec("cmd /c tasklist /fi ""imagename eq electron.exe"" /nh")
Dim checkOutput
checkOutput = checkObj.StdOut.ReadAll()
If InStr(checkOutput, "electron.exe") > 0 Then electronRunning = True
On Error GoTo 0
logFile.WriteLine "  electron running: " & electronRunning

If Not electronRunning Then
    MsgBox "Electron failed to start!" & vbCrLf & "Check debug.log", vbCritical, "Exam Game"
End If

logFile.WriteLine "=== Done ==="
logFile.Close
