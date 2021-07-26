#include "..\..\AutoIt-HTML-Parser-master\HTMLParser.au3"

Func _taadd_sync($sUrl, $sPathId, $mangaId)
    Local $outputDir = @ScriptDir & "\..\www\data\" & $sPathId & "\"

    $sUrl = "https://www.taadd.com" & $sUrl & "?waring=1&a=1"
    ;MsgBox(0, "", $sUrl)

    HttpSetUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36")
    Local $bResponse = InetRead($sURL, 1 + 2 + 8 + 16)
    ;If @error <> 0 Then ConsoleWrite(_InetGetErrorText(@extended))
    Local $sResponse = BinaryToString($bResponse)

    Local $tTokenList = _HTMLParser($sResponse)
    Local $pItem = _HTMLParser_GetFirstStartTag($tTokenList.head);finds first start tag. In this example it will be <html>
    Local $aTables = _HTMLParser_GetElementsByTagName("table", $pItem)
    Local $pImg = _HTMLParser_GetElementsByTagName('img', $aTables[0])[0]
    Local $aHyperlinks = _HTMLParser_GetElementsByTagName('a', $aTables[2])

    $aH1 = _HTMLParser_GetElementsByTagName("h1", $aTables[1])
    $aText = _HTMLParser_Element_GetText($aH1[0])
    $sName = __HTMLParser_GetString(__doublyLinkedList_Node($aText[0]).data)
    $sName = StringMid($sName, 1, StringLen($sName) - 6)

    Local $hQuery
    _SQLite_Query($hDB, "UPDATE manga SET name=? WHERE id=?", $hQuery)
    _SQLite_Bind_Text($hQuery, 1, $sName)
    _SQLite_Bind_Int($hQuery, 2, $mangaId)
    _SQLite_Step($hQuery)
    _SQLite_QueryFinalize($hQuery)

    DirCreate($outputDir)

    Local $src = _HTMLParser_Element_GetAttribute('src', $pImg)
    Local $extension = StringMid($src, StringInStr($src, ".", 1, -1) + 1)
    Local $fileName = "poster"
    If Not FileExists($outputDir & $fileName & "." & $extension) Then
        InetGet($src, $outputDir & $fileName & "." & $extension, 1 + 2 + 8 + 16, 0)
        _SQLite_Query($hDB, "UPDATE manga SET poster=? WHERE id=?", $hQuery)
        _SQLite_Bind_Text($hQuery, 1, $fileName & "." & $extension)
        _SQLite_Bind_Int($hQuery, 2, $mangaId)
        _SQLite_Step($hQuery)
        _SQLite_QueryFinalize($hQuery)
    EndIf


    Local $i
    ; For $i = 0 To UBound($aHyperlinks, 1) - 1 Step +2
    For $i = UBound($aHyperlinks, 1) -(1 + Mod(UBound($aHyperlinks, 1)+1, 2)) To 0 Step -2
        Local $href = _HTMLParser_Element_GetAttribute('href', $aHyperlinks[$i])
        Local $text = ""
        Local $aText = _HTMLParser_Element_GetText($aHyperlinks[$i])
        Local $j
        For $j = 0 To UBound($aText, 1) - 1 Step +1
            Local $tNode = __doublyLinkedList_Node($aText[$j])
            $text &= StringStripWS(__HTMLParser_GetString($tNode.data), 3)
        Next
        Local $sDateAdded = ""
        Local $aText = _HTMLParser_Element_GetText($aHyperlinks[$i + 1])
        For $j = 0 To UBound($aText, 1) - 1 Step +1
            Local $tNode = __doublyLinkedList_Node($aText[$j])
            $sDateAdded &= StringStripWS(__HTMLParser_GetString($tNode.data), 3)
        Next

        Local $sChapter = StringRegExp($href, '(?i)\/chapter\/([^\/]+)', 1)[0]

        DirCreate($outputDir & $sChapter)

        Local $hQuery
        _SQLite_Query($hDB, "SELECT id FROM chapter WHERE manga_id = ? AND name = ? AND pathId = ? AND date_added = ? LIMIT 1", $hQuery)
        _SQLite_Bind_Int($hQuery, 1, $mangaId)
        _SQLite_Bind_Text($hQuery, 2, $text)
        _SQLite_Bind_Text($hQuery, 3, $sChapter)
        _SQLite_Bind_Text($hQuery, 4, $sDateAdded)

        Local $aRow
        Local $bExists = _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
        _SQLite_QueryFinalize($hQuery)

        If Not $bExists Then
            _SQLite_Query($hDB, "INSERT INTO chapter (manga_id, name, pathId, date_added) VALUES (?, ?, ?, ?)", $hQuery)
            _SQLite_Bind_Int($hQuery, 1, $mangaId)
            _SQLite_Bind_Text($hQuery, 2, $text)
            _SQLite_Bind_Text($hQuery, 3, $sChapter)
            _SQLite_Bind_Text($hQuery, 4, $sDateAdded)

            _SQLite_Step($hQuery)
            ;_SQLite_QueryReset($hQuery)
            _SQLite_QueryFinalize($hQuery)
            Local $chapterId = _SQLite_LastInsertRowID($hDB)
        Else
            Local $chapterId = $aRow[0]
            ContinueLoop; We skip the chapter, because it already exists.
        EndIf

        _taadd_download_chapter($href, $outputDir & $sChapter & "\", $chapterId)
    Next
EndFunc

Func _taadd_download_chapter($sUrl, $outputDir, $chapterId)
    $sUrl = "https://www.taadd.com" & $sUrl

    HttpSetUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36")
    Local $bResponse = InetRead($sURL, 1 + 2 + 8 + 16)
    ;If @error <> 0 Then ConsoleWrite(_InetGetErrorText(@extended))
    Local $sResponse = BinaryToString($bResponse)
    $sResponse = StringRegExpReplace($sResponse, "(?i)<([a-z]+:[a-z]+)[^>]+>[^<]*<\/(?1)>", "")
    $sResponse = StringReplace($sResponse, 'mobile/" "', 'mobile/"')

    Local $tTokenList = _HTMLParser($sResponse)
    Local $pItem = _HTMLParser_GetFirstStartTag($tTokenList.head);finds first start tag. In this example it will be <html>
    Local $pSelect = _HTMLParser_GetElementByID('page', $pItem)
    Local $aOptions = _HTMLParser_GetElementsByTagName('option', $pSelect)
    Local $hQuery, $aRow
    _SQLite_Query($hDB, "SELECT COUNT(id) FROM page WHERE chapter_id = ?", $hQuery)
    _SQLite_Bind_Int($hQuery, 1, $chapterId)
    If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK And UBound($aOptions, 1) <= $aRow[0] Then
        _SQLite_QueryFinalize($hQuery)
        Return True
    EndIf
    _SQLite_QueryFinalize($hQuery)
    Local $i, $j
    For $i = 0 To UBound($aOptions, 1) - 1 Step +1
        Local $value = _HTMLParser_Element_GetAttribute('value', $aOptions[$i])
        Local $page = ""
        Local $aText = _HTMLParser_Element_GetText($aOptions[$i])
        For $j = 0 To UBound($aText, 1) - 1 Step +1
            Local $tNode = __doublyLinkedList_Node($aText[$j])
            $page &= StringStripWS(__HTMLParser_GetString($tNode.data), 3)
        Next

        _taadd_download_page($value, $outputDir, $page, $chapterId)
    Next
EndFunc

Func _taadd_download_page($sUrl, $outputDir, $fileName, $chapterId)
    ;$sUrl = "https://www.taadd.com" & $sUrl

    HttpSetUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36")
    Local $bResponse = InetRead($sURL, 1 + 2 + 8 + 16)
    ;If @error <> 0 Then ConsoleWrite(_InetGetErrorText(@extended))
    Local $sResponse = BinaryToString($bResponse)
    $sResponse = StringRegExpReplace($sResponse, "(?i)<([a-z]+:[a-z]+)[^>]+>[^<]*<\/(?1)>", "")
    $sResponse = StringReplace($sResponse, 'mobile/" "', 'mobile/"')
    $sResponse = StringReplace($sResponse, "id='comicpic'", 'id="comicpic"')

    Local $tTokenList = _HTMLParser($sResponse)
    Local $pItem = _HTMLParser_GetFirstStartTag($tTokenList.head);finds first start tag. In this example it will be <html>
    Local $pImg = _HTMLParser_GetElementByID('comicpic', $pItem)
    Local $src = _HTMLParser_Element_GetAttribute('src', $pImg)

    Local $extension = StringMid($src, StringInStr($src, ".", 1, -1) + 1)

    If FileExists($outputDir & $fileName & "." & $extension) Then Return True
    InetGet($src, $outputDir & $fileName & "." & $extension, 1 + 2 + 8 + 16, 0)
    ;If @error Then Exit MsgBox(0, "error", @error&@CRLF&$src&@CRLF&$outputDir & $fileName & $extension)

    Local $hQuery
    _SQLite_Query($hDB, "INSERT INTO page (chapter_id, name, pathId) VALUES (?, ?, ?)", $hQuery)

    _SQLite_Bind_Int($hQuery, 1, $chapterId)
    _SQLite_Bind_Text($hQuery, 2, $fileName)
    _SQLite_Bind_Text($hQuery, 3, $fileName & "." & $extension)

    _SQLite_Step($hQuery)
    ;_SQLite_QueryReset($hQuery)
    _SQLite_QueryFinalize($hQuery)
EndFunc
