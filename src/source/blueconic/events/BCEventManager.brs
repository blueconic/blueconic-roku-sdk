' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class that handles the publishing and subscribing of events in BlueConic.
function __BCEventManager_builder()
    instance = {}
    ' Constructor.
    '
    ' @param client The BlueConic client instance.
    instance.new = function(client as object)
        m.client = invalid
        m._eventQueue = invalid
        m._handlerRegistry = invalid
        m.client = client
        m._eventQueue = BCEventQueue()
        m._handlerRegistry = BCHandlerRegistry()
    end function
    ' Publishes an event to the event queue and handles it.
    '
    ' @param event The event to be published.
    instance.publish = sub(event as object)
        if not m.client.isEnabled()
            BCLogError("BlueConic client is not enabled. Cannot publish event: " + event.name)
            return
        end if
        event.setLocation(m.client.getScreenName())
        eventClassName = event.name
        BCLogVerbose("Publish for " + eventClassName)
        m._eventQueue.addEvent(event)
        m._handleEvents(eventClassName)
    end sub
    ' Subscribes to an event with a handler function.
    '
    ' @param eventName The name of the event to subscribe to.
    ' @param eventHandler The function to handle the event.
    ' @param onlyOnce If true, the handler will be removed after the first invocation.
    ' @param identifier An optional unique identifier for the subscription. If not provided, a random UUID will be generated.
    instance.subscribe = sub(eventName as object, eventHandler as object, onlyOnce = false as boolean, identifier = invalid as dynamic)
        if identifier = invalid
            deviceInfo = CreateObject("roDeviceInfo")
            identifier = deviceInfo.GetRandomUUID()
        end if
        BCLogInfo("Subscribe to event " + eventName + " with uuid " + identifier)
        m._handlerRegistry.subscribe(identifier, eventName, eventHandler, onlyOnce)
    end sub
    ' Unsubscribes from an event using the provided identifier.
    '
    ' @param identifier The unique identifier for the subscription to be removed.
    instance.unsubscribe = sub(identifier as string)
        BCLogInfo("Unsubscribe for " + identifier)
        m._handlerRegistry.removeHandlerByUUID(identifier)
    end sub
    ' Removes all events from the queue.
    instance.clearEvents = sub()
        m._eventQueue.clearEvents()
    end sub
    ' Handles all events in the queue.
    instance.handleAllEvents = sub()
        m._handleEvents(invalid)
    end sub
    ' Publishes an advanced event with a specific name and context.
    '
    ' @param eventName The name of the advanced event.
    ' @param context The context object associated with the event.
    instance.publishAdvancedEvent = sub(eventName as string, context as object)
        m.publish(BCAdvancedEvent(eventName, context))
    end sub
    ' Publishes a click event with a selector and context.
    '
    ' @param selector The selector for the click event.
    ' @param context The context object associated with the click event.
    instance.publishClickEvent = sub(selector as string, context as object)
        m.publish(BCClickEvent(selector, context))
    end sub
    ' Publishes an update content event with content and an optional selector.
    '
    ' @param content The content to be updated.
    ' @param selector The optional selector for the update content event.
    instance.publishUpdateContentEvent = sub(content as string, selector as string)
        m.publish(BCUpdateContentEvent(content, selector))
    end sub
    ' Publishes an update values event with a selector and values.
    '
    ' @param selector The selector for the update values event.
    ' @param values The values to be updated in the event.
    instance.publishUpdateValuesEvent = sub(selector as string, values as object)
        m.publish(BCUpdateValuesEvent(selector, values))
    end sub
    ' Clears the event handler mapping for a listener UUID
    '
    ' @param uuid The unique identifier of the listener whose event handlers should be cleared.
    instance.clearEventHandlers = sub(uuid as string)
        m._handlerRegistry.removeHandlerByUUID(uuid)
    end sub
    ' Handles a specific event by invoking the registered handlers.
    '
    ' @param event The event to be handled.
    instance._handleEvent = sub(event as object)
        className = event.name
        handlers = m._handlerRegistry.getHandlers(className)
        BCLogInfo("Number of handlers: " + handlers.count().toStr() + " found for event: " + className)
        if handlers.count() = 0
            BCLogWarning("No handlers found for event: " + className + ". This event will not be handled. Once plugins are initialized we will try again. Make sure you invoked a PAGEVIEW event to initialize plugins before invoking publish(event).")
        end if
        for each handlerData in handlers
            uuid = handlerData.id
            onlyOnce = handlerData.onlyOnce
            isEventAlreadyHandled = false
            for each handledById in event.handledBy
                if handledById = uuid
                    isEventAlreadyHandled = true
                    exit for
                end if
            end for
            BCLogInfo("Event: " + className + " isEventAlreadyHandled: " + isEventAlreadyHandled.toStr() + " by handler with id: " + uuid)
            if not isEventAlreadyHandled
                event.addHandledBy(uuid)
                event.onlyOnce = onlyOnce
                handlerFunction = handlerData.handler
                handlerFunction(event)
                BCLogInfo("Event: " + className + " is handled by handler with id: " + uuid)
            end if
            if onlyOnce
                m._handlerRegistry.removeHandlerByUUID(uuid)
            end if
        end for
    end sub
    ' Handles events in the queue based on the provided event name.
    '
    ' @param eventName The name of the event to handle. If invalid, all events in the queue will be handled.
    instance._handleEvents = sub(eventName as dynamic)
        for each event in m._eventQueue.getQueue()
            eventClassName = event.name
            if eventName = invalid or eventClassName = eventName
                m._handleEvent(event)
            end if
        end for
    end sub
    return instance
