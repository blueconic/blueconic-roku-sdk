' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling the BlueConic profile.
function __BCProfile_builder()
    instance = {}
    ' Constructor.
    '
    ' @param client The BlueConic client object that interacts with the profile.
    instance.new = function(client as object)
        m.client = invalid
        m.cache = invalid
        m.client = client
        m.cache = BCCache().createCache()
    end function
    ' Method to set domain group
    '
    ' @param domainGroup The domain group to set for the profile.
    instance.setDomainGroup = sub(domainGroup as string)
        m.cache.setDomainGroup(domainGroup)
    end sub
    ' Method to get domain group
    '
    ' @return The domain group associated with the profile.
    instance.getDomainGroup = function() as string
        return m.cache.getDomainGroup()
    end function
    ' Method to set profile ID
    '
    ' @param profileId The profile ID to set for the profile.
    instance.setProfileId = sub(profileId as string)
        m.cache.storageManager.saveData(BCConstants().STORAGE.BC_PROFILE_ID_NAME, profileId, BCConstants().STORAGE.CACHE)
    end sub
    ' Method to get profile ID
    '
    ' @return The profile ID associated with the profile.
    instance.getId = function() as string
        return m.cache.storageManager.readData(BCConstants().STORAGE.BC_PROFILE_ID_NAME, BCConstants().STORAGE.CACHE, "")
    end function
    ' Method to clear the profile ID
    instance.clearProfileId = sub()
        m.cache.storageManager.deleteData(BCConstants().STORAGE.BC_PROFILE_ID_NAME, BCConstants().STORAGE.CACHE)
        m.cache.storageManager.deleteData(BCConstants().STORAGE.BC_SESSION_COOKIE_NAME, BCConstants().STORAGE.COOKIES)
    end sub
    ' Method to get privacy legislation
    '
    ' @return The privacy legislation associated with the profile.
    instance.getPrivacyLegislation = function() as string
        return m.getValue("privacy_legislation")
    end function
    ' Method to set privacy legislation
    '
    ' @param privacyLegislation The privacy legislation to set for the profile.
    instance.setPrivacyLegislation = sub(privacyLegislation as string)
        if not m.client.isEnabled()
            return
        end if
        m.setValue("privacy_legislation", privacyLegislation)
    end sub
    ' Method to get consented objectives
    '
    ' @return The consented objectives associated with the profile.
    instance.getConsentedObjectives = function() as object
        return m.getValues("consented_objectives")
    end function
    ' Method to set consented objectives
    '
    ' @param consentedObjectives The consented objectives to set for the profile.
    instance.setConsentedObjectives = sub(consentedObjectives as object)
        if not m.client.isEnabled()
            return
        end if
        m.setValues("consented_objectives", consentedObjectives)
    end sub
    ' Method to add consented objective
    '
    ' @param consentedObjectives The consented objective to add to the profile.
    instance.addConsentedObjective = sub(consentedObjectives as string)
        if not m.client.isEnabled()
            return
        end if
        m.addValue("consented_objectives", consentedObjectives)
    end sub
    ' Method to get refused objectives
    '
    ' @return The refused objectives associated with the profile.
    instance.getRefusedObjectives = function() as object
        return m.getValues("refused_objectives")
    end function
    ' Method to set refused objectives
    '
    ' @param refusedObjectives The refused objectives to set for the profile.
    instance.setRefusedObjectives = sub(refusedObjectives as object)
        if not m.client.isEnabled()
            return
        end if
        m.setValues("refused_objectives", refusedObjectives)
    end sub
    ' Method to add refused objective
    '
    ' @param refusedObjectives The refused objective to add to the profile.
    instance.addRefusedObjective = sub(refusedObjectives as string)
        ' Check if client is enabled
        m.addValue("refused_objectives", refusedObjectives)
    end sub
    ' Method to get value
    '
    ' @param property The property for which to get the value.
    ' @return The value associated with the property, or an empty string if not found.
    instance.getValue = function(property as string) as string
        values = m.cache.properties[property]
        if values = invalid or values.count() = 0
            return ""
        else
            return values[0]
        end if
    end function
    ' Method to get values
    '
    ' @param property The property for which to get the values.
    ' @return An array of values associated with the property, or an empty array if not found.
    instance.getValues = function(property as string) as object
        values = m.cache.properties[property]
        if values = invalid
            return []
        end if
        return values
    end function
    ' Method to get all properties
    '
    ' @return An object containing all properties and their values.
    instance.getAllProperties = function() as object
        return m.cache.properties
    end function
    ' Method to add value
    '
    ' @param property The property to which the value should be added.
    ' @param value The value to add to the property.
    instance.addValue = sub(property as string, value as string)
        if not m.client.isEnabled()
            return
        end if
        m.addValues(property, [
            value
        ])
    end sub
    ' Method to add values
    '
    ' @param property The property to which the values should be added.
    ' @param values An array of values to add to the property.
    instance.addValues = sub(property as string, values as object)
        if not m.client.isEnabled()
            return
        end if
        if property = ""
            return
        end if
        m.cache.setProperties(property, values)
        m.client._commitLog.addProperties(property, values)
        m.client.scheduleSendUpdates()
    end sub
    ' Method to set value
    '
    ' @param property The property to set.
    ' @param value The value to set for the property.
    instance.setValue = function(property as string, value as string)
        if value <> ""
            m.setValues(property, [
                value
            ])
        else
            m.setValues(property, [])
        end if
    end function
    ' Method to set values
    '
    ' @param property The property to set.
    ' @param values An array of values to set for the property.
    instance.setValues = sub(property as string, values as object)
        if not m.client.isEnabled()
            return
        end if
        if property = ""
            return
        end if
        m.cache.setProperties(property, values)
        m.client._commitLog.setProperties(property, values)
        m.client.scheduleSendUpdates()
    end sub
    ' Method to increment value
    '
    ' @param property The property to increment.
    ' @param value The value to increment by.
    instance.incrementValue = sub(property as string, value as integer)
        if not m.client.isEnabled()
            return
        end if
        if property = ""
            return
        end if
        valueStr = value.toStr()
        m.client._commitLog.incrementProperty(property, valueStr)
        m.client.scheduleSendUpdates()
    end sub
    ' Method to reset state
    '
    ' @param profileProperties An object containing properties to reset in the profile.
    instance._resetState = sub(profileProperties as object)
        if not m.client.isEnabled()
            return
        end if
        m.client._commitLog.clearAll()
        m.client._requestLog.clearAll()
        m.cache.clearProperties()
        for each key in profileProperties.keys()
            value = profileProperties[key]
            m.cache.setProperties(key, value)
        end for
    end sub
    ' Method to update profile
    instance._updateProfile = sub()
        if not m.client.isEnabled()
            return
        end if
        m.client.scheduleSendUpdates()
    end sub
    ' Method to reload profile
    instance._reloadProfile = sub()
        if not m.client.isEnabled()
            return
        end if
        conCommands = BCRPCConnectorCommands()
        commands = []
        getProfileCommand = conCommands.getProfileCommand()
        commands.push(getProfileCommand)
        getPropertiesCommand = conCommands.getGetPropertiesCommand("", invalid)
        commands.push(getPropertiesCommand)
        responses = m.client._rpcConnector.execute(m.client._appId, m.client._hostname, m.client._zoneId, commands, m.getDomainGroup(), m.client._simulatorData)
        responseParserObj = BCResponseParser()
        responseParserObj.handleGetProfileResponse(responses.getById(getProfileCommand.id), m.client)
        getPropertiesResponse = responses.getById(getPropertiesCommand.id)
        if getPropertiesResponse <> invalid
            responseParserObj.handleGetPropertiesResponse(getPropertiesResponse, m)
            m._resetState(getPropertiesResponse.properties)
        end if
    end sub
    ' Method to delete profile
    instance._deleteProfile = sub()
        if not m.client.isEnabled()
            return
        end if
        conCommands = BCRPCConnectorCommands()
        commands = []
        deleteProfileCommand = conCommands.deleteProfileCommand()
        commands.push(deleteProfileCommand)
        responses = m.client._rpcConnector.execute(m.client._appId, m.client._hostname, m.client._zoneId, commands, m.getDomainGroup(), m.client._simulatorData)
        responseParserObj = BCResponseParser()
        responseParserObj.handleDeleteProfileResponse(responses.getById(deleteProfileCommand.id), m)
        m.clearProfileId()
        m._resetState({})
    end sub
    return instance
end function
function BCProfile(client as object)
    instance = __BCProfile_builder()
    instance.new(client)
    return instance
end function