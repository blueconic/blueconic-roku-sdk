' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.

' Commit log class to handle properties, events, and timelines.
' This class is used to collect changes made during a session and apply them in a batch.
function __BCCommitLog_builder()
    instance = {}
    ' Constructor
    instance.new = function()
        m._properties = invalid
        m._events = invalid
        m._timelines = invalid
        m._properties = []
        m._events = []
        m._timelines = []
    end function
    ' Set properties. This will overwrite existing values for the property.
    ' If the property already exists, it will update the values.
    '
    ' @param name The name of the property
    ' @param values The values to set for the property
    instance.setProperties = sub(name as string, values as object)
        if name = "" or values.count() = 0
            return
        end if
        existingEntry = m.getPropertyCommitEntry(name)
        if existingEntry <> invalid
            existingEntry.setValues(values)
        else
            entry = BCPropertyCommitEntry(name, "SET", values)
            m._properties.push(entry)
        end if
    end sub
    ' Add properties. This will add values to the existing property or create a new one if it does not exist.
    ' If the property already exists, it will append the values to the existing values.
    '
    ' @param name The name of the property
    ' @param values The values to add to the property
    instance.addProperties = sub(name as string, values as object)
        if name = "" or values.count() = 0
            return
        end if
        existingEntry = m.getPropertyCommitEntry(name)
        if existingEntry <> invalid
            existingValues = existingEntry.getValues()
            for each value in values
                existingEntry.addValue(value)
            end for
        else
            entry = BCPropertyCommitEntry(name, "ADD", values)
            m._properties.push(entry)
        end if
    end sub
    ' Increment properties. This will add values to the existing property or create a new one if it does not exist.
    ' If the property already exists, it will append the values to the existing values.
    '
    ' @param name The name of the property
    ' @param values The values to increment for the property
    instance.incrementProperties = sub(name as string, values as object)
        if name = "" or values.count() = 0
            return
        end if
        existingEntry = m.getPropertyCommitEntry(name)
        if existingEntry <> invalid
            for each value in values
                existingEntry.addValue(value)
            end for
        else
            entry = BCPropertyCommitEntry(name, "INCREMENT", values)
            m._properties.push(entry)
        end if
    end sub
    ' Increment property. This will add a single value to the existing property or create a new one if it does not exist.
    ' If the property already exists, it will append the value to the existing values.
    '
    ' @param name The name of the property
    ' @param value The value to increment for the property
    instance.incrementProperty = sub(name as string, value as string)
        if name = "" or value = ""
            return
        end if
        m.incrementProperties(name, [
            value
        ])
    end sub
    ' Create event. This will create a new event with the given type and interaction ID.
    '
    ' @param eventType The type of the event
    ' @param interactionId The interaction ID for the event
    instance.createEvent = sub(eventType as string, interactionId as string)
        if interactionId = ""
            return
        end if
        m.updateEvent(eventType, interactionId, 1)
    end sub
    ' Update event. This will update the count of an existing event or create a new one if it does not exist.
    '
    ' @param eventType The type of the event
    ' @param interactionId The interaction ID for the event
    ' @param amount The amount to increase the count by
    instance.updateEvent = sub(eventType as string, interactionId as string, amount as integer)
        existingEntry = m.getEventCommitEntry(eventType, interactionId)
        if existingEntry <> invalid
            existingEntry.increaseCount(amount)
        else
            newEntry = BCEventCommitEntry(eventType, interactionId)
            if amount > 1
                newEntry.increaseCount(amount - 1)
            end if
            m._events.push(newEntry)
        end if
    end sub
    ' Create timeline event. This will create a new timeline event with the given type and properties.
    '
    ' @param eventType The type of the timeline event
    ' @param properties The properties for the timeline event
    instance.createTimelineEvent = sub(eventType as string, properties as object)
        m.updateTimeline(eventType, properties)
    end sub
    ' Update timeline. This will update the timeline with a new entry.
    '
    ' @param eventType The type of the timeline event
    ' @param properties The properties for the timeline event
    instance.updateTimeline = sub(eventType as string, properties as object)
        newEntry = BCTimelineCommitEntry(eventType, properties)
        m._timelines.push(newEntry)
    end sub
    ' Get properties.
    '
    ' @return Returns all properties in the commit log
    instance.getProperties = function() as object
        return m._properties
    end function
    ' Get properties by type.
    '
    ' @param eventType The type of the properties to retrieve
    ' @return Returns all properties of the specified type in the commit log
    instance.getPropertiesByType = function(eventType as string) as object
        result = {}
        for each entry in m._properties
            if entry.getType() = eventType
                result[entry.getId()] = entry
            end if
        end for
        return result
    end function
    ' Get events.
    '
    ' @return Returns all events in the commit log
    instance.getEvents = function() as object
        return m._events
    end function
    ' Get timeline events.
    '
    ' @return Returns all timeline events in the commit log
    instance.getTimelineEvents = function() as object
        return m._timelines
    end function
    ' Get count.
    '
    ' @return Returns the total count of properties, events, and timelines in the commit log
    instance.getCount = function() as integer
        return m._events.count() + m._properties.count() + m._timelines.count()
    end function
    ' Get property commit entry.
    '
    ' @param propertyId The ID of the property to retrieve
    ' @return Returns the property commit entry if found, otherwise returns invalid
    instance.getPropertyCommitEntry = function(propertyId as string) as object
        if propertyId = ""
            return invalid
        end if
        for each entry in m._properties
            if entry.getId() = propertyId
                return entry
            end if
        end for
        return invalid
    end function
    ' Get event commit entry.
    '
    ' @param eventType The type of the event to retrieve
    ' @param interactionId The interaction ID of the event to retrieve
    ' @return Returns the event commit entry if found, otherwise returns invalid
    instance.getEventCommitEntry = function(eventType as string, interactionId as string) as object
        if interactionId = ""
            return invalid
        end if
        for each entry in m._events
            if entry.getId() = interactionId and entry.getType() = eventType
                return entry
            end if
        end for
        return invalid
    end function
    ' Clear all entries. This will remove all properties, events, and timelines from the commit log.
    instance.clearAll = function()
        m._properties.clear()
        m._events.clear()
        m._timelines.clear()
    end function
    ' Merge commit log. This will merge the entries from another commit log into this one.
    '
    ' @param commitLog The commit log to merge
    instance.mergeCommitLog = sub(commitLog as object)
        if commitLog.getCount() = 0
            return
        end if
        for each entry in commitLog.getEvents()
            m.updateEvent(entry.getType(), entry.getId(), entry.getCount())
        end for
        for each entry in commitLog.getProperties()
            if entry.getType() = "SET"
                m.setProperties(entry.getId(), entry.getValues())
            else if entry.getType() = "ADD"
                m.addProperties(entry.getId(), entry.getValues())
            else if entry.getType() = "INCREMENT"
                m.incrementProperties(entry.getId(), entry.getValues())
            end if
        end for
        for each entry in commitLog.getTimelineEvents()
            m.updateTimeline(entry.getType(), entry.getProperties())
        end for
        commitLog.clearAll()
    end sub
    return instance
