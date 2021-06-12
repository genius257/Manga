#include <Misc.au3>
#include <StringConstants.au3>
#include <TrayConstants.au3>
#include <SQLite.au3>
#include <SQLite.dll.au3>
#include "_AzUnixTime.au3"
#include "api.au3"

#include ".\api\taadd.au3"

$mutex = _Singleton($_mangaSvc_mutexName, 1)

If $mutex = 0 Then Exit -1

TraySetIcon("shell32.dll", 253)

Global $aQueue[0][2]

_SQLite_Startup(@ScriptDir&"\sqlite3.dll", False, 1, _mangaSvc_PrintCallback)
If @error <> 0 Then _mangaSvc_PrintCallback("_SQLite_Startup failed!")
Global Const $sDatabase = @ScriptDir & "\database.sqlite3"
Global Const $bDatabaseExists = FileExists($sDatabase)
Global Const $hDB = _SQLite_Open($sDatabase)
If @error <> 0 Then _mangaSvc_PrintCallback("_SQLite_Open failed!")
If Not $bDatabaseExists Then
    ;setup database for first time usage.
    _SQLite_Exec($hDB, "CREATE TABLE manga (id INTEGER PRIMARY KEY, api TEXT, url TEXT, pathId TEXT, name TEXT, poster TEXT, created_at INTEGER DEFAULT (strftime('%s', 'now')) NOT NULL, updated_at INTEGER, deleted_at INTEGER)")
    _SQLite_Exec($hDB, "CREATE TABLE chapter (id INTEGER PRIMARY KEY, manga_id INTEGER, name TEXT, pathId TEXT, date_added TEXT, created_at INTEGER DEFAULT (strftime('%s', 'now')) NOT NULL, updated_at INTEGER, deleted_at INTEGER)")
    _SQLite_Exec($hDB, "CREATE TABLE page (id INTEGER PRIMARY KEY, chapter_id INTEGER, name TEXT, pathId TEXT, created_at INTEGER DEFAULT (strftime('%s', 'now')) NOT NULL, updated_at INTEGER, deleted_at INTEGER)")
    _SQLite_Exec($hDB, "CREATE TABLE history (id INTEGER PRIMARY KEY, page_id INTEGER, created_at INTEGER DEFAULT (strftime('%s', 'now')) NOT NULL, updated_at INTEGER, deleted_at INTEGER)")
EndIf

Func DB_CLEANUP()
    Local $hStmt
	$hStmt = _SQLite_NextStmt($hDB)
    If @error <> 0 Then Return MsgBox(0, "", "Error: "&@error)
	While $hStmt>0
		_SQLite_QueryFinalize($hStmt)
		$hStmt = _SQLite_NextStmt($hDB)
	WEnd
	_SQLite_Close($hDB)
	_SQLite_Shutdown()
EndFunc

OnAutoItExitRegister("DB_CLEANUP")

GUIRegisterMsg($WM_COPYDATA, "WM_COPYDATA")

GUICreate($_mangaSvc_mutexName)

checkForUpdates()

AdlibRegister("checkForUpdates", 1000 * 60 * 10)

While 1
    Sleep(10)
    If UBound($aQueue, 1) > 0 Then
        processQueueEntry()
    EndIf
WEnd

Func WM_COPYDATA($hWnd, $iMsg, $wParam, $lParam)
    ;MsgBox(0, "", "WM_COPYDATA")
    Local $tCOPYDATASTRUCT = DllStructCreate($tagCOPYDATASTRUCT, $lParam)
    ;MsgBox(0, "", DllStructGetData($tCOPYDATASTRUCT, "dwData"))

    Local $sString = _WinAPI_GetString(DllStructGetData($tCOPYDATASTRUCT, "lpData"))
    ;MsgBox(0, "", '"'&$sString&'"')
    Local $aString = StringSplit($sString, " ", $STR_NOCOUNT)
    If @error <> 0 Or UBound($aString, 1) < 2 Then Return
    Local $sApiId = $aString[0]
    Local $sUrl = $aString[1]

    Local $ubound = UBound($aQueue, 1)
    Redim $aQueue[$ubound + 1][2]
    $aQueue[$ubound][0] = $sApiId
    $aQueue[$ubound][1] = $sUrl
    #cs
    MsgBox(0, "", _
        "Subscribe:"&@CRLF& _
        @TAB&"API ID: "&$sApiId&@CRLF& _
        @TAB&"URL: "&$sUrl&@CRLF _
    )
    #ce
EndFunc

