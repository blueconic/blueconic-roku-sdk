' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling the preferred hour of a user based on the current time.
function __BCPreferredHourListener_builder()
    instance = __BCPlugin_builder()
    instance.super0_new = instance.new
    instance.new = sub()
        m.super0_new()
        m._PARAMETER_PROPERTY = "property"
        m._PARAMETER_LOCALE = "locale"
        m._TAG_PROFILE_PROPERTY = "profileproperty"
        m._DATA = "data"
        m._TIME = "TIME"
        m._PROFILE_VALUE_PREFIX = "_hl_"
    end sub
    ' Constants
    instance.super0_onLoad = instance.onLoad
    instance.onLoad = sub()
        propertyJson = m._getParameterValue(m._PARAMETER_PROPERTY)
        locale = m._getParameterValue(m._PARAMETER_LOCALE)
        if propertyJson <> invalid
            propertyArray = ParseJson(propertyJson)
            if propertyArray <> invalid and propertyArray.count() > 0
                property = propertyArray[0]
                propertyId = property[m._TAG_PROFILE_PROPERTY]
                if propertyId <> invalid
                    baseDate = CreateObject("roDateTime")
                    baseDate.fromSeconds(1325372400)
                    currentDate = CreateObject("roDateTime")
                    currentDate.mark()
                    diffSeconds = currentDate.asSeconds() - baseDate.asSeconds()
                    days = Fix(diffSeconds / 86400)
                    now = CreateObject("roDateTime")
                    now.mark()
                    hour = now.getHours()
                    timeFrame = m._getTimeFrame(hour, locale)
                    dataObj = {}
                    dataObj.p = 1
                    dataObj.d = days
                    dataObj.n = timeFrame
                    dataArray = []
                    dataArray.push(dataObj)
                    valueObj = {}
                    valueObj[m._TIME] = now.asSecondsLong() * 1000
                    valueObj[m._DATA] = dataArray
                    valueJson = FormatJson(valueObj)
                    m._client.profile().addValue(m._PROFILE_VALUE_PREFIX + propertyId, valueJson)
                end if
            end if
        end if
    end sub
    instance.super0_onDestroy = instance.onDestroy
    instance.onDestroy = sub()
    end sub
    ' Returns the time frame for the given hour in the specified locale.
    '
    ' @param hour The hour for which to get the time frame.
    ' @param locale The locale to use for formatting the time.
    ' @return The formatted time frame string.
    instance._getTimeFrame = function(hour as integer, locale as dynamic) as string
        return m._getHour(hour, locale) + " - " + m._getHour(hour + 1, locale)
    end function
    ' Returns the formatted hour string based on the locale.
    '
    ' @param hour The hour to format.
    ' @param locale The locale to use for formatting.
    ' @return The formatted hour string.
    instance._getHour = function(hour as integer, locale as dynamic) as string
        formattedHour = ""
        localHour = hour
        if locale = "en-us"
            amPm = "AM"
            if localHour >= 12
                amPm = "PM"
                localHour = localHour MOD 12
            end if
            if localHour = 0
                localHour = 12
            end if
            formattedHour = localHour.toStr() + " " + amPm
        else
            hourString = localHour.toStr()
            if localHour < 10
                hourString = "0" + hourString
            end if
            formattedHour = hourString + ":00"
        end if
        return formattedHour
    end function
    ' Retrieves the value of a parameter by its ID from the interaction context.
    '
    ' @param id The ID of the parameter to retrieve.
    ' @return The value of the parameter if found, otherwise invalid.
    instance._getParameterValue = function(id as string) as dynamic
        parameters = m._interactionContext.getParameters()
        if parameters <> invalid and parameters[id] <> invalid
            values = parameters[id]
            if values <> invalid and values.count() > 0
                return values[0]
            end if
        end if
        return invalid
    end function
    return instance
end function
function BCPreferredHourListener()
    instance = __BCPreferredHourListener_builder()
    instance.new()
    return instance
end function