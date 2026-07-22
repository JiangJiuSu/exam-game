Set WshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' 获取当前脚本所在目录
strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' 切换到项目目录
WshShell.CurrentDirectory = strPath

' 检查 node_modules 是否存在
If Not objFSO.FolderExists(strPath & "\node_modules") Then
    MsgBox "首次运行，正在安装依赖..." & vbCrLf & "这可能需要几分钟时间，请耐心等待。", vbInformation, "考研游戏系统"
    WshShell.Run "cmd /c cd /d """ & strPath & """ && npm install", 1, True
End If

' 使用 electron:dev 脚本启动（自动协调 Vite 和 Electron）
WshShell.Run "cmd /c cd /d """ & strPath & """ && npm run electron:dev", 1, True
