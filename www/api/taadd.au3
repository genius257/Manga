#include "..\..\Server.au3"
#include "..\..\AutoIt-HTML-Parser-master\HTMLParser.au3"
#include "..\..\mangaSvc\api.au3"
#include "..\..\lib\sqlite3.au3"

ConsoleWrite("X-Powered-By: AutoIt/"&@AutoItVersion&@LF)
ConsoleWrite("Content-type: text/html; charset=UTF-8"&@LF)
ConsoleWrite(@LF)

$REQUEST_URI = EnvGet("REQUEST_URI")

;$sURL = "https://www.taadd.com/list/New-Update"
$sURL = "https://www.taadd.com" & $REQUEST_URI

If StringRight($REQUEST_URI, 11) = "/subscribe/" Then $sURL = StringMid($sURL, 1, StringLen($sURL)-11)
If StringLeft($REQUEST_URI, 8) = '/search/' Then $sURL = StringRegExpReplace($sURL, "//www.", "//my.") & "?" & EnvGet("QUERY_STRING")

HttpSetUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36")
$bResponse = InetRead($sURL, 1 + 2 + 8 + 16)
;If @error <> 0 Then ConsoleWrite(_InetGetErrorText(@extended))
$sResponse = BinaryToString($bResponse)
If (StringLeft($REQUEST_URI, 6) = "/book/") Then
    $tTokenList = _HTMLParser($sResponse)
    $pItem = _HTMLParser_GetFirstStartTag($tTokenList.head);finds first start tag. In this example it will be <html>
    $aTables = _HTMLParser_GetElementsByTagName("table", $pItem)

    $posterImage = _HTMLParser_Element_GetAttribute("src", _HTMLParser_GetElementsByTagName("img", $aTables[0])[0])
    $aH1 = _HTMLParser_GetElementsByTagName("h1", $aTables[1])
    $aText = _HTMLParser_Element_GetText($aH1[0])
    $name = __HTMLParser_GetString(__doublyLinkedList_Node($aText[0]).data)
    $name = StringMid($name, 1, StringLen($name) - 6)
    ;$name = StringMid(_HTMLParser_Element_GetText(__HTMLParser_GetString(_HTMLParser_GetElementsByTagName("h1", $aTables[1])[0])[0]), 1, -6)

    If StringRight($REQUEST_URI, 11) = "/subscribe/" Then
        _mangaSvc_Subscribe("taadd", StringMid($REQUEST_URI, 1, StringLen($REQUEST_URI)-11))
        ConsoleWrite(StringFormat('<html><head><meta http-equiv="refresh" content="3;url=/api/taadd%s" /></head><body>', StringMid($REQUEST_URI, 1, StringLen($REQUEST_URI)-11)))
        ConsoleWrite("Subscribed.");FIXME: we should do a check, to make sure the subsribe request was accurly successfull, before informing the end user.
        ConsoleWrite("</body></html>")
    Else
        ConsoleWrite("<html><head></head><body>")
        ConsoleWrite("<h1>"&$name&"</h1>")

        _SQLite_Startup(@ScriptDir & "\..\..\mangaSvc\sqlite3.dll", False, 1, _mangaSvc_PrintCallback)
        $hDB = _SQLite_Open(@ScriptDir & "\..\..\mangaSvc\database.sqlite3")
        Local $hQuery, $aRow
        _SQLite_Query($hDB, "SELECT id FROM manga WHERE api = ? AND url = ? LIMIT 1", $hQuery)
        _SQLite_Bind_Text($hQuery, 1, "taadd")
        _SQLite_Bind_Text($hQuery, 2, $REQUEST_URI)
        If _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK Then
            ConsoleWrite("<h2>NOTICE: you have already subscribed to this manga.</h2>")
        EndIf

        ConsoleWrite('<a href=".'&StringMid($REQUEST_URI, 6)&'/subscribe/">subscribe</a>')
        ConsoleWrite('<img src="'&$posterImage&'"/>')
        ;ConsoleWrite(__HTMLParser_GetString(__doublyLinkedList_Node($aTables[2]).data))
        ;FIXME: we need to add a innerHTML/innerText getter
        ConsoleWrite("</body></html>")
    EndIf
Else
    $sResponse = StringRegExpReplace($sResponse, '(?i)<a ([^>]*)href="(https?:)?(\/\/)?(www.)?taadd.com\/', '<a $1href="/api/taadd/')
    $sResponse = StringRegExpReplace($sResponse, 'action="(https?:)?(\/\/)?(my.)?taadd.com\/', 'action="/api/taadd/')
    ConsoleWrite($sResponse)
EndIf
