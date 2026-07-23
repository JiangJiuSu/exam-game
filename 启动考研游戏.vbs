Set WshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strPath

' ============================================
' Step 1: Check if Node.js is installed
' ============================================
Dim nodeExists
nodeExists = False
On Error Resume Next
Dim execObj, nodeOutput
nodeOutput = ""
Set execObj = WshShell.Exec("cmd /c node --version")
If Err.Number = 0 Then
    nodeOutput = execObj.StdOut.ReadAll()
    If Len(Trim(nodeOutput)) > 0 Then nodeExists = True
Else
    Err.Clear
End If
On Error GoTo 0

If Not nodeExists Then
    MsgBox "Node.js not found. Auto downloading..." & vbCrLf & "This is a one-time setup.", vbInformation, "Exam Game"

    Dim nodeVer, nodeUrl, nodeMsi, psCmd
    nodeVer = "v20.18.1"
    nodeUrl = "https://nodejs.org/dist/" & nodeVer & "/node-" & nodeVer & "-x64.msi"
    nodeMsi = objFSO.GetSpecialFolder(2) & "\node-install.msi"

    psCmd = "powershell -Command ""$ProgressPreference='SilentlyContinue'; " & _
            "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " & _
            "Invoke-WebRequest -Uri '" & nodeUrl & "' -OutFile '" & nodeMsi & "'"""
    WshShell.Run psCmd, 0, True

    If objFSO.FileExists(nodeMsi) Then
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

        ' Verify
        On Error Resume Next
        nodeExists = False
        Set execObj = WshShell.Exec("cmd /c node --version")
        nodeOutput = execObj.StdOut.ReadAll()
        If Len(Trim(nodeOutput)) > 0 Then nodeExists = True
        On Error GoTo 0
    End If

    If Not nodeExists Then
        MsgBox "Install failed!" & vbCrLf & "Please install Node.js manually:" & vbCrLf & "https://nodejs.org/", vbCritical, "Exam Game"
        WScript.Quit
    End If
End If

' ============================================
' Step 2: Set npm mirror
' ============================================
WshShell.Run "cmd /c npm config set registry https://registry.npmmirror.com", 0, True

' ============================================
' Step 3: Install dependencies
' ============================================
If Not objFSO.FolderExists(strPath & "\node_modules") Then
    WshShell.Run "cmd /c cd /d """ & strPath & """ && npm install", 1, True
    If Not objFSO.FolderExists(strPath & "\node_modules") Then
        MsgBox "Install failed! Check network.", vbCritical, "Exam Game"
        WScript.Quit
    End If
End If

' ============================================
' Step 4: Start Vite
' ============================================
WshShell.Run "cmd /c cd /d """ & strPath & """ && npx vite", 0, False

' Wait for Vite (port 5173)
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

If Not viteReady Then
    MsgBox "Vite failed to start!" & vbCrLf & "Port 5173 may be occupied.", vbCritical, "Exam Game"
    WScript.Quit
End If

' ============================================
' Step 5: Start Electron
' ============================================
WshShell.Run "cmd /c cd /d """ & strPath & """ && npx electron .", 0, False
