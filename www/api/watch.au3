#include <Array.au3>
#include "..\..\lib\sqlite3.au3"

$REQUEST_URI = EnvGet("REQUEST_URI")

$aREQUEST_URI = StringRegExp($REQUEST_URI, "^(?:/:([0-9]+))/?$", 1)

ConsoleWrite("X-Powered-By: AutoIt/"&@AutoItVersion&@LF)
If Not IsArray($aREQUEST_URI) Then
    ConsoleWrite("Status: 400 Bad Request"&@LF)
    ConsoleWrite(@LF)
    ConsoleWrite("{}")
    Exit
EndIf
ConsoleWrite("Content-type: application/json; charset=UTF-8"&@LF)

$iPageId = $aREQUEST_URI[0]

_SQLite_Startup(@ScriptDir&"\..\..\mangaSvc\sqlite3.dll", False, 1)
Global Const $sDatabase = @ScriptDir & "\..\..\mangaSvc\database.sqlite3"
If Not FileExists($sDatabase) Then
    ConsoleWrite("Status: 500 Internal Server Error"&@LF)
    ConsoleWrite(@LF)
    ConsoleWrite("{}")
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

Local $hQuery, $aRow
_SQLite_Query($hDB, "SELECT id FROM history WHERE page_id = ? LIMIT 1", $hQuery)
_SQLite_Bind_Int($hQuery, 1, $iPageId)
If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
    _SQLite_Query($hDB, "UPDATE history SET updated_at = (strftime('%s', 'now')) WHERE page_id = ?", $hQuery)
Else
    _SQLite_Query($hDB, "INSERT INTO history (page_id) VALUES (?)", $hQuery)
EndIf
_SQLite_Bind_Int($hQuery, 1, $iPageId)
_SQLite_Step($hQuery)
$iStatus = _SQLite_QueryFinalize($hQuery)
If $iStatus <> $SQLITE_OK Then
    ConsoleWrite("Status: 500 Internal Server Error"&@LF)
    ConsoleWrite(@LF)
    ConsoleWrite(StringFormat('{"message":"Could not register page view! (SQLITE status: %s)"}', $iStatus))
EndIf

ConsoleWrite(@LF)
ConsoleWrite("{}")