end function
function BCEventManager(client as object)
    instance = __BCEventManager_builder()
    instance.new(client)
    return instance
end function

' This class manages a queue of events and provides methods to add, clear, and remove events.
function __BCEventQueue_builder()
    instance = {}
    ' Constructor
    instance.new = function()
        m._queue = invalid
        m._queue = []
    end function
    ' Returns the current queue of events as an object.
    '
    ' @return An object containing the events in the queue.
    instance.getQueue = function() as object
        result = []
        for each event in m._queue
            result.push(event)
        end for
        return result
    end function
    ' Adds an event to the queue.
    '
    ' @param event The event object to be added to the queue.
    instance.addEvent = sub(event as object)
        m._queue.push(event)
    end sub
    ' Clears all events from the queue.
    instance.clearEvents = sub()
        m._queue = []
    end sub
    ' Removes events from the queue by their screen name.
    '
    ' @param screenName The screen name of the events to be removed.
    instance.removeByScreenName = sub(screenName as dynamic)
        replacement = []
        for each event in m._queue
            if screenName <> invalid and screenName <> event.screenName
                replacement.push(event)
            end if
        end for
        m._queue = replacement
    end sub
    return instance
end function
function BCEventQueue()
    instance = __BCEventQueue_builder()
    instance.new()
    return instance
end function
' This class manages a registry of event handlers, allowing for subscription and unsubscription of handlers based on UUIDs.
function __BCHandlerRegistry_builder()
    instance = {}
    instance.new = function()
        m._handlerMap = invalid
        m._handlerMap = {}
    end function
    ' Subscribes a handler to an event class with a unique identifier.
    '
    ' @param uuid The unique identifier for the handler.
    ' @param className The name of the event class to subscribe to.
    ' @param handler The function that will handle the event.
    ' @param onlyOnce If true, the handler will be removed after the first invocation.
    instance.subscribe = sub(uuid as string, className as string, handler as Function, onlyOnce = false as boolean)
        existing = m._handlerMap[className]
        if existing = invalid
            eventHandlers = []
            eventHandlers.push(BCTriple(handler, uuid, onlyOnce))
            m._handlerMap[className] = eventHandlers
        else if not m._containsUUID(existing, uuid)
            existing.push(BCTriple(handler, uuid, onlyOnce))
        end if
    end sub
    ' Retrieves all handlers for a specific event class.
    '
    ' @param className The name of the event class for which to retrieve handlers.
    ' @return An object containing all handlers for the specified class.
    instance.getHandlers = function(className as string) as object
        handlers = m._handlerMap[className]
        if handlers = invalid
            return []
        end if
        result = []
        for each handlerData in handlers
            result.push(handlerData)
        end for
        return result
    end function
    ' Removes a handler by its unique identifier from the registry.
    ' '
    ' @param uuid The unique identifier of the handler to be removed.
    instance.removeHandlerByUUID = sub(uuid as string)
        replacement = {}
        for each key in m._handlerMap
            value = m._handlerMap[key]
            purged = m._purge(value, uuid)
            if purged.count() > 0
                replacement[key] = purged
            end if
        end for
        m._handlerMap = replacement
    end sub
    ' Purges a specific UUID from the list of values.
    '
    ' @param values The list of values from which to remove the UUID.
    ' @param uuid The unique identifier to be removed.
    ' @return An object containing the values after the UUID has been removed.
    instance._purge = function(values as object, uuid as string) as object
        result = []
        for each value in values
            if value.id <> uuid
                result.push(value)
            end if
        end for
        return result
    end function
    ' Checks if the provided UUID exists in the list of values.
    ' '
    ' @param values The list of values to check.
    ' @param uuid The unique identifier to search for.
    ' @return True if the UUID is found in the values, otherwise false.
    instance._containsUUID = function(values as object, uuid as string) as boolean
        for each value in values
            if uuid = value.id
                return true
            end if
        end for
        return false
    end function
    return instance
