' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class to handle BlueConic request commands
function __BCConnectorCommands_builder()
    instance = {}
    instance.new = sub()
    end sub
    ' Method to get profile command
    '
    ' @return: The profile command object
    instance.getProfileCommand = function() as object
        parameters = {
            "forceCreate": [
                "true"
            ]
        }
        return m._requestCommand("getProfile", parameters, invalid)
    end function
    ' Method to create profile command
    '
    ' @return: The create profile command object
    instance.createProfileCommand = function() as object
        return m._requestCommand("createProfile", invalid, invalid)
    end function
    ' Method to delete profile command
    '
    ' @return: The delete profile command object
    instance.deleteProfileCommand = function() as object
        return m._requestCommand("deleteProfile", invalid, invalid)
    end function
    ' Method to get properties command
    '
    ' @param hash: The profile hash
    ' @param propertyIds: The property IDs to retrieve (optional)
    ' @return: The get properties command object
    instance.getGetPropertiesCommand = function(hash as string, propertyIds = invalid as object) as object
        parameters = {}
        if hash <> ""
            parameters["hash"] = [
                hash
            ]
        end if
        if propertyIds <> invalid
            parameters["property"] = propertyIds
        end if
        return m._requestCommand("getProperties", parameters, invalid)
    end function
    ' Method to get property labels command
    '
    ' @return: The get property labels command object
    instance.getPropertyLabelsCommand = function() as object
        return m._requestCommand("getPropertyLabels", invalid, invalid)
    end function
    ' Method to set properties command
    '
    ' @param values: The properties to set, where each property is an object with a type and values
    ' @return: The set properties command object
    instance.getSetPropertiesCommand = function(values as object) as object
        properties = {}
        for each propertyEntry in values
            propertyValue = values[propertyEntry]
            if propertyValue.getType() = "SET"
                properties[propertyEntry] = propertyValue.getValues()
            end if
        end for
        parameters = {
            properties: properties
        }
        return m._requestCommand("setProperties", invalid, parameters)
    end function
    ' Method to add properties command
    '
    ' @param values: The properties to add, where each property is an object with a type and values
    ' @return: The add properties command object
    instance.getAddPropertiesCommand = function(values as object) as object
        properties = {}
        for each propertyEntry in values
            propertyValue = values[propertyEntry]
            if propertyValue.getType() = "ADD"
                properties[propertyEntry] = propertyValue.getValues()
            end if
        end for
        parameters = {
            properties: properties
        }
        return m._requestCommand("addProperties", invalid, parameters)
    end function
    ' Method to increment properties command
    '
    ' @param values: The properties to increment, where each property is an object with a type and values
    ' @return: The increment properties command object
    instance.getIncrementPropertiesCommand = function(values as object) as object
        properties = {}
        for each propertyEntry in values
            propertyValue = values[propertyEntry]
            if propertyValue.getType() = "INCREMENT"
                properties[propertyEntry] = propertyValue.getValues()
            end if
        end for
        parameters = {
            properties: properties
        }
        return m._requestCommand("incrementProperties", invalid, parameters)
    end function
    ' Method to create event command
    '
    ' @param eventType: The type of the event
    ' @param interactionId: The interaction ID for the event
    ' @return: The create event command object
    instance.getCreateEventCommand = function(eventType as string, interactionId as string) as object
        parameters = {
            type: [
                eventType
            ]
            interaction: [
                interactionId
            ]
        }
        return m._requestCommand("createEvent", parameters, invalid)
    end function
    ' Method to get interactions command
    '
    ' @param eventType: The type of the event
    ' @param properties: The properties associated with the event
    ' @return: The get interactions command object
    instance.getInteractionsCommand = function(eventType as string, properties as object) as object
        parameters = {
            type: [
                eventType
            ]
            interaction: []
        }
        if eventType <> "PAGEVIEW"
            parameters["timelineContext"] = [
                FormatJson(properties)
            ]
        end if
        return m._requestCommand("createEvent", parameters, invalid)
    end function
    ' Method to get timeline command
    '
    ' @param eventType: The type of the event
    ' @param properties: The properties associated with the event
    ' @return: The get timeline command object
    instance.getTimelineCommand = function(eventType as string, properties as object) as object
        parameters = {
            profile: [
                properties.profile
            ]
            type: [
                eventType
            ]
        }
        if properties.doesExist("interactionId")
            parameters["eventSource"] = [
                properties.interactionId
            ]
        end if
        if properties.doesExist("eventId")
            parameters["eventId"] = [
                properties.eventId
            ]
        end if
        if properties.doesExist("timestamp")
            parameters["timestamp"] = [
                properties.timestamp
            ]
        end if
        data = {}
        if properties.doesExist("data") and Type(properties.data) = "roAssociativeArray" and not m._isArray(properties.data)
            data = properties.data
            keys = data.keys()
            for each key in keys
                data[key] = m._ensureArray(data[key])
                nestedPropertyCheck = false
                if Type(data[key]) = "roArray" and data[key].count() > 0 and Type(data[key][0]) = "roAssociativeArray" and Type(data[key][0]) <> "roDateTime"
                    nestedPropertyCheck = true
                end if
                if nestedPropertyCheck
                    for each nestedObject in data[key]
                        if Type(nestedObject) = "roAssociativeArray"
                            nestedKeys = nestedObject.keys()
                            for each nestedKey in nestedKeys
                                nestedObject[nestedKey] = m._ensureArray(nestedObject[nestedKey])
                            end for
                        end if
                    end for
                end if
            end for
        end if
        parameters["data"] = m._ensureArray(FormatJson(data))
        return m._requestCommand("createTimelineEvent", parameters, invalid)
    end function
    ' Method to ensure array
    '
    ' @param value: The value to ensure is an array
    ' @return: An array containing the value if it was not already an array, or the original array
    instance._ensureArray = function(value as dynamic) as object
        if Type(value) <> "roArray"
            return [
                value
            ]
        end if
        return value
    end function
    ' Method to check if value is array
    '
    ' @param value: The value to check
    ' @return: True if the value is an array, false otherwise
    instance._isArray = function(value as dynamic) as boolean
        return Type(value) = "roArray"
    end function
    ' Method to create request command
    '
    ' @param methodName: The name of the method to call
    ' @param parameters: The parameters for the method (optional)
    ' @param nestedParameters: Nested parameters for the method (optional)
    ' @return: The command object for the request
    instance._requestCommand = function(methodName as string, parameters = invalid as object, nestedParameters = invalid as object) as object
        commandObj = {
            methodName: methodName
            parameters: parameters
            nestedParameters: nestedParameters
            id: (CreateObject("roDateTime").asSeconds() + Rnd(10000)).toStr()
            toJson: function(self as object) as string
                request = {
                    method: self.methodName
                    id: self.id
                    params: invalid
                }
                if self.nestedParameters <> invalid then
                    ignoreUnsupportedTypes = &h0100
                    request.params = FormatJson(self.nestedParameters, ignoreUnsupportedTypes)
                else if self.parameters <> invalid then
                    request.params = FormatJson(self.parameters)
                end if
                return FormatJson(request)
            end function
        }
        return commandObj
    end function
    return instance
end function
function BCConnectorCommands()
    instance = __BCConnectorCommands_builder()
    instance.new()
    return instance
end function