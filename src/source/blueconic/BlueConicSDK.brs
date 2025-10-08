' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
'import "pkg:/source/blueconic/storage/BCStorageManager.bs"
'import "pkg:/source/blueconic/storage/BCCache.bs"
'import "pkg:/source/blueconic/connection/BCNetworkManager.bs"
'import "pkg:/source/blueconic/connection/BCRequest.bs"
'import "pkg:/source/blueconic/connection/BCResponse.bs"
'import "pkg:/source/blueconic/connection/BCCommitLog.bs"
'import "pkg:/source/blueconic/profile/BCProfile.bs"
'import "pkg:/source/blueconic/events/BCEventManager.bs"
'import "pkg:/source/blueconic/plugins/BCPluginsManager.bs"
'import "pkg:/source/blueconic/plugins/BCGlobalListener.bs"
'import "pkg:/source/blueconic/plugins/BCPreferredHourListener.bs"
'import "pkg:/source/blueconic/plugins/BCVisitListener.bs"
'import "pkg:/source/blueconic/plugins/BCPropertiesBasedDialogue.bs"
'import "pkg:/source/blueconic/plugins/service/BCEventServiceBase.bs"
'import "pkg:/source/blueconic/plugins/BCEngagementScoreListener.bs"
'import "pkg:/source/blueconic/plugins/service/BCEngagementService.bs"
'import "pkg:/source/blueconic/plugins/BCBehaviorListener.bs"
'import "pkg:/source/blueconic/plugins/service/BCEnrichByBehaviorService.bs"
'import "pkg:/source/blueconic/plugins/BCEngagementRankingListener.bs"
'import "pkg:/source/blueconic/plugins/BCRecommendationsDialogue.bs"
'import "pkg:/source/blueconic/util/BCLogger.bs"

' BCConstants is a function that returns an object containing constants used throughout the BlueConic SDK.
'
' @return An object containing SDK version, user agent, storage keys, events, and parameters.
function BCConstants() as object
    SDK_VERSION = "1.1.0"
    SDK_DATA = {
        SDK_VERSION: SDK_VERSION
        USER_AGENT: "BlueConic Roku SDK " + SDK_VERSION
    }
    STORAGE = {
        CACHE: "BC.Cache"
        COOKIES: "BC.Cookies"
        BC_PROFILE_ID_NAME: "BCProfileID"
        BC_SESSION_COOKIE_NAME: "BCSessionID"
        BC_DOMAIN_GROUP_NAME: "BCDomainGroup"
        BC_PROFILE_PROPERTIES_NAME: "BCProfileProperties"
        BC_PROFILE_PROPERTIES_LABELS_NAME: "BCProfilePropertiesLabels"
    }
    EVENTS = {
        PAGEVIEW: "PAGEVIEW"
        VIEW: "VIEW"
        CONVERSION: "CONVERSION"
        CLICK: "CLICK"
    }
    PARAMETERS = {
        INITIALIZATION_PAGEVIEW: "INITIALIZE"
    }
    return {
        SDK_DATA: SDK_DATA
        STORAGE: STORAGE
        EVENTS: EVENTS
        PARAMETERS: PARAMETERS
    }
end function
' Configuration class for BlueConic SDK. 
function __BlueConicConfiguration_builder()
    instance = {}
    ' Constructor.
    '
    ' @param hostName The hostname for the BlueConic server.
    ' @param appID The application ID for the BlueConic client.
    ' @param isDebugMode Boolean indicating if the SDK is in debug mode.
    ' @param simulatorUsername Optional username for the simulator.
    ' @param simulatorSessionId Optional session ID for the simulator.
    instance.new = function(hostName as string, appID = "" as string, isDebugMode = false as boolean, simulatorUsername = "" as string, simulatorSessionId = "" as string)
        m.hostName = invalid
        m.appID = invalid
        m.isDebugMode = invalid
        m.simulatorUsername = invalid
        m.simulatorSessionId = invalid
        m.hostName = hostName
        m.appID = appID
        m.isDebugMode = isDebugMode
        m.simulatorUsername = simulatorUsername
        m.simulatorSessionId = simulatorSessionId
    end function
    return instance
