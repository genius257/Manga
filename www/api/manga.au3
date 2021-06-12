#include <Array.au3>
#include <SQLite.au3>
#include <SQLite.dll.au3>

ConsoleWrite("X-Powered-By: AutoIt/"&@AutoItVersion&@LF)
ConsoleWrite("Content-type: text/json; charset=UTF-8"&@LF)
ConsoleWrite(@LF)

_SQLite_Startup(@ScriptDir&"\..\..\mangaSvc\sqlite3.dll", False, 1)
Global Const $sDatabase = @ScriptDir & "\..\..\mangaSvc\database.sqlite3"
If Not FileExists($sDatabase) Then
    ConsoleWrite("[]")
    Exit
EndIf
Global Const $hDB = _SQLite_Open($sDatabase)

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

Local $hQuery
_SQLite_Query($hDB, "SELECT * FROM manga WHERE deleted_at IS NULL ORDER BY name", $hQuery)

;_SQLite_Bind_Text($hQuery, 1, $sApiId)
;_SQLite_Bind_Text($hQuery, 2, $sUrl)
;_SQLite_Bind_Text($hQuery, 3, $sPathId)

;_SQLite_Step($hQuery)
;_SQLite_QueryReset($hQuery)
;_SQLite_QueryFinalize($hQuery)
;$mangaId = _SQLite_LastInsertRowID($hDB)
ConsoleWrite("[")
Local $columns = Null
Local $aRow, $aRows[0]
;Local $aNames
;_SQLite_FetchNames($hQuery, $aNames)
Local $_iColumns = sqlite3_column_count($hQuery)
While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
    ;Local $_iColumns = sqlite3_column_count($hQuery)
    Redim $aRows[UBound($aRows) + 1]
    $aRows[UBound($aRows) - 1] = "{"
    For $i = 0 To $_iColumns - 1 Step +1
        $aRows[UBound($aRows) - 1] &= StringFormat('"%s":"%s"%s', sqlite3_column_name16($hQuery, $i), $aRow[$i], $i = ($_iColumns - 1) ? '' : ',')
    Next
    $aRows[UBound($aRows) - 1] &= "}"
    ;$aRows[UBound($aRows) - 1] = StringFormat('{"name":"%s"}', $aRow[4])
WEnd
ConsoleWrite(_ArrayToString($aRows, ","))
ConsoleWrite("]")

Func _SQLite_NextStmt($hDB)
	If __SQLite_hChk($hDB, 2) Then Return SetError(@error, 0, $SQLITE_MISUSE)
	Local $iRval = DllCall($__g_hDll_SQLite, "ptr:cdecl", "sqlite3_next_stmt", "ptr", $hDB, "ptr", 0)
	If @error Then Return SetError(1, @error, $SQLITE_MISUSE) ; DllCall error
	Return $iRval[0]
EndFunc

Func _SQLite_Step($hQuery)
    Local $iRval_Step = DllCall($__g_hDll_SQLite, "int:cdecl", "sqlite3_step", "ptr", $hQuery)
    If @error Then Return SetError(1, @error, $SQLITE_MISUSE) ; DllCall error
EndFunc

Func sqlite3_column_count($hQuery)
    If __SQLite_hChk($hQuery, 3, False) Then Return SetError(@error, 0, $SQLITE_MISUSE)
    Local $iRval_Step = DllCall($__g_hDll_SQLite, "int:cdecl", "sqlite3_column_count", "ptr", $hQuery)
    If @error Then Return SetError(1, @error, $SQLITE_MISUSE) ; DllCall error
    Return $iRval_Step[0]
EndFunc

Func sqlite3_data_count($hQuery)
    If __SQLite_hChk($hQuery, 3, False) Then Return SetError(@error, 0, $SQLITE_MISUSE)
    Local $iRval_ColCnt = DllCall($__g_hDll_SQLite, "int:cdecl", "sqlite3_data_count", "ptr", $hQuery)
    If @error Then Return SetError(2, @error, $SQLITE_MISUSE) ; DllCall error
    Return $iRval_ColCnt[0]
EndFunc

Func sqlite3_column_name16($hQuery, $iCnt)
    Local $avColName = DllCall($__g_hDll_SQLite, "wstr:cdecl", "sqlite3_column_name16", "ptr", $hQuery, "int", $iCnt)
    If @error Then Return SetError(2, @error, $SQLITE_MISUSE) ; DllCall error
    ;$aNames[$iCnt] = $avColName[0]
    Return $avColName[0]
EndFunc
