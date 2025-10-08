' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
'
' Class handling the engagement ranking of a user based on their interactions.
function __BCEngagementRankingListener_builder()
    instance = __BCPlugin_builder()
    instance.super0_new = instance.new
    instance.new = sub()
        m.super0_new()
        m.engagementService = invalid
        m.PARAMETER_RULES = "engagement_rules"
        m.PARAMETER_INTERESTS = "interests"
        m.PARAMETER_PROPERTY = "property"
        m.TAG_VALUES = "values"
        m.TAG_RULES = "rules"
    end sub
    ' Constants
    instance.super0_onLoad = instance.onLoad
    instance.onLoad = sub()
        engagementRulesJson = m.getParameterValue(m.PARAMETER_RULES)
        interestsJson = m.getParameterValue(m.PARAMETER_INTERESTS)
        if engagementRulesJson <> invalid then
            jsonObject = ParseJson(engagementRulesJson)
            if jsonObject <> invalid and jsonObject[m.TAG_RULES] <> invalid
                rules = jsonObject[m.TAG_RULES]
                interestsObject = ParseJson(interestsJson)
                interests = []
                if interestsObject <> invalid and interestsObject[m.TAG_VALUES] <> invalid
                    interests = m.getStringList(interestsObject[m.TAG_VALUES])
                end if
                m.engagementService = BCEngagementService(m._client, m._interactionContext, m._interactionContext.getInteractionId(), true, interests, true)
                m.engagementService.applyEngagementRules(rules)
                if m.engagementService.isChanged()
                    m.engagementService.save()
                end if
            end if
        end if
    end sub
    instance.super0_onDestroy = instance.onDestroy
    instance.onDestroy = sub()
        m._client.eventManager().clearEventHandlers(m._interactionContext.getInteractionId())
    end sub
    ' Converts a JSON array to a string list.
    ' @param jsonArray JSON array to convert.
    ' @return List of strings which are part of the JSON array.
    instance.getStringList = function(jsonArray as dynamic) as object
        result = []
        if jsonArray = invalid then
            return result
        end if
        for i = 0 to jsonArray.count() - 1
            if jsonArray[i] <> invalid
                result.push(jsonArray[i].toStr())
            end if
        end for
        return result
    end function
    ' Returns the first value for a parameter. When no parameter value is found, invalid is returned.
    ' @param id ID of the parameter
    ' @return Parameter value
    instance.getParameterValue = function(id as string) as dynamic
        ' Get all the parameters from the context.
        parameters = m._interactionContext.getParameters()
        values = parameters[id]
        if values <> invalid and values.count() > 0
            return values[0]
        else
            return invalid
        end if
    end function
    return instance
end function
function BCEngagementRankingListener()
    instance = __BCEngagementRankingListener_builder()
    instance.new()
    return instance
end function