end function
function BCHandlerRegistry()
    instance = __BCHandlerRegistry_builder()
    instance.new()
    return instance
end function
' This class represents a triple of handler, id, and onlyOnce flag for event handling.
function __BCTriple_builder()
    instance = {}
    ' Constructor.
    '
    ' @param handler The function that will handle the event.
    ' @param id The unique identifier for the handler.
    ' @param onlyOnce If true, the handler will be removed after the first invocation.
    instance.new = function(handler as Function, id as string, onlyOnce as boolean)
        m.handler = invalid
        m.id = invalid
        m.onlyOnce = invalid
        m.handler = handler
        m.id = id
        m.onlyOnce = onlyOnce
    end function
    return instance
end function
function BCTriple(handler as Function, id as string, onlyOnce as boolean)
    instance = __BCTriple_builder()
    instance.new(handler, id, onlyOnce)
    return instance
end function
' This class represents a base event in BlueConic, providing common properties and methods for all events.
function __BCEvent_builder()
    instance = {}
    ' Constructor.
    instance.new = function()
        m.name = invalid
        m.handledBy = invalid
        m.screenName = invalid
        m.onlyOnce = invalid
        m.name = "BCEvent"
        m.handledBy = []
        m.screenName = invalid
        m.onlyOnce = false
    end function
    ' Adds a handler identifier to the list of handlers that have processed this event.
    '
    ' @param handledBy The identifier of the handler that has processed the event.
    instance.addHandledBy = sub(handledBy as string)
        m.handledBy.push(handledBy)
    end sub
    ' Sets the screen name for the event, which is used to identify the context in which the event occurred.
    '
    ' @param location The screen name or location where the event occurred.
    instance.setLocation = sub(location as string)
        m.screenName = location
    end sub
    return instance
end function
function BCEvent()
    instance = __BCEvent_builder()
    instance.new()
    return instance
end function
' This class represents an advanced event in BlueConic, allowing for additional context to be passed along with the event.
function __BCAdvancedEvent_builder()
    instance = __BCEvent_builder()
    ' Constructor.
    '
    ' @param eventName The name of the advanced event.
    ' @param context The context object associated with the event. If not provided, an empty array will be used.
    instance.super0_new = instance.new
    instance.new = function(eventName as string, context = invalid as dynamic)
        m.super0_new()
        m.eventName = invalid
        m.context = invalid
        m.name = "advancedEvent"
        m.eventName = eventName
        if context = invalid
            m.context = []
        else
            m.context = []
            for each item in context
                m.context.push(item)
            end for
        end if
    end function
    return instance
end function
function BCAdvancedEvent(eventName as string, context = invalid as dynamic)
    instance = __BCAdvancedEvent_builder()
    instance.new(eventName, context)
    return instance
