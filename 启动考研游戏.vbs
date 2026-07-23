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
Dim execObj
Set execObj = WshShell.Exec("cmd /c node --version")
Dim nodeOutput
nodeOutput = execObj.StdOut.ReadAll()
If Len(Trim(nodeOutput)) > 0 Then nodeExists = True
On Error GoTo 0

If Not nodeExists Then
    Dim installMsg
    installMsg = "Node.js not found. Auto installing..." & vbCrLf & _
                 "This is a one-time setup (about 1 minute)." & vbCrLf & vbCrLf & _
                 "Click OK to continue."
    MsgBox installMsg, vbInformation, "Exam Game"

    ' Download and install Node.js silently
    Dim nodeVer, nodeUrl, nodeMsi, psCmd
    nodeVer = "v20.18.1"
    nodeUrl = "https://nodejs.org/dist/" & nodeVer & "/node-" & nodeVer & "-x64.msi"
    nodeMsi = objFSO.GetSpecialFolder(2) & "\node-install.msi"

    psCmd = "powershell -Command ""$ProgressPreference='SilentlyContinue'; " & _
            "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " & _
            "Invoke-WebRequest -Uri '" & nodeUrl & "' -OutFile '" & nodeMsi & "'"""
    WshShell.Run psCmd, 0, True

    If Not objFSO.FileExists(nodeMsi) Then
        MsgBox "Download failed!" & vbCrLf & "Please install Node.js manually:" & vbCrLf & "https://nodejs.org/", vbCritical, "Exam Game"
        WScript.Quit
    End If

    WshShell.Run "msiexec /i """ & nodeMsi & """ /passive /norestart", 1, True
    On Error Resume Next
    objFSO.DeleteFile nodeMsi, True
    On Error GoTo 0

    ' Refresh PATH
    Dim regPath
    On Error Resume Next
    regPath = WshShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\Path")
    WshShell.Environment("Process")("Path") = regPath
    On Error GoTo 0

    ' Verify install
    nodeExists = False
    On Error Resume Next
    Set execObj = WshShell.Exec("cmd /c node --version")
    nodeOutput = execObj.StdOut.ReadAll()
    If Len(Trim(nodeOutput)) > 0 Then nodeExists = True
    On Error GoTo 0

    If Not nodeExists Then
        MsgBox "Install failed!" & vbCrLf & "Please install Node.js manually:" & vbCrLf & "https://nodejs.org/", vbCritical, "Exam Game"
        WScript.Quit
    End If
End If

' ============================================
' Step 2: Set npm mirror for China
' ============================================
WshShell.Run "cmd /c npm config set registry https://registry.npmmirror.com", 0, True

' ============================================
' Step 3: Install project dependencies
' ============================================
If Not objFSO.FolderExists(strPath & "\node_modules") Then
    WshShell.Run "cmd /c cd /d """ & strPath & """ && npm install", 1, True
    If Not objFSO.FolderExists(strPath & "\node_modules") Then
        MsgBox "Install failed! Check your network connection.", vbCritical, "Exam Game"
        WScript.Quit
    End If
End If

' ============================================
' Step 4: Start the app
' ============================================
WshShell.Run "cmd /c cd /d """ & strPath & """ && npm run electron:dev", 1, True