end function
function BlueConicConfiguration(hostName as string, appID = "" as string, isDebugMode = false as boolean, simulatorUsername = "" as string, simulatorSessionId = "" as string)
    instance = __BlueConicConfiguration_builder()
    instance.new(hostName, appID, isDebugMode, simulatorUsername, simulatorSessionId)
    return instance
end function
' Builder class for BlueConicConfiguration.
function __BlueConicConfigurationBuilder_builder()
    instance = {}
    ' Constructor
    instance.new = function()
        m._hostName = invalid
        m._appID = invalid
        m._isDebugMode = invalid
        m._simulatorUsername = invalid
        m._simulatorSessionId = invalid
        m._hostName = ""
        m._appID = ""
        m._isDebugMode = false
        m._simulatorUsername = ""
        m._simulatorSessionId = ""
    end function
    ' Method to set host name
    '
    ' @param hostName The hostname for the BlueConic server.
    ' @return The builder object for method chaining.
    instance.setHostName = function(hostName as string) as object
        m._hostName = hostName
        return m
    end function
    ' Method to set override app ID
    '
    ' @param appID The application ID for the BlueConic client.
    ' @return The builder object for method chaining.
    instance.setOverrideAppId = function(appID as string) as object
        m._appID = appID
        return m
    end function
    ' Method to set debug mode
    '
    ' @param isDebugMode Boolean indicating if the SDK is in debug mode.
    ' @return The builder object for method chaining.
    instance.setDebugMode = function(isDebugMode as boolean) as object
        m._isDebugMode = isDebugMode
        return m
    end function
    ' Method to set simulator data
    '
    ' @param simulatorUsername Optional username for the simulator.
    ' @param simulatorSessionId Optional session ID for the simulator.
    ' @return The builder object for method chaining.
    instance.setSimulatorData = function(simulatorUsername as string, simulatorSessionId as string) as object
        m._simulatorUsername = simulatorUsername
        m._simulatorSessionId = simulatorSessionId
        return m
    end function
    ' Method to build BlueConicConfiguration
    '
    ' @param globalNode The global node to which the configuration will be added.
    instance.build = sub(globalNode as object)
        configuration = BlueConicConfiguration(m._hostName, m._appID, m._isDebugMode, m._simulatorUsername, m._simulatorSessionId)
        globalNode.addFields({
            blueConicConfiguration: configuration
        })
    end sub
    return instance
end function
function BlueConicConfigurationBuilder()
    instance = __BlueConicConfigurationBuilder_builder()
    instance.new()
    return instance
