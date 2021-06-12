#include <SQLite.au3>

ConsoleWrite("X-Powered-By: AutoIt/"&@AutoItVersion&@LF)
ConsoleWrite("Content-type: text/html; charset=UTF-8"&@LF)
ConsoleWrite(@LF)

$QUERY_STRING = EnvGet("QUERY_STRING")

$aQuery = StringRegExp($QUERY_STRING, "^([a-z]+)=([0-9]+)", 1)
$sQuery = UBound($aQuery, 1) > 0 ? $aQuery[0] : Null
$iQuery = UBound($aQuery, 1) > 0 ? $aQuery[1] : Null

_SQLite_Startup(@ScriptDir&"\..\mangaSvc\sqlite3.dll", False, 1)
Global Const $sDatabase = @ScriptDir & "\..\mangaSvc\database.sqlite3"
Global Const $bDatabaseExists = FileExists($sDatabase)
Global Const $hDB = _SQLite_Open($sDatabase)
If Not $bDatabaseExists Then Exit
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

ConsoleWrite('<!DOCTYPE html><html><head></head><body>')
Switch ($sQuery)
    Case "manga"
        ConsoleWrite("<table>")
        ConsoleWrite("<tr><th>name</th><th>date added</th><th>watched</th></tr>")
        Local $hQuery
        _SQLite_Query($hDB, "SELECT id, name, date_added FROM chapter WHERE manga_id = ? ORDER BY id ASC", $hQuery)
        _SQLite_Bind_Text($hQuery, 1, $iQuery)
        Local $aRow
        While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
            ;ConsoleWrite(StringFormat('<a href="?chapter=%s">%s</a>', $aRow[0], $aRow[1]))
            ConsoleWrite(StringFormat('<tr><td><a href="?chapter=%s">%s</a></td><td><a href="?chapter=%s">%s</a></td>', $aRow[0], $aRow[1], $aRow[0], $aRow[2]))
            Local $hQuery2
            _SQLite_Query($hDB, "SELECT (SELECT count(history.id) FROM history LEFT JOIN page ON page.id = history.page_id LEFT JOIN chapter ON chapter.id = page.chapter_id WHERE chapter.id = ?) AS read, (SELECT count(page.id) FROM page LEFT JOIN chapter on chapter.id = page.chapter_id WHERE chapter.id = ?) as total", $hQuery2)
            _SQLite_Bind_Int($hQuery2, 1, $aRow[0])
            _SQLite_Bind_Int($hQuery2, 2, $aRow[0])
            Local $aRow2
            If _SQLite_FetchData($hQuery2, $aRow2) = $SQLITE_OK Then
                ConsoleWrite(StringFormat('<td>%s (%s of %s)</td>', ($aRow2[0] == 0) ? 'Un-read' : ($aRow2[0] < $aRow2[1] ? 'In progress' : 'Read'), $aRow2[0], $aRow2[1]))
            Else
                ConsoleWrite('<td>SQLITE ERROR</dt>')
            EndIf
            ConsoleWrite('</tr>')
        WEnd
        ConsoleWrite("</table>")
    Case "chapter"
        $aQuery2 = StringRegExp($QUERY_STRING, "^[a-z]+=[0-9]+&([a-z]+)=([0-9]+)", 1)
        Local $hQuery
        ;_SQLite_Query($hDB, "SELECT id FROM page WHERE chapter_id = ? ORDER BY id ASC LIMIT 1", $hQuery)
        If UBound($aQuery2, 1) > 0 Then
            _SQLite_Query($hDB, "SELECT page.id, page.pathId, chapter.pathId, manga.pathId FROM page LEFT JOIN chapter ON chapter.id = page.chapter_id LEFT JOIN manga ON manga.id = chapter.manga_id WHERE page.id = ? ORDER BY page.id ASC LIMIT 1", $hQuery)
            _SQLite_Bind_Int($hQuery, 1, $aQuery2[1])
        Else
            _SQLite_Query($hDB, "SELECT page.id, page.pathId, chapter.pathId, manga.pathId FROM page LEFT JOIN chapter ON chapter.id = page.chapter_id LEFT JOIN manga ON manga.id = chapter.manga_id WHERE page.chapter_id = ? ORDER BY page.id ASC LIMIT 1", $hQuery)
            _SQLite_Bind_Int($hQuery, 1, $iQuery)
        EndIf
        Local $aRow
        If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
            $pageId = $aRow[0]
            ;$iPage = $aRow[0]
            $pagePathId = $aRow[1]
            $chapterPathId = $aRow[2]
            $mangaPathId = $aRow[3]
        Else
            ConsoleWrite("problem")
            Exit
        EndIf
        ;$iPage = UBound($aQuery2, 1) > 0 ? $aQuery2[1] : 1
        Local $hQuery
        ;_SQLite_Query($hDB, "SELECT pathId FROM chapter WHERE id = ? ORDER BY id ASC", $hQuery)
        _SQLite_Query($hDB, "SELECT manga.pathId, chapter.pathId FROM chapter LEFT JOIN manga ON manga.id = chapter.manga_id WHERE chapter.id = ?", $hQuery)
        _SQLite_Bind_Int($hQuery, 1, $iQuery)
        Local $aRow
        If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
            $previousHref = getPreviousHref($pageId);StringFormat('?chapter=%s&page=%s', $iQuery, $iPage - 1)
            $nextHref = getNextHref($pageId); StringFormat('?chapter=%s&page=%s', $iQuery, $iPage + 1)

            $sDataPath = @ScriptDir & "\data\" & $aRow[0] & "\" & $aRow[1]
            ;ConsoleWrite(StringFormat('<script type="text/javascript">var page=%s;var nextpage=%s;var previousPage=%s;</script>', $iPage, FileExists($sDataPath & "\" & ($iPage + 1) & ".jpg"), FileExists($sDataPath & "\" & ($iPage - 1) & ".jpg")))
            ConsoleWrite('<script type="text/javascript" src="/js/read.js"></script>')
            ConsoleWrite('<link rel="stylesheet" href="/css/read.css" />')
            ConsoleWrite(StringFormat('<a href="%s"><div id="previous"></div></a>', $previousHref))
            ConsoleWrite(StringFormat('<a href="%s">', $nextHref))
            ConsoleWrite(StringFormat('<img src="/data/%s/%s/%s" />', $mangaPathId, $chapterPathId, $pagePathId))
            ConsoleWrite('</a>')
            ConsoleWrite(StringFormat('<a href="%s"><div id="next"></div></a>', $nextHref))
        EndIf
        _SQLite_Query($hDB, "SELECT id FROM history WHERE page_id = ? LIMIT 1", $hQuery)
        _SQLite_Bind_Int($hQuery, 1, $pageId)
        If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
            _SQLite_Query($hDB, "UPDATE history SET updated_at = (strftime('%s', 'now')) WHERE page_id = ?", $hQuery)
        Else
            _SQLite_Query($hDB, "INSERT INTO history (page_id) VALUES (?)", $hQuery)
        EndIf
        _SQLite_Bind_Int($hQuery, 1, $pageId)
        _SQLite_Step($hQuery)
        _SQLite_QueryFinalize($hQuery)
    Case "page"
        ;FIXME: get chapter id and redirect to chapter=X&page=Y
        Exit MsgBox(0, "", "NO!")
        _SQLite_Query($hDB, 'SELECT chapter_id, id FROM page WHERE chapter_id = (SELECT chapter_id FROM page WHERE id = ?) AND id > ? ORDER BY id LIMIT 1', $hQuery)
        _SQLite_Bind_Int($hQuery, 1, $pageId)
        _SQLite_Bind_Int($hQuery, 2, $pageId)
        Local $aRow
        If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then

        EndIf
    Case Else
        ;ConsoleWrite('query: "'&$sQuery&'"')
EndSwitch
;ConsoleWrite('here the manga will be shown')
;ConsoleWrite('<br />'&$QUERY_STRING)
ConsoleWrite('</body></html>')

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

Func getPreviousHref($pageId)
    _SQLite_Query($hDB, 'SELECT chapter_id, id FROM page WHERE chapter_id = (SELECT chapter_id FROM page WHERE id = ?) AND id < ? ORDER BY id DESC LIMIT 1', $hQuery)
    _SQLite_Bind_Int($hQuery, 1, $pageId)
    _SQLite_Bind_Int($hQuery, 2, $pageId)
    Local $aRow
    If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
        Return StringFormat("?chapter=%s&page=%s", $aRow[0], $aRow[1])
    Else
        _SQLite_Query($hDB, 'SELECT * FROM chapter WHERE id > (SELECT chapter_id FROM page WHERE id = ?) AND manga_id = (SELECT manga_id FROM chapter WHERE id = (SELECT chapter_id FROM page WHERE id = ?)) ORDER BY id ASC LIMIT 1', $hQuery)
        _SQLite_Bind_Int($hQuery, 1, $pageId)
        _SQLite_Bind_Int($hQuery, 2, $pageId)
        If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
            _SQLite_Query($hDB, 'SELECT chapter_id, id FROM page WHERE chapter_id = ? ORDER BY id DESC LIMIT 1', $hQuery)
            _SQLite_Bind_Int($hQuery, 1, $aRow[0])
            If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
                Return StringFormat("?chapter=%s&page=%s", $aRow[0], $aRow[1])
            Else
                Return SetError(1, 1, "/")
            EndIf
        Else
            Return SetError(1, 1, "/")
        EndIf
    EndIf
EndFunc

Func getNextHref($pageId)
    _SQLite_Query($hDB, 'SELECT chapter_id, id FROM page WHERE chapter_id = (SELECT chapter_id FROM page WHERE id = ?) AND id > ? ORDER BY id LIMIT 1', $hQuery)
    _SQLite_Bind_Int($hQuery, 1, $pageId)
    _SQLite_Bind_Int($hQuery, 2, $pageId)
    Local $aRow
    If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
        Return StringFormat("?chapter=%s&page=%s", $aRow[0], $aRow[1])
    Else
        _SQLite_Query($hDB, 'SELECT id FROM chapter WHERE id < (SELECT chapter_id FROM page WHERE id = ?) AND manga_id = (SELECT manga_id FROM chapter WHERE id = (SELECT chapter_id FROM page WHERE id = ?)) ORDER BY id DESC LIMIT 1', $hQuery)
        _SQLite_Bind_Int($hQuery, 1, $pageId)
        _SQLite_Bind_Int($hQuery, 2, $pageId)
        If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
            _SQLite_Query($hDB, 'SELECT chapter_id, id FROM page WHERE chapter_id = ? ORDER BY id ASC LIMIT 1', $hQuery)
            _SQLite_Bind_Int($hQuery, 1, $aRow[0])
            If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
                Return StringFormat("?chapter=%s&page=%s", $aRow[0], $aRow[1])
            Else
                Return SetError(1, 1, "/")
            EndIf
        Else
            Return SetError(1, 1, "/")
        EndIf
    EndIf
EndFunc