Func processQueueEntry()
    TraySetIcon("shell32.dll", 16739)
    Local $ubound = UBound($aQueue, 1)
    Local $sApiId = $aQueue[$ubound-1][0]
    Local $sUrl = $aQueue[$ubound-1][1]
    Local $sPathId = $sApiId & GetUnixTimeStamp()
    Redim $aQueue[$ubound-1][2]
    TrayTip("Processing entry", $sApiId & @CRLF & $sUrl, 10, $TIP_ICONASTERISK)
    Local $hQuery
    Local $aRow
    _SQLite_Query($hDB, "SELECT id FROM manga WHERE api = ? AND url = ? LIMIT 1", $hQuery)
    _SQLite_Bind_Text($hQuery, 1, $sApiId)
    _SQLite_Bind_Text($hQuery, 2, $sUrl)
    Local $bExists = _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
    Local $mangaId = $bExists ? $aRow[0] : 0
    If Not $bExists Then
        _SQLite_Query($hDB, "INSERT INTO manga (api, url, pathId) VALUES (?, ?, ?)", $hQuery)

        _SQLite_Bind_Text($hQuery, 1, $sApiId)
        _SQLite_Bind_Text($hQuery, 2, $sUrl)
        _SQLite_Bind_Text($hQuery, 3, $sPathId)

        _SQLite_Step($hQuery)
        ;_SQLite_QueryReset($hQuery)
        _SQLite_QueryFinalize($hQuery)
        $mangaId = _SQLite_LastInsertRowID($hDB)
    EndIf

    Call("_"&$sApiId&"_sync", $sUrl, $sPathId, $mangaId)
    Local $error = @error
    TraySetIcon("shell32.dll", 253)
    If $error <> 0 Then Return False
    Return True
EndFunc

Func _SQLite_Step($hQuery)
    Local $iRval_Step = DllCall($__g_hDll_SQLite, "int:cdecl", "sqlite3_step", "ptr", $hQuery)
	If @error Then Return SetError(1, @error, $SQLITE_MISUSE) ; DllCall error
EndFunc

Func _SQLite_Bind_Blob($hQuery, $paramterIndex, $largedata, $bytes)
    If __SQLite_hChk($hQuery, 7, False) Then Return SetError(@error, 0, $SQLITE_MISUSE)

    ; TODO
    ;   last paramtere in dll call needs "SQLITE_STATIC" dont know how to pass
    ;               passing int 0 instead..?
    ;           #define SQLITE_STATIC   ((sqlite3_destructor_type)0)

    Local $vResult = DllCall($__g_hDll_SQLite, "ptr:cdecl", "sqlite3_bind_blob", "ptr", $hQuery, "int", $paramterIndex, "ptr", $largedata, "int", $bytes, "int", 0)
    If @error Then Return SetError(1, @error, $SQLITE_MISUSE) ; Dllcall error

    Return SetError(0, 0, $SQLITE_OK)
EndFunc   ;==>_SQLite_Bind_Blob

Func _SQLite_Bind_Text($hQuery, $iRowID, $sTextRow)
    Local $iRval = DllCall($__g_hDll_SQLite, "int:cdecl", "sqlite3_bind_text16", _
            "ptr", $hQuery, _
            "int", $iRowID, _
            "wstr", $sTextRow, _
            "int", -1, _
            "ptr", NULL)
    If @error Then Return SetError(1, @error, $SQLITE_MISUSE) ; DllCall error
    If $iRval[0] <> $SQLITE_OK Then
        Return SetError(-1, 0, $iRval[0])
    EndIf
    Return $iRval[0]
EndFunc

Func _SQLite_Bind_Int($hQuery, $iRowID, $iIntRow)
    Local $iRval = DllCall($__g_hDll_SQLite, "int:cdecl", "sqlite3_bind_int", _
            "ptr", $hQuery, _
            "int", $iRowID, _
            "int", $iIntRow)
    If @error Then Return SetError(1, @error, $SQLITE_MISUSE) ; DllCall error
    If $iRval[0] <> $SQLITE_OK Then
        Return SetError(-1, 0, $iRval[0])
    EndIf
    Return $iRval[0]
EndFunc

Func _SQLite_NextStmt($hDB)
	If __SQLite_hChk($hDB, 2) Then Return SetError(@error, 0, $SQLITE_MISUSE)
	Local $iRval = DllCall($__g_hDll_SQLite, "ptr:cdecl", "sqlite3_next_stmt", "ptr", $hDB, "ptr", 0)
	If @error Then Return SetError(1, @error, $SQLITE_MISUSE) ; DllCall error
	Return $iRval[0]
EndFunc

Func checkForUpdates()
    Local $hQuery
    _SQLite_Query($hDB, "SELECT id, api, url FROM manga WHERE ((updated_at IS NOT NULL AND (updated_at + 3600 * 24) <= CAST(strftime('%s', 'now') AS INTEGER)) OR (updated_at IS NULL AND (created_at + 3600 * 24) <= CAST(strftime('%s', 'now') AS INTEGER))) AND deleted_at IS NULL;", $hQuery)
    Local $aRow
    While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
        Local $hQuery2
        Local $aRow2
        _SQLite_Query($hDB, "UPDATE manga SET updated_at = CAST(strftime('%s', 'now') AS INTEGER) WHERE id = ?;", $hQuery2)
        _SQLite_Bind_Int($hQuery2, 1, $aRow[0])
        Local $sqlite_status = _SQLite_Step($hQuery2)
        _SQLite_QueryFinalize($hQuery2)
        If Not ($sqlite_status = $SQLITE_OK) Then ContinueLoop
        Local $ubound = UBound($aQueue, 1)
        Redim $aQueue[$ubound + 1][2]
        $aQueue[$ubound][0] = $aRow[1]
        $aQueue[$ubound][1] = $aRow[2]
    WEnd
EndFunc