end function
' This class represents a click event in BlueConic, which includes a selector and an optional context.
function __BCClickEvent_builder()
    instance = __BCEvent_builder()
    ' Constructor.
    '
    ' @param selector The selector for the click event.
    ' @param context The context object associated with the click event. If not provided, an empty array will be used.
    instance.super0_new = instance.new
    instance.new = function(selector as string, context = invalid as dynamic)
        m.super0_new()
        m.selector = invalid
        m.context = invalid
        m.name = "clickEvent"
        m.selector = selector
        if context = invalid
            m.context = []
        else
            m.context = []
            for each item in context
                m.context.push(item)
            end for
        end if
    end function
    return instance
end function
function BCClickEvent(selector as string, context = invalid as dynamic)
    instance = __BCClickEvent_builder()
    instance.new(selector, context)
    return instance
end function
' This class represents an update content event in BlueConic, which includes content and an optional selector.
function __BCUpdateContentEvent_builder()
    instance = __BCEvent_builder()
    ' Constructor.
    '
    ' @param content The content to be updated.
    ' @param selector The optional selector for the update content event. If not provided, it defaults to invalid.
    instance.super0_new = instance.new
    instance.new = function(content as string, selector = invalid as dynamic)
        m.super0_new()
        m.content = invalid
        m.selector = invalid
        m.name = "updateContentEvent"
        m.content = content
        m.selector = selector
    end function
    return instance
end function
function BCUpdateContentEvent(content as string, selector = invalid as dynamic)
    instance = __BCUpdateContentEvent_builder()
    instance.new(content, selector)
    return instance
end function
' This class represents an update values event in BlueConic, which includes a selector and a list of values.
function __BCUpdateValuesEvent_builder()
    instance = __BCEvent_builder()
    ' Constructor.
    '
    ' @param selector The selector for the update values event.
    ' @param values The values to be updated in the event. If not provided, an empty array will be used.
    instance.super0_new = instance.new
    instance.new = function(selector as string, values as object)
        m.super0_new()
        m.selector = invalid
        m.values = invalid
        m.name = "updateValuesEvent"
        m.selector = selector
        m.values = []
        if values <> invalid
            for each value in values
                m.values.push(value)
            end for
        end if
    end function
    return instance
end function
function BCUpdateValuesEvent(selector as string, values as object)
    instance = __BCUpdateValuesEvent_builder()
    instance.new(selector, values)
    return instance
end function
' This class represents a properties dialogue event in BlueConic, which includes a variant ID, position, and data.
function __BCPropertiesDialogueEvent_builder()
    instance = __BCEvent_builder()
    ' Constructor.
    '
    ' @param variantId The ID of the variant associated with the properties dialogue.
    ' @param position The position of the properties dialogue.
    ' @param data The data associated with the properties dialogue. If not provided, it defaults to an empty string.
    instance.super0_new = instance.new
    instance.new = function(variantId as string, position as string, data as string)
        m.super0_new()
        m.variantId = invalid
        m.position = invalid
        m.data = invalid
        m.name = "propertiesDialogueEvent"
        m.variantId = variantId
        m.position = position
        m.data = data
    end function
    return instance
end function
function BCPropertiesDialogueEvent(variantId as string, position as string, data as string)
    instance = __BCPropertiesDialogueEvent_builder()
    instance.new(variantId, position, data)
    return instance
end function
' This class represents a recommendations dialogue event in BlueConic, which includes a variant ID, position, store id, and recommendations.
function __BCRecommendationsDialogueEvent_builder()
    instance = __BCEvent_builder()
    ' Constructor.
    '
    ' @param variantId The ID of the variant associated with the properties dialogue.
    ' @param position The position of the properties dialogue.
    ' @param storeId The store ID associated with the properties dialogue.
    ' @param recommendations The recommendations associated with the properties dialogue. If not provided, it defaults to an empty string.
    instance.super0_new = instance.new
    instance.new = function(variantId as string, position as string, storeId as string, recommendations as string)
        m.super0_new()
        m.variantId = invalid
        m.position = invalid
        m.storeId = invalid
        m.recommendations = invalid
        m.name = "recommendationsDialogueEvent"
        m.variantId = variantId
        m.position = position
        m.storeId = storeId
        m.recommendations = recommendations
    end function
    return instance
end function
function BCRecommendationsDialogueEvent(variantId as string, position as string, storeId as string, recommendations as string)
    instance = __BCRecommendationsDialogueEvent_builder()
    instance.new(variantId, position, storeId, recommendations)
    return instance
end function