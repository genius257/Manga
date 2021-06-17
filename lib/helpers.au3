#include-once

Func HTML_WriteError($sMessage, $bHeaders = False)
    If $bHeaders Then
        ConsoleWrite("X-Powered-By: AutoIt/"&@AutoItVersion&@LF)
        ConsoleWrite("Content-type: text/html; charset=UTF-8"&@LF)
        ConsoleWrite("Status: 500 Internal Server Error"&@LF)
        ConsoleWrite(@LF)
    EndIf
    ConsoleWrite(StringFormat('<!DOCTYPE html><html><head></head><body style="margin:0;padding:0;width:100vw;height:100vh;display:flex;justify-content:center;align-items:center;"><div style="width:700px;min-height:300px;border:1px solid #000;background-color:#C15058;color:#FFF;font-size:35px;padding:10px;display:flex;align-items:center;justify-content:center;">An error occured: %s</div></body></html>', $sMessage))
    Exit
EndFunc

Func HTML_WiteSqliteError()
    ;
EndFunc
