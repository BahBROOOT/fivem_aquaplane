Config = {}
Config.Debug = true

Config.CheckIntervalMs = 120 -- How often to check for Aquaplaning (in ms)

Config.MinSpeedKmh = 65.0 -- Minimum speed for Aquaplaning

Config.RainThreshold = 0.15 -- At wich rain level should Aquaplaning start (0.0-1.0)

-- Base probability per second that an event will be triggered,
-- if all conditions are fulfilled (will be dynamically scaled).
Config.BaseChancePerSecond = 0.05

Config.DurationMs = { min = 700, max = 1600 } -- Duration in ms (min/max -> will be randomly selected)

Config.GripMultiplier = 0.55 -- Hower much grip is reduced (0.0-1.0)

Config.TractionLossMult = 1.6 -- Additional Traction-Loss Multiplikator (> 1.0 increases the Traction-Loss)

Config.SteerBiasMax = 0.33 -- Maximum Steer Bias (0.0-1.0) (negative/positive)

-- Effects
Config.CameraShake = true
Config.CameraShakeAmplitude = 0.12  -- 0.0 - 1.0 typical value
Config.ScreenHint = true

-- Vehicle Weighting (GTA5 Vehicle Class IDs)
-- 0: Compacts, 1: Sedans, 2: SUVs, 3: Coupes, 4: Muscle, 5: Sports Classics, 6: Sports,
-- 7: Super, 8: Motorcycles, 9: Off-road, 10: Industrial, 11: Utility, 12: Vans,
-- 13: Cycles, 14: Boats, 15: Helicopters, 16: Planes, 17: Service, 18: Emergency,
-- 19: Military, 20: Commercial, 21: Trains
Config.ClassMultiplier = {
    [0] = 1.10,  -- Compacts
    [1] = 1.00,  -- Sedans
    [2] = 0.85,  -- SUVs (heavy vehicles)
    [3] = 1.05,  -- Coupes
    [4] = 1.00,  -- Muscle
    [5] = 1.05,  -- Sports Classics
    [6] = 1.15,  -- Sports
    [7] = 1.20,  -- Super
    [8] = 0.00,  -- Motorcycles (deactivated - to remove wierd behavior)
    [9] = 0.75,  -- Off-road
    [10] = 0.40, -- Industrial
    [11] = 0.60, -- Utility
    [12] = 0.85, -- Vans
    [13] = 0.00, -- Cycles
    [14] = 0.00, -- Boats
    [15] = 0.00, -- Helicopters
    [16] = 0.00, -- Planes
    [17] = 0.70, -- Service
    [18] = 0.90, -- Emergency
    [19] = 0.50, -- Military
    [20] = 0.50, -- Commercial
    [21] = 0.00  -- Trains
}

-- Optional Wheel Surface Check (if your build/native supports it).
-- If true, tries to check the material under the wheels and increases the chance for asphalt.
Config.TryWheelSurfaceCheck = true
