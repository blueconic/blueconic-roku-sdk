' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling the storage management for BlueConic.
function __BCStorageManager_builder()
    instance = {}
    instance.new = sub()
    end sub
    ' Method to save data
    '
    ' @param key The key under which the data is stored.
    ' @param value The value to be stored.
    ' @param section The section in which the data is stored.
    ' @param flush Whether to flush the changes immediately (default is true).
    instance.saveData = sub(key as string, value as dynamic, section as string, flush = true as boolean)
        sec = CreateObject("roRegistrySection", section)
        sec.write(key, value.toStr())
        if flush then
            sec.flush()
        end if
    end sub
    ' Method to save data as JSON
    '
    ' @param key The key under which the JSON data is stored.
    ' @param value The object to be stored as JSON.
    ' @param section The section in which the JSON data is stored.
    ' @param flush Whether to flush the changes immediately (default is true).
    instance.saveDataJSON = sub(key as string, value as object, section as string, flush = true as boolean)
        parsedValue = FormatJson(value)
        m.saveData(key, parsedValue, section, flush)
    end sub
    ' Method to delete data
    '
    ' @param key The key of the data to be deleted.
    ' @param section The section from which the data is deleted.
    ' @param flush Whether to flush the changes immediately (default is true).
    instance.deleteData = sub(key as string, section as string, flush = true as boolean)
        sec = CreateObject("roRegistrySection", section)
        sec.delete(key)
        if flush then
            sec.flush()
        end if
    end sub
    ' Method to clear all data
    '
    ' @param section The section from which all data is deleted.
    ' @param flush Whether to flush the changes immediately (default is true).
    instance.deleteAllData = sub(section as string, flush = true as boolean)
        sec = CreateObject("roRegistrySection", section)
        for each key in sec.getKeyList()
            sec.delete(key)
        end for
        if flush then
            sec.flush()
        end if
    end sub
    ' Method to read data
    '
    ' @param key The key of the data to be read.
    ' @param section The section from which the data is read.
    ' @param default The default value to return if the key does not exist (default is invalid).
    ' @return The value associated with the key, or the default value if the key does not exist.
    instance.readData = function(key as string, section as string, default = invalid as dynamic) as dynamic
        sec = CreateObject("roRegistrySection", section)
        if sec.exists(key) then
            return sec.read(key)
        end if
        return default
    end function
    ' Method to read data as integer
    '
    ' @param key The key of the data to be read.
    ' @param section The section from which the data is read.
    ' @param default The default value to return if the key does not exist (default is 0).
    ' @return The integer value associated with the key, or the default value if the key does not exist.
    instance.readDataInt = function(key as string, section as string, default = 0 as integer) as integer
        result = m.readData(key, section, default)
        if Type(result) <> "Integer"
            result = result.toInt()
        end if
        return result
    end function
    ' Method to read data as boolean
    '
    ' @param key The key of the data to be read.
    ' @param section The section from which the data is read.
    ' @param default The default value to return if the key does not exist (default is false).
    ' @return The boolean value associated with the key, or the default value if the key does not exist.
    instance.readDataBoolean = function(key as string, section as string, default = false as boolean) as boolean
        result = m.readData(key, section, default)
        if Type(result) <> "Boolean"
            if result = true.toStr()
                result = true
            else
                result = false
            end if
        end if
        return result
    end function
    ' Method to read data as JSON
    '
    ' @param key The key of the data to be read.
    ' @param section The section from which the data is read.
    ' @param default The default value to return if the key does not exist (default is invalid).
    ' @return The object parsed from the JSON string associated with the key, or the default value if the key does not exist.
    instance.readDataJSON = function(key as string, section as string, default = invalid as dynamic) as object
        result = m.readData(key, section, default)
        if Type(result) = "roAssociativeArray" and result.count() = 0
            return default
        end if
        return ParseJson(result)
    end function
    return instance
end function
function BCStorageManager()
    instance = __BCStorageManager_builder()
    instance.new()
    return instance
end function