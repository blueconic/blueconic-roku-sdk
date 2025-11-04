' $LastChangedBy$
' $LastChangedDate$
' $LastChangedRevision$
' $HeadURL$
'
' Copyright 2014 BlueConic Inc./BlueConic B.V. All rights reserved.
' Class handling the plugins in BlueConic.
function __BCPluginsManager_builder()
    instance = {}
    instance.new = sub()
        m._plugins = {}
        m._currentInteractions = []
    end sub
    ' Initializes the plugins manager with a list of interactions.
    '
    ' @param interactions An object containing the interactions to initialize.
    instance.initialize = sub(interactions as object)
        for each interaction in interactions
            m._currentInteractions.push(interaction)
            interaction.onLoad()
        end for
    end sub
    ' Retrieves a plugin by its class name.
    '
    ' @param className The class name of the plugin to retrieve.
    ' @return The plugin object if found, otherwise invalid.
    instance.getPlugin = function(className as string, id as string) as object
        if m._plugins[className] <> invalid
            return m._plugins[className]
        end if
        plugin = invalid
        if className = ""
            return invalid
        else if className = "listenerinteractiontype"
            plugin = BCGlobalListener()
        else if className = "listener_preferred_hour"
            plugin = BCPreferredHourListener()
        else if className = "dialogue_properties_based"
            plugin = BCPropertiesBasedDialogue()
        else if className = "visitlistener"
            plugin = BCVisitListener()
        else if className = "engagement_score"
            plugin = BCEngagementScoreListener()
        else if className = "enrichprofilebyvisitorbehavior"
            plugin = BCBehaviorListener()
        else if className = "engagement_interest_ranking"
            plugin = BCEngagementRankingListener()
        else if className = "dialogue_recommendations"
            plugin = BCRecommendationsDialogue()
        end if
        if plugin <> invalid
            if id <> invalid and id <> ""
                m.registerPluginClass(plugin, className + "-" + id)
            else
                m.registerPluginClass(plugin, className)
            end if
        end if
        return plugin
    end function
    ' Destroys all current interactions and their associated plugins.
    instance.destroyPlugins = sub()
        toDestroy = m._currentInteractions
        count = toDestroy.count()
        m._currentInteractions = []
        for each interaction in toDestroy
            if interaction <> invalid
                interaction.onDestroy()
            end if
        end for
        if count > 0
            BCLogInfo("Destroyed all " + count.toStr() + " interactions")
        end if
    end sub
    ' Registers a plugin class with the manager.
    '
    ' @param pluginClass The class of the plugin to register.
    ' @param className The name of the plugin class to register
    instance.registerPluginClass = sub(pluginClass as object, className as string)
        m._plugins[className] = pluginClass
        BCLogInfo("Registered plugin class for class name '" + className)
    end sub
    return instance
end function
function BCPluginsManager()
    instance = __BCPluginsManager_builder()
    instance.new()
    return instance
end function
' Class representing a BlueConic plugin.
function __BCPlugin_builder()
    instance = {}
    instance.new = sub()
        m._client = invalid
        m._interactionContext = invalid
    end sub
    ' Initializes the plugin with a client and interaction context.
    '
    ' @param client The client object to use for the plugin.
    ' @param interactionContext The context of the interaction for the plugin.
    ' @return The initialized plugin object.
    instance.init = function(client as object, interactionContext as object) as object
        m._client = client
        m._interactionContext = interactionContext
        return m
    end function
    instance.onLoad = sub()
    end sub
    instance.onDestroy = sub()
    end sub
    return instance
end function
function BCPlugin()
    instance = __BCPlugin_builder()
    instance.new()
    return instance
