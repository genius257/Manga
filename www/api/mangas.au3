#include <Array.au3>
#include "..\..\lib\sqlite3.au3"
$__g_hPrintCallback_SQLite = SQLite_CustonPrint

Global $sqlite_messagelog = ""
Func SQLite_CustonPrint($sText)
    $sqlite_messagelog &= $sText
EndFunc

$REQUEST_URI = EnvGet("REQUEST_URI")
;; $aREQUEST_URI = StringRegExp($REQUEST_URI, "^(?:/:([0-9]+))?/?$", 1)
$aREQUEST_URI = StringRegExp($REQUEST_URI, "^(?:/:([0-9]+))?(?:/chapters(?:/:([0-9]+))?(?:/pages(?:/:([0-9]+))?)?)?/?$", 1)

$iMangaId = StringIsDigit(Execute('$aREQUEST_URI[0]')) ? $aREQUEST_URI[0] : Null
;; $bManga = StringRegExp($REQUEST_URI, "/mangas/?") ;; ALWAYS TRUE
$iChapterId = StringIsDigit(Execute('$aREQUEST_URI[1]')) ? $aREQUEST_URI[1] : Null
$bChapter = StringRegExp($REQUEST_URI, "/chapter/?")
$iPageId = StringIsDigit(Execute('$aREQUEST_URI[2]')) ? $aREQUEST_URI[2] : Null
$bPage = StringRegExp($REQUEST_URI, "/page/?")
$iREQUEST_URI = IsArray($aREQUEST_URI) And (Not ($aREQUEST_URI[0] = "")) And (Not ($aREQUEST_URI[0] = "/")) ? $aREQUEST_URI[0] : Null

ConsoleWrite("X-Powered-By: AutoIt/"&@AutoItVersion&@LF)
If Not IsArray($aREQUEST_URI) Then
    ConsoleWrite("Status: 400 Bad Request"&@LF)
    ConsoleWrite(@LF)
    ConsoleWrite("[]")
    Exit
EndIf
ConsoleWrite("Content-type: application/json; charset=UTF-8"&@LF)

Global $sBefore = ""
Global $sAfter = ""
Global $iOffset = 0
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
        Case 'offset'
            $iOffset = Int(Execute("$aQueryEntry[1]"), 1)
        Case 'limit'
            $iLimit = Int(Execute("$aQueryEntry[1]"), 1)
        Case 'order'
            $bOrder = (Execute("$aQueryEntry[1]") = "1")
    EndSwitch
Next

_SQLite_Startup(@ScriptDir&"\..\..\mangaSvc\sqlite3.dll", False, 1)
Global Const $sDatabase = @ScriptDir & "\..\..\mangaSvc\database.sqlite3"
If Not FileExists($sDatabase) Then
    ConsoleWrite(@LF)
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

$sQuery = StringFormat("SELECT %s FROM manga WHERE deleted_at IS NULL %s", $bChapter ? "id" : "*" ,$iMangaId = Null ? "" : "AND id = ?")

If ($bChapter) Then
    $sQuery = StringFormat("SELECT %s FROM chapter WHERE deleted_at IS NULL %s AND manga_id IN (%s)", $bPage ? "id" : "*, (SELECT COUNT(*) FROM chapter _chapter WHERE chapter.manga_id = _chapter.manga_id AND chapter.id >= _chapter.id ) as `index`, (SELECT COUNT(id) FROM history WHERE history.page_id IN (SELECT id FROM page WHERE page.chapter_id = chapter.id)) AS `pages_watched`, (SELECT count(id) FROM page WHERE page.chapter_id = chapter.id) as `pages`", $iChapterId = Null ? "" : "AND id = ?", $sQuery)
EndIf

If ($bPage) Then
    $sQuery = StringFormat("SELECT *, (SELECT COUNT(*) FROM page _page WHERE page.chapter_id = _page.chapter_id AND page.id >= _page.id ) as `index`, (EXISTS (SELECT id FROM `history` WHERE `history`.`page_id` = `page`.`id`)) as watched FROM page WHERE deleted_at IS NULL %s AND chapter_id IN (%s)", $iPageId = Null ? "" : "AND id = ?", $sQuery)
EndIf

Local $hQuery
_SQLite_Query( _
    $hDB, _
    StringFormat( _
        $sQuery&" %s ORDER BY IFNULL(updated_at, created_at) %s, id %s LIMIT ?, ?", _
        $sBefore = "" ? ($sAfter = "" ? "" : "AND created_at > ?") : "AND created_at < ?", _
        $bOrder ? "ASC" : "DESC", _
        $bOrder ? "ASC" : "DESC" _
    ), _
    $hQuery _
)

$i = 1
If Not($iPageId = Null) Then
    _SQLite_Bind_Int($hQuery, $i, $iPageId)
    $i+=1
EndIf

If Not($iChapterId = Null) Then
    _SQLite_Bind_Int($hQuery, $i, $iChapterId)
    $i+=1
EndIf

If Not($iMangaId = Null) Then
    _SQLite_Bind_Int($hQuery, $i, $iMangaId)
    $i+=1
EndIf

If Not ($sBefore = "") Then
    _SQLite_Bind_Int($hQuery, $i, $sBefore)
    $i+=1
ElseIf Not ($sAfter = "") Then
    _SQLite_Bind_Int($hQuery, $i, $sAfter)
    $i+=1
EndIf

_SQLite_Bind_Int($hQuery, $i, $iOffset)
$i+=1
_SQLite_Bind_Int($hQuery, $i, $iLimit)

If Not ($sqlite_messagelog = "") Then
    ConsoleWrite("Status: 500 Internal Server Error"&@LF)
    ConsoleWrite(@LF)
    ConsoleWrite('{"error": "'&StringRegExpReplace(StringRegExpReplace($sqlite_messagelog, '["\\]', '\$0'), '\R', '\\n')&'"}')
    Exit
EndIf

ConsoleWrite(@LF)
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
