--[[
ForceOrg Tile Creator Tool 1.3

By Raikoh and Bone White
Updated by Ziggy Stardust

Saving and Loading script functions mostly written by Bone White from the TTS Discord.

This tool will search for models in a zone, then save them to a Tile.
In a nutshell, it works by effectively "additive loading" the models, instead of storing them in a bag.
This is far more efficient for thousands of models. 

For more information and variants of this tool, reach out to Raikoh067 on Discord.
]]--

--Variable declairations
local ZONE_POS
local ZONE_SCALE

--Manual Exclusions, when you set up the zon
local IGNORED_GUIDS =
{
    "e7ca6e", --Exclude Models Buidler Table
    "6012bf", --...and ForceOrg Table...
    "4ee1f2", --...and FTC board matObjSurface...
    "948ce5", --...and FTC Table...
    "28865a", --...and FTC Felt Surface.}
}

-- These affect the created/updated tile, modify to your preference
local IS_LOCKED = true
local SPAWNED_TILE_SCALE = 6.72 -- 6.72 ForceOrg Default
local TILE_ROTATION = 180 -- 180 ForceOrg Default

-- Set default tile art. CTRL + Clicking a tile before save will update it in place and put the old tile above the device.
local CARD_FRONT = "https://steamusercontent-a.akamaihd.net/ugc/14676347933992118556/09D092FEC8D4EE784223D199DED1C5A96EB4CEAC/" -- Default Insructions
local CARD_BACK = "https://steamusercontent-a.akamaihd.net/ugc/2298588777399277771/F36A07139E1E971F5F62C5C5F22677FECFDBE1FB/" -- Black background

