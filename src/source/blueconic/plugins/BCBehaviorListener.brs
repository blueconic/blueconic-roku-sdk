' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
'
' Class handling the behavior listener for enriching profiles based on visitor behavior.
function __BCBehaviorListener_builder()
    instance = __BCPlugin_builder()
    instance.super0_new = instance.new
    instance.new = sub()
        m.super0_new()
        m.enrichByBehaviorService = invalid
        m._PARAMETER_RULES = "listener_rules"
        m._TAG_RULES = "rules"
    end sub
    ' Constants
    instance.super0_onLoad = instance.onLoad
    instance.onLoad = sub()
        rulesJson = m._getParameterValue(m._PARAMETER_RULES)
        if rulesJson = invalid or rulesJson = "" then
            return
        end if
        jsonObject = ParseJson(rulesJson)
        if jsonObject <> invalid then
            rules = jsonObject.lookupCI(m._TAG_RULES)
            if rules <> invalid then
                m.enrichByBehaviorService = BCEnrichByBehaviorService(m._client, m._interactionContext)
                m.enrichByBehaviorService.applyRules(rules)
            else
                BCLogError("Invalid json for: " + m._PARAMETER_RULES)
            end if
        else
            BCLogError("Invalid json for: " + m._PARAMETER_RULES)
        end if
    end sub
    instance.super0_onDestroy = instance.onDestroy
    instance.onDestroy = sub()
        m._client.eventManager().clearEventHandlers(m._interactionContext.getInteractionId())
    end sub
    ' Returns the first value for a parameter. When no parameter value is found, invalid is returned.
    '
    ' @param id ID of the parameter
    ' @return Parameter value or invalid
    instance._getParameterValue = function(id as string) as dynamic
        parameters = m._interactionContext.getParameters()
        if parameters = invalid then
            return invalid
        end if
        values = parameters[id]
        if values <> invalid and values.count() > 0 then
            return values[0]
        else
            return invalid
        end if
    end function
    return instance
end function
function BCBehaviorListener()
    instance = __BCBehaviorListener_builder()
    instance.new()
    return instance
end function