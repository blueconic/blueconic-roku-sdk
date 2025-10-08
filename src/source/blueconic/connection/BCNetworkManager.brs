' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling network communication.
function __BCHttpURLConnectionClient_builder()
    instance = {}
    instance.new = sub()
    end sub
    ' Method to get data from the server.
    '
    ' @param httpRequest: The HTTP request object containing method, URL, headers, post data, and request parameters.
    ' @param domainGroup: The domain group for the request.
    ' @return: The response from the server as a string.
    instance.execute = function(httpRequest as object) as string
        timeoutMs = 10000
        urlTransfer = CreateObject("roUrlTransfer")
        port = CreateObject("roMessagePort")
        urlTransfer.setMessagePort(port)
        urlTransfer.setCertificatesFile("common:/certs/ca-bundle.crt")
        urlTransfer.initClientCertificates()
        url = httpRequest.getUrl() + m._generateQueryParameters(httpRequest.getRequestParameters())
        BCLogInfo("URL: " + url)
        urlTransfer.setUrl(url)
        for each headerKey in httpRequest.getHeaders()
            headerValue = httpRequest.getHeaders()[headerKey]
            BCLogInfo("Add header: " + headerKey + " with value: " + headerValue)
            urlTransfer.addHeader(headerKey, headerValue)
        end for
        urlTransfer.addHeader("Content-Type", "application/json")
        urlTransfer.addHeader("User-Agent", BCConstants().SDK_DATA.USER_AGENT)
        urlTransfer.addHeader("Connection", "close")
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
        urlTransfer.addHeader("Cookie", cookieHeader)
        urlTransfer.enableEncodings(true)
        if httpRequest.getMethod() = "GET"
            if (urlTransfer.asyncGetToString()) then
                urlEvent = wait(timeoutMs, urlTransfer.GetPort())
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
                        BCLogError("Server response is invalid, with status code: " + statusCode.ToStr())
                        return "{}"
                    end if
                else if urlEvent = invalid then
                    BCLogError("AsyncGetFromString timeout when waiting for response from: " + url)
                    urlTransfer.asyncCancel()
                    return "{}"
                else
                    BCLogError("AsyncGetFromString Unknown Event: " + urlEvent)
                    return "{}"
                end if
            end if
        else if httpRequest.getMethod() = "POST"
            BCLogInfo("Post data: " + httpRequest.getPostData())
            if (urlTransfer.asyncPostFromString(httpRequest.getPostData())) then
                urlEvent = wait(timeoutMs, urlTransfer.GetPort())
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
                            redirectRequest = BCHttpURLConnectionRequest(httpRequest.getMethod(), newUrl, httpRequest.getHeaders(), httpRequest.getPostData(), httpRequest.getRequestParameters())
                            return m.execute(redirectRequest)
                        else
                            BCLogError("Server response is invalid, with status code: " + statusCode.ToStr())
                            return "{}"
                        end if
                    end if
                else if urlEvent = invalid then
                    BCLogError("AsyncPostFromString timeout when waiting for response from: " + url)
                    urlTransfer.asyncCancel()
                    return "{}"
                else
                    BCLogError("AsyncPostFromString Unknown Event: " + urlEvent)
                    return "{}"
                end if
            end if
        else
            BCLogError("Unsupported HTTP method: " + httpRequest.getMethod())
            return "{}"
        end if
    end function
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
    return instance
end function
function BCHttpURLConnectionClient()
    instance = __BCHttpURLConnectionClient_builder()
    instance.new()
    return instance
end function
' Class representing an HTTP request.
function __BCHttpURLConnectionRequest_builder()
    instance = {}
    ' Constructor
    '
    ' @param method: HTTP method (GET, POST, etc.)
    ' @param url: The URL for the request
    ' @param headers: Request headers as key-value pairs
    ' @param postData: Data to be sent in POST requests
    ' @param requestParameters: Additional request parameters (optional)
    instance.new = sub(method as string, url as string, headers as object, postData as string, requestParameters = {} as object)
        m._method = ""
        m._url = ""
        m._headers = {}
        m._postData = ""
        m._requestParameters = {}
        m._method = method
        m._url = url
        m._headers = headers
        m._postData = postData
        m._requestParameters = requestParameters
    end sub
    ' Getter for method
    '
    ' @return: The HTTP method
    instance.getMethod = function() as string
        return m._method
    end function
    ' Getter for URL
    '
    ' @return: The URL
    instance.getUrl = function() as string
        return m._url
    end function
    ' Getter for headers
    '
    ' @return: The headers object
    instance.getHeaders = function() as object
        return m._headers
    end function
    ' Getter for post data
    '
    ' @return: The post data string
    instance.getPostData = function() as string
        return m._postData
    end function
    ' Getter for request parameters
    '
    ' @return: The request parameters object
    instance.getRequestParameters = function() as object
        return m._requestParameters
    end function
    return instance
end function
function BCHttpURLConnectionRequest(method as string, url as string, headers as object, postData as string, requestParameters = {} as object)
    instance = __BCHttpURLConnectionRequest_builder()
    instance.new(method, url, headers, postData, requestParameters)
    return instance
end function
' Class handling RPC network communication.
function __BCRPCConnector_builder()
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
    instance.execute = function(appId as string, hostName as string, zoneId as dynamic, commands as object, domainGroup as string, simulatorData as object, screenName = "") as object
        requests = m.requestBuilder().getRequests(commands)
        requestParameters = {}
        m._addSimulatorData(requestParameters, simulatorData)
        m._addTime(requestParameters, CreateObject("roDateTime"))
        zoneIdValue = ""
        if zoneId <> invalid and zoneId <> ""
            zoneIdValue = "/" + zoneId.toStr()
        end if
        absoluteUrl = hostName + "/DG/" + domainGroup + "/rest/rpc/json" + zoneIdValue
        requestParameters["overruleReferrer"] = appId
        referer = "app://" + appId + "/" + screenName
        BCLogInfo("Referer: " + referer)
        headers = {
            "Referer": referer
        }
        postRequest = BCHttpURLConnectionRequest("POST", absoluteUrl, headers, requests, requestParameters)
        content = BCHttpURLConnectionClient().execute(postRequest)
        responsesList = m._getResponses(content)
        return BCResponsesContainer(responsesList)
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
function BCRPCConnector()
    instance = __BCRPCConnector_builder()
    instance.new()
    return instance
end function
' Class handling REST network communication.
function __BCRESTConnector_builder()
    instance = {}
    instance.new = sub()
    end sub
    ' Method to execute REST network requests.
    '
    ' @param hostName: The hostname of the server.
    ' @param zoneId: The zone ID for the request.
    ' @param command: The command object containing path, method, subPath, postBody, and queryParameters.
    ' @return: The response from the server as a string.
    instance.execute = function(hostName as string, zoneId as dynamic, command as object) as string
        zoneIdValue = ""
        if zoneId <> invalid and zoneId <> ""
            zoneIdValue = "/" + zoneId
        end if
        subValue = ""
        if command.subPath <> invalid and command.subPath <> ""
            subValue = "/" + command.subPath
        end if
        absoluteUrl = hostName + "/rest/v2/" + command.path + zoneIdValue + subValue
        request = BCHttpURLConnectionRequest(command.method, absoluteUrl, {}, command.postBody, command.queryParameters)
        content = BCHttpURLConnectionClient().execute(request)
        return content
    end function
    return instance
end function
function BCRESTConnector()
    instance = __BCRESTConnector_builder()
    instance.new()
    return instance
end function