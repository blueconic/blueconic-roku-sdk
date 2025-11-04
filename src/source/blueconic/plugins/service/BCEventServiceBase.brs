' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
'
' Class handling the base functionality for event services.
function __BCEventServiceBase_builder()
    instance = {}
    ' The mapping of event class names to the corresponding rules
    ' Constants
    ' Constructor
    instance.new = sub(client as object, listenerUUID as string)
        m._eventMapping = invalid
        m._client = invalid
        m._listenerUUID = invalid
        m._ANY = "any"
        m._SCORE_INTEREST = "K"
        m._CONTAINS = "contains"
        m._MATCHES = "matches"
        m._EMPTY = "empty"
        m._PRE_PREFIX = "pre_"
        m._PRE_ANY = "pre_any"
        m._PRE_CONTEXT = "pre_context"
        m._PRE_MOBILE = "pre_mobile"
        m._TAG_CONTENT_AREA = "contentarea"
        m._TAG_SELECTOR = "selector"
        m._TAG_WORDS = "words"
        m._TAG_EVENT = "event"
        m._TAG_CONTEXT_POSITION = "contextposition"
        m._TAG_CLICKAREA = "clickarea"
        m._TAG_VALUES = "values"
        m._TAG_SELECTEDOPTION = "selectedoption"
        m._TAG_CONTEXT = "context"
        m._TAG_REGEXP = "regexp"
        m._TAG_DATETIME = "datetime"
        m._TAG_DATE = "date"
        m._TAG_RULE_TYPE = "ruletype"
        m._TAG_ADD_SET = "addset"
        m._TAG_URL = "url"
        m._TAG_CONTAINS_MATCHES = "containsmatches"
        m._TAG_PROFILE_PROPERTY = "profileproperty"
        m._TAG_INTERESTS = "interests"
        m._TAG_POINTS = "points"
        m._RULETYPE_SCORE_CONTENT = "scorecontent"
        m._RULETYPE_SCORE_CLICK = "scoreclick"
        m._RULETYPE_SCORE_URL = "scoreurl"
        m._RULETYPE_SCORE_EVENT = "scoreevent"
        m._RULETYPE_SCORE_SOCIAL_EVENT = "scoresocialevent"
        m._RULETYPE_INTEREST_URL = "interesturl"
        m._RULETYPE_INTEREST_CLICK = "interestclick"
        m._RULETYPE_INTEREST_CONTENT = "interestcontent"
        m._RULETYPE_INTEREST_EVENT = "interestevent"
        m._RULETYPE_INTEREST_SOCIAL_EVENT = "interestsocialevent"
        m._MERGE_STRATEGY_ADD = "add"
        m._MERGE_STRATEGY_SET = "set"
        m._MERGE_STRATEGY_SET_IF_EMPTY = "set_if_empty"
        m._MERGE_STRATEGY_MERGE = "merge"
        m._client = client
        m._listenerUUID = listenerUUID
        m._eventMapping = {}
    end sub
    instance.handleEvent = sub(event as object)
    end sub
    ' Manages a map from class name of the event to rule.
    '
    ' @param eventName Classname of the event.
    ' @param rule The JSON Object representing the rule as defined in the listener.
    instance.addRuleToMap = sub(eventName as string, rule as object)
        if m._eventMapping = invalid or Type(m._eventMapping) <> "roAssociativeArray"
            m._eventMapping = {}
        end if
        if eventName = invalid or eventName = ""
            return
        end if
        rules = m._eventMapping[eventName]
        if rules <> invalid then
            rules.push(rule)
        else
            ruleList = []
            ruleList.push(rule)
            m._eventMapping[eventName] = ruleList
        end if
    end sub
    ' Subscribes this instance as an event handler for all relevant class names in the event mapping.
    ' This method should be called once all event rules have been registered and the component is
    ' ready to handle incoming events.
    instance.subscribeListeners = sub()
        if m._client = invalid
            BCLogWarning("Client is invalid, cannot subscribe listeners")
            return
        end if
        eventManager = m._client.eventManager()
        if eventManager = invalid
            BCLogWarning("Event manager is invalid, cannot subscribe listeners")
            return
        end if
        if m._eventMapping = invalid
            return
        end if
        for each className in m._eventMapping
            if className <> invalid and className <> ""
                eventManager.subscribe(className, m.handleEvent, false, m._listenerUUID)
            end if
        end for
    end sub
    ' Returns the applicable rules for an event.
    '
    ' @param event The event
    ' @return the applicable rules for the event, possibly invalid
    instance.getRules = function(event as object) as dynamic
        if event = invalid
            return invalid
        end if
        if not event.doesExist("name") or event.name = invalid
            return invalid
        end if
        eventClassName = event.name
        rules = m._eventMapping[eventClassName]
        if rules <> invalid then
            return rules
        else
            return invalid
        end if
    end function
    ' Registers an event in the event manager.
    '
    ' @param rule The JSON Object representing the rule as defined in the listener
    ' @param className Class name of the event
    instance.registerEvent = sub(rule as object, className as string)
        ' Add it to the rule map, the corresponding event handler will be registered later on
        m.addRuleToMap(className, rule)
    end sub
    ' Returns the selector based on a selector value in the form { name : 'name', selector : 'sel' }.
    '
    ' @param value the selector value.
    ' @return returns the selector
    instance._getSelector = function(value as object) as string
        selector = invalid
        if value = invalid then
            return ""
        end if
        selectorString = value.lookupCI(m._TAG_SELECTOR)
        if selectorString = invalid or selectorString = "" then
            return ""
        end if
        prefixIndex = selectorString.inStr(m._PRE_PREFIX)
        if prefixIndex = -1 then
            selector = selectorString
            return selector
        end if
        prefixLength = m._PRE_PREFIX.len()
        selectorSubstring = selectorString.mid(prefixLength)
        if selectorSubstring = "mobile" then
            selector = m._ANY
        else if selectorString = m._PRE_CONTEXT then
            selector = m._PRE_CONTEXT
        else
            BCLogWarning("Ignoring selector : '" + selectorString + "', not implemented.")
        end if
        if selector = invalid then
            return ""
        else
            return selector
        end if
    end function
    ' Retrieves the content based on the selector and context.
    '
    ' @param selector The selector to use for retrieving content
    ' @param context The context object containing additional information
    ' @param scene The current scene object, if available
    ' @return an array of content strings, possibly empty
    instance._getContent = function(selector as string, context as object, scene as dynamic) as object
        result = []
        if selector = m._PRE_CONTEXT then
            return context
        end if
        if selector = invalid or selector = "" or selector.inStr("jQuery(") > 0 then
            return result
        end if
        if scene <> invalid then
            if selector = m._ANY then
                allViews = m._getAllViewsOfScene(scene)
                for each view in allViews
                    content = m._getContentForView(view)
                    if content <> invalid and content <> "" then
                        m._addUniqueContent(content, result)
                    end if
                end for
            else
                view = m._getView(selector, scene)
                if view <> invalid then
                    content = m._getContentForView(view)
                    if content <> invalid and content <> "" then
                        m._addUniqueContent(content, result)
                    end if
                end if
            end if
        end if
        return result
    end function
    ' Helper function to get all views from a scene
    '
    ' @param scene The scene object to traverse
    ' @return an array of all views in the scene
    instance._getAllViewsOfScene = function(scene as object) as object
        allViews = []
        if scene <> invalid then
            m._collectAllNodesRecursive(scene, allViews)
        end if
        return allViews
    end function
    ' Helper function to get a specific view by selector
    '
    ' @param selector The selector to find the view
    ' @param scene The scene object to search in
    ' @return the view object if found, otherwise invalid
    instance._getView = function(selector as string, scene as object) as object
        if scene = invalid then
            return invalid
        end if
        foundNode = scene.findNode(selector)
        if foundNode <> invalid then
            return foundNode
        end if
        allViews = m._getAllViewsOfScene(scene)
        for each view in allViews
            if view.hasField("id") and view.id = selector then
                return view
            end if
            if view.subtype() = selector then
                return view
            end if
        end for
        return invalid
    end function
    ' Helper function to recursively collect all nodes in a scene
    '
    ' @param node The current node to process
    ' @param allViews The array to collect nodes into (passed by reference)
    instance._collectAllNodesRecursive = sub(node as object, allViews as object)
        if node = invalid or allViews = invalid
            return
        end if
        allViews.push(node)
        if node.getChildCount() > 0 then
            for i = 0 to node.getChildCount() - 1
                child = node.getChild(i)
                m._collectAllNodesRecursive(child, allViews)
            end for
        end if
    end sub
    ' Helper function to get content from a view
    '
    ' @param view The view object from which to extract content
    ' @return The text content of the view, or an empty string if not found
    instance._getContentForView = function(view as object) as string
        if view <> invalid then
            if view.hasField("text") then
                return view.text
            else if view.hasField("title") then
                return view.title
            else if view.hasField("content") then
                return view.content
            else if view.hasField("description") then
                return view.description
            end if
        end if
        return ""
    end function
    ' Checks if the content contains any of the words defined in the rule.
    '
    ' @param rule The rule to check against
    ' @param contentList The list of content to check
    ' @param words The list of words to check for
    ' @return true if any of the words are found in the content, false otherwise
    instance._contentContainsWord = function(rule as object, contentList as object, words as object) as boolean
        matchingType = rule.lookupCI(m._TAG_CONTAINS_MATCHES)
        if matchingType = invalid or matchingType = "" then
            matchingType = m._CONTAINS
        end if
        content = ""
        for each str in contentList
            if str <> invalid and Type(str) = "roString"
                content += " " + LCase(str)
            end if
        end for
        ruleType = rule.lookupCI(m._TAG_RULE_TYPE)
        if matchingType = m._EMPTY and content.trim() = "" then
            return true
        end if
        for each wordEntry in words
            word = wordEntry
            word = LCase(word).trim()
            if word = m._PRE_ANY then
                BCLogInfo("Found any word")
                return true
            else if ruleType = m._RULETYPE_SCORE_URL or ruleType = m._RULETYPE_INTEREST_URL then
                if matchingType = m._CONTAINS then
                    if content.inStr(word) > 0 then
                        return true
                    end if
                else
                    for each contentItem in contentList
                        if LCase(contentItem) = word then
                            return true
                        end if
                    end for
                end if
            else if matchingType = m._CONTAINS and content.inStr(word) > 0 then
                BCLogInfo("Found matching word : " + word)
                return true
            else if matchingType = m._MATCHES then
                for each contentItem in contentList
                    if LCase(contentItem) = word then
                        BCLogInfo("Found exactly matching word " + word)
                        return true
                    end if
                end for
            end if
        end for
        return false
    end function
    ' Returns a list of strings from a JSON array.
    '
    ' @param jsonArray The JSON array to convert
    ' @return an array of strings, possibly empty
    instance._getStringList = function(jsonArray as object) as object
        result = []
        if jsonArray = invalid then
            return result
        end if
        arrayType = Type(jsonArray)
        if arrayType = "roArray" then
            if jsonArray.count() = 0 then
                return result
            end if
            for each item in jsonArray
                if item <> invalid then
                    if Type(item) = "roString" then
                        result.push(item)
                    else
                        result.push(item.toStr())
                    end if
                end if
            end for
        else if arrayType = "roAssociativeArray" then
            BCLogWarning("Received associative array instead of indexed array, processing values")
            for each key in jsonArray
                item = jsonArray[key]
                if item <> invalid then
                    if Type(item) = "roString" then
                        result.push(item)
                    else
                        result.push(item.toStr())
                    end if
                end if
            end for
        else
            BCLogWarning("Expected roArray but received: " + arrayType)
            return result
        end if
        return result
    end function
    ' Returns the current time as a string.
    '
    ' @return the current time as a string
    instance._getCurrentTime = function() as string
        return CreateObject("roDateTime").asSecondsLong().toStr()
    end function
    ' Returns the current time in milliseconds.
    '
    ' @return the current time in milliseconds
    instance._getCurrentTimeMillis = function() as longinteger
        return CreateObject("roDateTime").asSecondsLong() * 1000
    end function
    ' Returns the current date as a string in the format "MM/DD/YYYY".
    '
    ' @return the current date as a string
    instance._getCurrentDate = function() as string
        dateTime = CreateObject("roDateTime")
        return dateTime.asDateString("short-date")
    end function
    ' Returns the profile property from the rule.
    '
    ' @param rule The rule object containing the profile property information.
    ' @return the profile property as a string, or an empty string if not found
    instance._getProfileProperty = function(rule as object) as string
        if rule = invalid or not rule.doesExist(m._TAG_PROFILE_PROPERTY)
            return ""
        end if
        profilePropertyArray = rule.lookupCI(m._TAG_PROFILE_PROPERTY)
        if profilePropertyArray = invalid or Type(profilePropertyArray) <> "roArray" or profilePropertyArray.count() = 0
            return ""
        end if
        profilePropertyObject = profilePropertyArray[0]
        if profilePropertyObject = invalid or not profilePropertyObject.doesExist(m._TAG_PROFILE_PROPERTY)
            return ""
        end if
        propertyValue = profilePropertyObject.lookupCI(m._TAG_PROFILE_PROPERTY)
        if propertyValue = invalid
            return ""
        end if
        return propertyValue
    end function
    ' Returns the merge strategy for the rule.
    '
    ' @param rule The rule object containing the merge strategy information.
    ' @return The merge strategy as a string, defaulting to "add".
    instance._getMergeStrategy = function(rule as object) as string
        strategy = rule.lookupCI(m._TAG_ADD_SET)
        if strategy = invalid then
            return m._MERGE_STRATEGY_ADD
        end if
        return strategy
    end function
    ' Helper function to add content to result array only if it's not already present
    '
    ' @param content The content to add
    ' @param result The result array to add to
    instance._addUniqueContent = sub(content as string, result as object)
        found = false
        for each existingContent in result
            if existingContent = content then
                found = true
                exit for
            end if
        end for
        if not found then
            result.push(content)
        end if
    end sub
    return instance
end function
function BCEventServiceBase(client as object, listenerUUID as string)
    instance = __BCEventServiceBase_builder()
    instance.new(client, listenerUUID)
    return instance
end function