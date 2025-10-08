' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling all API calls to BlueConic.
function __BlueConicClient_builder()
    instance = {}
    ' Constructor.
    '
    ' @param scene The scene object to which this client belongs.
    instance.new = function(scene as object)
        m._task = invalid
        m._requestCounter = 0
        m._callbacks = {}
        m._subscribeHandlers = {}
        m._task = CreateObject("roSGNode", "BlueConicTask")
        m._task.observeField("response", "onCommandResponse")
        m._task.observeField("subscribeHandler", "onHandlerResponse")
        scene.blueConicClient = m
    end function
    ' Registers an event of the specified type with the given data.
    '
    ' @param eventType The type of the event to register.
    ' @param properties The properties associated with the event.
    instance.createEvent = sub(eventType as string, properties as object)
        m._task.request = {
            requestType: "createEvent"
            eventType: eventType
            properties: properties
            requestId: m._getNextRequestId()
        }
    end sub
    ' Registers a page view event with the specified screen name and properties.
    '
    ' @param screenName The name of the screen for the page view event.
    ' @param properties The properties associated with the page view event.
    instance.createPageViewEvent = sub(screenName as string, properties as object)
        m._task.request = {
            requestType: "createPageViewEvent"
            screenName: screenName
            properties: properties
            requestId: m._getNextRequestId()
        }
    end sub
    ' Registers a view event with the specified interaction ID and properties.
    '
    ' @param interactionId The ID of the interaction for the view event.
    ' @param properties The properties associated with the view event.
    instance.createViewEvent = sub(interactionId as string, properties as object)
        m._task.request = {
            requestType: "createViewEvent"
            interactionId: interactionId
            properties: properties
            requestId: m._getNextRequestId()
        }
    end sub
    ' Registers a conversion event with the specified interaction ID and properties.
    '
    ' @param interactionId The ID of the interaction for the conversion event.
    ' @param properties The properties associated with the conversion event.
    instance.createConversionEvent = sub(interactionId as string, properties as object)
        m._task.request = {
            requestType: "createConversionEvent"
            interactionId: interactionId
            properties: properties
            requestId: m._getNextRequestId()
        }
    end sub
    ' Registers a click event with the specified interaction ID and properties.
    '
    ' @param interactionId The ID of the interaction for the click event.
    ' @param properties The properties associated with the click event.
    instance.createClickEvent = sub(interactionId as string, properties as object)
        m._task.request = {
            requestType: "createClickEvent"
            interactionId: interactionId
            properties: properties
            requestId: m._getNextRequestId()
        }
    end sub
    ' Registers a timeline event with the specified event type, date, and properties.
    '
    ' @param eventType The type of the timeline event.
    ' @param eventDate The date of the timeline event.
    ' @param properties The properties associated with the timeline event.
    instance.createTimelineEvent = sub(eventType as string, eventDate as string, properties as object)
        m._task.request = {
            requestType: "createTimelineEvent"
            eventType: eventType
            eventDate: eventDate
            properties: properties
            requestId: m._getNextRequestId()
        }
    end sub
    ' Registers a timeline event by ID with the specified event ID, type, date, and properties.
    '
    ' @param eventId The ID of the timeline event.
    ' @param eventType The type of the timeline event.
    ' @param eventDate The date of the timeline event.
    ' @param properties The properties associated with the timeline event.
    instance.createTimelineEventById = sub(eventId as string, eventType as string, eventDate as string, properties as object)
        m._task.request = {
            requestType: "createTimelineEventById"
            eventId: eventId
            eventType: eventType
            eventDate: eventDate
            properties: properties
            requestId: m._getNextRequestId()
        }
    end sub
    instance.createRecommendationsEvent = sub(storeId as string, action as string, itemIds as object)
        m._task.request = {
            requestType: "createRecommendationsEvent"
            storeId: storeId
            action: action
            itemIds: itemIds
            requestId: m._getNextRequestId()
        }
    end sub
    ' Returns the profile object for managing user profile data.
    '
    ' @return An object representing the user profile.
    instance.profile = function() as object
        if m._profile = invalid
            m._profile = {
                _parent: m
                ' Returns the profile ID.
                '
                ' @param callback The callback function to handle the profile ID.
                getId: function(callback as Function)
                    requestId = m._parent._getNextRequestId()
                    m._parent._registerCallback(requestId, callback)
                    m._parent._task.request = {
                        requestType: "getId"
                        requestId: requestId
                    }
                end function
                ' Returns the privacy legislation.
                '
                ' @param callback The callback function to handle the privacy legislation response value.
                getPrivacyLegislation: function(callback as Function)
                    requestId = m._parent._getNextRequestId()
                    m._parent._registerCallback(requestId, callback)
                    m._parent._task.request = {
                        requestType: "getPrivacyLegislation"
                        requestId: requestId
                    }
                end function
                ' Sets the privacy legislation.
                '
                ' @param privacyLegislation The privacy legislation to set.
                setPrivacyLegislation: function(privacyLegislation as string)
                    m._parent._task.request = {
                        requestType: "setPrivacyLegislation"
                        privacyLegislation: privacyLegislation
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Returns the consented objectives.
                '
                ' @param callback The callback function to handle the consented objectives response value.
                getConsentedObjectives: function(callback as Function)
                    requestId = m._parent._getNextRequestId()
                    m._parent._registerCallback(requestId, callback)
                    m._parent._task.request = {
                        requestType: "getConsentedObjectives"
                        requestId: requestId
                    }
                end function
                ' Sets the consented objectives.
                '
                ' @param consentedObjectives The consented objectives to set.
                setConsentedObjectives: function(consentedObjectives as object)
                    m._parent._task.request = {
                        requestType: "setConsentedObjectives"
                        consentedObjectives: consentedObjectives
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Adds a consented objective.
                '
                ' @param consentedObjective The consented objective to add.
                addConsentedObjective: function(consentedObjective as string)
                    m._parent._task.request = {
                        requestType: "addConsentedObjective"
                        consentedObjective: consentedObjective
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Returns the refused objectives.
                '
                ' @param callback The callback function to handle the refused objectives response value.
                getRefusedObjectives: function(callback as Function)
                    requestId = m._parent._getNextRequestId()
                    m._parent._registerCallback(requestId, callback)
                    m._parent._task.request = {
                        requestType: "getRefusedObjectives"
                        requestId: requestId
                    }
                end function
                ' Sets the refused objectives.
                '
                ' @param refusedObjectives The refused objectives to set.
                setRefusedObjectives: function(refusedObjectives as object)
                    m._parent._task.request = {
                        requestType: "setRefusedObjectives"
                        refusedObjectives: refusedObjectives
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Adds a refused objective.
                '
                ' @param refusedObjective The refused objective to add.
                addRefusedObjective: function(refusedObjective as string)
                    m._parent._task.request = {
                        requestType: "addRefusedObjective"
                        refusedObjective: refusedObjective
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Returns the value of a specific property.
                '
                ' @param property The property to get the value for.
                ' @param callback The callback function to handle the value response.
                getValue: function(property as string, callback as Function)
                    requestId = m._parent._getNextRequestId()
                    m._parent._registerCallback(requestId, callback)
                    m._parent._task.request = {
                        requestType: "getValue"
                        property: property
                        requestId: requestId
                    }
                end function
                ' Returns the values of a specific property.
                '
                ' @param property The property to get the values for.
                ' @param callback The callback function to handle the values response.
                getValues: function(property as object, callback as Function)
                    requestId = m._parent._getNextRequestId()
                    m._parent._registerCallback(requestId, callback)
                    m._parent._task.request = {
                        requestType: "getValues"
                        property: property
                        requestId: requestId
                    }
                end function
                ' Returns all properties of the profile.
                '
                ' @param callback The callback function to handle the properties response.
                getAllProperties: function(callback as Function)
                    requestId = m._parent._getNextRequestId()
                    m._parent._registerCallback(requestId, callback)
                    m._parent._task.request = {
                        requestType: "getAllProperties"
                        requestId: requestId
                    }
                end function
                ' Adds a value to a specific property.
                '
                ' @param property The property to which the value should be added.
                ' @param value The value to add to the property.
                addValue: function(property as string, value as string)
                    m._parent._task.request = {
                        requestType: "addValue"
                        property: property
                        value: value
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Adds multiple values to a specific property.
                '
                ' @param property The property to which the values should be added.
                ' @param values The values to add to the property.
                addValues: function(property as string, values as object)
                    m._parent._task.request = {
                        requestType: "addValues"
                        property: property
                        values: values
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Sets a value for a specific property.
                '
                ' @param property The property to set the value for.
                ' @param value The value to set for the property.
                setValue: function(property as string, value as string)
                    m._parent._task.request = {
                        requestType: "setValue"
                        property: property
                        value: value
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Sets multiple values for a specific property.
                '
                ' @param property The property to set the values for.
                ' @param values The values to set for the property.
                setValues: function(property as string, values as object)
                    m._parent._task.request = {
                        requestType: "setValues"
                        property: property
                        values: values
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Increments a value for a specific property.
                '
                ' @param property The property for which the value should be incremented.
                ' @param value The value to increment for the property.
                incrementValue: function(property as string, value as integer)
                    m._parent._task.request = {
                        requestType: "incrementValue"
                        property: property
                        value: value
                        requestId: m._parent._getNextRequestId()
                    }
                end function
            }
        end if
        return m._profile
    end function
    ' Returns the current screen name.
    '
    ' @param callback The callback function to handle the screen name response.
    instance.getScreenName = sub(callback as Function)
        requestId = m._getNextRequestId()
        m._registerCallback(requestId, callback)
        m._task.request = {
            requestType: "getScreenName"
            requestId: requestId
        }
    end sub
    ' Returns the segments associated with the profile.
    '
    ' @param callback The callback function to handle the segments response.
    instance.getSegments = sub(callback as Function)
        requestId = m._getNextRequestId()
        m._registerCallback(requestId, callback)
        m._task.request = {
            requestType: "getSegments"
            requestId: requestId
        }
    end sub
    ' Checks if the BlueConic client is enabled.
    '
    ' @param callback The callback function to handle the enabled status response.
    instance.isEnabled = sub(callback as Function)
        requestId = m._getNextRequestId()
        m._registerCallback(requestId, callback)
        m._task.request = {
            requestType: "isEnabled"
            requestId: requestId
        }
    end sub
    ' Creates a new profile by clearing the current profile ID from the BlueConic client locally (cache). A new profile ID will be generated. All profile properties and values will be cleared.
    instance.createProfile = sub()
        m._task.request = {
            requestType: "createProfile"
            requestId: m._getNextRequestId()
        }
    end sub
    ' Removes the profile from the BlueConic servers. The profile ID will be removed from the BlueConic client. A new profile ID will be generated. All profile properties and values will be cleared.
    instance.deleteProfile = sub()
        m._task.request = {
            requestType: "deleteProfile"
            requestId: m._getNextRequestId()
        }
    end sub
    ' Update the profile to sync over the data from the CTV app to the BlueConic servers and also pull in the data that has changed on the BlueConic side.
    instance.updateProfile = sub()
        m._task.request = {
            requestType: "updateProfile"
            requestId: m._getNextRequestId()
        }
    end sub
    ' Returns the event manager for handling events in BlueConic.
    instance.eventManager = function() as object
        if m._eventManager = invalid
            m._eventManager = {
                _parent: m
                ' Publishes an advanced event with the specified name and context.
                '
                ' @param eventName The name of the event to publish.
                ' @param context The context data associated with the event.
                publishAdvancedEvent: function(eventName as string, context as object)
                    m._parent._task.request = {
                        requestType: "publishAdvancedEvent"
                        eventName: eventName
                        context: context
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Publishes a click event with the specified selector and context.
                '
                ' @param selector The selector for the click event.
                ' @param context The context data associated with the click event.
                publishClickEvent: function(selector as string, context as object)
                    m._parent._task.request = {
                        requestType: "publishClickEvent"
                        selector: selector
                        context: context
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Publishes an update content event with the specified content and selector.
                '
                ' @param content The content to publish in the event.
                ' @param selector The selector for the update content event.
                publishUpdateContentEvent: function(content as string, selector as string)
                    m._parent._task.request = {
                        requestType: "publishUpdateContentEvent"
                        content: content
                        selector: selector
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Publishes an update values event with the specified selector and values.
                '
                ' @param selector The selector for the update values event.
                ' @param values The values to publish in the event.
                publishUpdateValuesEvent: function(selector as string, values as object)
                    m._parent._task.request = {
                        requestType: "publishUpdateValuesEvent"
                        selector: selector
                        values: values
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Subscribes to an event with the specified name and handler.
                '
                ' @param eventName The name of the event to subscribe to.
                ' @param handler The function to handle the event when it occurs.
                ' @param onlyOnce Optional. If true, the handler will be called only once.
                ' @param identifier Optional. A unique identifier for the subscription.
                subscribe: function(eventName as string, handler as Function, onlyOnce = false as boolean, identifier = invalid as dynamic)
                    if identifier = invalid
                        deviceInfo = CreateObject("roDeviceInfo")
                        identifier = deviceInfo.GetRandomUUID()
                    end if
                    m._parent._registerSubscribeHandler(identifier, handler)
                    m._parent._task.request = {
                        requestType: "subscribe"
                        eventName: eventName
                        onlyOnce: onlyOnce
                        identifier: identifier
                        requestId: m._parent._getNextRequestId()
                    }
                end function
                ' Unsubscribes from an event with the specified identifier.
                '
                ' @param identifier The unique identifier for the subscription to unsubscribe from.
                unsubscribe: function(identifier as string)
                    m._parent._task.request = {
                        requestType: "unsubscribe"
                        identifier: identifier
                        requestId: m._parent._getNextRequestId()
                    }
                end function
            }
        end if
        return m._eventManager
    end function
    ' Increments the request counter and returns the next request ID.
    '
    ' @return The next request ID as an integer.
    instance._getNextRequestId = function() as integer
        m._requestCounter = m._requestCounter + 1
        return m._requestCounter
    end function
    ' Registers a callback function for a specific request ID.
    '
    ' @param requestId The ID of the request to register the callback for.
    ' @param callback The callback function to be called when the response is received.
    instance._registerCallback = sub(requestId as integer, callback as Function)
        m._callbacks[requestId.toStr()] = callback
    end sub
    ' Registers a subscribe handler for a specific identifier.
    '
    ' @param identifier The unique identifier for the subscription.
    ' @param handler The function to handle the subscription event.
    instance._registerSubscribeHandler = sub(identifier as string, handler as Function)
        m._subscribeHandlers[identifier] = handler
    end sub
    ' Processes the response from the BlueConic Task.
    '
    ' @param response The response object received from the BlueConic Task.
    ' @return The processed response value based on the response data.
    instance._processResponse = function(response as object) as dynamic
        if response.success <> true
            return {}
        end if
        if response.isEnabled <> invalid
            return response.isEnabled
        else if response.profileId <> invalid
            return response.profileId
        else if response.screenName <> invalid
            return response.screenName
        else if response.isEnabled <> invalid
            return response.isEnabled
        else if response.privacyLegislation <> invalid
            return response.privacyLegislation
        else if response.consentedObjectives <> invalid
            return response.consentedObjectives
        else if response.refusedObjectives <> invalid
            return response.refusedObjectives
        else if response.value <> invalid
            return response.value
        else if response.values <> invalid
            return response.values
        else if response.properties <> invalid
            return response.properties
        else if response.segments <> invalid
            return response.segments
        end if
    end function
    return instance
end function
function BlueConicClient(scene as object)
    instance = __BlueConicClient_builder()
    instance.new(scene)
    return instance
end function

' Returns the BlueConicClient instance for the current scene.
'
' @return The BlueConicClient instance.
sub getBlueConicClientInstance() as object
    if GetGlobalAA().blueConicClient = invalid
        return BlueConicClient(GetGlobalAA())
    else if GetGlobalAA().blueConicClient <> invalid
        return GetGlobalAA().blueConicClient
    end if
end sub

' Handles the response from the BlueConic Task when a command is executed.
'
' @param event The event object containing the response data.
sub onCommandResponse(event as object)
    response = event.getData()
    if response <> invalid and response.requestId <> invalid
        requestId = response.requestId.toStr()
        if m.blueConicClient._callbacks[requestId] <> invalid
            callback = m.blueConicClient._callbacks[requestId]
            m.blueConicClient._callbacks.delete(requestId)
            callbackValue = m.blueConicClient._processResponse(response)
            callback(callbackValue)
        end if
    end if
end sub

' Handles the response from the BlueConic Task when a subscription event occurs.
'
' @param event The event object containing the response data.
sub onHandlerResponse(event as object)
    response = event.getData()
    if response <> invalid and response.handledByIdentifiers <> invalid
        identifier = response.handledByIdentifiers[0]
        onlyOnce = response.onlyOnce
        if m.blueConicClient._subscribeHandlers[identifier] <> invalid
            handler = m.blueConicClient._subscribeHandlers[identifier]
            handler(response.eventData)
            if onlyOnce = true
                m.blueConicClient._subscribeHandlers.delete(identifier)
            end if
        end if
    end if
end sub