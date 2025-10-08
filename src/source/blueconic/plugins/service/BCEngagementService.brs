' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
'
' Class handling the engagement service functionality.
function __BCEngagementService_builder()
    instance = __BCEventServiceBase_builder()
    ' Constructor
    instance.super0_new = instance.new
    instance.new = function(client as object, context as object, propertyId as string, isInterest as boolean, allInterests = [] as object, useHalfTime = false as boolean)
        m.super0_new(client, context.getInteractionId())
        m._propertyId = invalid
        m._isInterest = invalid
        m._allInterests = invalid
        m._useHalfTime = invalid
        m._days = invalid
        m._changes = invalid
        m._propertyId = propertyId
        m._isInterest = isInterest
        m._allInterests = allInterests
        m._useHalfTime = useHalfTime
        m._days = m._getDays(useHalfTime, m._getCurrentTimeMillis())
        m._changes = []
    end function
    ' Called when an event is thrown by the app developer.
    '
    ' @param event The event that needs to be handled
    instance.super0_handleEvent = instance.handleEvent
    instance.handleEvent = sub(event as object)
        if m.blueConicClient = invalid then
            BCLogError("BlueConic client object not found. Cannot handle event: " + event.name)
            return
        end if
        scoreEngagementService = invalid
        if m.blueConicClient._pluginsManager._plugins.engagement_score <> invalid then
            scoreEngagementService = m.blueConicClient._pluginsManager._plugins.engagement_score.engagementService
            if scoreEngagementService = invalid
                BCLogError("Engagement service instance for score not found. Cannot handle event: " + event.name)
            end if
        end if
        interestEngagementService = invalid
        if m.blueConicClient._pluginsManager._plugins.engagement_interest_ranking <> invalid then
            interestEngagementService = m.blueConicClient._pluginsManager._plugins.engagement_interest_ranking.engagementService
            if interestEngagementService = invalid
                BCLogError("Engagement service instance for interest not found. Cannot handle event: " + event.name)
            end if
        end if
        if scoreEngagementService = invalid and interestEngagementService = invalid then
            BCLogError("No engagement service instances found. Cannot handle event: " + event.name)
            return
        end if
        scene = invalid
        if m.global <> invalid
            scene = m.global.getScene()
        end if
        for each id in event.handledBy
            instance = invalid
            if id = scoreEngagementService._listenerUUID then
                instance = scoreEngagementService
            else if id = interestEngagementService._listenerUUID then
                instance = interestEngagementService
            end if
            if instance <> invalid then
                rules = instance.getRules(event)
                if rules <> invalid then
                    for each rule in rules
                        points = instance._getPoints(rule)
                        if points = 0 then
                            BCLogWarning("No points defined: ignoring this rule")
                            continue for
                        end if
                        eventType = event.name
                        if eventType = "clickEvent" then
                            instance._handleClickRule(instance, rule, event, scene)
                        else if eventType = "advancedEvent" then
                            instance._handleEventRule(instance, rule, event)
                        else if eventType = "updateContentEvent" then
                            instance._handleUpdateContentEvent(instance, rule, event)
                        end if
                    end for
                end if
                instance.save()
            end if
        end for
    end sub
    ' Applies rules and determines which keywords earn points based on the engagement rule settings.
    '
    ' @param rules the engagement rules
    instance.applyEngagementRules = sub(rules as object)
        scene = invalid
        if m._client.blueConicTask <> invalid
            scene = m._client.blueConicTask.getScene()
        end if
        for each rule in rules
            BCLogInfo("Handling : " + FormatJson(rule))
            ruleType = rule.lookupCI(m._TAG_RULE_TYPE)
            points = m._getPoints(rule)
            if points = 0 then
                BCLogWarning("No points defined: ignoring this rule")
                continue for
            end if
            if ruleType = m._RULETYPE_SCORE_CONTENT or ruleType = m._RULETYPE_INTEREST_CONTENT then
                selector = m._getSelector(rule.lookupCI(m._TAG_CONTENT_AREA))
                if selector = invalid then
                    m._LOG.warn("Found content rule without content area selector:" + FormatJson(rule))
                    continue for
                end if
                m._addPointsForRule(rule, m._getContent(selector, [], scene))
                m.registerEvent(rule, "updateContentEvent")
            else if ruleType = m._RULETYPE_SCORE_CLICK or ruleType = m._RULETYPE_INTEREST_CLICK then
                m.registerEvent(rule, "clickEvent")
            else if ruleType = m._RULETYPE_SCORE_URL or ruleType = m._RULETYPE_INTEREST_URL then
                urlConfig = rule.lookupCI(m._TAG_URL)
                if urlConfig = m._TAG_URL or urlConfig = m._TAG_OR or urlConfig = m._TAG_URLREFERRER then
                    url = m._client.screenName
                    m._addPointsForRule(rule, [
                        url
                    ])
                else
                    BCLogWarning("Url config '" + urlConfig + "' is not supported")
                end if
            else if ruleType = m._RULETYPE_SCORE_EVENT or ruleType = m._RULETYPE_INTEREST_EVENT or ruleType = m._RULETYPE_SCORE_SOCIAL_EVENT or ruleType = m._RULETYPE_INTEREST_SOCIAL_EVENT then
                m.registerEvent(rule, "advancedEvent")
            end if
        end for
        m.subscribeListeners()
    end sub
    ' Returns true whether changes are made.
    '
    ' @return true when changes were made, false otherwise.
    instance.isChanged = function() as boolean
        return m._changes.count() > 0
    end function
    ' Adds points for a keyword to the _changes objects.
    '
    ' @param keyword The keyword to which the points needs to be assigned
    ' @param score Number of points to assign
    instance.addPoints = sub(keyword as string, score as integer)
        BCLogInfo("Adding " + str(score) + " points for " + keyword)
        changeObj = {
            n: keyword
            p: score
        }
        m._changes.push(changeObj)
    end sub
    ' Returns the new added points in a format based on the HalfTime mechanism.
    '
    ' @param time The time.
    ' @return a stringified JSON structure
    instance.getHalfTimeData = function(time as longinteger) as string
        value = {
            TIME: time
            days: m._days
            data: m._changes
        }
        return FormatJson(value)
    end function
    ' Returns the new added points in a format based on the old mechanism.
    '
    ' @param time The time.
    ' @return a stringified JSON structure
    instance.getFormattedData = function(time as longinteger) as string
        value = {
            TIME: time
        }
        for each change in m._changes
            name = change.n
            points = change.p
            if points = 0 then
                continue for
            end if
            if value.doesExist(name) then
                data = value[name]
            else
                data = {}
            end if
            dayKey = "p" + m._days.toStr()
            existing = 0
            if data.doesExist(dayKey) then
                existing = data[dayKey]
            end if
            data[dayKey] = existing + points
            value[name] = data
        end for
        return FormatJson(value)
    end function
    ' Saves the engagement data to the profile.
    instance.save = sub()
        if m._changes.count() = 0 then
            return
        end if
        time = m._getCurrentTimeMillis()
        if m._useHalfTime then
            data = m.getHalfTimeData(time)
        else
            data = m.getFormattedData(time)
        end if
        BCLogInfo("Adding '" + data + "' to property '_" + m._propertyId + "'")
        m._client.profile().addValue("_" + m._propertyId, data)
        ' flush the list
        m._changes = []
    end sub
    ' Handles the content rule when the content is updated with the update content event.
    '
    ' @param rule JSON object of the content rule as defined in the listener
    ' @param updateContentEvent The update content event
    instance._handleUpdateContentEvent = sub(instance as object, rule as object, updateContentEvent as object)
        ' check if the selector is ok
        contentArea = rule.lookupCI(instance._TAG_CONTENT_AREA)
        if contentArea <> invalid then
            selector = contentArea.lookupCI(instance._TAG_SELECTOR)
            if selector <> invalid and not selector.inStr(instance._PRE_MOBILE) > 0 and selector <> updateContentEvent.selector then
                return
            end if
            instance._addPointsForRule(rule, [
                updateContentEvent.content
            ])
        end if
    end sub
    ' Handles the advanced event rule when an advanced event is thrown by the app developer.
    '
    ' @param rule JSON object of the advanced event rule as defined in the listener
    ' @param advancedEvent The advanced event
    instance._handleEventRule = sub(instance as object, rule as object, advancedEvent as object)
        eventName = rule.lookupCI(instance._TAG_EVENT)
        if eventName <> invalid and eventName <> advancedEvent.eventName then
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
        instance._addPointsForRule(rule, contextContent)
    end sub
    ' Handles a click event
    '
    ' @param rule JSON object of the rule as defined in the listener
    ' @param event The click event
    instance._handleClickRule = sub(instance as object, rule as object, event as object, scene as dynamic)
        contentArea = rule.lookupCI(instance._TAG_CONTENT_AREA)
        selector = event.selector
        ruleType = rule.lookupCI(instance._TAG_RULE_TYPE)
        ruleSelector = invalid
        if ruleType = instance._RULETYPE_SCORE_CLICK or ruleType = instance._RULETYPE_INTEREST_CLICK then
            clickArea = rule.lookupCI(instance._TAG_CLICKAREA)
            if clickArea <> invalid then
                ruleSelector = clickArea.lookupCI(instance._TAG_SELECTOR)
            end if
        end if
        if selector <> ruleSelector then
            return
        end if
        words = instance._getStringList(rule.lookupCI(instance._TAG_WORDS))
        points = instance._getPoints(rule)
        contentSelector = contentArea.lookupCI(instance._TAG_SELECTOR)
        if (contentSelector = instance._PRE_ANY or contentSelector = instance._TAG_CONTEXT) and words.count() > 0 and words[0] = instance._PRE_ANY then
            if instance._isInterest then
                interestsObject = rule.lookupCI(instance._TAG_INTERESTS)
                if interestsObject <> invalid and interestsObject[0] = instance._TAG_SELECTOR then
                    interestSelector = interestsObject.lookupCI(instance._TAG_SELECTOR)
                    interestsToScore = instance._getContent(interestSelector, event.context, scene)
                    if interestsToScore.count() > 0 then
                        for each interestToScore in interestsToScore
                            instance.addPoints(LCase(interestToScore), points)
                        end for
                    end if
                else
                    ruleInterests = instance._getStringList(rule.lookupCI(instance._TAG_INTERESTS))
                    if ruleInterests.count() > 0 and ruleInterests[0] = instance._PRE_ANY then
                        for each interest in instance._allInterests
                            instance.addPoints(LCase(interest), points)
                        end for
                    else if ruleInterests.count() > 0 and ruleInterests[0] = instance._TAG_CONTEXT then
                        for each contextItem in event.context
                            instance.addPoints(LCase(contextItem), points)
                        end for
                    else if ruleInterests.count() > 0 then
                        for each ruleInterest in ruleInterests
                            instance.addPoints(LCase(ruleInterest), points)
                        end for
                    end if
                end if
            else
                instance.addPoints(instance._SCORE_INTEREST, points)
            end if
        else
            contentSelector = instance._getSelector(contentArea)
            instance._addPointsForRule(rule, instance._getContent(contentSelector, event.context, scene))
        end if
    end sub
    ' Adds points for interests.
    '
    ' @param rule the rule for which to add points.
    ' @param content the content to check, array
    instance._addPointsForInterests = sub(rule as object, content as object)
        points = m._getPoints(rule)
        ruleInterests = []
        if rule.doesExist(m._TAG_INTERESTS) then
            ruleInterests = m._getStringList(rule.lookupCI(m._TAG_INTERESTS))
        end if
        if ruleInterests.count() > 0 and ruleInterests[0] = m._PRE_ANY then
            for each checkInterest in m._allInterests
                if m._contentContainsWord(rule, content, [
                    checkInterest
                ]) then
                    m.addPoints(LCase(checkInterest), points)
                end if
            end for
        else if m._contentContainsWord(rule, content, m._getWords(m._getStringList(rule.lookupCI(m._TAG_WORDS)))) then
            if ruleInterests.count() > 0 and ruleInterests[0] = m._TAG_CONTEXT then
                for each interest in content
                    m.addPoints(LCase(interest), points)
                end for
            else
                for each interest in ruleInterests
                    m.addPoints(LCase(interest), points)
                end for
            end if
        end if
    end sub
    ' Returns a words array based on the words value in the rule.
    '
    ' @param words the words
    ' @return returns an array with zero or more words
    instance._getWords = function(words as object) as object
        if words = invalid then
            return [
                m._PRE_ANY
            ]
        else
            return words
        end if
    end function
    ' Adds points for a interest ranking or score rule.
    '
    ' @param rule the rule for which to add points.
    ' @param content the content to check, array
    instance._addPointsForRule = sub(rule as object, content as object)
        if m._isInterest then
            m._addPointsForInterests(rule, content)
        else if m._contentContainsWord(rule, content, m._getWords(m._getStringList(rule.lookupCI(m._TAG_WORDS)))) then
            m.addPoints(m._SCORE_INTEREST, rule.lookupCI(m._TAG_POINTS))
        end if
    end sub
    ' Retrieves the number of points from the configured rule.
    '
    ' @param rule The JSON Object representing the rule as defined in the listener
    ' @return Number of points. When nothing is configured, zero is returned
    instance._getPoints = function(rule as object) as integer
        if rule.doesExist(m._TAG_POINTS) then
            points = rule.lookupCI(m._TAG_POINTS)
            if points <> invalid then
                return points
            end if
        end if
        return 0
    end function
    ' Helper functions that need to be implemented
    '
    ' @param useHalfTime Whether to use the half time mechanism
    ' @param currentTime The current time in milliseconds
    ' @return the number of days since the base date
    instance._getDays = function(useHalfTime as boolean, currentTime as longinteger) as integer
        baseDate = CreateObject("roDateTime")
        if useHalfTime then
            ' New base is 1 sept 2017
            baseDate.fromISO8601String("2017-09-01T00:00:00Z")
        else
            ' Old base is 1 jan 2012
            baseDate.fromISO8601String("2012-01-01T00:00:00Z")
        end if
        baseDateMillis = baseDate.asSecondsLong() * 1000
        diff = currentTime - baseDateMillis
        days = int(diff / (24 * 3600 * 1000))
        return days
    end function
    return instance
end function
function BCEngagementService(client as object, context as object, propertyId as string, isInterest as boolean, allInterests = [] as object, useHalfTime = false as boolean)
    instance = __BCEngagementService_builder()
    instance.new(client, context, propertyId, isInterest, allInterests, useHalfTime)
    return instance
end function