' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
'
' Class handling the 
function __BCEnrichByBehaviorService_builder()
    instance = __BCEventServiceBase_builder()
    ' Constructor
    instance.super0_new = instance.new
    instance.new = function(client as object, context as object)
        m.super0_new(client, context.getInteractionId())
    end function
    ' Called when an event is thrown by the app developer.
    '
    ' @param event The event that needs to be handled
    instance.super0_handleEvent = instance.handleEvent
    instance.handleEvent = sub(event as object)
        if m.blueConicClient = invalid
            BCLogError("BlueConic client object not found. Cannot handle event: " + event.name)
            return
        end if
        if m.blueConicClient._pluginsManager._plugins.enrichprofilebyvisitorbehavior = invalid
            BCLogError("Enrichment by visitor behavior plugin not found. Cannot handle event: " + event.name)
            return
        end if
        instance = m.blueconicClient._pluginsManager._plugins.enrichprofilebyvisitorbehavior.enrichByBehaviorService
        if instance = invalid
            BCLogError("Enrichment by visitor behavior service instance not found. Cannot handle event: " + event.name)
            return
        end if
        scene = invalid
        if m.global <> invalid
            scene = m.global.getScene()
        end if
        rules = instance.getRules(event)
        if rules <> invalid then
            for each rule in rules
                eventType = event.name
                if eventType = "clickEvent" then
                    instance._handleClickRule(instance, rule, event, scene)
                else if eventType = "advancedEvent" then
                    instance._handleEventRule(instance, rule, event, scene)
                else if eventType = "updateContentEvent" then
                    instance._handleUpdateContentEvent(instance, rule, event)
                end if
            end for
        end if
    end sub
    ' Applies rules and determines which keywords earn points based on the engagement rule settings
    '
    ' @param rules the engagement rules
    instance.applyRules = sub(rules as object)
        scene = invalid
        if m._client.blueConicTask <> invalid
            scene = m._client.blueConicTask.getScene()
        end if
        for each rule in rules
            BCLogInfo("Handling : " + FormatJson(rule))
            ruleType = rule.lookupCI(m._TAG_RULE_TYPE)
            profileProperty = m._getProfileProperty(rule)
            emptyList = []
            context = [
                "context"
            ]
            values = m._getValues(rule, context, scene)
            if values.count() = 0 then
                BCLogWarning("No values defined: ignoring this rule")
                continue for
            end if
            if profileProperty = invalid or profileProperty = "" then
                BCLogWarning("No profile property defined: ignoring this rule")
                continue for
            end if
            if ruleType = m._RULETYPE_SCORE_CONTENT then
                contentArea = rule.lookupCI(m._TAG_CONTENT_AREA)
                if contentArea <> invalid then
                    selector = m._getSelector(contentArea)
                    if selector = invalid or selector = "" then
                        BCLogWarning("Found content rule without content area selector: " + FormatJson(rule))
                        continue for
                    end if
                    words = m._getStringList(rule.lookupCI(m._TAG_WORDS))
                    if m._contentContainsWord(rule, m._getContent(selector, emptyList, scene), words) then
                        m._updateProfileValuesByRule(rule, emptyList, scene)
                    end if
                    m.registerEvent(rule, "updateContentEvent")
                end if
            else if ruleType = m._RULETYPE_SCORE_CLICK then
                clickArea = rule.lookupCI(m._TAG_CLICKAREA)
                if clickArea <> invalid then
                    clickSelector = m._getSelector(clickArea)
                    if clickSelector <> invalid and clickSelector <> "" then
                        m.registerEvent(rule, "clickEvent")
                    end if
                end if
            else if ruleType = m._RULETYPE_SCORE_URL then
                urlConfig = rule.lookupCI(m._TAG_URL)
                if urlConfig = "url" or urlConfig = "or" or urlConfig = "urlreferrer" then
                    url = m._client.screenName
                    urlWords = m._getStringList(rule.lookupCI(m._TAG_WORDS))
                    if m._contentContainsWord(rule, [
                        url
                    ], urlWords) then
                        m._updateProfileValuesByRule(rule, emptyList, scene)
                    end if
                else
                    BCLogWarning("Url config '" + urlConfig + "' is not supported for mobile")
                end if
            else if ruleType = m._RULETYPE_SCORE_EVENT or ruleType = m._RULETYPE_SCORE_SOCIAL_EVENT then
                m.registerEvent(rule, "advancedEvent")
            end if
        end for
        m.subscribeListeners()
    end sub
    ' Handles the content rule when the content is updated with the update content event
    '
    ' @param rule JSON object of the content rule as defined in the listener
    ' @param updateContentEvent The update content event
    instance._handleUpdateContentEvent = sub(instance as object, rule as object, updateContentEvent as object)
        contentArea = rule.lookupCI(instance._TAG_CONTENT_AREA)
        if contentArea = invalid then
            return
        end if
        selector = contentArea.lookupCI(instance._TAG_SELECTOR)
        if selector = invalid then
            return
        end if
        if selector.inStr(instance._PRE_MOBILE) = -1 and selector <> updateContentEvent.selector then
            return
        end if
        content = [
            updateContentEvent.content
        ]
        words = instance._getStringList(rule.lookupCI(instance._TAG_WORDS))
        if instance._contentContainsWord(rule, content, words) then
            profileProperty = instance._getProfileProperty(rule)
            if profileProperty <> invalid and profileProperty <> "" then
                instance._updateProfileValues(profileProperty, content, instance._getMergeStrategy(rule))
            end if
        end if
    end sub
    ' Handles the advanced event rule when an advanced event is thrown by the app developer
    '
    ' @param rule JSON object of the advanced event rule as defined in the listener
    ' @param advancedEvent The advanced event
    instance._handleEventRule = sub(instance as object, rule as object, advancedEvent as object, scene as dynamic)
        eventName = rule.lookupCI(instance._TAG_EVENT)
        if eventName = invalid or eventName <> advancedEvent.eventName then
            return
        end if
        contextContent = []
        contextPosition = rule.lookupCI(instance._TAG_CONTEXT_POSITION)
        if contextPosition = invalid or contextPosition = "" then
            contextContent = advancedEvent.context
        else
            contextPositionIndex = val(contextPosition)
            if advancedEvent.context.count() >= contextPositionIndex then
                contextContent.push(advancedEvent.context[contextPositionIndex - 1])
            end if
        end if
        words = instance._getStringList(rule.lookupCI(instance._TAG_WORDS))
        if instance._contentContainsWord(rule, contextContent, words) then
            instance._updateProfileValuesByRule(rule, advancedEvent.context, scene)
        end if
    end sub
    ' Handles a click event
    '
    ' @param rule JSON object of the rule as defined in the listener
    ' @param event The Click event that has been published
    instance._handleClickRule = sub(instance as object, rule as object, event as object, scene as dynamic)
        contentArea = rule.lookupCI(instance._TAG_CONTENT_AREA)
        if contentArea = invalid then
            return
        end if
        selector = event.selector
        clickArea = rule.lookupCI(instance._TAG_CLICKAREA)
        if clickArea = invalid then
            return
        end if
        clickAreaSelector = clickArea.lookupCI(instance._TAG_SELECTOR)
        if selector <> clickAreaSelector then
            return
        end if
        words = instance._getStringList(rule.lookupCI(instance._TAG_WORDS))
        contentAreaSelector = contentArea.lookupCI(instance._TAG_SELECTOR)
        if (contentAreaSelector = instance._PRE_ANY or contentAreaSelector = instance._PRE_CONTEXT) and words.count() > 0 and words[0] = instance._PRE_ANY then
            instance._updateProfileValuesByRule(rule, event.context, scene)
        else
            contentSelector = instance._getSelector(contentArea)
            if instance._contentContainsWord(rule, instance._getContent(contentSelector, event.context, scene), words) then
                instance._updateProfileValuesByRule(rule, event.context, scene)
            end if
        end if
    end sub
    ' Updates a profile property value by information provided by the rule configuration
    '
    ' @param rule Rule configuration provided by the listener
    ' @param context The context
    instance._updateProfileValuesByRule = sub(rule as object, context as object, scene as dynamic)
        profileProperty = m._getProfileProperty(rule)
        if profileProperty <> invalid and profileProperty <> "" then
            values = m._getValues(rule, context, scene)
            m._updateProfileValues(profileProperty, values, m._getMergeStrategy(rule))
        end if
    end sub
    ' Updates values of a profile property with provided content
    '
    ' @param profileProperty The profile property id
    ' @param content The content to store in the profile property
    ' @param mergeStrategy merge strategy for updating the profile property ('add', 'set', 'set_if_empty' or 'merge')
    instance._updateProfileValues = sub(profileProperty as string, content as object, mergeStrategy as string)
        if profileProperty = "" or content.count() = 0 or mergeStrategy = "" then
            return
        end if
        if mergeStrategy = m._MERGE_STRATEGY_ADD then
            m._client.profile().addValues(profileProperty, content)
        else if mergeStrategy = m._MERGE_STRATEGY_SET then
            m._client.profile().setValues(profileProperty, content)
        else if mergeStrategy = m._MERGE_STRATEGY_SET_IF_EMPTY then
            value = m._client.profile().getValue(profileProperty)
            if value = invalid or value = "" then
                m._client.profile().setValues(profileProperty, content)
            end if
        else if mergeStrategy = m._MERGE_STRATEGY_MERGE then
            m._mergeValues(profileProperty, content)
        end if
    end sub
    ' Gets values from rule configuration
    '
    ' @param rule The rule configuration
    ' @param context The context
    ' @return Array of values
    instance._getValues = function(rule as object, context as object, scene as dynamic) as object
        values = []
        valuesConfig = rule.lookupCI(m._TAG_VALUES)
        if valuesConfig = invalid then
            return values
        end if
        if type(valuesConfig) = "roAssociativeArray" then
            if valuesConfig.doesExist(m._TAG_SELECTOR) then
                selector = valuesConfig.lookupCI(m._TAG_SELECTOR)
                contentValues = m._getContent(selector, context, scene)
                for each contentValue in contentValues
                    values.push(contentValue)
                end for
            else if valuesConfig.doesExist(m._TAG_SELECTEDOPTION) then
                selectedOption = valuesConfig.lookupCI(m._TAG_SELECTEDOPTION)
                if selectedOption = m._TAG_CONTEXT then
                    for each contextItem in context
                        values.push(contextItem)
                    end for
                else if selectedOption = m._TAG_DATETIME then
                    values.push(m._getCurrentTime())
                else if selectedOption = m._TAG_DATE then
                    values.push(m._getCurrentDate())
                end if
            end if
        else if type(valuesConfig) = "roArray" then
            for each value in valuesConfig
                if value <> invalid then
                    values.push(value.toStr())
                end if
            end for
        else if type(valuesConfig) = "roString" or type(valuesConfig) = "String" then
            if valuesConfig = m._TAG_DATETIME then
                values.push(m._getCurrentTime())
            else if valuesConfig = m._TAG_DATE then
                values.push(m._getCurrentDate())
            else
                values.push(valuesConfig)
            end if
        end if
        return values
    end function
    ' Gets the first non-empty value from a collection
    '
    ' @param values Collection of values
    ' @return First non-empty value or "0"
    instance._getFirstNonEmptyValue = function(values as object) as string
        for each value in values
            trimmedValue = value.trim()
            if trimmedValue <> "" then
                return trimmedValue
            end if
        end for
        return "0"
    end function
    ' Merges values by adding them numerically
    '
    ' @param propertyId The property ID
    ' @param values The values to merge
    instance._mergeValues = sub(propertyId as string, values as object)
        currentValues = m._client.profile().getValues(propertyId)
        currentValue = m._getFirstNonEmptyValue(currentValues)
        currentFloat = val(currentValue)
        canSum = true
        for each value in values
            numericValue = val(value)
            if numericValue = 0 and value <> "0" then
                canSum = false
                exit for
            end if
            currentFloat = currentFloat + numericValue
        end for
        if canSum then
            m._client.profile().setValues(propertyId, [
                currentFloat.toStr()
            ])
        else
            m._client.profile().addValues(propertyId, values)
        end if
    end sub
    return instance
end function
function BCEnrichByBehaviorService(client as object, context as object)
    instance = __BCEnrichByBehaviorService_builder()
    instance.new(client, context)
    return instance
end function