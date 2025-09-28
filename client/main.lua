--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local backups = {}
local active = false
local activeUntil = 0
local activeVeh = nil
local originalBias = 0.0

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function dbg(...)
    if Config.Debug then
        print("[aquaplane]", ...)
    end
end

local function clamp(x, min, max)
    if x < min then return min end
    if x > max then return max end
    return x
end

local function randomRange(a, b)
    return a + (b - a) * math.random()
end

local function getVehKey(veh)
    return veh
end

local function backupHandling(veh)
    local key = getVehKey(veh)
    if backups[key] then return end
    backups[key] = {
        fTractionCurveMin = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMin'),
        fTractionCurveMax = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMax'),
        fLowSpeedTractionLossMult = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fLowSpeedTractionLossMult'),
        fTractionLossMult = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionLossMult')
    }
    dbg("Saved handling for", veh)
end

local function restoreHandling(veh)
    local key = getVehKey(veh)
    local b = backups[key]
    if not b then return end
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMin', b.fTractionCurveMin)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMax', b.fTractionCurveMax)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fLowSpeedTractionLossMult', b.fLowSpeedTractionLossMult)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionLossMult', b.fTractionLossMult)
    backups[key] = nil
    dbg("Restored handling for", veh)
end

local function showHint(msg, ms)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, ms or 1200)
end

local function startAquaplane(veh, durationMs)
    active = true
    activeVeh = veh
    activeUntil = GetGameTimer() + durationMs
    backupHandling(veh)

    -- Reduce Grip
    local b = backups[getVehKey(veh)]
    local newMin = b.fTractionCurveMin * Config.GripMultiplier
    local newMax = b.fTractionCurveMax * clamp(Config.GripMultiplier + 0.05, 0.1, 1.0)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMin', newMin)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMax', newMax)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fLowSpeedTractionLossMult', b.fLowSpeedTractionLossMult * 1.15)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionLossMult', b.fTractionLossMult * Config.TractionLossMult)

    SetVehicleReduceGrip(veh, true)

    -- Steer Bias
    originalBias = 0.0
    local bias = (math.random() < 0.5 and -1 or 1) * randomRange(0.05, Config.SteerBiasMax)
    SetVehicleSteerBias(veh, bias)

    if Config.ScreenHint then
        showHint("~b~AQUAPLANING!~s~ Reduce Speed and Steer carefully.", 1400)
    end
    if Config.CameraShake then
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", Config.CameraShakeAmplitude)
    end
    dbg(("Started Aquaplaning for %d ms, bias %.2f"):format(durationMs, bias))
end

local function stopAquaplane()
    if not active then return end
    if DoesEntityExist(activeVeh) then
        SetVehicleReduceGrip(activeVeh, false)
        SetVehicleSteerBias(activeVeh, originalBias or 0.0)
        restoreHandling(activeVeh)
    end
    active = false
    activeVeh = nil
    activeUntil = 0
    if Config.CameraShake then
        StopGameplayCamShaking(true)
    end
    dbg("Aquaplaning stopped")
end

local function classMultiplierFor(veh)
    local cls = GetVehicleClass(veh)
    return Config.ClassMultiplier[cls] or 0.0
end

local function kmhFromEntitySpeed(entity)
    return GetEntitySpeed(entity) * 3.6
end

-- (Optional) Wheel-Surface-Check – higher Chance on Asphalt/Bitumen
local function surfaceBonus(veh)
    if not Config.TryWheelSurfaceCheck then return 1.0 end
    local ok = pcall(function()
        local asphaltLike = 0
        local checked = 0
        for i = 0, 3 do
            local mat = GetVehicleWheelSurfaceMaterial(veh, i) -- kann nil/0 sein
            if mat ~= nil then
                checked = checked + 1
                -- "asphalt-like" id's
                if mat == 282940568 or mat == -1084640111 or mat == -124769592  or mat == -1942898710 then
                    asphaltLike = asphaltLike + 1
                end
            end
        end
        if checked == 0 then return 1.0 end
        local share = asphaltLike / checked
        -- More asphalt = more risk
        return 1.0 + share * 0.35
    end)
    if not ok then
        return 1.0
    end
end


--------------------------------------------------------------------------------
-- Main Thread
--------------------------------------------------------------------------------


CreateThread(function()
    math.randomseed(GetGameTimer())
    local cooldownUntil = 0

    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped then
                local speedKmh = kmhFromEntitySpeed(veh)
                local rain = GetRainLevel() or 0.0
                local clsMult = classMultiplierFor(veh)
                local eligible = clsMult > 0.0

                if active and GetGameTimer() > activeUntil then
                    stopAquaplane()
                    cooldownUntil = GetGameTimer() + 1200
                end

                if not active and eligible and GetGameTimer() > cooldownUntil then
                    if IsVehicleOnAllWheels(veh) and speedKmh >= Config.MinSpeedKmh and rain >= Config.RainThreshold then
                        local speedFactor = clamp((speedKmh - Config.MinSpeedKmh) / 90.0, 0.0, 1.0)
                        local intervalSec = Config.CheckIntervalMs / 1000.0

                        local chancePerSec = Config.BaseChancePerSecond * clsMult * clamp(rain * 1.5, 0.0, 1.5) * (surfaceBonus(veh) or 1.0)
                        local chanceThisTick = 1.0 - math.pow(1.0 - chancePerSec * speedFactor, intervalSec)

                        if Config.Debug then
                            dbg(("spd=%.1f rain=%.2f classMult=%.2f chanceTick=%.4f"):format(speedKmh, rain, clsMult, chanceThisTick))
                        end

                        if math.random() < chanceThisTick then
                            startAquaplane(veh, math.floor(randomRange(Config.DurationMs.min, Config.DurationMs.max)))
                        end
                    end
                end
            else
                if active then stopAquaplane() end
            end
        else
            if active then stopAquaplane() end
        end
        Wait(Config.CheckIntervalMs)
    end
end)


--------------------------------------------------------------------------------
-- Additional Safety-net
--------------------------------------------------------------------------------


AddEventHandler("onResourceStop", function(resName)
    if (GetCurrentResourceName() ~= resName) then return end
    if active then
        stopAquaplane()
    end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        restoreHandling(veh)
        SetVehicleReduceGrip(veh, false)
        SetVehicleSteerBias(veh, 0.0)
    end
end)
