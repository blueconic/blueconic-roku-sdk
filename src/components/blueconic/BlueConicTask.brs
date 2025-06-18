' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' BlueConicTask is a task that initializes the BlueConic SDK and listens for messages to handle requests.

' Initializes the task and sets up the message port for communication.
sub init()
    m.port = createObject("roMessagePort")
    m.top.observeField("flushUpdates", m.port)
    m.top.observeFieldScoped("request", m.port)
    m.top.functionName = "execute"
    m.top.control = "RUN"
end sub

' Executes the task by setting up the BlueConic SDK and starting the listener for incoming messages.
sub execute()
    setupTask()
    startListener()
end sub

' Sets up the BlueConic SDK by retrieving the configuration and initializing the client.
sub setupTask()
    configuration = m.global.blueConicConfiguration
    if configuration = invalid then
        print "[BlueConic] ❌ >> BlueConicTask: No configuration found. SDK will not be initialized. Make sure to set the SDK configuration for the GlobalNode at application start."
        return
    end if
    m.blueConicClient = BlueConicClientImpl(m.top)
    m.blueConicClient.initialize(configuration, m.global)
    m.taskCheckInterval = 250
end sub

' Starts the listener that waits for messages on the message port and handles them accordingly.
sub startListener()
    if m.blueConicClient = invalid then
        return
    end if
    while (true)
        message = wait(m.taskCheckInterval, m.port)
        if message <> invalid
            messageType = type(message)
            if messageType = "roSGNodeEvent" then
                field = message.getField()
                if field = "flushUpdates" then
                    m.blueConicClient._isFlushing = false
                    m.blueConicClient.sendUpdates()
                    m.top.removeChild(m.blueConicClient._flushTimer)
                    m.blueConicClient._flushTimer = invalid
                else if field = "request" then
                    handleRequest(message.getData())
                end if
            end if
        end if
    end while
end sub

' This is triggered by the batching timer in the SDK
sub onFlushUpdates()
    ' Notify task that it can send updates
    m.top.flushUpdates = true
end sub

