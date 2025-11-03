' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling the BlueConic cache.
function __BCCache_builder()
    instance = {}
    ' Constructor
    instance.new = function()
        m.properties = invalid
        m.propertiesLabels = invalid
        m.domainGroup = invalid
        m.storageManager = invalid
        m.SEPARATOR = ";"
        m.M = 10000
        m.properties = {}
        m.propertiesLabels = {}
        m.domainGroup = "DEFAULT"
        m.storageManager = BCStorageManager()
    end function
    ' Creates a new cache instance.
    '
    ' @return A new cache object.
    instance.createCache = function() as object
        m.properties = m.storageManager.readDataJSON(BCConstants().STORAGE.BC_PROFILE_PROPERTIES_NAME, BCConstants().STORAGE.CACHE, {})
        return m
    end function
    ' Retrieves the domain group from the cache.
    '
    ' @return The domain group associated with the cache.
    instance.getDomainGroup = function() as string
        m.domainGroup = m.storageManager.readData(BCConstants().STORAGE.BC_DOMAIN_GROUP_NAME, BCConstants().STORAGE.CACHE, "DEFAULT")
        return m.domainGroup
    end function
    ' Sets the domain group in the cache.
    '
    ' @param domainGroup The domain group to set.
    instance.setDomainGroup = sub(domainGroup as string)
        m.domainGroup = domainGroup
        m.storageManager.saveData(BCConstants().STORAGE.BC_DOMAIN_GROUP_NAME, m.domainGroup, BCConstants().STORAGE.CACHE)
    end sub
    ' Sets the properties for a given key.
    '
    ' @param key The key for the property.
    ' @param value The value to set for the property.
    instance.setProperties = sub(key as string, value as object)
        if m.properties = invalid or Type(m.properties) <> "roAssociativeArray"
            m.properties = {}
        end if
        if key = invalid or key = ""
            return
        end if
        if value = invalid
            return
        end if
        m.properties[key] = value
        m.saveCache()
    end sub
    ' Clears the properties from the cache.
    instance.clearProperties = sub()
        m.properties = {}
        m.storageManager.deleteData(BCConstants().STORAGE.BC_PROFILE_PROPERTIES_NAME, BCConstants().STORAGE.CACHE)
    end sub
    ' Saves the current state of the cache.
    instance.saveCache = sub()
        m.storageManager.saveData(BCConstants().STORAGE.BC_DOMAIN_GROUP_NAME, m.domainGroup, BCConstants().STORAGE.CACHE)
        m.storageManager.saveDataJSON(BCConstants().STORAGE.BC_PROFILE_PROPERTIES_NAME, m.properties, BCConstants().STORAGE.CACHE)
    end sub
    ' Retrieves the property ids for the properties in the cache.
    '
    ' @return A list of property ids.
    instance.getPropertiesIds = function() as object
        return m.properties.keys()
    end function
    ' Returns the hash for all properties in a map. Entries are separated by a ';'.
    '
    ' @return A string representing the hash of all properties.
    instance.getHash = function() as string
        if m.properties = invalid
            return ""
        end if
        hashString = ""
        for each key in m.properties.keys()
            value = m.properties[key]
            propertyHash = m._getPropertyHash(key, value)
            if propertyHash <> ""
                hashString = hashString + propertyHash + m.SEPARATOR
            end if
        end for
        return hashString
    end function
    ' Returns the hash value for a single property and its values.
    '
    ' @param id The property id.
    ' @param values The values associated with the property.
    ' @return A string representing the hash of the property values.
    instance._getPropertyHash = function(id as string, values as object) as string
        if values = invalid
            return ""
        end if
        hash = m._getStringHash(id)
        for each value in values
            if Type(value) = "String"
                hash = hash + m._getStringHash(value)
            end if
        end for
        return (hash Mod m.M).toStr()
    end function
    ' Hashing method for a single string.
    '
    ' @param input The string to hash.
    ' @return An integer representing the hash of the string.
    instance._getStringHash = function(input as string) as integer
        hash = 0
        for i = 0 to Len(input) - 1
            hash = hash + Asc(Mid(input, i + 1, 1))
        end for
        return hash Mod m.M
    end function
    return instance
end function
function BCCache()
    instance = __BCCache_builder()
    instance.new()
    return instance
end function