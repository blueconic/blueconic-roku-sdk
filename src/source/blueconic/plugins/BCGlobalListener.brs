' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling the global listener for the BlueConic platform.
function __BCGLobalListener_builder()
    instance = __BCPlugin_builder()
    instance.super0_new = instance.new
    instance.new = sub()
        m.super0_new()
        m._VISIT_EXPIRE_INTERVAL = 30
        m._CURRENT_OSNAME = "currentosname"
        m._OSNAME = "osname"
        m._CURRENT_OSVERSION = "currentosversion"
        m._OSVERSION = "osversion"
        m._CURRENT_RESOLUTION = "currentresolution"
        m._CURRENT_SCREEN_WIDTH = "currentscreenwidth"
        m._CURRENT_SCREEN_HEIGHT = "currentscreenheight"
        m._RESOLUTION = "resolution"
        m._LANGUAGE = "language"
        m._VISITS = "visits"
        m._VISIT_CLICKS = "visitclicks"
        m._CLICK_COUNT = "clickcount"
        m._LAST_VISIT_DATE = "lastvisitdate"
        m._APP_ID = "ctv_app_id"
        m._APP_NAME = "ctv_app_name"
        m._APP_NAMES = "ctv_app_names"
        m._APP_NAME_VERSION = "ctv_app_nameversion"
        m._APP_NAME_VERSIONS = "ctv_app_nameversions"
        m._APP_VENDOR = "ctv_app_vendor"
        m._APP_VENDORS = "ctv_app_vendors"
        m._APP_MODEL = "ctv_app_model"
        m._APP_MODELS = "ctv_app_models"
        m._APP_AD_ID = "ctv_app_ad_id"
        m._APP_IDS = "ctv_app_ids"
        m._APP_AD_IDS = "ctv_app_ad_ids"
        m._CTV_APP_TYPE = "ctv_app"
        m._CONNECTION_TYPE = "connection"
        m._ORIGIN_TYPE = "origin_type"
        m._ORIGIN_SOURCE = "origin_source"
        m._ORIGIN_DETAIL = "origin_detail"
        m._DEVICETYPE = "devicetype"
        m._VISITEDSITES = "visitedsites"
        m._ENTRYPAGE = "entrypage"
        m._RECEIVED_FROM_SYSTEM = "received_from_system"
        m._RECEIVED_FROM_CONNECTION = "received_from_connection"
    end sub
    ' Expire interval for visits. When this interval is passed without pageview we start the "visitclick" at 0.
    ' Number in minutes.
    ' Global listener properties.
    ' Visits to the app.
    ' Page views current session.
    ' Page views overall.
    ' CTV specific properties (for global listener).
    ' Readable data to be used as the origin.
    instance.super0_onLoad = instance.onLoad
    instance.onLoad = function()
        m._setSystemInformation()
        m._setStatistics()
    end function
    instance.super0_onDestroy = instance.onDestroy
    instance.onDestroy = function()
    end function
    ' Method to set the system information, app information, and origin.
    instance._setSystemInformation = sub()
        m._setDeviceInformation()
        m._setAppInformation()
        m._setOrigin()
    end sub
    ' Method to set the device information, including OS name, version, resolution, language, and advertisement ID.
    instance._setDeviceInformation = sub()
        propertyValuesToAdd = {}
        propertyValuesToSet = {}
        deviceInfo = CreateObject("roDeviceInfo")
        systemName = "Roku"
        systemVersion = deviceInfo.getOSVersion()
        version = systemName + " " + systemVersion.major + "." + systemVersion.minor
        if systemName <> invalid
            propertyValuesToSet[m._CURRENT_OSNAME] = [
                systemName
            ]
            propertyValuesToAdd[m._OSNAME] = [
                systemName
            ]
        end if
        if version <> invalid
            propertyValuesToSet[m._CURRENT_OSVERSION] = [
                version
            ]
            propertyValuesToAdd[m._OSVERSION] = [
                version
            ]
        end if
        resolution = deviceInfo.getDisplaySize()
        resolutionValue = resolution.w.toStr() + "x" + resolution.h.toStr()
        propertyValuesToSet[m._CURRENT_SCREEN_WIDTH] = [
            resolution.w.toStr()
        ]
        propertyValuesToSet[m._CURRENT_SCREEN_HEIGHT] = [
            resolution.h.toStr()
        ]
        propertyValuesToSet[m._CURRENT_RESOLUTION] = [
            resolutionValue
        ]
        propertyValuesToAdd[m._RESOLUTION] = [
            resolutionValue
        ]
        language = deviceInfo.getCurrentLocale()
        if language <> invalid
            propertyValuesToSet[m._LANGUAGE] = [
                language
            ]
        end if
        advertisementId = deviceInfo.getRIDA()
        propertyValuesToSet[m._APP_AD_ID] = [
            advertisementId
        ]
        propertyValuesToAdd[m._APP_AD_IDS] = [
            advertisementId
        ]
        m._handleProperties(propertyValuesToAdd, propertyValuesToSet, {})
    end sub
    ' Method to set the application information, including app ID, name, version, vendor, model, and DPI.
    instance._setAppInformation = sub()
        propertyValuesToSet = {}
        propertyValuesToAdd = {}
        appInfo = CreateObject("roAppInfo")
        appId = appInfo.getID()
        appName = appInfo.getTitle()
        appVersion = appInfo.getVersion()
        if appId <> invalid
            propertyValuesToSet[m._APP_ID] = [
                appId
            ]
            propertyValuesToAdd[m._APP_IDS] = [
                appId
            ]
        end if
        if appName <> invalid
            propertyValuesToSet[m._APP_NAME] = [
                appName
            ]
            propertyValuesToAdd[m._APP_NAMES] = [
                appName
            ]
        end if
        if appName <> invalid and appVersion <> invalid
            appNameVersion = appName + " " + appVersion
            propertyValuesToSet[m._APP_NAME_VERSION] = [
                appNameVersion
            ]
            propertyValuesToAdd[m._APP_NAME_VERSIONS] = [
                appNameVersion
            ]
        end if
        deviceInfo = CreateObject("roDeviceInfo")
        deviceName = deviceInfo.getModel()
        propertyValuesToSet[m._APP_VENDOR] = [
            "Roku"
        ]
        propertyValuesToAdd[m._APP_VENDORS] = [
            "Roku"
        ]
        propertyValuesToSet[m._APP_MODEL] = [
            deviceName
        ]
        propertyValuesToAdd[m._APP_MODELS] = [
            deviceName
        ]
        m._handleProperties(propertyValuesToAdd, propertyValuesToSet, {})
    end sub
    ' Method to set the origin information based on the profile data.
    instance._setOrigin = sub()
        profile = m._client.profile()
        originTypes = m._client.profile().getValues(m._ORIGIN_TYPE)
        originSources = profile.getValues(m._ORIGIN_SOURCE)
        originDetails = profile.getValues(m._ORIGIN_DETAIL)
        if originTypes.count() >= 2 or originSources.count() >= 2 or originDetails.count() >= 2
            propertyValuesToSet = {}
            propertyValuesToSet[m._ORIGIN_TYPE] = []
            if originTypes.count() = 1
                propertyValuesToSet[m._ORIGIN_TYPE] = [
                    originTypes[0]
                ]
            end if
            if originSources.Count() = 1
                propertyValuesToSet[m._ORIGIN_SOURCE] = [
                    originSources[0]
                ]
            end if
            if originDetails.Count() = 1
                propertyValuesToSet[m._ORIGIN_DETAIL] = [
                    originDetails[0]
                ]
            end if
            m._handleProperties({}, propertyValuesToSet, {})
            return
        end if
        if originTypes.count() > 0 or originSources.count() > 0 or originDetails.count() > 0
            return
        end if
        visits = profile.getValue(m._VISITS)
        if visits = ""
            visits = 0
        else
            visits = val(visits)
        end if
        deviceType = profile.getValue(m._DEVICETYPE)
        visitedSites = profile.getValues(m._VISITEDSITES)
        entryPages = profile.getValues(m._ENTRYPAGE)
        ctvAppIds = profile.getValues(m._APP_ID)
        ctvAppNameAndVersions = profile.getValues(m._APP_NAME_VERSION)
        receivedFromSystems = profile.getValues(m._RECEIVED_FROM_SYSTEM)
        receivedFromConnections = profile.getValues(m._RECEIVED_FROM_CONNECTION)
        propertyValuesToSet = {}
        propertyValuesToAdd = {}
        if visitedSites.count() = 0 and receivedFromSystems.count() = 0
            propertyValuesToSet[m._ORIGIN_TYPE] = [
                m._CTV_APP_TYPE
            ]
            propertyValuesToAdd[m._ORIGIN_SOURCE] = ctvAppIds
            propertyValuesToAdd[m._ORIGIN_DETAIL] = ctvAppNameAndVersions
        else if receivedFromSystems.count() > 0 and visitedSites.count() = 0 and visits <= 1
            propertyValuesToSet[m._ORIGIN_TYPE] = [
                m._CONNECTION_TYPE
            ]
            propertyValuesToAdd[m._ORIGIN_SOURCE] = receivedFromSystems
            propertyValuesToAdd[m._ORIGIN_DETAIL] = receivedFromConnections
        end if
        m._handleProperties(propertyValuesToAdd, propertyValuesToSet, {})
    end sub
    ' Method to set the statistics for the global listener, including visit clicks and last visit date.
    instance._setStatistics = sub()
        profile = m._client.profile()
        propertyValuesToAdd = {}
        propertyValuesToSet = {}
        propertyValuesToIncrement = {}
        lastVisitDateValue = profile.getValue(m._LAST_VISIT_DATE)
        if lastVisitDateValue = ""
            lastVisitDateValue = "0"
        end if
        visitsValue = profile.getValue(m._VISITS)
        if visitsValue = ""
            visitsValue = "0"
        end if
        lastVisitDate = val(lastVisitDateValue)
        visits = val(visitsValue)
        nowInMillis = CreateObject("roDateTime").asSecondsLong() * 1000
        expire = lastVisitDate + (m._VISIT_EXPIRE_INTERVAL * 60 * 1000)
        propertyValuesToIncrement[m._CLICK_COUNT] = "1"
        if nowInMillis > expire or visits = 0
            propertyValuesToSet[m._VISIT_CLICKS] = [
                "1"
            ]
            propertyValuesToIncrement[m._VISITS] = "1"
        else
            propertyValuesToIncrement[m._VISIT_CLICKS] = "1"
        end if
        propertyValuesToSet[m._LAST_VISIT_DATE] = [
            nowInMillis.toStr()
        ]
        m._handleProperties(propertyValuesToAdd, propertyValuesToSet, propertyValuesToIncrement)
    end sub
    ' Method to handle the properties by adding, setting, or incrementing values in the profile.
    '
    ' @param propertyValuesToAdd Dictionary of properties to add.
    ' @param propertyValuesToSet Dictionary of properties to set.
    ' @param propertyValuesToIncrement Dictionary of properties to increment.
    instance._handleProperties = sub(propertyValuesToAdd as object, propertyValuesToSet as object, propertyValuesToIncrement as object)
        profile = m._client.profile()
        for each key in propertyValuesToAdd
            values = propertyValuesToAdd[key]
            profile.addValues(key, values)
        end for
        for each key in propertyValuesToSet
            values = propertyValuesToSet[key]
            profile.setValues(key, values)
        end for
        for each key in propertyValuesToIncrement
            value = propertyValuesToIncrement[key]
            profile.incrementValue(key, value)
        end for
    end sub
    return instance
end function
function BCGLobalListener()
    instance = __BCGLobalListener_builder()
    instance.new()
    return instance
end function