' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class to handle BlueConic responses
function __BCResponse_builder()
    instance = {}
    ' Constructor.
    '
    ' @param singleMap: A map containing single properties
    ' @param nestedMap: A map containing nested properties
    ' @param properties: A map containing properties
    ' @param interactions: An array of interaction objects
    ' @param connections: An array of connection objects
    ' @param segments: An array of segment objects
    instance.new = function(singleMap as object, nestedMap as object, properties as object, interactions as object, connections as object, segments as object)
        m.singleMap = invalid
        m.nestedMap = invalid
        m.properties = invalid
        m.interactions = invalid
        m.connections = invalid
        m.segments = invalid
        m.singleMap = singleMap
        m.nestedMap = nestedMap
        m.properties = properties
        m.interactions = interactions
        m.connections = connections
        m.segments = segments
    end function
    ' Method to get labels
    '
    ' @return: A map of labels, excluding the "result" property if it exists
    instance.getLabels = function() as object
        labels = m.nestedMap
        ' Remove the "result" property if it exists
        if labels.doesExist("result")
            labels.delete("result")
        end if
        return labels
    end function
    return instance
end function
function BCResponse(singleMap as object, nestedMap as object, properties as object, interactions as object, connections as object, segments as object)
    instance = __BCResponse_builder()
    instance.new(singleMap, nestedMap, properties, interactions, connections, segments)
    return instance
end function
' Class to handle a collection of BlueConic responses
function __BCResponsesContainer_builder()
    instance = {}
    ' Constructor
    '
    ' @param responsesValues: An object containing response values
    instance.new = function(responsesValues as object)
        m.responses = invalid
        m.responses = responsesValues
    end function
    ' Method to get response by ID
    '
    ' @param id: The ID of the response to retrieve
    ' @return: The response object if found, otherwise invalid
    instance.getById = function(id as string) as object
        for each response in m.responses
            if response.singleMap.doesExist("id") and response.singleMap["id"] = id
                return response
            end if
        end for
        return invalid
    end function
    return instance
end function
function BCResponsesContainer(responsesValues as object)
    instance = __BCResponsesContainer_builder()
    instance.new(responsesValues)
    return instance