' Handles incoming requests by checking the request type and calling the appropriate method on the BlueConic SDK.
'
' @param request The request object containing the request type and any additional data needed for processing.
sub handleRequest(request as object)
    if request = invalid or request.requestType = invalid then
        return
    end if
    responseData = {
        requestId: request.requestId
    }
    if request.requestType = "isEnabled"
        isEnabled = m.blueConicClient.isEnabled()
        responseData.isEnabled = isEnabled
        responseData.success = true
    else if request.requestType = "createEvent"
        m.blueConicClient.createEvent(request.eventType, request.properties)
        responseData.success = true
    else if request.requestType = "createPageViewEvent"
        m.blueConicClient.createPageViewEvent(request.screenName, request.properties)
        responseData.success = true
    else if request.requestType = "createViewEvent"
        m.blueConicClient.createViewEvent(request.interactionId, request.properties)
        responseData.success = true
    else if request.requestType = "createConversionEvent"
        m.blueConicClient.createConversionEvent(request.interactionId, request.properties)
        responseData.success = true
    else if request.requestType = "createClickEvent"
        m.blueConicClient.createClickEvent(request.interactionId, request.properties)
        responseData.success = true
    else if request.requestType = "createTimelineEvent"
        m.blueConicClient.createTimelineEvent(request.eventType, request.eventDate, request.properties)
        responseData.success = true
    else if request.requestType = "createTimelineEventById"
        m.blueConicClient.createTimelineEventById(request.eventId, request.eventType, request.eventDate, request.properties)
        responseData.success = true
    else if request.requestType = "getId"
        profileId = m.blueConicClient.profile().getId()
        responseData.profileId = profileId
        responseData.success = true
    else if request.requestType = "getPrivacyLegislation"
        privacyLegislation = m.blueConicClient.profile().getPrivacyLegislation()
        responseData.privacyLegislation = privacyLegislation
        responseData.success = true
    else if request.requestType = "setPrivacyLegislation"
        m.blueConicClient.profile().setPrivacyLegislation(request.privacyLegislation)
        responseData.success = true
    else if request.requestType = "getConsentedObjectives"
        consentedObjectives = m.blueConicClient.profile().getConsentedObjectives()
        responseData.consentedObjectives = consentedObjectives
        responseData.success = true
    else if request.requestType = "setConsentedObjectives"
        m.blueConicClient.profile().setConsentedObjectives(request.consentedObjectives)
        responseData.success = true
    else if request.requestType = "addConsentedObjective"
        m.blueConicClient.profile().addConsentedObjective(request.consentedObjective)
        responseData.success = true
    else if request.requestType = "getRefusedObjectives"
        refusedObjectives = m.blueConicClient.profile().getRefusedObjectives()
        responseData.refusedObjectives = refusedObjectives
        responseData.success = true
    else if request.requestType = "setRefusedObjectives"
        m.blueConicClient.profile().setRefusedObjectives(request.refusedObjectives)
        responseData.success = true
    else if request.requestType = "addRefusedObjective"
        m.blueConicClient.profile().addRefusedObjective(request.refusedObjective)
        responseData.success = true
    else if request.requestType = "getValue"
        value = m.blueConicClient.profile().getValue(request.property)
        responseData.value = value
        responseData.success = true
    else if request.requestType = "getValues"
        values = m.blueConicClient.profile().getValues(request.property)
        responseData.values = values
        responseData.success = true
    else if request.requestType = "getAllProperties"
        allProperties = m.blueConicClient.profile().getAllProperties()
        responseData.properties = allProperties
        responseData.success = true
    else if request.requestType = "addValue"
        m.blueConicClient.profile().addValue(request.property, request.value)
        responseData.success = true
    else if request.requestType = "addValues"
        m.blueConicClient.profile().addValues(request.property, request.values)
        responseData.success = true
    else if request.requestType = "setValue"
        m.blueConicClient.profile().setValue(request.property, request.value)
        responseData.success = true
    else if request.requestType = "setValues"
        m.blueConicClient.profile().setValues(request.property, request.values)
        responseData.success = true
    else if request.requestType = "incrementValue"
        m.blueConicClient.profile().incrementValue(request.property, request.value)
        responseData.success = true
    else if request.requestType = "getScreenName"
        screenName = m.blueConicClient.getScreenName()
        responseData.screenName = screenName
        responseData.success = true
    else if request.requestType = "getSegments"
        segments = m.blueConicClient.getSegments()
        responseData.segments = segments
        responseData.success = true
    else if request.requestType = "isEnabled"
        isEnabled = m.blueConicClient.isEnabled()
        responseData.isEnabled = isEnabled
        responseData.success = true
    else if request.requestType = "createProfile"
        m.blueConicClient.createProfile()
        responseData.success = true
    else if request.requestType = "deleteProfile"
        m.blueConicClient.deleteProfile()
        responseData.success = true
    else if request.requestType = "updateProfile"
        m.blueConicClient.updateProfile()
        responseData.success = true
    else if request.requestType = "publishAdvancedEvent"
        m.blueConicClient.eventManager().publishAdvancedEvent(request.eventName, request.context)
        responseData.success = true
    else if request.requestType = "publishClickEvent"
        m.blueConicClient.eventManager().publishAdvancedEvent(request.selector, request.context)
        responseData.success = true
    else if request.requestType = "publishUpdateContentEvent"
        m.blueConicClient.eventManager().publishAdvancedEvent(request.content, request.selector)
        responseData.success = true
    else if request.requestType = "publishUpdateValuesEvent"
        m.blueConicClient.eventManager().publishAdvancedEvent(request.selector, request.values)
        responseData.success = true
    else if request.requestType = "subscribe"
        m.blueConicClient.eventManager().subscribe(request.eventName, sub(event as object)
            m.top.subscribeHandler = {
                handledByIdentifiers: event.handledBy
                onlyOnce: event.onlyOnce
                eventData: event
            }
        end sub, request.onlyOnce, request.identifier)
        responseData.success = true
    else if request.requestType = "unsubscribe"
        m.blueConicClient.eventManager().unsubscribe(request.identifier)
        responseData.success = true
    end if
    m.top.response = responseData
end sub