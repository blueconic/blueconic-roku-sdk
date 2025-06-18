' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.

' Method for logging messages verbose in BlueConic.
'
' @param message The message to log.
sub BCLogVerbose(message as string)
    if (isDebug())
        print logPrefix(); " 💬 >> "; message
    end if
end sub

' Method for logging informational messages in BlueConic.
'
' @param message The message to log.
sub BCLogInfo(message as string)
    if (isDebug())
        print logPrefix(); " ℹ️ >> "; message
    end if
end sub

' Method for logging warnings in BlueConic.
'
' @param message The warning message to log.
sub BCLogWarning(message as string)
    if (isDebug())
        print logPrefix(); " ⚠️ >> "; message
    end if
end sub

' Method for logging errors in BlueConic.
'
' @param message The error message to log.
' @param error Optional error object to log additional details.
sub BCLogError(message as string, error = invalid as object)
    if (isDebug())
        print logPrefix(); " ❌ >> "; message
    end if
end sub

' Method for adding the prefix for each log message.
'
' @return The prefix string to be used in log messages.
function logPrefix() as string
    return "[BlueConic " + shortTimestamp() + "]"
end function

' Method for generating a short timestamp for log messages.
'
' @return A string representing the current timestamp in ISO format.
function shortTimestamp() as string
    date = CreateObject("roDateTime")
    seconds = date.AsSeconds()
    return date.toISOString().replace("T", " ").replace("Z", "")
end function

' Method to check if the application is in debug mode.
'
' @return True if the application is in debug mode, false otherwise.
function isDebug() as boolean
    if (m.global.doesExist("blueConicConfiguration") = false)
        return false
    end if
    return m.global.blueConicConfiguration.isDebugMode
end function