end function
' Class representing the context of an interaction in BlueConic.
function __BCInteractionContext_builder()
    instance = {}
    ' Constructor.
    '
    ' @param interaction The interaction object containing details about the interaction.
    ' @param connections The connections associated with the interaction.
    ' @param locale The locale to use for parameters, if available.
    instance.new = function(interaction as object, connections as object, locale as string)
        m._interaction = invalid
        m._connections = invalid
        m._parameters = {}
        m._defaultLocale = invalid
        m._interaction = interaction
        m._connections = connections
        if interaction.doesExist("defaultLocale")
            m._defaultLocale = interaction.defaultLocale
        else
            m._defaultLocale = ""
        end if
        if interaction.doesExist("paramresult")
            allParameters = interaction.paramresult
            if locale <> ""
                m._parameters = m._getLocaleParameters(allParameters, locale)
            else
                m._parameters = m._getLocaleParameters(allParameters, m._defaultLocale)
            end if
        end if
    end function
    ' Retrieves the interaction object associated with this context.
    '
    ' @return The interaction object.
    instance.getInteractionId = function() as string
        return m._interaction.id
    end function
    ' Retrieves the interaction name.
    '
    ' @return The name of the interaction.
    instance.getName = function() as string
        return m._interaction.name
    end function
    ' Retrieves the interaction type ID.
    '
    ' @return The ID of the interaction type.
    instance.getInteractionTypeId = function() as string
        return m._interaction.interactionTypeId
    end function
    ' Retrieves the interaction type name.
    '
    ' @return The name of the interaction type.
    instance.getPluginType = function() as string
        return m._interaction.pluginType
    end function
    ' Retrieve the parameters associated with this interaction.
    '
    ' @return An object containing the parameters for this interaction.
    instance.getParameters = function() as object
        return m._parameters
    end function
    ' Retrieves the position identifier associated with this interaction.
    '
    ' @return The identifier of the position.
    instance.getPositionIdentifier = function() as string
        return m._interaction.positionId
    end function
    ' Retrieves the position name associated with this interaction.
    '
    ' @return The name of the position.
    instance.getPositionName = function() as string
        return m._interaction.positionName
    end function
    ' Retrieves the dialogue ID associated with this interaction.
    '
    ' @return The ID of the dialogue.
    instance.getDialogueId = function() as string
        return m._interaction.dialogueId
    end function
    ' Retrieves the dialogue name associated with this interaction.
    '
    ' @return The name of the dialogue.
    instance.getDialogueName = function() as string
        return m._interaction.dialogueName
    end function
    ' Retrieves the connection object associated with this interaction by its ID.
    '
    ' @param id The ID of the connection to retrieve.
    instance.getConnection = function(id as string) as object
        for each connection in m._connections
            if connection.id = id
                return connection
            end if
        end for
        return invalid
    end function
    ' Retrieves the locale parameters for this interaction.
    '
    ' @param allParameters An object containing all parameters for the interaction.
    ' @param locale The locale to use for retrieving parameters.
    ' @return An object containing the parameters for the specified locale.
    instance._getLocaleParameters = function(allParameters as object, locale as string) as object
        if allParameters = invalid
            return {}
        end if
        availableLocales = allParameters.keys()
        localeParameters = allParameters[locale]
        if localeParameters <> invalid
            BCLogInfo("Locale used: " + locale + " for plugin '" + m._interaction.pluginClass + "'")
            return localeParameters
        end if
        if m._defaultLocale <> invalid and m._defaultLocale <> locale
            BCLogInfo("The locale '" + locale + "' doesn't exist, using default locale '" + m._defaultLocale + "' instead.")
            return m._getLocaleParameters(allParameters, m._defaultLocale)
        else if availableLocales.count() > 0
            firstLocale = availableLocales[0]
            BCLogInfo("The default locale '" + locale + "' is not valid, using the first valid locale '" + firstLocale + "' instead.")
            return m._getLocaleParameters(allParameters, firstLocale)
        end if
        return {}
    end function
    return instance
end function
function BCInteractionContext(interaction as object, connections as object, locale as string)
    instance = __BCInteractionContext_builder()
    instance.new(interaction, connections, locale)
    return instance
end function