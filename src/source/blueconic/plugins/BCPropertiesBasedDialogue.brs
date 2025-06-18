' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling the properties based dialogue.
function __BCPropertiesBasedDialogue_builder()
    instance = __BCPlugin_builder()
    instance.super0_new = instance.new
    instance.new = sub()
        m.super0_new()
    end sub
    instance.super0_onLoad = instance.onLoad
    instance.onLoad = function()
        config = "{}"
        if m._interactionContext.getParameters()["config"] <> invalid and m._interactionContext.getParameters()["config"].Count() > 0
            config = m._interactionContext.getParameters()["config"][0]
        end if
        config = m._replaceTokens(config)
        propertiesEvent = BCPropertiesDialogueEvent(m._interactionContext.getInteractionId(), m._interactionContext.getPositionName(), config)
        m._client.eventManager().publish(propertiesEvent)
        frontendViewCount = ""
        if m._interactionContext.getParameters()["frontendViewCount"] <> invalid and m._interactionContext.getParameters()["frontendViewCount"].Count() > 0
            frontendViewCount = m._interactionContext.getParameters()["frontendViewCount"][0]
        end if
        if frontendViewCount <> "" and frontendViewCount = "always"
            m._client.createViewEvent(m._interactionContext.getInteractionId(), {})
        end if
    end function
    instance.super0_onDestroy = instance.onDestroy
    instance.onDestroy = function()
    end function
    ' Replaces tokens in the configuration string with values from the profile.
    '
    ' @param config The configuration string containing tokens to be replaced.
    ' @return The configuration string with tokens replaced by profile values.
    instance._replaceTokens = function(config as string) as string
        result = config
        startPos = 1
        maxReplacements = 1000
        replacementCount = 0
        openPos = Instr(startPos, result, "{{")
        while openPos > 0 and replacementCount < maxReplacements
            replacementCount = replacementCount + 1
            closePos = Instr(openPos + 2, result, "}}")
            if closePos = 0 then
                startPos = openPos + 2
            else
                tokenStart = openPos + 2
                tokenLength = closePos - tokenStart
                token = Mid(result, tokenStart, tokenLength)
                profileValues = m._client.profile().getValues(token)
                tokenValue = ""
                if profileValues <> invalid and profileValues.count() > 0
                    for i = 0 to profileValues.count() - 1
                        if i > 0 then
                            tokenValue = tokenValue + ","
                        end if
                        tokenValue = tokenValue + profileValues[i]
                    end for
                    beforeToken = Left(result, openPos - 1)
                    afterToken = Mid(result, closePos + 2)
                    result = beforeToken + tokenValue + afterToken
                    startPos = openPos + Len(tokenValue)
                else
                    startPos = closePos + 2
                end if
            end if
            openPos = Instr(startPos, result, "{{")
        end while
        return result
    end function
    return instance
end function
function BCPropertiesBasedDialogue()
    instance = __BCPropertiesBasedDialogue_builder()
    instance.new()
    return instance
end function