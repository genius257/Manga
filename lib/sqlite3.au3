#include-once

#include <SQLite.au3>

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

Func _sqlite_sql($pStmt)
    $aRet = DllCall($__g_hDll_SQLite, "str:cdecl", "sqlite3_sql", "ptr", $pStmt)
    If @error Then Return SetError(1, @error, $SQLITE_MISUSE) ; DllCall error
    Return $aRet[0]
EndFunc
