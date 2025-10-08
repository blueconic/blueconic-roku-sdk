' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling the recommendations dialogue.
function __BCRecommendationsDialogue_builder()
    instance = __BCPlugin_builder()
    instance.super0_new = instance.new
    instance.new = sub()
        m.super0_new()
    end sub
    instance.super0_onLoad = instance.onLoad
    instance.onLoad = sub()
        recommendationsRulesJson = m._getParameterValue("rules")
        rules = ParseJson(recommendationsRulesJson)
        storeId = m._getParameterValue("storeId")
        frequencyCap = Val(m._getParameterValue("frequencyCap"))
        imageWidth = Val(m._getParameterValue("imageWidth"))
        imageHeight = Val(m._getParameterValue("imageHeight"))
        manualViewCountingParam = m._getParameterValue("manualViewCounting")
        manualViewCounting = (LCase(manualViewCountingParam) = "true")
        recommendationItems = m._getItems(rules, storeId, frequencyCap, imageWidth, imageHeight, manualViewCounting)
        recommendationEvent = BCRecommendationsDialogueEvent(m._interactionContext.getInteractionId(), m._interactionContext.getPositionName(), storeId, recommendationItems)
        m._client.eventManager().publish(recommendationEvent)
    end sub
    instance.super0_onDestroy = instance.onDestroy
    instance.onDestroy = sub()
    end sub
    instance._getItems = function(rules, storeId as string, frequencyCap as integer, imageWidth as integer, imageHeight as integer, manualViewCounting as boolean) as object
        valueObj = m._getQueryStringParametersForRecommendations(rules, storeId, frequencyCap, imageWidth, imageHeight, manualViewCounting)
        recommendationData = m._client._getRecommendations(valueObj)
        return recommendationData
    end function
    ' Retrieve query string for recommendation request based on configuration.
    '
    ' @return: Query string parameters as object
    instance._getQueryStringParametersForRecommendations = function(rules as object, storeId as string, frequencyCap as integer, imageWidth as integer, imageHeight as integer, manualViewCounting as boolean) as object
        result = {}
        if storeId = ""
            return result
        else
            result["storeId"] = storeId
        end if
        profileId = ""
        if m._client <> invalid and m._client.profile().getId() <> invalid
            profileId = m._client.profile().getId()
        end if
        result["profileId"] = profileId
        isDebugMode = false
        if m._client <> invalid and m._client._configuration <> invalid
            isDebugMode = m._client._configuration.isDebugMode
        end if
        result["debug"] = isDebugMode
        if frequencyCap <> 0
            result["frequencyCap"] = frequencyCap
        end if
        if imageWidth <> 0
            result["imageWidth"] = imageWidth
        end if
        if imageHeight <> 0
            result["imageHeight"] = imageHeight
        end if
        result["manualViewCounting"] = manualViewCounting
        result["request"] = m._getRules(rules)
        return result
    end function
    ' Returns the result data from the rules attribute.
    '
    ' @return: Result array
    instance._getRules = function(rules as object) as object
        result = []
        if rules <> invalid and Type(rules) = "roArray"
            for i = 0 to rules.count() - 1
                rule = rules[i]
                if rule <> invalid
                    ruleObj = {}
                    ' Set id based on isFallback
                    if rule.isFallback = true
                        ruleObj["id"] = "default"
                    else
                        ruleObj["id"] = rule.id
                    end if
                    ruleObj["filters"] = m._getRuleFilters(rule)
                    ruleObj["boosts"] = m._getBoostFilters(rule)
                    ' Set count (null if fallback)
                    if rule.isFallback = true
                        ruleObj["count"] = invalid
                    else
                        if rule.doesExist("amount")
                            ruleObj["count"] = rule.amount
                        else
                            ruleObj["count"] = invalid
                        end if
                    end if
                    result.push(ruleObj)
                end if
            end for
        end if
        return result
    end function
    ' Return rule filters.
    '
    ' @param rule: Rule object
    ' @return: Rule filters array
    instance._getRuleFilters = function(rule as object) as object
        queryFilterRules = []
        ' Handle filters array
        if rule.doesExist("filters") and Type(rule.filters) = "roArray"
            for i = 0 to rule.filters.count() - 1
                filter = rule.filters[i]
                if filter <> invalid
                    filterType = ""
                    if filter.filterType = "SHOW" and filter.id <> "IN_STOCK"
                        filterType = "_ONLY"
                    end if
                    filterId = filter.id + filterType
                    queryFilterRules.push(filterId)
                end if
            end for
        end if
        return queryFilterRules
    end function
    ' Returns the boost filters
    ' Makes sure all algorithms contain a value.
    '
    ' @param rule: Rule object
    ' @return: Algorithms array
    instance._getBoostFilters = function(rule as object) as object
        if not rule.doesExist("algorithms") or Type(rule.algorithms) <> "roArray"
            return []
        end if
        result = []
        for i = 0 to rule.algorithms.count() - 1
            algorithm = rule.algorithms[i]
            if algorithm <> invalid
                ' Create a copy of the algorithm object
                algorithmCopy = {}
                for each key in algorithm
                    algorithmCopy[key] = algorithm[key]
                end for
                ' Remove rampUp when undefined/null
                if not algorithmCopy.doesExist("rampUp") or algorithmCopy.rampUp = invalid
                    algorithmCopy.delete("rampUp")
                end if
                result.push(algorithmCopy)
            end if
        end for
        return result
    end function
    ' ' Returns the first value for a parameter. When no parameter value is found, empty string is returned.
    ' '
    ' ' @param id: ID of the parameter
    ' ' @return: Parameter value
    ' private function _getParameterValue(id as string) as string
    '     ' Get all the parameters from the context
    '     if m.context <> invalid and m.context.doesExist("parameters")
    '         parameters = m.context.parameters
    '         if parameters.doesExist(id) and Type(parameters[id]) = "roArray" and parameters[id].count() > 0
    '             return parameters[id][0].toStr()
    '         end if
    '     end if
    '     return ""
    ' end function
    ' Retrieves the value of a parameter from the interaction context.
    '
    ' @param key The key of the parameter to retrieve.
    ' @return The value of the parameter if found, otherwise an empty string.
    instance._getParameterValue = function(key as string) as dynamic
        if m._interactionContext.getParameters()[key] <> invalid and m._interactionContext.getParameters()[key].Count() > 0
            return m._interactionContext.getParameters()[key][0]
        else
            return ""
        end if
    end function
    return instance
end function
function BCRecommendationsDialogue()
    instance = __BCRecommendationsDialogue_builder()
    instance.new()
    return instance
end function