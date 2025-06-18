' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class used to manage network requests to the BlueConic server.
function __BCNetworkManager_builder()
    instance = {}
    instance.new = sub()
    end sub
    ' Method to execute network requests.
    '
    ' @param appId: The application ID.
    ' @param hostName: The hostname of the server.
    ' @param commands: The commands to be executed.
    ' @param domainGroup: The domain group for the request.
    ' @param simulatorData: Data for the simulator, if applicable.
    ' @param screenName: The name of the screen, default is an empty string.
    ' @return: A container object with the responses from the server.
    instance.execute = function(appId as string, hostName as string, commands as object, domainGroup as string, simulatorData as object, screenName = "") as object
        requests = m.requestBuilder().getRequests(commands)
        requestParameters = {}
        m._addSimulatorData(requestParameters, simulatorData)
        m._addTime(requestParameters, CreateObject("roDateTime"))
        absoluteUrl = hostName + "/DG/" + domainGroup + "/rest/rpc/json"
        content = m.getData(absoluteUrl, appId, hostName, requests, requestParameters, domainGroup, screenName)
        responsesList = m._getResponses(content)
        return BCResponsesContainer(responsesList)
    end function
    ' Method to get data from the server.
    '
    ' @param url: The URL to send the request to.
    ' @param appId: The application ID.
    ' @param hostName: The hostname of the server.
    ' @param postData: The data to be sent in the POST request.
    ' @param requestParameters: Additional parameters for the request.
    ' @param domainGroup: The domain group for the request.
    ' @param screenName: The name of the screen, default is an empty string.
    ' @return: The response from the server as an object.
    instance.getData = function(url as string, appId as string, hostName as string, postData as object, requestParameters as object, domainGroup as string, screenName as string) as object
        timeoutMs = 10000
        requestParameters["overruleReferrer"] = appId
        request = CreateObject("roUrlTransfer")
        port = CreateObject("roMessagePort")
        request.setMessagePort(port)
        request.setCertificatesFile("common:/certs/ca-bundle.crt")
        request.initClientCertificates()
        url = url + m._generateQueryParameters(requestParameters)
        BCLogInfo("URL: " + url)
        request.setUrl(url)
        referer = "app://" + appId + "/" + screenName
        BCLogInfo("Referer: " + referer)
        request.addHeader("Referer", referer)
        request.addHeader("Content-Type", "text/plain")
        request.addHeader("User-Agent", BCConstants().SDK_DATA.USER_AGENT)
        request.addHeader("Connection", "close")
        cookies = m._getAllCookies()
        cookieHeader = ""
        for each cookieKey in cookies
            cookieValue = cookies[cookieKey]
            if cookieHeader <> ""
                cookieHeader = cookieHeader + ";"
            end if
            cookieHeader = cookieHeader + cookieKey + "=" + cookieValue
        end for
        BCLogInfo("Cookie header: " + cookieHeader)
        request.addHeader("Cookie", cookieHeader)
        request.enableEncodings(true)
        BCLogInfo("Post data: " + postData.toStr())
        if (request.AsyncPostFromString(postData.toStr())) then
            urlEvent = wait(timeoutMs, request.GetPort())
            if type(urlEvent) = "roUrlEvent"
                statusCode = urlEvent.getResponseCode()
                if statusCode = 200 then
                    message = statusCode.toStr() + " - Request OK"
                    response = urlEvent.getString()
                    BCLogInfo("Response: " + response)
                    headers = urlEvent.getResponseHeadersArray()
                    m._handleCookieResponse(headers)
                    return response
                else
                    newUrl = invalid
                    if statusCode = 302 or statusCode = 301 or statusCode = 303 then
                        newUrl = urlEvent.getResponseHeaders()["Location"]
                    else if statusCode = 300 then
                        responseContent = urlEvent.GetString()
                        responseObject = ParseJson(responseContent)
                        if responseObject <> invalid and responseObject.doesExist("location")
                            newUrl = responseObject.location
                        end if
                    end if
                    if newUrl <> invalid then
                        BCLogInfo("Redirect to URL: " + newUrl)
                        return m.getData(newUrl, appId, hostName, postData, requestParameters, domainGroup, screenName)
                    else
                        BCLogError("Server response is invalid, with status code: " + statusCode.ToStr())
                        return "{}"
                    end if
                end if
            else if urlEvent = invalid then
                BCLogError("AsyncGetFromString timeout when waiting for response from: " + url)
                request.asyncCancel()
                return "{}"
            else
                BCLogError("AsyncPostFromString Unknown Event: " + urlEvent)
                return "{}"
            end if
        end if
    end function
    ' Method to build requests
    '
    ' @return: An object with methods to build requests.
    instance.requestBuilder = function() as object
        return {
            ' Method to get requests in JSON format.
            '
            ' @param requestCommands: An array of request commands.
            ' @return: A JSON string representing the requests.
            getRequests: function(requestCommands as object) as string
                jsonRequests = []
                for each command in requestCommands
                    jsonRequests.push(command.toJson(command))
                end for
                return "[" + jsonRequests.join(",") + "]"
            end function
            ' Method to add a request command to the request commands array.
            '
            ' @param requestCommands: An array of request commands.
            ' @param requestCommand: The request command to be added.
            addRequestCommand: sub(requestCommands as object, requestCommand as object)
                requestCommands.push(requestCommand)
            end sub
        }
    end function
    ' Method to add simulator data
    '
    ' @param parameters: The parameters object to which simulator data will be added.
    ' @param simulatorData: The simulator data object containing user name and session ID.
    instance._addSimulatorData = sub(parameters as object, simulatorData as object)
        if simulatorData.doesExist("simulatorUserName")
            parameters["username"] = simulatorData.simulatorUserName
        else
            parameters["username"] = ""
        end if
        if simulatorData.doesExist("simulatorSessionId")
            parameters["mobileSessionId"] = simulatorData.simulatorSessionId
        else
            parameters["mobileSessionId"] = ""
        end if
        BCLogVerbose("Add simulator data to request. Username: " + parameters["username"] + ", CTV Session ID: " + parameters["mobileSessionId"])
    end sub
    ' Method to add time data
    '
    ' @param parameters: The parameters object to which time data will be added.
    ' @param now: The current date and time object.
    ' @note: The time is formatted in ISO 8601 format with timezone offset.
    instance._addTime = sub(parameters as object, now as object)
        isoDate = now.toISOString().Split("Z")[0]
        tzo = now.getTimezoneOffset() / 60
        sign = "+"
        if tzo < 0
            sign = "-"
            tzo = Abs(tzo)
        end if
        pad = function(num as integer) as string
            if num < 10
                return "0" + num.toStr()
            else
                return num.toStr()
            end if
        end function
        timezoneOffset = sign + pad(Int(tzo)) + ":" + pad(Int((tzo Mod 1) * 60))
        time = isoDate + timezoneOffset
        BCLogVerbose("Add time data to request. Time: " + time)
        parameters["time"] = time
    end sub
    ' Method to get all cookies.
    '
    ' @return: An object containing all cookies, specifically the BCSessionID.
    instance._getAllCookies = function() as object
        return {
            "BCSessionID": BCStorageManager().readData(BCConstants().STORAGE.BC_SESSION_COOKIE_NAME, BCConstants().STORAGE.COOKIES, "")
        }
    end function
    ' Method to handle cookie response
    '
    ' @param headers: The response headers from the server.
    instance._handleCookieResponse = sub(headers as object)
        for each header in headers
            cookies = header["set-cookie"]
            if cookies <> invalid
                m._processCookies(cookies)
            end if
        end for
    end sub
    ' Helper function to process cookies
    '
    ' @param cookies: A string containing the cookies from the response headers.
    instance._processCookies = sub(cookies as string)
        parts = cookies.split(";")
        for each part in parts
            m._processCookiePart(part)
        end for
    end sub
    ' Helper function to process a single cookie part
    '
    ' @param part: A string representing a single cookie part, typically in the format "key=value".
    instance._processCookiePart = sub(part as string)
        if part.instr("=") > -1
            keyValue = part.split("=")
            key = keyValue[0].trim()
            value = keyValue[1].trim()
            if key = BCConstants().STORAGE.BC_SESSION_COOKIE_NAME
                m._saveCookie(key, value)
            end if
        end if
    end sub
    ' Method to save a cookie
    '
    ' @param key: The key of the cookie to be saved.
    ' @param value: The value of the cookie to be saved.
    ' @note: This method uses the BCStorageManager (roRegistry) to save the cookie.
    instance._saveCookie = sub(key as string, value as string)
        BCLogInfo("Save cookie: " + key + " with value: " + value)
        BCStorageManager().saveData(key, value, BCConstants().STORAGE.COOKIES)
    end sub
    ' Method to generate query parameters
    '
    ' @param map: An object containing key-value pairs to be converted into query parameters.
    ' @return: A string representing the query parameters in the format "?key1=value1&key2=value2".
    instance._generateQueryParameters = function(map as object) as string
        queryParameters = "?"
        for each key in map
            value = map[key]
            if queryParameters <> "?"
                queryParameters = queryParameters + "&"
            end if
            queryParameters = queryParameters + key + "=" + m._encodeURIComponent(value)
        end for
        return queryParameters
    end function
    ' Method to encode a URI component
    '
    ' @param value: The string value to be encoded.
    ' @return: The encoded string value.
    instance._encodeURIComponent = function(value as string) as string
        return CreateObject("roUrlTransfer").escape(value)
    end function
    ' Method to get responses from a JSON string.
    '
    ' @param json: A JSON string containing the responses.
    ' @return: An array of response objects parsed from the JSON string.
    instance._getResponses = function(json as string) as object
        parsedJson = ParseJson(json)
        responsesValues = []
        if Type(parsedJson) = "roArray"
            for each jsonElement in parsedJson
                response = BCResponseParser().parse(jsonElement)
                responsesValues.push(response)
            end for
        end if
        return responsesValues
    end function
    return instance
end function
function BCNetworkManager()
    instance = __BCNetworkManager_builder()
    instance.new()
    return instance
end function