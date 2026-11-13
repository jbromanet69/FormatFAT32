' FormatFAT32 - console-less launcher.
' WScript.exe is a GUI-subsystem host: no console window is ever created.
' The actual work is done by Format-RemovableFat32.ps1, which shows only
' its own dialogs (confirmation, result, errors) and the UAC prompt.
Option Explicit

Dim oShell, oFso, sDir, sPs, sCmd, sLangFile, oText, sLang, sArg, i

Set oShell = CreateObject("WScript.Shell")
Set oFso = CreateObject("Scripting.FileSystemObject")

sDir = oFso.GetParentFolderName(WScript.ScriptFullName)
sPs = oShell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"

If Not oFso.FileExists(sPs) Then
    MsgBox "Windows PowerShell was not found." & vbCrLf & vbCrLf & sPs, vbCritical, "FormatFAT32"
    WScript.Quit 1
End If

If Not oFso.FileExists(sDir & "\Format-RemovableFat32.ps1") Then
    MsgBox "Format-RemovableFat32.ps1 is missing from:" & vbCrLf & vbCrLf & sDir, vbCritical, "FormatFAT32"
    WScript.Quit 1
End If

sCmd = Chr(34) & sPs & Chr(34) & " -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA" & _
       " -File " & Chr(34) & sDir & "\Format-RemovableFat32.ps1" & Chr(34)

' UI language chosen at install time (written by the installer).
sLangFile = sDir & "\language.txt"
If oFso.FileExists(sLangFile) Then
    Set oText = oFso.OpenTextFile(sLangFile, 1)
    If Not oText.AtEndOfStream Then sLang = Trim(oText.ReadLine())
    oText.Close
    If Len(sLang) > 0 Then
        sCmd = sCmd & " -Language " & Chr(34) & sLang & Chr(34)
    End If
End If

' Drive root passed by the Explorer verb ("D:\").
' The trailing backslash is stripped: Windows argv parsing would treat the
' sequence \" as an escaped quote when the argument is passed on.
For i = 0 To WScript.Arguments.Count - 1
    sArg = WScript.Arguments(i)
    Do While Len(sArg) > 2 And Right(sArg, 1) = "\"
        sArg = Left(sArg, Len(sArg) - 1)
    Loop
    If Len(sArg) > 0 Then
        sCmd = sCmd & " -Drive " & Chr(34) & sArg & Chr(34)
        Exit For
    End If
Next

oShell.Run sCmd, 0, True