end function
' Class to parse BlueConic responses
function __BCResponseParser_builder()
    instance = {}
    instance.new = sub()
    end sub
    ' Method to get a connection object from a JSON element
    '
    ' @param element: The JSON element containing connection data
    ' @return: A BCConnection object with the parsed data
    instance.getConnection = function(element as object) as object
        id = ""
        paramResult = {}
        jsonObject = element
        for each key in jsonObject.keys()
            value = jsonObject[key]
            if Type(value) = "String" or Type(value) = "roString"
                if key = "id"
                    id = value
                end if
            else
                if LCase(key) = "parameters"
                    for each nextValue in value
                        parameters = nextValue["parameter"]
                        paramResult = m.getParameters(parameters)
                    end for
                end if
            end if
        end for
        return BCConnection(id, paramResult)
    end function
    ' Method to get a segment object from a JSON element
    '
    ' @param element: The JSON element containing segment data
    ' @return: A BCSegment object with the parsed data
    instance.getSegment = function(element as object) as object
        id = ""
        name = ""
        jsonObject = element
        for each key in jsonObject.keys()
            value = jsonObject[key]
            if Type(value) = "String" or Type(value) = "roString"
                if key = "id"
                    id = value
                else if key = "name"
                    name = value
                end if
            end if
        end for
        return BCSegment(id, name)
    end function
    ' Method to get an interaction object from a JSON element
    '
    ' @param element: The JSON element containing interaction data
    ' @return: A BCInteraction object with the parsed data
    instance.getInteraction = function(element as object) as object
        fields = {
            "myInteractionTypeId": "interactionTypeId"
            "position": "positionId"
            "pluginClass": "pluginClass"
            "id": "id"
            "defaultLocale": "defaultLocale"
            "name": "name"
            "positionName": "positionName"
            "myPluginType": "pluginType"
            "dialogueId": "dialogueId"
            "dialogueName": "dialogueName"
        }
        result = {
            id: ""
            name: ""
            interactionTypeId: ""
            positionId: ""
            positionName: ""
            pluginClass: ""
            pluginType: ""
            dialogueId: ""
            dialogueName: ""
            defaultLocale: ""
            paramResult: {}
        }
        for each key in element.keys()
            value = element[key]
            if (Type(value) = "String" or Type(value) = "roString") and fields.doesExist(key)
                result[fields[key]] = value
            else if LCase(key) = "parameters"
                for each nextValue in value
                    locale = nextValue["locale"]
                    parameters = nextValue["parameter"]
                    result.paramResult[locale] = m.getParameters(parameters)
                end for
            end if
        end for
        return BCInteraction(result.id, result.name, result.interactionTypeId, result.pluginClass, result.pluginType, result.positionId, result.positionName, result.dialogueId, result.dialogueName, result.defaultLocale, result.paramResult)
    end function
    ' Method to get parameters from a JSON object
    '
    ' @param parameters: An object containing parameter data
    ' @return: A map of parameter IDs to their values
    instance.getParameters = function(parameters as object) as object
        result = {}
        for each parameter in parameters
            param = parameter
            id = param["id"]
            values = []
            for each element in param["value"]
                values.push(element.toStr())
            end for
            result[id] = values
        end for
        return result
    end function
    ' Method to parse a JSON element into a BCResponse object
    '
    ' @param jsonElement: The JSON element to parse
    ' @return: A BCResponse object containing the parsed data
    instance.parse = function(jsonElement as object) as object
        singleMap = {}
        nestedMap = {}
        properties = {}
        interactions = []
        connections = []
        segments = []
        for each key in jsonElement.keys()
            value = jsonElement[key]
            if Type(value) <> "roArray" and Type(value) <> "roAssociativeArray"
                singleMap[key] = value.toStr()
            else
                map = {}
                for each nestedKey in value.keys()
                    nestedValue = value[nestedKey]
                    if Type(nestedValue) <> "roArray" and Type(nestedValue) <> "roAssociativeArray"
                        map[nestedKey] = nestedValue.toStr()
                    else
                        m.handleNestedKey(nestedKey, nestedValue, properties, nestedMap, interactions, connections, segments)
                    end if
                end for
                nestedMap[key] = map
            end if
        end for
        return BCResponse(singleMap, nestedMap, properties, interactions, connections, segments)
    end function
    ' Method to handle nested keys in the JSON element
    '
    ' @param nestedKey: The key of the nested element
    ' @param nestedValue: The value of the nested element
    ' @param properties: The properties map to update
    ' @param nestedMap: The nested map to update
    ' @param interactions: The interactions array to update
    ' @param connections: The connections array to update
    ' @param segments: The segments array to update
    instance.handleNestedKey = sub(nestedKey as string, nestedValue as object, properties as object, nestedMap as object, interactions as object, connections as object, segments as object)
        if nestedKey = "properties"
            for each langId in nestedValue.keys()
                value = nestedValue[langId]
                if Type(value) = "roArray"
                    val = []
                    for each jsonElement in value
                        val.push(jsonElement.toStr())
                    end for
                    properties[langId] = val
                else
                    labels = {}
                    for each key in value.keys()
                        languageValue = value[key]
                        labels[key] = languageValue.toStr()
                    end for
                    nestedMap[langId] = labels
                end if
            end for
        else if nestedKey = "interactions"
            m.processNestedArray(nestedValue, interactions, "interaction")
        else if nestedKey = "connections"
            m.processNestedArray(nestedValue, connections, "connection")
        else if nestedKey = "segments"
            m.processNestedArray(nestedValue, segments, "segment")
        end if
    end sub
    ' Method to process a nested array and populate the result array based on the value type
    '
    ' @param nestedArray: The nested array to process
    ' @param resultArray: The array to populate with processed values
    ' @param valueType: The type of values to process ("interaction", "connection", or "segment")
    instance.processNestedArray = sub(nestedArray as object, resultArray as object, valueType as string)
        for each nextValue in nestedArray
            if Type(nextValue) = "String" or Type(nextValue) = "Int" or Type(nextValue) = "Float" or Type(nextValue) = "Boolean"
                ' Skip adding to resultArray, as it is not an object
            else
                if valueType = "interaction"
                    resultArray.push(m.getInteraction(nextValue))
                else if valueType = "connection"
                    resultArray.push(m.getConnection(nextValue))
                else if valueType = "segment"
                    resultArray.push(m.getSegment(nextValue))
                end if
            end if
        end for
    end sub
    ' Method to handle the response for getting a profile
    '
    ' @param response: The response object containing the profile data
    ' @param profile: The profile object to update
    ' @return: True if the profile was successfully updated, otherwise false
    instance.handleGetProfileResponse = function(response as object, client as object) as boolean
        if response = invalid
            return false
        end if
        map = response.singleMap
        results = response.nestedMap["result"]
        if results = invalid
            return false
        end if
        domainGroupId = results["domainGroupId"]
        if domainGroupId = invalid
            return false
        end if
        BCLogInfo("DomainGroupId: " + domainGroupId)
        client.profile().setDomainGroup(domainGroupId)
        zoneId = map["zoneId"]
        client.setZoneId(zoneId)
        profileId = map["profileId"]
        if profileId = invalid or profileId = ""
            return false
        else
            return m.handleProfileId(profileId, client.profile())
        end if
    end function
    ' Method to handle the response for setting a profile ID
    '
    ' @param profileId: The profile ID to set
    ' @param profile: The profile object to update
    ' @return: True if the profile ID was successfully set, otherwise false
    instance.handleProfileId = function(profileId as string, profile as object) as boolean
        if profileId = invalid or profileId = ""
            return false
        end if
        ' Get currently stored profile id.
        currentProfileId = profile.getId()
        BCLogInfo("Recieved profileId: '" + profileId + "' while currentProfileId: '" + currentProfileId + "'")
        if profileId = currentProfileId
            return false
        end if
        profile.setProfileId(profileId)
        ' Read back the set cookie. This is to verify the cookie could be set.
        profileFromCookie = profile.getId()
        if profileId = profileFromCookie
            BCLogInfo("ProfileId changed to '" + profileId + "' and is successfully stored, start reloading the properties.")
            return true
        end if
        BCLogWarning("Set cookie failed: " + profileId + " != " + profileFromCookie)
        return false
    end function
    ' Method to handle the response for deleting a profile
    '
    ' @param response: The response object containing the deletion result
    ' @param profile: The profile object to update
    ' @return: True if the profile was successfully deleted, otherwise false
    instance.handleDeleteProfileResponse = function(response as object, profile as object) as boolean
        if response = invalid
            return false
        end if
        results = response.nestedMap["result"]
        if results = invalid
            return false
        end if
        domainGroupId = results["domainGroupId"]
        if domainGroupId = invalid
            return false
        end if
        BCLogInfo("DomainGroupId: " + domainGroupId)
        profile.setDomainGroup(domainGroupId)
        return m.handleProfileId("", profile)
    end function
    ' Method to handle the response for getting properties
    '
    ' @param response: The response object containing the properties data
    ' @param profile: The profile object to update with the properties
    instance.handleGetPropertiesResponse = sub(response as object, profile as object)
        if response = invalid
            return
        end if
        properties = response.properties
        for each key in properties
            value = properties[key]
            profile.cache.setProperties(key, value)
        end for
        BCLogInfo("Updated properties: " + properties.keys().join(", "))
    end sub
    ' Method to handle the response for getting interactions
    '
    ' @param response: The response object containing the interactions data
    ' @param client: The client object to update with the interactions
    ' @return: An array of interaction instances created from the response
    instance.handleGetInteractionsResponse = function(response as object, client as object) as object
        if response = invalid
            return []
        end if
        segments = response.segments
        client.setSegments(segments)
        connections = response.connections
        instances = []
        interactions = response.interactions
        for each interactionEntry in interactions
            pluginClass = client._pluginsManager.getPlugin(interactionEntry.interactionTypeId, interactionEntry.dialogueId)
            print interactionEntry
            if pluginClass = invalid
                BCLogWarning("Plugin class '" + interactionEntry.pluginClass + "' not found for type id '" + interactionEntry.interactionTypeId + " and id '" + interactionEntry.id + "'")
            else
                interactionContext = BCInteractionContext(interactionEntry, connections, client._locale)
                instance = pluginClass.init(client, interactionContext)
                instances.push(instance)
            end if
        end for
        return instances
    end function
    return instance
