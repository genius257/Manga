#include <WinAPIProc.au3>
#include <WinAPIError.au3>
#include <WinAPIMem.au3>
#include <WinAPIMisc.au3>
#include <SendMessage.au3>
#include <WinAPISysWin.au3>
#include <GuiEdit.au3>
#include <WinAPIFiles.au3>

Global Const $tagCOPYDATASTRUCT = "ULONG_PTR dwData;DWORD cbData;PTR lpData;"
Global Const $ERROR_FILE_NOT_FOUND = 0x2
Global Const $WM_COPYDATA = 0x004A

Global $_mangaSvc_mutexName = "mangaSvc"

Func _mangaSvc_isServiceRunning()
    $mutex = _WinAPI_OpenMutex($_mangaSvc_mutexName)
    $error = _WinAPI_GetLastError()
    Return $error = 0
EndFunc

Func _mangaSvc_getWindow()
    Return _WinAPI_FindWindow("AutoIt v3 GUI", $_mangaSvc_mutexName)
EndFunc

Func _mangaSvc_Subscribe($sApiId, $sUrl)
    If Not _mangaSvc_isServiceRunning() Then _mangaSvc_Run()

    ;_WinAPI_PostMessage(_mangaSvc_getWindow(), $WM_COPYDATA, 0, 
    Local $tCOPYDATASTRUCT = DllStructCreate($tagCOPYDATASTRUCT)
    $sString = StringFormat("%s %s", $sApiId, $sUrl)
    $tString = DllStructCreate("WCHAR["&(StringLen($sString) + 1)&"]")
    DllStructSetData($tString, 1, $sString)
    ;Local $pString = _WinAPI_CreateString(StringFormat("%s %s", $sApiId, $sUrl))
    $pString = DllStructGetPtr($tString)
    DllStructSetData($tCOPYDATASTRUCT, "cbData", DllStructGetSize($tString))
    DllStructSetData($tCOPYDATASTRUCT, "lpData", $pString)
    ;DllStructSetData($tCOPYDATASTRUCT, "dwData", 123)
    Local $time = TimerInit()
    Local $hWnd = _mangaSvc_getWindow()
    While $hWnd = 0
        Sleep(10)
        $hWnd = _mangaSvc_getWindow()
        If TimerDiff($time) > 1000 Then Return SetError(1, 1, False)
    WEnd
    _SendMessage($HWnd, $WM_COPYDATA, 0, DllStructGetPtr($tCOPYDATASTRUCT))
EndFunc

Func _mangaSvc_Run()
    Local Static $sPath = Null
    If $sPath = Null Then
        Local $i = 0
        $sPath = @ScriptDir
        While 1
            If FileExists($sPath & "\settings.ini") Then ExitLoop
            $sPath &= "\.."
            $i+=1
            If $i > 20 Then Return SetError(1, 1, False)
        WEnd
    EndIf
    Local Static $sAu3Path = _WinAPI_GetFullPathName(IniRead($sPath & "\settings.ini", "AU3", "Path", 'C:\Program Files (x86)\AutoIt3'))
    Run(StringFormat('"%s\AutoIt3%s.exe" "%s\mangaSvc\main.au3"', $sAu3Path, @AutoItX64 ? "_x64" : "", $sPath))
    If @error <> 0 Then Return SetError(@error, @extended, False)
    Return True
EndFunc

Func _mangaSvc_PrintCallback($sText)
    Local Static $hGui = Null
    Local Static $hEdit = Null

    If $hGui = Null Then
        $hGui = GUICreate("", 700, 320)
        $hEdit = GUICtrlCreateEdit("", 0, 0, 700, 320)
        GUISetState(@SW_SHOW, $hGui)
    EndIf

    _GUICtrlEdit_AppendText($hEdit, $sText&@CRLF&@CRLF)
EndFunc
