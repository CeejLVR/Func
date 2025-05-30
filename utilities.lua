local Utils = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local services = {VirtualInputManager = Instance.new("VirtualInputManager")}

setmetatable(services, {
    __index = function(self, idx)
        self[idx] = cloneref(game:GetService(idx))
        return self[idx]
    end,
})

--local Utils = require(game.ReplicatedStorage.Utils)
--put in any script that uses this



function Utils.EnsureCharacterLoaded(player)
    if player and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid")  then
        return true
    else
        return false
    end
end


-- Safely calls a function and logs errors if any occur.
-- Use case: Wraps any function call to prevent script crashing from runtime errors.
function Utils.SafeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then warn("[SafeCall Error]:", result) end
    return ok, result
end


-- Safely sets a property on an instance if it exists and is writable.
-- Use case: Avoids errors when trying to set properties on nil or locked instances.
function Utils.SafeSetProperty(instance, property, value)
    if instance and instance[property] ~= nil then
        pcall(function()
            instance[property] = value
        end)
    end
end


-- Checks if an object is a descendant of a given ancestor.
-- Use case: Validates hierarchy relationship, useful for security checks or GUI parenting.
function Utils.IsDescendantOf(object, ancestor)
    while object do
        if object == ancestor then return true end
        object = object.Parent
    end
    return false
end


-- Checks if an instance is valid (exists and not destroyed).
-- Use case: Confirm object existence before accessing it to avoid nil errors.
function Utils.IsValid(instance)
    return instance and instance.Parent ~= nil
end


-- Waits for a descendant of a specific class under a parent, with timeout.
-- Use case: Wait for parts of a character or UI to load before accessing them.
function Utils.WaitForDescendantOfClass(parent, className, timeout)
    timeout = timeout or 10
    local start = tick()
    while tick() - start < timeout do
        for _, descendant in ipairs(parent:GetDescendants()) do
            if descendant:IsA(className) then
                return descendant
            end
        end
        task.wait(0.1)
    end
    return nil
end


-- Gets the player's character, humanoid, and HumanoidRootPart safely.
-- Use case: Frequently used to manipulate player character or track position.
function Utils.GetCharacter(player)
    player = player or Players.LocalPlayer
    if not player then return nil end

    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
    local humanoid = char:FindFirstChildOfClass("Humanoid") or Utils.WaitForDescendantOfClass(char, "Humanoid", 5)

    if humanoid and hrp then
        return char, humanoid, hrp
    end
    return nil
end


-- Returns whether the local player’s character is alive.
-- Use case: Used in scripts that need to check player state before actions.
function Utils.IsPlayerAlive()
    local player = Players.LocalPlayer
    local char = player and player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end


-- Tweens properties on an instance smoothly with error handling.
-- Use case: Animate UI elements, parts, or effects with easing.
function Utils.Tween(instance, props, duration, easingStyle, easingDirection)
    duration = duration or 1
    easingStyle = easingStyle or Enum.EasingStyle.Sine
    easingDirection = easingDirection or Enum.EasingDirection.Out

    local info = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween
    local ok, err = pcall(function()
        tween = TweenService:Create(instance, info, props)
        tween:Play()
    end)
    if not ok then
        warn("[Tween Error]:", err)
    end
    return tween
end


-- Shows a notification to the player using Roblox’s built-in notification system.
-- Use case: Inform the player about important events or script statuses.
function Utils.Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Notification",
            Text = text or "",
            Duration = duration or 4
        })
    end)
end


-- Returns a debounced version of a callback, preventing rapid repeated calls.
-- Use case: Useful for button presses or repeated events to avoid spamming.
function Utils.Debounce(callback, delay)
    local isDebounced = false
    return function(...)
        if isDebounced then return end
        isDebounced = true
        task.spawn(function(...)
            callback(...)
            task.delay(delay or 1, function()
                isDebounced = false
            end)
        end, ...)
    end
end


-- Safely connects a function to an event, catching errors inside the handler.
-- Use case: Keeps event connections robust against runtime errors in handlers.
function Utils.SafeConnect(event, func)
    return event:Connect(function(...)
        local ok, err = pcall(func, ...)
        if not ok then
            warn("[SafeConnect Error]:", err)
        end
    end)
end


-- Runs a looped function at intervals until a break condition returns true.
-- Use case: Continuously run checks or updates safely with error trapping.
function Utils.SafeLoop(interval, shouldBreak, fn)
    task.spawn(function()
        while true do
            local ok, err = pcall(fn)
            if not ok then warn("[SafeLoop Error]:", err) end
            if shouldBreak and shouldBreak() then break end
            task.wait(interval)
        end
    end)
end


--Calculates the distance between two Vector2 or Vector3 values.
--Useful for targeting or proximity checks.
function Utils.CalculateDistance(x, y)
    local typeX = typeof(x)
    local typeY = typeof(y)
    local isVector3Pair = typeX == "Vector3" and typeY == "Vector3"
    local isVector2Pair = typeX == "Vector2" and typeY == "Vector2"

    if not (isVector3Pair or isVector2Pair) then
        warn("CalculateDistance expects two Vector3s or two Vector2s, got:", typeX, "and", typeY)
        return
    end

    return (x - y).Magnitude
end


--Binds a function to a key press using UserInputService.InputBegan.
--Ignores inputs when processed by the game (e.g., typing in chat).
function Utils.AddInputListener(keycode, func)
    local UIS = game:GetService("UserInputService")
    if not keycode or not func then return end
    if typeof(keycode) ~= "EnumItem" or keycode.EnumType ~= Enum.KeyCode then
        warn("AddInputListener expects KeyCode, got:", typeof(keycode))
        return
    end
    if typeof(func) ~= "function" then
        warn("AddInputListener expects a function, got:", typeof(func))
        return
    end

    return UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == keycode then
            func()
        end
    end)
end


--Finds the closest player to the given Vector3 position.
--Optional filters: team name and required child (e.g., "Humanoid").
function Utils.GetClosestPlayer(position, teamName, child)
    if typeof(position) ~= "Vector3" then
        warn("GetClosestPlayer expects Vector3, got:", typeof(position))
        return
    end

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local closestPlayer
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not teamName or (player.Team and player.Team.Name == teamName) then
                if not child or player:FindFirstChild(child) then
                    local distance = Utils.CalculateDistance(position, player.Character.HumanoidRootPart.Position)
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end


return Utils