end function
function BCCommitLog()
    instance = __BCCommitLog_builder()
    instance.new()
    return instance
end function
' Abstract commit entry class implemented by property, event and timeline commit entries.
function __BCCommitEntry_builder()
    instance = {}
    ' Constructor.
    '
    ' @param id The identifier for the commit entry
    instance.new = function(id as string)
        m._identifier = invalid
        m._identifier = id
    end function
    ' Get type.
    '
    ' @return Returns the type of the commit entry
    instance.getType = function() as string
        return ""
    end function
    ' Get ID.
    '
    ' @return Returns the identifier of the commit entry
    instance.getId = function() as string
        return m._identifier
    end function
    return instance
end function
function BCCommitEntry(id as string)
    instance = __BCCommitEntry_builder()
    instance.new(id)
    return instance
end function
' Commit entry class for properties.
function __BCPropertyCommitEntry_builder()
    instance = __BCCommitEntry_builder()
    ' Constructor.
    '
    ' @param propertyIdentifier The identifier for the property commit entry
    ' @param entryType The type of the property commit entry (ADD, SET, INCREMENT)
    ' @param values The values for the property commit entry
    instance.super0_new = instance.new
    instance.new = function(propertyIdentifier as string, entryType as string, values as object)
        m.super0_new(propertyIdentifier)
        m._type = invalid
        m._values = invalid
        m._type = entryType
        m._values = values
    end function
    ' Get type.
    '
    ' @return Returns the type of the property commit entry
    instance.super0_getType = instance.getType
    instance.getType = function() as string
        return m._type
    end function
    ' Get values.
    '
    ' @return Returns the values of the property commit entry
    instance.getValues = function() as object
        return m._values
    end function
    ' Set values.
    '
    ' @param values The values to set for the property commit entry
    instance.setValues = function(values as object)
        if values.count() > 0
            m._values = values
        end if
    end function
    ' Add value.
    '
    ' @param value The value to add to the property commit entry
    instance.addValue = function(value as string)
        m._values.push(value)
    end function
    return instance
end function
function BCPropertyCommitEntry(propertyIdentifier as string, entryType as string, values as object)
    instance = __BCPropertyCommitEntry_builder()
    instance.new(propertyIdentifier, entryType, values)
    return instance
end function
' Commit entry class for events.
function __BCEventCommitEntry_builder()
    instance = __BCCommitEntry_builder()
    ' Constructor
    '
    ' @param eventType The type of the event
    ' @param interactionId The interaction ID for the event
    instance.super0_new = instance.new
    instance.new = function(eventType as string, interactionId as string)
        m.super0_new(interactionId)
        m._type = invalid
        m._count = invalid
        m._type = eventType
        m._count = 1
    end function
    ' Get type.
    '
    ' @return Returns the type of the event commit entry
    instance.super0_getType = instance.getType
    instance.getType = function() as string
        return m._type
    end function
    ' Get count.
    '
    ' @return Returns the count of the event commit entry
    instance.getCount = function() as integer
        return m._count
    end function
    ' Increase count.
    '
    ' @param amount The amount to increase the count by
    instance.increaseCount = function(amount as integer)
        m._count += amount
    end function
    return instance
end function
function BCEventCommitEntry(eventType as string, interactionId as string)
    instance = __BCEventCommitEntry_builder()
    instance.new(eventType, interactionId)
    return instance
end function
' Commit entry class for timeline events.
function __BCTimelineCommitEntry_builder()
    instance = __BCCommitEntry_builder()
    ' Constructor.
    '
    ' @param eventType The type of the timeline event
    ' @param properties The properties for the timeline event
    instance.super0_new = instance.new
    instance.new = function(eventType as string, properties as object)
        m.super0_new(eventType)
        m._eventType = invalid
        m._properties = invalid
        m._eventType = eventType
        m._properties = properties
    end function
    ' Get type.
    '
    ' @return Returns the type of the timeline commit entry
    instance.super0_getType = instance.getType
    instance.getType = function() as string
        return m._eventType
    end function
    ' Get properties.
    '
    ' @return Returns the properties of the timeline commit entry
    instance.getProperties = function() as object
        return m._properties
    end function
    return instance
end function
function BCTimelineCommitEntry(eventType as string, properties as object)
    instance = __BCTimelineCommitEntry_builder()
    instance.new(eventType, properties)
    return instance
end function