-- Other variables (updated dynamicly later so dont change here, wouldn't do anything)
local UPDATE_TARGET
local DROP_OFF
local OBJECTS


-- FUNCTIONS BEYOND THIS POINT

-- Reset button id: resetDeviceButton
function resetDevice()
    ZONE_POS = nil
    ZONE_SCALE = nil
    script_state = ""
    onLoad('')
end

function onLoad(script_state)
    
    if not script_state.ZONE_POS then
        self.UI.setAttribute("panelSetupText", "active", true)    
        self.UI.setAttribute("xmlSetupButton", "active", true)
        self.UI.setAttribute("setupPanel", "active", true)

        self.UI.setAttribute("panelSaveText", "active", false)    
        self.UI.setAttribute("xmlSaveButton", "active", false)
        self.UI.setAttribute("resetDeviceButton", "active", false)
       
    else
        self.UI.setAttribute("panelSaveText", "active", true)    
        self.UI.setAttribute("xmlSaveButton", "active", true)
        self.UI.setAttribute("resetDeviceButton", "active", true)

        self.UI.setAttribute("panelSetupText", "active", false)    
        self.UI.setAttribute("xmlSetupButton", "active", false)
        self.UI.setAttribute("setupPanel", "active", false)

        local state = JSON.decode(script_state)
        ZONE_POS = state.savedZONE_POS
        ZONE_SCALE = state.savedZONE_SCALE
        IGNORED_GUIDS = state.savedIGNORED_GUIDS
    end
end

--
function onSave()
    
    local state = {
        savedZONE_POS = ZONE_POS,
        savedZONE_SCALE = ZONE_SCALE,
        ssavedIGNORED_GUIDS = IGNORED_GUIDS
    }
    return JSON.encode(state)

end

-- Needed to update the field when text is input for the Zone GUID
function InputValueChanged(_, value, id)
    self.UI.setAttribute(id, "text", value)
end

function setupDevice(player, value, id)
    local zoneGUID = self.UI.getAttribute("xmlGUIDInput", "text")
    if zoneGUID == nil or zoneGUID =="" then
        broadcastToAll("Field is empty, please paste the Zone GUID", "Red")
        return
    else
        if getObjectFromGUID(zoneGUID) then
            local zone = getObjectFromGUID(zoneGUID)
            ZONE_POS = zone.getPosition()
            ZONE_SCALE = zone.getScale()
            ZONE_SCALE.y = ZONE_SCALE.y * 2 -- Makes it fatter
            zone.destruct()

            --toggle the UI
            self.UI.setAttribute("panelSaveText", "active", true)    
            self.UI.setAttribute("xmlSaveButton", "active", true)
            self.UI.setAttribute("resetDeviceButton", "active", true)

            self.UI.setAttribute("panelSetupText", "active", false)    
            self.UI.setAttribute("xmlSetupButton", "active", false)
            self.UI.setAttribute("setupPanel", "active", false)

            -- Easier to filter donig this also, making a new filtered list also
            local IGNORED_GUIDS_SET = {}

            if IGNORED_GUIDS then
                for _, guid in ipairs(IGNORED_GUIDS) do
                    IGNORED_GUIDS_SET[guid] = true
                end
            end

            local filtered_objects = {}


            local step1 = false -- spawn zone
            local step2 = false -- find zone
            local step3 = false -- get objects in zone
            local step4 = false -- filter results
            local step5 = false -- add GUIDs to Ignore
            local step6 = false -- destory zone

            --step1 spawn zone
            spawnObject({
                position = ZONE_POS,
                scale = ZONE_SCALE, 
                type = 'ScriptingTrigger',
                callback_owner = self,
                callback_function = function(obj)
                    obj.setName("TempZone")
                end
            })

            Wait.time(function() step1 = true end,.1) -- small delay to kick this off.

            --step2 find zone
            Wait.condition( 
                function()
                    for _,o in ipairs(getObjects()) do
                        if o.type == "Scripting" then
                            if o.getName() == "TempZone" then
                                zone = o
                                step2 = true
                                break
                            end
                        end
                    end
                end,
                function()
                    return step1 == true
                end, 20
            )

            --step3 get objects in zone
            Wait.condition(
                function()
                    OBJECTS = zone.getObjects()
                    step3 = true
                end,
                function()
                    return step2 == true
                end, 20
            )


            --step4 filter results
            Wait.condition(
                function()
                    for _, obj in ipairs(OBJECTS) do
                        if not IGNORED_GUIDS_SET[obj.guid] then
                            table.insert(filtered_objects, obj)
                            
                        end
                    end
                    step4 = true
                end,
                function()
                    return step3 == true
                end, 20
            )

            --step5 encode to JSON
            Wait.condition(
                function()
                    for i, obj in ipairs(filtered_objects) do
                        table.insert(IGNORED_GUIDS, obj.guid)
                        broadcastToAll("Adding GUID: " .. obj.guid .. " to the list of objects to ignore","Green")
                        if i == #filtered_objects then step5 = true end
                    end
                end,
                function()
                    return step4 == true
                end, 20
            )

            --step6
            Wait.condition(function() zone.destruct() step5 = true end, function() return step4 == true end, 20)


        else
            broadcastToAll("Error: No zone with GUID: " .. zoneGUID .. " was found.", "Red")
            return
        end
    end

end

--------------------
function saveModels(player)

    UPDATE_TARGET = self.getPosition() + Vector(0, 0, 12) -- Just using offsets now 
    DROP_OFF = self.getPosition() + Vector(0, 0, 12)  -- Just using offsets now

    -- Easier to filter donig this also, making a new filtered list also
    local IGNORED_GUIDS_SET = {}
    
    if not IGNORED_GUIDS then
        broadcastToAll("Nothing in the Ignore GUIDs list", "White")
    else
        for _, guid in ipairs(IGNORED_GUIDS) do
            IGNORED_GUIDS_SET[guid] = true
        end
    end

    local filtered_objects = {}

    luaString = ""
    local step1 = false -- spawn zone
    local step2 = false -- find zone
    local step3 = false -- get objects in zone
    local step4 = false -- filter results
    local step5 = false -- encode to JSON
    local step6 = false -- destory zone
    local step7 = false -- Spawn tile and move stuff around

    --step1 spawn zone
    spawnObject({
        position = ZONE_POS,
        scale = ZONE_SCALE, 
        type = 'ScriptingTrigger',
        callback_owner = self,
        callback_function = function(obj)
            obj.setName("TempZone")
        end
    })
    
    Wait.time(function() step1 = true end,.1) -- small delay to kick this off.

    --step2 find zone
    Wait.condition( 
        function()
            for _,o in ipairs(getObjects()) do
                if o.type == "Scripting" then
                    if o.getName() == "TempZone" then
                        zone = o
                        step2 = true
                        break
                    end
                end
            end
        end,
        function()
            return step1 == true
        end, 20
    )

    --step3 get objects in zone
    Wait.condition(
        function()
            OBJECTS = zone.getObjects()
            step3 = true
        end,
        function()
            return step2 == true
        end, 20
    )

    --step4 filter results
    Wait.condition(
        function()
            for _, obj in ipairs(OBJECTS) do
                if not IGNORED_GUIDS_SET[obj.guid] then
                    table.insert(filtered_objects, obj)
                end
            end
            step4 = true
        end,
        function()
            return step3 == true
        end, 20
    )

    --step5 encode to JSON
    Wait.condition(
        function()
            if #filtered_objects == 0 then 
                broadcastToAll("0 Objecets detected. Stopping Operation","Red")
                zone.destruct()
            else
                broadcastToAll("Saving " .. #filtered_objects .. " Objects.","Green")
            end

            luaString = "\n\nobjectJSONs = {\n"

            for i, obj in ipairs(filtered_objects) do
                json_data = obj.getJSON(false)
                json_data = json_data:gsub([[,"AltLookAngle":{"x":0.0,"y":0.0,"z":0.0}]], "")
                json_data = json_data:gsub([[,"Nickname":""]], "")
                json_data = json_data:gsub([[,"GMNotes":""]], "")
                json_data = json_data:gsub([[,"LuaScript":""]], "")
                json_data = json_data:gsub([[,"LuaScriptState":""]], "")
                json_data = json_data:gsub([[,"XmlUI":""]], "")
                json_data = json_data:gsub([[,"Value":0]], "")
                json_data = json_data:gsub([[,"LayoutGroupSortIndex":0]], "")
                json_data = json_data:gsub([[,"Sticky":false]], "")
                json_data = json_data:gsub([[,"GridProjection":false]], "")
                json_data = json_data:gsub([[,"HideWhenFaceDown":false]], "")
                json_data = json_data:gsub([[,"Hands":false]], "")
                json_data = json_data:gsub([[,"IgnoreFoW":false]], "")
                luaString = luaString..'  [['..json_data..']],\n'
                if i == #filtered_objects then step5 = true end
            end
        end,
        function()
            return step4 == true
        end, 20
    )
    
    --step6
    Wait.condition(function() zone.destruct() step6 = true end, function() return step5 == true end, 20)

    --step7
    Wait.condition(
        function()
            luaString = luaString.."\n}\n\n" --The luaString is appended at the end of the Tiles LuaScript parameter, using the script a few lines down
            
            ------------------
            -- Spawn the Tile
            
            local my_position = self.getPosition()-- Create a position for the Models Tile to spawn, offset from the location of the button. (no longer used )
            local Tile_position = UPDATE_TARGET

            --This bit of code checks if you have a tile selected then updates to target that.
            local selection = Player[(player.color)].getSelectedObjects()
            if #selection == 1 and selection[1].type == "Tile"  then 
                local selectedObject = selection[1]
                Tile_position = selectedObject.getPosition()
                info = selectedObject.getCustomObject()
                CARD_FRONT = info.image --updates the image from the default Space Marine to whatever the previous card had for top art.
                selectedObject.setPosition(DROP_OFF)
                selectedObject.setLock(false)
            else
                broadcastToAll("No tile was selected for update. Using Default Art.\n\nTo Update a tile in place, 1st select the tile with CTRL + Click before hitting","Red")
            end
            
            local TileData = getTileData()
            TileData.LuaScript = TileData.LuaScript..luaString-- Append the luaString of saved objects we just made to the LuaScript field of the Tile data
            local TileCustom = spawnObjectData({data = TileData})-- Spawn the Tile thats prepared in the getTileData() function
            TileCustom.setPosition(Tile_position) -- Set the position of the Tile to the Tile position we set up above
            TileCustom.setRotation({0, TILE_ROTATION, 0}) --^
            Wait.time(function()TileCustom.call("setProtectedTable", {table = IGNORED_GUIDS}) end,.2)
            Wait.time(function()TileCustom.call("setZone", {pos = ZONE_POS , scale = ZONE_SCALE}) end,.2)
        end,
        function()
            return step6 == true
        end, 20
    )
end

------------------
function getTileData() -- This fuction prepares the Models Tile data.
    return {
        Name = "Custom_Tile",
        Nickname = "",
        Description = "",
        GMNotes = self.getGMNotes(),
        CustomImage = {
            ImageURL = CARD_FRONT,
            ImageSecondaryURL = CARD_BACK,
            ImageScalar = 1.0,
            WidthScale = 0.0,
            CustomTile = {
                Type = 0,
                Thickness = 0.1,
                Stackable = false,
            }
        },
        LuaScript = [[
    IGNORED_GUIDS = {
            }
    OBJECTS = nil
    -- Zone Settings

    ZONE_POS = nil
    ZONE_SCALE = nil

    IGNORED_GUIDS = {}

    -- sets protected objects from the creator
    function setProtectedTable(params)
        IGNORED_GUIDS = params.table
    end

    function setZone(params)
        ZONE_POS = params.pos
        ZONE_SCALE = params.scale
    end

    function onLoad()

        self.createButton({
            label = "Load Models",
            font_size = 115,
            color = {0, 0, 0},
            font_color = {1, 1, 1},
            position = {0, 0, 1.15},
            rotation = {0, 0, 0},
            scale = {.9, .9, .8},
            width = 750,
            height = 220,
            --width = 675,
            --height = 155,
            click_function = "loadModels",
            function_owner = self,
        })	
    
        -----------------
        -- Create a Clear Zone button on the Tile
        -- THIS FUNCTION IS CURRENTLY DISABLED
        --self.createButton({
            --label = "Pack Up",
            --font_size = 100,
            --color = {.8, 0, 0},
            --font_color = {0, 0, 0},
            --position = {0, .5, 1.25},
            --rotation = {0, 0, 0},
            --scale = {.7, .7, .6},
            --width = 440,
            --height = 110,                        
            --click_function = "clearzone",
            --function_owner = self,
        --})
    end
    
    -------------------
    -- Prepares the models saved into the Tile from Models Saver tool
    string.split = function(s, delimiter)
        local result = { }
        local from  = 1
        local delim_from, delim_to = string.find( s, delimiter, from  )
        while delim_from do
            table.insert( result, string.sub( s, from , delim_from-1 ) )
            from  = delim_to + 1
            delim_from, delim_to = string.find( s, delimiter, from  )
        end
        table.insert( result, string.sub( s, from  ) )
        return result
    end
	
    function loadModels(objectClicked, clickerColor, altClickUsed)
        -------------------

        -- Easier to filter donig this also, making a new filtered list also
        local IGNORED_GUIDS_SET = {}
        for _, guid in ipairs(IGNORED_GUIDS) do
            IGNORED_GUIDS_SET[guid] = true
        end

        local filtered_objects = {}

        local step1 = false -- spawn zone
        local step2 = false -- find zone
        local step3 = false -- get objects in zone
        local step4 = false -- filter results
        local step5 = false -- delete objects
        local step6 = false -- destory zone
        local step7 = false -- load objects

        --step1
        spawnObject({
            position = ZONE_POS,
            scale = ZONE_SCALE, 
            type = 'ScriptingTrigger',
            callback_owner = self,
            callback_function = function(obj)
                obj.setName("TempZone")
            end
        })
        Wait.time(function() step1 = true end,.1) -- small delay to kick this off.

        --step2
        Wait.condition( 
            function()
                for _,o in ipairs(getObjects()) do
                    if o.type == "Scripting" then
                        if o.getName() == "TempZone" then
                            zone = o
                            step2 = true
                            break
                        end
                    end
                end
            end,
            function()
                return step1 == true
            end, 20
        )

        --step3
        Wait.condition(
            function()
                OBJECTS = zone.getObjects()
                step3 = true
            end,
            function()
                return step2 == true
            end, 20
        )

        --step4
        Wait.condition(
            function()
                for _, obj in ipairs(OBJECTS) do
                    if not IGNORED_GUIDS_SET[obj.guid] then
                        table.insert(filtered_objects, obj)
                    end
                end
                step4 = true
            end,
            function()
                return step3 == true
            end, 20
        )

        --step5
        Wait.condition(
            function()
                for i, obj in ipairs(filtered_objects) do
                    obj.destruct()
                    if i == #filtered_objects then step5 = true end
                end
                if #filtered_objects == 0 then
                    step5 = true
                end    
            end,
            function()
                return step4 == true
            end, 20
        )
        
        --step6
        Wait.condition(function() zone.destruct() step6 = true end, function() return step5 == true end, 20)

        Wait.condition(
            function()
                for _, objectJSON in ipairs(objectJSONs) do 
                    -- Spawn the Models from the JSON data
                    spawnObjectJSON({
                        json = objectJSON
                    })
                end
            end,
            function()
                return step6 == true
            end, 20
        )
    end
    
    -----------------------------------------------------------------------------------------------------------------
    -- This function runs when the Clear Models button is clicked on the Models Tile
    function clearModels(objectClicked, clickerColor, altClickUsed)

        local scriptzoneParams = {                  -- Define the parameters for the scripting zone
               position = {x=1.17, y=10, z=12.50},
            scale = {x=158.19, y=19, z=102.82},
            type = 'ScriptingTrigger',              -- Use the ScriptingTrigger type to spawn a Scripting Zone
            callback_function = scriptzoneCallback, -- Specify the function to call when the zone is created
            callback_owner = self,
            }

    spawnObject(scriptzoneParams)
    
    end

        ]],
        LuaScriptState = "",
        Transform = { --Moved controls to the top of the script for EZ access.
            scaleX = SPAWNED_TILE_SCALE,
            scaleY = SPAWNED_TILE_SCALE,
            scaleZ = SPAWNED_TILE_SCALE
        },
        ColorDiffuse = {0, 0, 0},
        Locked = IS_LOCKED,
    } -- End of Card Stuff
end