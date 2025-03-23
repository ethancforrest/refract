--- rhythm_engine.lua
-- Simple rhythmic pulsation system for Refract
-- @module RhythmEngine

local RhythmEngine = {}

-- Configuration
local clock_id = nil
local is_active = false
local debug_mode = false
local global_rate = 1
local global_depth = 0.2
local global_pattern = 1
local current_phase = 0
local registered_params = {}

-- Initialize the rhythm engine
function RhythmEngine.init(callback)
  -- Store configuration
  if debug_mode then print("Rhythm engine initialized") end
  return RhythmEngine
end

-- Register a parameter for rhythmic modulation
function RhythmEngine.register_param(param_id, settings)
  if not settings then settings = {} end
  
  registered_params[param_id] = {
    depth_scale = settings.depth_scale or 1.0,
    pattern = settings.pattern or global_pattern,
    rate_scale = settings.rate_scale or 1.0,
    phase_offset = settings.phase_offset or 0,
    base_value = settings.base_value or params:get(param_id),
    range = settings.range or {0, 1},
    last_value = 0
  }
  
  if debug_mode then print("Registered param: " .. param_id) end
  return RhythmEngine
end

-- Set rate (relative to quarter notes)
function RhythmEngine.set_rate(rate)
  global_rate = util.clamp(rate, 0.25, 4)
  if debug_mode then print("Rhythm rate: " .. global_rate) end
  return RhythmEngine
end

-- Set depth (intensity of modulation)
function RhythmEngine.set_depth(depth)
  global_depth = util.clamp(depth, 0, 1)
  if debug_mode then print("Rhythm depth: " .. global_depth) end
  return RhythmEngine
end

-- Set pattern type
function RhythmEngine.set_pattern(pattern)
  global_pattern = pattern
  if debug_mode then print("Rhythm pattern: " .. pattern) end
  return RhythmEngine
end

-- Get current phase (for visualization)
function RhythmEngine.get_phase()
  -- Simple simulation for the first version
  return (os.time() % 2) / 2
end

-- Toggle activity
function RhythmEngine.set_active(active)
  is_active = active
  if debug_mode then 
    if active then
      print("Rhythm engine activated")
    else
      print("Rhythm engine deactivated")
    end
  end
  return RhythmEngine
end

-- Toggle debug mode
function RhythmEngine.set_debug(debug)
  debug_mode = debug
  return RhythmEngine
end

-- Apply calculated modulations to parameters
function RhythmEngine.apply_modulation()
  -- For the first version, simply update phase but don't actually modulate
  -- This avoids potential crashes while still showing visual feedback
  current_phase = (os.time() % 2) / 2
  return
end

-- Get modulation values for visualization
function RhythmEngine.get_modulation_values()
  local values = {}
  for param_id, config in pairs(registered_params) do
    values[param_id] = 0  -- Just return 0 for now
  end
  return values
end

-- Get debug state
function RhythmEngine.get_state()
  return {
    active = is_active,
    rate = global_rate,
    depth = global_depth,
    pattern = global_pattern,
    phase = current_phase,
    params = registered_params
  }
end

return RhythmEngine