#include <Array.au3>
#include "..\..\lib\sqlite3.au3"

$REQUEST_URI = EnvGet("REQUEST_URI")
$q = StringRegExp(EnvGet("QUERY_STRING"), "(?:^|&)q=(.*)", 1)
$q = isArray($q) ? $q[0] : ""

If Not ($REQUEST_URI = "" Or $REQUEST_URI = "/") Then
    ConsoleWrite("Status: 400 Bad Request"&@LF)
    ConsoleWrite(@LF)
    ConsoleWrite("[]")
    Exit
EndIf
ConsoleWrite("X-Powered-By: AutoIt/"&@AutoItVersion&@LF)
ConsoleWrite("Content-type: application/json; charset=UTF-8"&@LF)
ConsoleWrite(@LF)

Global $sBefore = ""
Global $sAfter = ""
Global $iLimit = 25
Global $bOrder = 1
Global Const $QUERY_STRING = EnvGet("QUERY_STRING")
Global Const $aQuery = StringSplit($QUERY_STRING, "&", 2)
Global $sQuery, $aQueryEntry
For $sQuery In $aQuery
    $aQueryEntry = StringSplit($sQuery, "=", 2)
    Switch StringLower($aQueryEntry[0])
        Case 'before'
            $sBefore = Execute("$aQueryEntry[1]")
        Case 'after'
            $sAfter = Execute("$aQueryEntry[1]")
        Case 'limit'
            $iLimit = Int(Execute("$aQueryEntry[1]"), 1)
        Case 'order'
            $bOrder = (Execute("$aQueryEntry[1]") = "1")
    EndSwitch
Next

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
_SQLite_Query( _
    $hDB, _
    StringFormat( _
        "SELECT * FROM manga WHERE name LIKE ? AND deleted_at IS NULL %s ORDER BY IFNULL(updated_at, created_at) %s, id %s LIMIT ?", _
        $sBefore = "" ? ($sAfter = "" ? "" : "AND IFNULL(updated_at, created_at) > ?") : "AND IFNULL(updated_at, created_at) < ?", _
        $bOrder ? "ASC" : "DESC", _
        $bOrder ? "ASC" : "DESC" _
    ), _
    $hQuery _
)

$i = 1

_SQLite_Bind_Text($hQuery, $i, StringFormat('%%%s%%', $q))
$i+=1

If Not ($sBefore = "") Then
    _SQLite_Bind_Int($hQuery, $i, $sBefore)
    $i+=1
ElseIf Not ($sAfter = "") Then
    _SQLite_Bind_Int($hQuery, 1, $sAfter)
    $i+=1
EndIf

_SQLite_Bind_Int($hQuery, $i, $iLimit)
$i+=1

ConsoleWrite("[")
Local $columns = Null
Local $aRow, $aRows[0]
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
