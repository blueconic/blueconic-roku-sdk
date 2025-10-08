' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling the visit listener functionality in BlueConic.
function __BCVisitListener_builder()
    instance = __BCPlugin_builder()
    instance.super0_new = instance.new
    instance.new = sub()
        m.super0_new()
        m.visitHistoryProperty = invalid
        m.VISIT_EXPIRE_INTERVAL = 30
        m.VISITS_PROPERTY = "visits_property"
        m.NR_VISITS = "nr_visits"
        m.NR_DAYS = "nr_days"
        m.NR_VISITS_PROPERTY = "nr_visits_property"
        m.TOTAL_VISITS_PROPERTY = "total_visits_property"
        m.START_SESSION_PROPERTY = "start_session_property"
        m.NR_PAGE_VIEWS_PROPERTY = "nr_page_views_property"
        m.SESSION_PAGE_VIEWS_PROPERTY = "session_page_views_property"
        m.FIRST_VISIT_DATE_PROPERTY = "first_visit_date_property"
        m.LAST_VISIT_DATE_PROPERTY = "last_visit_date_property"
        m.AVERAGE_VISIT_TIME_PROPERTY = "average_visit_time_property"
        m.TOTAL_VISIT_TIME_PROPERTY = "total_visit_time_property"
        m.DIRECT_VISITS_ONLY = "directVisitsOnly"
        m.visitsProperty = invalid
        m.nrVisits = 100
        m.nrDays = 30
        m.nrVisitsProperty = invalid
        m.totalVisitsProperty = invalid
        m.startSessionProperty = invalid
        m.nrPageViewsProperty = invalid
        m.sessionPageViewsProperty = invalid
        m.firstVisitDateProperty = invalid
        m.lastVisitDateProperty = invalid
        m.averageVisitTimeProperty = invalid
        m.totalVisitTimeProperty = invalid
        m.directVisitsOnly = false
    end sub
    ' Visit listener property keys
    instance.super0_onLoad = instance.onLoad
    instance.onLoad = sub()
        m.visitHistoryProperty = "_vl_" + m._interactionContext.getInteractionId()
        ' property which will hold the visit timestamps
        m.visitsProperty = m._getParameterValue(m.VISITS_PROPERTY)
        ' maximum number of visits to keep track off
        if m._interactionContext.getParameters()[m.NR_VISITS] <> invalid and m._interactionContext.getParameters()[m.NR_VISITS].Count() > 0
            value = m._interactionContext.getParameters()[m.NR_VISITS][0]
            if Str(Val(value)) <> "0" or value = "0"
                m.nrVisits = Val(value)
            end if
        end if
        ' maximum number of days to keep track off
        if m._interactionContext.getParameters()[m.NR_DAYS] <> invalid and m._interactionContext.getParameters()[m.NR_DAYS].Count() > 0
            value = m._interactionContext.getParameters()[m.NR_DAYS][0]
            if Str(Val(value)) <> "0" or value = "0"
                m.nrDays = Val(value)
            end if
        end if
        ' property which will hold the number of visits for the configured amount of days
        m.nrVisitsProperty = m._getParameterValue(m.NR_VISITS_PROPERTY)
        ' property which will hold the total number of visits
        m.totalVisitsProperty = m._getParameterValue(m.TOTAL_VISITS_PROPERTY)
        ' property which will hold the session start
        m.startSessionProperty = m._getParameterValue(m.START_SESSION_PROPERTY)
        ' property which will hold the number of page views (total)
        m.nrPageViewsProperty = m._getParameterValue(m.NR_PAGE_VIEWS_PROPERTY)
        ' property which will hold the number of page views for the current visit/session
        m.sessionPageViewsProperty = m._getParameterValue(m.SESSION_PAGE_VIEWS_PROPERTY)
        ' property which will hold the first visited date
        m.firstVisitDateProperty = m._getParameterValue(m.FIRST_VISIT_DATE_PROPERTY)
        ' property which will hold the last visited date
        m.lastVisitDateProperty = m._getParameterValue(m.LAST_VISIT_DATE_PROPERTY)
        ' property which will hold the average visit time
        m.averageVisitTimeProperty = m._getParameterValue(m.AVERAGE_VISIT_TIME_PROPERTY)
        ' property which will hold the total visit time
        m.totalVisitTimeProperty = m._getParameterValue(m.TOTAL_VISIT_TIME_PROPERTY)
        ' only track data for direct visits
        m.directVisitsOnly = false
        if m._interactionContext.getParameters()[m.DIRECT_VISITS_ONLY] <> invalid and m._interactionContext.getParameters()[m.DIRECT_VISITS_ONLY].Count() > 0
            value = m._interactionContext.getParameters()[m.DIRECT_VISITS_ONLY][0]
            m.directVisitsOnly = (LCase(value) = "true")
        end if
        m._handleNewPageView()
    end sub
    instance.super0_onDestroy = instance.onDestroy
    instance.onDestroy = sub()
    end sub
    ' Handles a new page view event.
    instance._handleNewPageView = sub()
        ' Get current time
        now = CreateObject("roDateTime")
        ' Get the visit history
        visitsHistory = m._getVisitsHistory()
        ' Determine if this is a new visit
        isNewVisit = true
        if visitsHistory.lastVisit > 0
            ' Returning visitor, check if the last known visit has expired
            visitExpireDate = CreateObject("roDateTime")
            visitExpireDate.fromSeconds(visitsHistory.lastVisit / 1000) ' Convert ms to seconds
            ' Add VISIT_EXPIRE_INTERVAL minutes to the last visit time
            visitExpireSeconds = visitExpireDate.asSeconds() + (m.VISIT_EXPIRE_INTERVAL * 60)
            isNewVisit = (now.asSeconds() > visitExpireSeconds)
        end if
        ' Check for direct visits only condition
        if m.directVisitsOnly and isNewVisit
            referrerUrl = m._client.profile().getValue("referrerUrl")
            if referrerUrl <> invalid and referrerUrl <> ""
                ' No direct visit, abort
                return
            end if
        end if
        ' Handle visit based on whether it's new or existing
        if isNewVisit
            m._handleNewVisit(visitsHistory, now)
        else
            m._handleExistingVisit(visitsHistory, now)
        end if
        ' Increment global page view counter
        visitsHistory.pageViews = visitsHistory.pageViews + 1
        if m.nrPageViewsProperty <> ""
            ' Increment page view total in profile
            m._client.profile().setValue(m.nrPageViewsProperty, visitsHistory.pageViews.toStr())
        end if
        ' Include the new visit
        if visitsHistory.firstVisit = 0
            ' Init first visit date
            visitsHistory.firstVisit = now.asSecondsLong() * 1000 ' Store as milliseconds
            if m.firstVisitDateProperty <> ""
                m._client.profile().setValue(m.firstVisitDateProperty, visitsHistory.firstVisit.toStr())
            end if
        end if
        ' Update the last visited date
        visitsHistory.lastVisit = now.asSecondsLong() * 1000 ' Store as milliseconds
        if m.lastVisitDateProperty <> ""
            m._client.profile().setValue(m.lastVisitDateProperty, visitsHistory.lastVisit.toStr())
        end if
        ' Persist updated history object in the profile
        m._client.profile().setValue(m.visitHistoryProperty, FormatJson(visitsHistory))
    end sub
    ' Handles a new visit or updates an existing visit in the profile.
    '
    ' @param visitsHistory The visit history object containing visit data.
    ' @param now The current time as an roDateTime object.
    instance._handleNewVisit = sub(visitsHistory as object, now as object)
        ' Increment visits and set session info
        visitsHistory.visits = visitsHistory.visits + 1
        visitsHistory.sessionStart = now.asSecondsLong() * 1000 ' Convert to ms 
        visitsHistory.sessionPageViews = 1
        if m.startSessionProperty <> ""
            ' Init start of session
            m._client.profile().setValue(m.startSessionProperty, visitsHistory.sessionStart.toStr())
        end if
        if m.sessionPageViewsProperty <> ""
            ' Init page view count for this visit in the profile
            m._client.profile().setValue(m.sessionPageViewsProperty, visitsHistory.sessionPageViews.toStr())
        end if
        if m.totalVisitsProperty <> ""
            m._client.profile().setValue(m.totalVisitsProperty, visitsHistory.visits.toStr())
        end if
        if m.visitsProperty <> ""
            ' Add the current visit timestamp in the profile
            visitTimestamps = m._client.profile().getValues(m.visitsProperty)
            if visitTimestamps = invalid
                visitTimestamps = []
            end if
            ' Current timestamp
            nowTimestamp = (now.asSecondsLong() * 1000).toStr()
            ' Add new timestamp to the beginning
            newVisitTimestamps = [
                nowTimestamp
            ]
            for each timestamp in visitTimestamps
                newVisitTimestamps.push(timestamp)
            end for
            visitTimestamps = newVisitTimestamps
            if visitTimestamps.count() <= m.nrVisits
                ' Add the new timestamp if we're under the limit
                m._client.profile().addValue(m.visitsProperty, nowTimestamp)
            else
                ' Sort timestamps descending
                sortedTimestamps = m._sortTimestampsDescending(visitTimestamps)
                ' Slice to match configured maximum number
                trimmedTimestamps = []
                for i = 0 to m.nrVisits - 1
                    if i < sortedTimestamps.count()
                        trimmedTimestamps.push(sortedTimestamps[i])
                    end if
                end for
                ' Update profile with trimmed list
                m._client.profile().setValues(m.visitsProperty, trimmedTimestamps)
            end if
            if m.nrVisitsProperty <> ""
                ' Calculate oldest date to consider (now - nrDays)
                nowMs = now.asSecondsLong() * 1000
                ' Calculate seconds for nrDays (days * 24hrs * 60min * 60sec)
                dayInSeconds = 24 * 60 * 60
                oldestDateSeconds = now.asSeconds() - (m.nrDays * dayInSeconds)
                ' Create a new date object with the calculated time
                oldestDate = CreateObject("roDateTime")
                oldestDate.fromSeconds(oldestDateSeconds)
                oldestDateMs = oldestDate.asSecondsLong() * 1000
                maxAge = nowMs - oldestDateMs
                ' Count visits within time period
                recentVisits = 0
                for each timestamp in visitTimestamps
                    timestampValue = Val(timestamp) ' Convert string to number
                    if (nowMs - timestampValue) < maxAge
                        recentVisits = recentVisits + 1
                    end if
                end for
                ' Update profile with count of recent visits
                m._client.profile().setValue(m.nrVisitsProperty, recentVisits.toStr())
            end if
        end if
    end sub
    ' Handles an existing visit, updating the visit history accordingly.
    '
    ' @param visitsHistory The visit history object containing visit data.
    ' @param now The current time as an roDateTime object.
    instance._handleExistingVisit = sub(visitsHistory as object, now as object)
        ' Increment session page views
        visitsHistory.sessionPageViews = visitsHistory.sessionPageViews + 1
        if m.sessionPageViewsProperty <> ""
            ' Increment page view for this visit in the profile
            m._client.profile().setValue(m.sessionPageViewsProperty, visitsHistory.sessionPageViews.toStr())
        end if
        ' Update time spent (in minutes)
        timeSpent = (now.asSecondsLong() * 1000 - visitsHistory.lastVisit) / 1000 / 60
        visitsHistory.totalVisitTime = visitsHistory.totalVisitTime + timeSpent
        if m.totalVisitTimeProperty <> ""
            ' Use Int() with +0.5 for proper rounding
            m._client.profile().setValue(m.totalVisitTimeProperty, Int(visitsHistory.totalVisitTime + 0.5).toStr())
        end if
        if m.averageVisitTimeProperty <> ""
            ' Calculate average visit time and round properly
            averageTime = visitsHistory.totalVisitTime / visitsHistory.visits
            m._client.profile().setValue(m.averageVisitTimeProperty, Int(averageTime + 0.5).toStr())
        end if
    end sub
    ' Sorts the timestamps in descending order using a simple bubble sort.
    '
    ' @param timestamps The object containing the timestamps to sort.
    ' @return An object containing the sorted timestamps in descending order.
    instance._sortTimestampsDescending = function(timestamps as object) as object
        sortedTimestamps = []
        ' Copy array to avoid modifying the original
        for each timestamp in timestamps
            sortedTimestamps.push(timestamp)
        end for
        ' Simple bubble sort (descending)
        n = sortedTimestamps.count()
        for i = 0 to n - 2
            for j = 0 to n - i - 2
                if Val(sortedTimestamps[j]) < Val(sortedTimestamps[j + 1])
                    temp = sortedTimestamps[j]
                    sortedTimestamps[j] = sortedTimestamps[j + 1]
                    sortedTimestamps[j + 1] = temp
                end if
            end for
        end for
        return sortedTimestamps
    end function
    ' Creates a new visit history object with default values.
    '
    ' @return An object representing the visit history with default values.
    instance._createVisitHistory = function() as object
        return {
            visits: 0
            sessionStart: 0
            firstVisit: 0
            lastVisit: 0
            totalVisitTime: 0.0
            pageViews: 0
            sessionPageViews: 0
        }
    end function
    ' Retrieves the visit history from the profile, or creates a new one if it doesn't exist.
    '
    ' @return An object containing the visit history.
    instance._getVisitsHistory = function() as object
        ' Try to get existing visit history from profile
        visitHistoryJson = m._client.profile().getValue(m.visitHistoryProperty)
        if visitHistoryJson <> invalid and visitHistoryJson <> ""
            ' Try to parse the stored JSON
            visitHistory = ParseJson(visitHistoryJson)
            return visitHistory
        end if
        ' Create a new visit history object if none exists or parsing failed
        return m._createVisitHistory()
    end function
    ' Retrieves the value of a parameter from the interaction context.
    '
    ' @param key The key of the parameter to retrieve.
    ' @return The value of the parameter if found, otherwise an empty string.
    instance._getParameterValue = sub(key as string) as dynamic
        if m._interactionContext.getParameters()[key] <> invalid and m._interactionContext.getParameters()[key].Count() > 0
            return m._interactionContext.getParameters()[key][0]
        else
            return ""
        end if
    end sub
    return instance
end function
function BCVisitListener()
    instance = __BCVisitListener_builder()
    instance.new()
    return instance
end function