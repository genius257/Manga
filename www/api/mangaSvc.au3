#include "../../mangaSvc/api.au3"

ConsoleWrite("X-Powered-By: AutoIt/"&@AutoItVersion&@LF)
ConsoleWrite("Content-type: text/json; charset=UTF-8"&@LF)
ConsoleWrite(@LF)

$QUERY_STRING = EnvGet("QUERY_STRING")
Switch StringLower($QUERY_STRING)
    Case "status"
        ConsoleWrite(StringFormat('{"running":%s}', _mangaSvc_isServiceRunning() ? 1 : 0))
    Case "start"
        ConsoleWrite(StringFormat('{"success": %s}', _mangaSvc_isServiceRunning() ? "True" : (_mangaSvc_Run() ? "True" : "False")))
EndSwitch