end function
function BCResponseParser()
    instance = __BCResponseParser_builder()
    instance.new()
    return instance
end function
' Classes to represent BlueConic connection
function __BCConnection_builder()
    instance = {}
    ' Constructor.
    '
    ' @param id: The ID of the connection
    ' @param paramResult: A map containing parameter results
    instance.new = function(id as string, paramResult as object)
        m.id = invalid
        m.paramResult = invalid
        m.id = id
        m.paramResult = paramResult
    end function
    return instance
end function
function BCConnection(id as string, paramResult as object)
    instance = __BCConnection_builder()
    instance.new(id, paramResult)
    return instance
end function
' Classes to represent BlueConic segment
function __BCSegment_builder()
    instance = {}
    ' Constructor.
    '
    ' @param id: The ID of the segment
    ' @param name: The name of the segment
    instance.new = function(id as string, name as string)
        m.id = invalid
        m.name = invalid
        m.id = id
        m.name = name
    end function
    return instance
end function
function BCSegment(id as string, name as string)
    instance = __BCSegment_builder()
    instance.new(id, name)
    return instance
end function
' Classes to represent BlueConic interaction
function __BCInteraction_builder()
    instance = {}
    ' Constructor.
    '
    ' @param id: The ID of the interaction
    ' @param name: The name of the interaction
    ' @param interactionTypeId: The interaction type ID
    ' @param pluginClass: The plugin class associated with the interaction
    ' @param pluginType: The plugin type associated with the interaction
    ' @param positionId: The position ID of the interaction
    ' @param positionName: The position name of the interaction
    ' @param dialogueId: The dialogue ID of the interaction
    ' @param dialogueName: The dialogue name of the interaction
    ' @param defaultLocale: The default locale for the interaction
    ' @param paramResult: A map containing parameter results for the interaction
    instance.new = function(id as string, name as string, interactionTypeId as string, pluginClass as string, pluginType as string, positionId as string, positionName as string, dialogueId as string, dialogueName as string, defaultLocale as string, paramResult as object)
        m.id = invalid
        m.name = invalid
        m.interactionTypeId = invalid
        m.pluginClass = invalid
        m.pluginType = invalid
        m.positionId = invalid
        m.positionName = invalid
        m.dialogueId = invalid
        m.dialogueName = invalid
        m.defaultLocale = invalid
        m.paramResult = invalid
        m.id = id
        m.name = name
        m.interactionTypeId = interactionTypeId
        m.pluginClass = pluginClass
        m.pluginType = pluginType
        m.positionId = positionId
        m.positionName = positionName
        m.dialogueId = dialogueId
        m.dialogueName = dialogueName
        m.defaultLocale = defaultLocale
        m.paramResult = paramResult
    end function
    return instance
end function
function BCInteraction(id as string, name as string, interactionTypeId as string, pluginClass as string, pluginType as string, positionId as string, positionName as string, dialogueId as string, dialogueName as string, defaultLocale as string, paramResult as object)
    instance = __BCInteraction_builder()
    instance.new(id, name, interactionTypeId, pluginClass, pluginType, positionId, positionName, dialogueId, dialogueName, defaultLocale, paramResult)
    return instance
end function