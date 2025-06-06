PROTECTED =
{
    "e7ca6e", --Exclude Models Buidler Table 
    "6012bf", --...and ForceOrg Table...
    "4ee1f2", --...and FTC board matObjSurface...
    "948ce5", --...and FTC Table...
    "28865a", --...and FTC Felt Surface.}
}

-- This function runs once when the game starts
function onLoad()
 self.createButton({
    click_function = 'clearZone',
    function_owner = self,
    label = 'Clear Zone',
    position = {0,0.5,12.5},
    scale = {13, 14, 13},
    rotation = {0,0,0},
    width = 1800,
    height = 400,
    font_size = 305,
    color = {.8, 0, 0},
  })
end




function clearZone(objectClicked, clickerColor, altClickUsed)
        -------------------

        -- Easier to filter donig this also, making a new filtered list also
        local PROTECTED_SET = {}
        for _, guid in ipairs(PROTECTED) do
            PROTECTED_SET[guid] = true
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
            position = {x=1.17, y=10, z=12.50},
            scale = {x=158.19, y=19, z=102.82}, 
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
                objects = zone.getObjects()
                step3 = true
            end,
            function()
                return step2 == true
            end, 20
        )

        --step4
        Wait.condition(
            function()
                for _, obj in ipairs(objects) do
                    if not PROTECTED_SET[obj.guid] then
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
        Wait.condition(function() zone.destruct() step6 = true broadcastToAll("Cleared Model Area", "Red") end, function() return step5 == true end)



end