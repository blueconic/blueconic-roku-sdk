' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
'
' Class handling the engagement score of a user based on their interactions.
function __BCEngagementScoreListener_builder()
    instance = __BCPlugin_builder()
    instance.super0_new = instance.new
    instance.new = sub()
        m.super0_new()
        m.engagementService = invalid
        m._PARAMETER_RULES = "engagement_rules"
        m._PARAMETER_PROPERTY = "property"
        m._TAG_RULES = "rules"
        m._TAG_PROFILE_PROPERTY = "profileproperty"
        m._PROPERTY_RULES = "propertyRules"
        m._DECAY = "decay"
    end sub
    ' Constants
    instance.super0_onLoad = instance.onLoad
    instance.onLoad = sub()
        parameters = m._interactionContext.getParameters()
        engagementRulesJson = m._getParameterValue(parameters, m._PARAMETER_RULES)
        if engagementRulesJson <> invalid then
            jsonObject = ParseJson(engagementRulesJson)
            if jsonObject <> invalid then
                rules = jsonObject.lookupCI(m._TAG_RULES)
                if rules <> invalid then
                    profileProperty = m._getProfilePropertyFromRules(parameters)
                    if profileProperty = invalid then
                        return
                    end if
                    m.engagementService = BCEngagementService(m._client, m._interactionContext, profileProperty, false, [], false)
                    m.engagementService.applyEngagementRules(rules)
                    m.engagementService.save()
                else
                    BCLogError("Invalid json for: " + m._PARAMETER_RULES + " or " + m._PARAMETER_PROPERTY)
                end if
            else
                BCLogError("Invalid json for: " + m._PARAMETER_RULES + " or " + m._PARAMETER_PROPERTY)
            end if
        else
            BCLogError("Invalid json for: " + m._PARAMETER_RULES + " or " + m._PARAMETER_PROPERTY)
        end if
    end sub
    instance.super0_onDestroy = instance.onDestroy
    instance.onDestroy = sub()
        m._client.eventManager().clearEventHandlers(m._interactionContext.getInteractionId())
    end sub
    ' Returns the first value for a parameter. When no parameter value is found, invalid is returned.
    '
    ' @param parameters The parameters as an associative array
    ' @param id ID of the parameter
    ' @return Parameter value or invalid
    instance._getParameterValue = function(parameters as object, id as string) as dynamic
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
    ' Return the leading profile property based on the rules.
    '
    ' @param parameters The parameters as an associative array
    ' @return return the profile property that is leading, or invalid
    instance._getProfilePropertyFromRules = function(parameters as object) as dynamic
        profileProperty = invalid
        propertyRulesJSON = m._getParameterValue(parameters, m._PROPERTY_RULES)
        if propertyRulesJSON <> invalid then
            propertyRules = ParseJson(propertyRulesJSON)
            if propertyRules <> invalid and propertyRules.count() > 0 then
                highDecay = 0
                for i = 0 to propertyRules.count() - 1
                    rule = propertyRules[i]
                    if rule <> invalid then
                        ruleProfileProperty = rule.lookupCI(m._TAG_PROFILE_PROPERTY)
                        if ruleProfileProperty = invalid then
                            ruleProfileProperty = ""
                        end if
                        decay = rule.lookupCI(m._DECAY)
                        if decay = invalid then
                            decay = 0
                        end if
                        if decay <> 0 and decay > highDecay then
                            highDecay = decay
                            profileProperty = ruleProfileProperty
                        end if
                    end if
                end for
            end if
        end if
        return profileProperty
    end function
    return instance
end function
function BCEngagementScoreListener()
    instance = __BCEngagementScoreListener_builder()
    instance.new()
    return instance
end function