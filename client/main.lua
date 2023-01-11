--[[Copyright © 2023 Mycroft (Kasey Fitton)

All rights reserved.

Permission is hereby granted, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software with 'All rights reserved'. Even if 'All rights reserved' is very clear :

  You shall not sell and/or resell this software
  You Can use and Modify this software
  You Shall Not Distribute and/or Redistribute the software
  The above copyright notice and this permission notice shall be included in all copies and files of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]

function Interact(Model, Object)
    -- Function Based upon: https://github.com/smallo92/xnVending
    ESX.TriggerServerCallback("vending:canBuyDink", function(canBuy)
        if canBuy then
            local ped = ESX.PlayerData.ped
            local position = GetOffsetFromEntityInWorldCoords(Object, 0.0, -0.97, 0.05)
           
            TaskTurnPedToFaceEntity(ped, Object, -1)
            RequestAnimDict(Config.DispenseDict[1])

            while not HasAnimDictLoaded(Config.DispenseDict[1]) do
                Wait(0)
            end

            RequestAmbientAudioBank("VENDING_MACHINE")
            HintAmbientAudioBank("VENDING_MACHINE", 0, -1)

            SetPedCurrentWeaponVisible(ped, false, true, 1, 0)
            RequestModel(Config.Models[Model].obj)
            while not HasModelLoaded(Config.Models[Model].obj) do
                Wait(0)
            end
            SetPedResetFlag(ped, 322, true)
            if not IsEntityAtCoord(ped, position, 0.1, 0.1, 0.1, false, true, 0)  then
                TaskGoStraightToCoord(ped, position, 2.0, 20000, GetEntityHeading(Object), 0.1)
                while not IsEntityAtCoord(ped, position,0.1, 0.1, 0.1, false, true, 0) do
                    TaskGoStraightToCoord(ped, position, 5.0, 20000, GetEntityHeading(Object), 0.2)
                    Wait(1000)
                end
            end
            TriggerServerEvent("vending:buyDrink", Model)
            TaskTurnPedToFaceEntity(ped, Object, -1)
            Wait(500)
            TaskPlayAnim(ped, Config.DispenseDict[1], Config.DispenseDict[2], 4.0, 5.0, -1, true, 1, 0, 0, 0)
            Wait(2500)
            local canModel = CreateObjectNoOffset(Config.Models[Model].obj, position, true, false, false)
            SetEntityAsMissionEntity(canModel, true, true)
            SetEntityProofs(canModel, false, true, false, false, false, false, 0, false)
            AttachEntityToEntity(canModel, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
            Wait(3700)
            TaskPlayAnim(ped, Config.DispenseDict[1], "PLYR_BUY_DRINK_PT2",4.0, 5.0, -1, true, 1, 0, 0, 0)
            Wait(1800)
            TriggerEvent('esx_status:add', 'hunger', Config.Models[Model].hunger)
            TriggerEvent('esx_status:add', 'thirst', Config.Models[Model].thirst)
            TaskPlayAnim(ped, Config.DispenseDict[1], "PLYR_BUY_DRINK_PT3",4.0, 5.0, -1, true, 1, 0, 0, 0)
            Wait(600)
            DetachEntity(canModel, true, true)
            ApplyForceToEntity(canModel, 1, vector3(-6.0, -10.0, -2.0), 0, 0, 0, 0, true, true, false, false, true)
            SetEntityAsNoLongerNeeded(canModel)
            Wait(1600)
            ClearPedTasks(ped)
            ReleaseAmbientAudioBank()
            RemoveAnimDict(Config.DispenseDict[1])
            SetModelAsNoLongerNeeded(Config.Models[Model].obj)
        else
            ESX.ShowNotification("Cannot Afford Drink!", "error")
        end
    end, Model)
end

local Interactions = {}

local function CreateObjectInteration(name, model, distance, helpText, action)
    Interactions[#Interactions + 1] = {name = name, model = model, distance = distance, helpText = helpText,action = action}
end

local Drawing = {showing = false, text = ""}

CreateThread(function()
    while not ESX.PlayerLoaded do
        Wait(0)
    end
    if Config.oxTarget then
        for i=1, #(Config.Models) do
            local options = {
                {
                    name = Config.Models[i].model..'-vend',
                    icon = 'fa-solid fa-road',
                    label = Config.Models[i].interactionLabel,
                    onSelect = function(entity)
                        Interact(i, entity)
                    end
                },
                distance = 1.0
            }
            exports.ox_target:addModel(Config.Models[i].model, options)
        end
    else
        for i=1, #(Config.Models) do
            CreateObjectInteration(Config.Models[i].model.. "-vend", Config.Models[i].model, 1.0, "[E] " ..Config.Models[i].interactionLabel .. " - $"..Config.Models[i].price, function(Object)
                Interact(i, Object)
            end)
        end
        while true do
            local Sleep = 1000
            local PlayerCoords = GetEntityCoords(ESX.PlayerData.ped)
            local Near = false
            for _,v in pairs(Interactions) do
                local interation = v
                local Object = GetClosestObjectOfType(PlayerCoords, interation.distance, joaat(interation.model), false)
                if Object and DoesEntityExist(Object) then
                    local coords = GetEntityCoords(Object)
                    local dist = #(PlayerCoords - coords)
                    if dist <= interation.distance then
                        Near = true
                        Sleep = 0
                        if interation.helpText then
                            if not Drawing.showing or Drawing.text ~= interation.helpText then
                                ESX.TextUI(interation.helpText, "info")
                                Drawing.showing = true
                                Drawing.text = interation.helpText
                            end
                        end
                        if interation.action then
                            if IsControlJustPressed(0, 38) then
                                local act = assert(pcall(interation.action, Object))
                                if not act then
                                    print("[ERROR] an Error occured during interaction on Object " .. interation.name)
                                end
                            end
                        end
                    end
                end
            end
            if not Near and Drawing.showing then
                ESX.HideUI()
                Drawing.showing = false
                Drawing.text = ""
            end
            Wait(Sleep)
        end
    end
end)