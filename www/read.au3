#include <SQLite.au3>
#include "../lib/helpers.au3"
#include "../lib/sqlite3.au3"

ConsoleWrite("X-Powered-By: AutoIt/"&@AutoItVersion&@LF)
ConsoleWrite("Content-type: text/html; charset=UTF-8"&@LF)
ConsoleWrite(@LF)

$sHTML = ""

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

$sHTML &= ('<!DOCTYPE html><html><head><link href="/css/main.css" rel="stylesheet" /><link rel="stylesheet" href="/css/read.css" /></head><body>')
Switch ($sQuery)
    Case "manga"
        $sHTML &= ('<div class="main">')
        $sHTML &= ("<div><table>")
        $sHTML &= ("<tr><th>name</th><th>date added</th><th>watched</th></tr>")
        Local $hQuery
        _SQLite_Query($hDB, "SELECT id, name, date_added FROM chapter WHERE manga_id = ? ORDER BY id ASC", $hQuery)
        _SQLite_Bind_Text($hQuery, 1, $iQuery)
        Local $aRow
        While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
            ;$sHTML &= (StringFormat('<a href="?chapter=%s">%s</a>', $aRow[0], $aRow[1]))
            $sHTML &= (StringFormat('<tr><td><a href="?chapter=%s">%s</a></td><td><a href="?chapter=%s">%s</a></td>', $aRow[0], $aRow[1], $aRow[0], $aRow[2]))
            Local $hQuery2
            _SQLite_Query($hDB, "SELECT (SELECT count(history.id) FROM history LEFT JOIN page ON page.id = history.page_id LEFT JOIN chapter ON chapter.id = page.chapter_id WHERE chapter.id = ?) AS read, (SELECT count(page.id) FROM page LEFT JOIN chapter on chapter.id = page.chapter_id WHERE chapter.id = ?) as total", $hQuery2)
            _SQLite_Bind_Int($hQuery2, 1, $aRow[0])
            _SQLite_Bind_Int($hQuery2, 2, $aRow[0])
            Local $aRow2
            If _SQLite_FetchData($hQuery2, $aRow2) = $SQLITE_OK Then
                $sHTML &= (StringFormat('<td>%s (%s of %s)</td>', ($aRow2[0] == 0) ? 'Un-read' : ($aRow2[0] < $aRow2[1] ? 'In progress' : 'Read'), $aRow2[0], $aRow2[1]))
            Else
                $sHTML &= ('<td>SQLITE ERROR</dt>')
            EndIf
            $sHTML &= ('</tr>')
        WEnd
        $sHTML &= ("</table></div>")
        $sHTML &= ('</div>')
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
            $sHTML &= ("problem")
            Exit
        EndIf
        ;$iPage = UBound($aQuery2, 1) > 0 ? $aQuery2[1] : 1
        Local $hQuery
        ;_SQLite_Query($hDB, "SELECT pathId FROM chapter WHERE id = ? ORDER BY id ASC", $hQuery)
        _SQLite_Query($hDB, "SELECT manga.pathId, chapter.pathId, manga.name, chapter.name FROM chapter LEFT JOIN manga ON manga.id = chapter.manga_id WHERE chapter.id = ?", $hQuery)
        _SQLite_Bind_Int($hQuery, 1, $iQuery)
        Local $aRow
        If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
            $previousHref = getPreviousHref($pageId);StringFormat('?chapter=%s&page=%s', $iQuery, $iPage - 1)
            $nextHref = getNextHref($pageId); StringFormat('?chapter=%s&page=%s', $iQuery, $iPage + 1)

            $sDataPath = @ScriptDir & "\data\" & $aRow[0] & "\" & $aRow[1]
            $sHTML &= (StringFormat('<div style="text-align:center;padding: 50px 0 0 0;">%s - %s - ?</div>', $aRow[2], $aRow[3]))
            $sHTML &= ('<div class="main">')
            $sHTML &= ('<script type="text/javascript" src="/js/read.js"></script>')
            $sHTML &= (StringFormat('<a href="%s"><div id="previous"></div></a>', $previousHref))
            $sHTML &= (StringFormat('<a href="%s">', $nextHref))
            $sHTML &= (StringFormat('<img src="/data/%s/%s/%s" />', $mangaPathId, $chapterPathId, $pagePathId))
            $sHTML &= ('</a>')
            $sHTML &= (StringFormat('<a href="%s"><div id="next"></div></a>', $nextHref))
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
        $iStatus = _SQLite_QueryFinalize($hQuery)
        If $iStatus <> $SQLITE_OK Then HTML_WriteError(StringFormat("Could not register page view! (SQLITE status: %s)", $iStatus))
        $sHTML &= ('</div>')
    #cs
    Case "page"
        ;FIXME: get chapter id and redirect to chapter=X&page=Y
        _SQLite_Query($hDB, 'SELECT chapter_id, id FROM page WHERE chapter_id = (SELECT chapter_id FROM page WHERE id = ?) AND id > ? ORDER BY id LIMIT 1', $hQuery)
        _SQLite_Bind_Int($hQuery, 1, $pageId)
        _SQLite_Bind_Int($hQuery, 2, $pageId)
        Local $aRow
        If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then

        EndIf
    #ce
    Case Else
        ;ConsoleWrite('query: "'&$sQuery&'"')
EndSwitch
$sHTML &= ('</body></html>')
ConsoleWrite($sHTML)

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