end function
' BlueConicClientImpl is the main class for interacting with the BlueConic SDK.
function __BlueConicClientImpl_builder()
    instance = {}
    ' Constructor.
    '
    ' @param task The task object that will manage the BlueConic client lifecycle.
    instance.new = function(task as object)
        m.blueConicTask = invalid
        m._configuration = invalid
        m._hostname = invalid
        m._appId = invalid
        m._enabled = false
        m._screenName = invalid
        m._storageManager = invalid
        m._rpcConnector = invalid
        m._restConnector = invalid
        m._constants = invalid
        m._commitLog = invalid
        m._requestLog = invalid
        m._profile = invalid
        m._eventManager = invalid
        m._pluginsManager = invalid
        m._locale = invalid
        m._isFlushing = invalid
        m._flushTimer = invalid
        m._simulatorData = {}
        m._segments = []
        m._zoneId = invalid
        m.blueConicTask = task
    end function
    ' Initializes the BlueConic client with the provided configuration and global node.
    '
    ' @param configuration The configuration object containing the hostname, app ID, and debug mode.
    ' @param globalNode The global node to which the BlueConic client will be attached.
    instance.initialize = sub(configuration as object, globalNode as object)
        if m.isEnabled()
            BCLogWarning("BlueConic client is already enabled.")
            return
        end if
        m._configuration = configuration
        if configuration.isDebugMode
            BCLogInfo("BlueConic SDK is in debug mode.")
        end if
        if configuration.appID = ""
            appInfo = CreateObject("roAppInfo")
            m._appId = appInfo.getId()
        else
            m._appId = configuration.appID
        end if
        if configuration.hostName = ""
            BCLogError("Unable to use BlueConic client. Make sure the hostname is set.")
            return
        end if
        m._hostname = configuration.hostname
        m._storageManager = BCStorageManager()
        m._rpcConnector = BCRPCConnector()
        m._restConnector = BCRESTConnector()
        m._constants = BCConstants()
        m._screenName = ""
        m._commitLog = BCCommitLog()
        m._requestLog = BCCommitLog()
        m._profile = BCProfile(m)
        m._eventManager = BCEventManager(m)
        m._pluginsManager = BCPluginsManager()
        deviceInfo = CreateObject("roDeviceInfo")
        m._locale = deviceInfo.GetCurrentLocale()
        m.setEnabled(true)
        ' INITIALZIE Page View event should only be sent once per application lifecycle
        if globalNode.isBlueConicSDKInitialized = false or globalNode.isBlueConicSDKInitialized = invalid
            m.createPageViewEvent(BCConstants().PARAMETERS.INITIALIZATION_PAGEVIEW, {
                "isCTVSDKInit": true
            })
            globalNode.addFields({
                isBlueConicSDKInitialized: true
            })
        end if
        BCLogVerbose("Created new BlueConic client")
        BCLogVerbose("BlueConic client is enabled")
        if configuration.simulatorUsername <> "" and configuration.simulatorSessionId <> ""
            m.setSimulatorData(configuration.simulatorUsername, configuration.simulatorSessionId)
        end if
    end sub
    ' Returns the current screen name.
    '
    ' @return The current screen name as a string.
    instance.getScreenName = function() as string
        return m._screenName
    end function
    ' Sets the screen name for the BlueConic client.
    '
    ' @param screenName The screen name to set.
    instance.setScreenName = function(screenName as string)
        m._screenName = screenName
    end function
    ' Returns if the BlueConic client is enabled.
    '
    ' @return True if the client is enabled, false otherwise.
    instance.isEnabled = function() as boolean
        return m._enabled
    end function
    ' Sets the enabled state of the BlueConic client.
    '
    ' @param enabled Boolean indicating whether the client should be enabled or disabled.
    instance.setEnabled = function(enabled as boolean)
        m._enabled = enabled
    end function
    ' Returns the segments associated with the BlueConic client.
    '
    ' @return An array of segments, each represented as an associative array with 'id' and 'name' keys.
    instance.getSegments = function() as object
        return m._segments
    end function
    ' Sets the segments for the BlueConic client.
    '
    ' @param segments An array of segments, each represented as an associative array with 'id' and 'name' keys.
    instance.setSegments = sub(segments as object)
        m._segments = []
        if Type(segments) = "roArray"
            for each segment in segments
                if not segment.doesExist("id") or not segment.doesExist("name")
                    BCLogError("Each segment must be an associative array with 'id' and 'name' keys.")
                    continue for
                end if
                m._segments.push({
                    id: segment["id"]
                    name: segment["name"]
                })
            end for
        else
            BCLogError("Segments must be provided as an array of BCSegment objects.")
        end if
    end sub
    ' Checks if a segment with the given ID exists in the BlueConic client.
    '
    ' @param segmentId The ID of the segment to check.
    ' @return True if the segment exists, false otherwise.
    instance.hasSegment = function(segmentId as string) as boolean
        for each segment in m._segments
            if segment.id = segmentId
                return true
            end if
        end for
        return false
    end function
    ' Sets the zone ID for the BlueConic client.
    '
    ' @param zoneId The zone ID to set. Can be a string or invalid.
    instance.setZoneId = function(zoneId as dynamic)
        m._zoneId = zoneId
    end function
    ' Returns the profile object associated with the BlueConic client.
    instance.profile = function() as object
        return m._profile
    end function
    ' Clears the profile ID from the BlueConic client locally (cache). A new profile ID will be generated.
    instance.createProfile = sub()
        if not m._enabled
            BCLogError("BlueConic client is not enabled. Cannot create profile.")
            return
        end if
        m._profile.clearProfileId()
        m._profile._reloadProfile()
    end sub
    ' Removes the profile from the BlueConic servers. The profile ID will be removed from the BlueConic client. A new profile ID will be generated.
    instance.deleteProfile = sub()
        if not m._enabled
            BCLogError("BlueConic client is not enabled. Cannot delete profile.")
            return
        end if
        m._profile._deleteProfile()
    end sub
    ' Updates the profile with the current data in the commit log.
    instance.updateProfile = sub()
        if not m._enabled
            BCLogError("BlueConic client is not enabled. Cannot update profile.")
            return
        end if
        m.sendUpdates()
    end sub
    ' Sets the locale for the BlueConic client.
    instance.setLocale = function(locale as string)
        m._locale = locale
    end function
    ' Returns the event manager for the BlueConic client.
    instance.eventManager = function() as object
        return m._eventManager
    end function
    ' Registers an event of the specified type with the given properties.
    '
    ' @param eventType The type of the event (e.g., PAGEVIEW, VIEW, CONVERSION, CLICK).
    ' @param properties An associative array containing properties related to the event.
    instance.createEvent = sub(eventType as string, properties as object)
        if not m._enabled
            BCLogError("BlueConic client is not enabled. Cannot create event.")
            return
        end if
        if eventType = m._constants.EVENTS.VIEW or eventType = m._constants.EVENTS.CONVERSION or eventType = m._constants.EVENTS.CLICK
            interactionId = ""
            if Type(properties["interactionId"]) = "String"
                interactionId = properties["interactionId"]
            end if
            m._commitLog.createEvent(eventType, interactionId)
            m.sendUpdates()
        else if eventType = m._constants.EVENTS.PAGEVIEW
            m.destroyPlugins()
            screenNameFromProperties = m._getScreenNameFromProperties(properties)
            if screenNameFromProperties <> ""
                m._screenName = screenNameFromProperties
            end if
            interactions = m._getInteractions(eventType, m._screenName, properties)
            m._pluginsManager.initialize(interactions)
            m.eventManager().handleAllEvents()
        end if
    end sub
    ' Creates a page view event with the specified screen name and properties.
    '
    ' @param screenName The name of the screen being viewed.
    ' @param properties An associative array containing properties related to the page view event.
    instance.createPageViewEvent = sub(screenName as string, properties as object)
        properties["screenName"] = screenName
        m.createEvent(BCConstants().EVENTS.PAGEVIEW, properties)
    end sub
    ' Creates a view event with the specified interaction ID and properties.
    '
    ' @param interactionId The ID of the interaction associated with the view event.
    ' @param properties An associative array containing properties related to the view event.
    instance.createViewEvent = sub(interactionId as string, properties as object)
        properties["interactionId"] = interactionId
        m.createEvent(BCConstants().EVENTS.VIEW, properties)
    end sub
    ' Creates a conversion event with the specified interaction ID and properties.
    '
    ' @param interactionId The ID of the interaction associated with the conversion event.
    ' @param properties An associative array containing properties related to the conversion event.
    instance.createConversionEvent = sub(interactionId as string, properties as object)
        properties["interactionId"] = interactionId
        m.createEvent(BCConstants().EVENTS.CONVERSION, properties)
    end sub
    ' Creates a click event with the specified interaction ID and properties.
    '
    ' @param interactionId The ID of the interaction associated with the click event.
    ' @param properties An associative array containing properties related to the click event.
    instance.createClickEvent = sub(interactionId as string, properties as object)
        properties["interactionId"] = interactionId
        m.createEvent(BCConstants().EVENTS.CLICK, properties)
    end sub
    ' Creates a timeline event with the specified event type, date, and properties.
    '
    ' @param eventType The type of the timeline event.
    ' @param eventDate The date of the timeline event in ISO format.
    ' @param properties An associative array containing properties related to the timeline event.
    instance.createTimelineEvent = sub(eventType as string, eventDate as string, properties as object)
        m.createTimelineEventById("", eventType, eventDate, properties)
    end sub
    ' Creates a timeline event with the specified event ID, type, date, and properties.
    '
    ' @param eventId The ID of the timeline event (optional).
    ' @param eventType The type of the timeline event.
    ' @param eventDate The date of the timeline event in ISO format.
    ' @param properties An associative array containing properties related to the timeline event.
    instance.createTimelineEventById = sub(eventId as string, eventType as string, eventDate as string, properties as object)
        if not m._enabled
            BCLogError("BlueConic client is not enabled. Cannot create timeline event.")
            return
        end if
        if eventType = ""
            BCLogError("Timeline event type is empty. In order to send a timeline event, a type is required.")
            return
        end if
        parameters = {
            profile: m._profile.getId()
            data: properties
            timestamp: eventDate
        }
        if eventId <> ""
            parameters["eventId"] = eventId
        end if
        m._commitLog.createTimelineEvent(eventType, parameters)
        m.sendUpdates()
    end sub
    instance.createRecommendationsEvent = sub(storeId as string, action as string, itemIds as object)
        if storeId = ""
            BCLogError("Store ID is empty. In order to send a recommendation event, a store ID is required.")
            return
        end if
        parameters = {
            profileId: m._profile.getId()
            storeId: storeId
            action: action
            itemId: itemIds
        }
        conCommands = BCRestConnectorCommands()
        createRecommendationsEventCommand = conCommands.createRecommendationsEventCommand(parameters)
        response = m._restConnector.execute(m._hostname, m._zoneId, createRecommendationsEventCommand)
        BCLogInfo("Create recommendation event response: " + response)
    end sub
    ' Sets the simulator data for the BlueConic client.
    '
    ' @param simulatorUsername The username for the simulator.
    ' @param simulatorSessionId The session ID for the simulator.
    instance.setSimulatorData = sub(simulatorUsername as string, simulatorSessionId as string)
        m._simulatorData = {
            simulatorUserName: simulatorUsername
            simulatorSessionId: simulatorSessionId
        }
    end sub
    ' Destroys all plugins associated with the BlueConic client.
    instance.destroyPlugins = sub()
        if not m._enabled
            BCLogError("BlueConic client is not enabled. Cannot destroy plugins.")
            return
        end if
        m._pluginsManager.destroyPlugins()
    end sub
    ' Schedules a timer to send updates after a delay.
    instance.scheduleSendUpdates = sub()
        ' Check if a timer is already scheduled
        if m._isFlushing = true
            return
        end if
        ' Mark flushing as active
        m._isFlushing = true
        ' Create the Timer node
        m._flushTimer = CreateObject("roSGNode", "Timer")
        m._flushTimer.control = "start"
        m._flushTimer.duration = 5
        ' Observe the "fire" event to send updates
        m._flushTimer.observeField("fire", "onFlushUpdates")
        m.blueConicTask.appendChild(m._flushTimer)
    end sub
    ' Sends updates to the BlueConic server based on the current commit log and request log.
    instance.sendUpdates = sub()
        reload = false
        conCommands = BCRPCConnectorCommands()
        commands = []
        m.eventManager().clearEvents()
        m._requestLog.mergeCommitLog(m._commitLog)
        toAdd = m._requestLog.getPropertiesByType("ADD")
        if toAdd.count() > 0
            toAddCommand = conCommands.getAddPropertiesCommand(toAdd)
            commands.push(toAddCommand)
        end if
        toSet = m._requestLog.getPropertiesByType("SET")
        if toSet.count() > 0
            toSetCommand = conCommands.getSetPropertiesCommand(toSet)
            commands.push(toSetCommand)
        end if
        toIncrement = m._requestLog.getPropertiesByType("INCREMENT")
        if toIncrement.count() > 0
            toIncrementCommand = conCommands.getIncrementPropertiesCommand(toIncrement)
            commands.push(toIncrementCommand)
        end if
        toEvents = m._requestLog.getEvents()
        for each event in toEvents
            getInteractionsCommand = conCommands.getCreateEventCommand(event.getType(), event.getId())
            commands.push(getInteractionsCommand)
        end for
        toTimelineEvents = m._requestLog.getTimelineEvents()
        for each event in toTimelineEvents
            getInteractionsCommand = conCommands.getTimelineCommand(event.getType(), event.getProperties())
            commands.push(getInteractionsCommand)
        end for
        getProfileCommand = conCommands.getProfileCommand()
        commands.push(getProfileCommand)
        hash = m._profile.cache.getHash()
        propertiesIds = m._profile.cache.getPropertiesIds()
        getPropertiesCommand = conCommands.getGetPropertiesCommand(hash, propertiesIds)
        commands.push(getPropertiesCommand)
        responses = m._rpcConnector.execute(m._appId, m._hostname, m._zoneId, commands, m._profile.getDomainGroup(), m._simulatorData, m.getScreenName())
        responseParserObj = BCResponseParser()
        reload = responseParserObj.handleGetProfileResponse(responses.getById(getProfileCommand.id), m)
        responseParserObj.handleGetPropertiesResponse(responses.getById(getPropertiesCommand.id), m._profile)
        m._requestLog.clearAll()
        if reload
            m._profile._reloadProfile()
        end if
    end sub
    ' Retrieves interactions from the BlueConic server based on the event type and properties.
    '
    ' @param eventType The type of the event (e.g., PAGEVIEW, VIEW, CONVERSION, CLICK).
    ' @param screenName The name of the screen associated with the event.
    ' @param properties An associative array containing properties related to the event.
    ' @return An object containing interactions retrieved from the server.
    instance._getInteractions = function(eventType as string, screenName as string, properties as object) as object
        reload = false
        isPageview = eventType = BCConstants().EVENTS.PAGEVIEW
        conCommands = BCRPCConnectorCommands()
        commands = []
        getProfileCommand = invalid
        getPropertiesCommand = invalid
        getInteractionsCommand = conCommands.getInteractionsCommand(eventType, properties)
        if isPageview
            hash = m._profile.cache.getHash()
            propertiesIds = m._profile.cache.getPropertiesIds()
            getProfileCommand = conCommands.getProfileCommand()
            commands.push(getProfileCommand)
            getPropertiesCommand = conCommands.getGetPropertiesCommand(hash, propertiesIds)
            commands.push(getPropertiesCommand)
        end if
        commands.push(getInteractionsCommand)
        responses = m._rpcConnector.execute(m._appId, m._hostname, m._zoneId, commands, "DEFAULT", m._simulatorData, screenName)
        responseParserObj = BCResponseParser()
        if isPageview and getProfileCommand <> invalid and getPropertiesCommand <> invalid
            reload = responseParserObj.handleGetProfileResponse(responses.getById(getProfileCommand.id), m)
            responseParserObj.handleGetPropertiesResponse(responses.getById(getPropertiesCommand.id), m._profile)
        end if
        interactions = responseParserObj.handleGetInteractionsResponse(responses.getById(getInteractionsCommand.id), m)
        if isPageview
            m._requestLog.clearAll()
            if reload
                m._profile._reloadProfile()
            end if
        end if
        return interactions
    end function
    ' Retrieves the screen name from the provided properties.
    '
    ' @param properties An associative array containing properties related to the event.
    ' @return The screen name as a string, or an empty string if not found.
    instance._getScreenNameFromProperties = function(properties as object) as string
        screenName = ""
        location = ""
        if properties.doesExist("screenName") and (Type(properties["screenName"]) = "String" or Type(properties["screenName"]) = "roString")
            screenName = properties["screenName"]
        end if
        if properties.doesExist("location") and (Type(properties["location"]) = "String" or Type(properties["screenName"]) = "roString")
            location = properties["location"]
        end if
        if screenName = "" then
            overrule = location
        else
            overrule = screenName
        end if
        if overrule <> ""
            if overrule.Left(1) = "/"
                return overrule.Mid(1)
            else
                return overrule
            end if
        end if
        return ""
    end function
    instance._getRecommendations = function(requestParameters as object) as string
        conCommands = BCRestConnectorCommands()
        getRecommendationsCommand = conCommands.getRecommendationsCommand(requestParameters)
        response = m._restConnector.execute(m._hostname, m._zoneId, getRecommendationsCommand)
        return response
    end function
    return instance
end function
function BlueConicClientImpl(task as object)
    instance = __BlueConicClientImpl_builder()
    instance.new(task)
    return instance
end function