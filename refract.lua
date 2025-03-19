-- refract.lua
-- A mandala-like FM synthesizer for norns
-- 
-- E1: Pattern Mode (Radial, Spiral, Reflection, Fractal)
-- E2: Harmony (harmonic relationships)
-- E3: Coherence (musical coherence strictness)
--
-- K2: Save snapshot
-- K3: Morph between snapshots
-- K1+K2: Freeze/unfreeze system
-- K1+K3: Reset system to defaults

local UI = require "ui"
local MusicUtil = require "musicutil"
local Mandala = include("lib/mandala")

engine.name = "Refract"

-- Constants
local NUM_PARAMS = 8
local SCREEN_FRAMERATE = 15
local PARAM_NAMES = {
  "Harmonic Center",
  "Orbital Period",
  "Symmetry",
  "Resonance",
  "Radiance",
  "Flow Rate",
  "Propagation",
  "Reflection"
}
local PATTERN_MODES = {"Radial", "Spiral", "Reflection", "Fractal"}
local HARMONY_DEFAULT = 0.5
local COHERENCE_DEFAULT = 0.5
local MAX_SNAPSHOTS = 4

-- Configuration for MIDI CCs
local MIDI_CC_MAP = {
  HARMONY = 9,
  COHERENCE = 10,
  MORPH = 11,
  FREEZE = 12
}

-- State variables
local mandala
local params_dirty = false
local alt_key = false
local pattern_mode = 1
local harmony = HARMONY_DEFAULT
local coherence = COHERENCE_DEFAULT
local snapshots = {}
local current_snapshot = 1
local morph_active = false
local morph_position = 0
local morph_start_snapshot = 1
local morph_end_snapshot = 2
local midi_in_device = nil
local midi_out_device = nil
local redraw_metro
local last_time_delta = 1/SCREEN_FRAMERATE
local last_time = 0

-- Update engine parameters based on mandala node values
local function update_engine_parameter(index, value)
  -- Validate index
  if index < 1 or index > NUM_PARAMS then
    print("Error: Invalid parameter index: " .. index)
    return
  end
  
  -- Validate value
  value = math.min(math.max(value or 0.5, 0), 1)
  
  -- Scale normalized value (0-1) to appropriate range for engine
  local scaled_value = value
  
  -- Parameter-specific scaling
  if index == 1 then
    -- Harmonic Center: MIDI note range 36-96
    scaled_value = util.linlin(0, 1, 36, 96, value)
  elseif index == 2 then
    -- Orbital Period: 0.25-4.0 beats
    scaled_value = util.linexp(0, 1, 0.25, 4.0, value)
  elseif index == 6 then
    -- Flow Rate: 0.25-4.0 beats
    scaled_value = util.linexp(0, 1, 0.25, 4.0, value)
  end
  
  -- Send to engine
  engine.controlParam(index, scaled_value)
end

-- Handle pulse arrival and parameter interactions
local function handle_pulse_arrival(source, target, strength)
  -- When a pulse arrives at its destination, cause an effect
  if not source or not target or not strength then
    -- Early return for invalid inputs
    return
  end
  
  -- Calculate new parameter value based on source, target, and harmony
  local source_value = mandala.nodes[source].value
  local target_value = mandala.nodes[target].value
  
  -- Define thresholds for different harmonic relationships
  local HIGH_HARMONY_THRESHOLD = 0.7
  local LOW_HARMONY_THRESHOLD = 0.3
  
  -- Calculate harmonic relationship
  local harmonic_ratio = harmony * 0.5 + 0.5 -- 0.5-1.0 range
  local new_value
  
  if harmony > HIGH_HARMONY_THRESHOLD then
    -- More consonant relations at high harmony
    new_value = source_value * harmonic_ratio + target_value * (1-harmonic_ratio)
    -- Snap to "perfect" intervals
    local perfect_intervals = {0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0}
    local closest_value = 0.5
    local closest_distance = 1.0
    for _, interval in ipairs(perfect_intervals) do
      local distance = math.abs(new_value - interval)
      if distance < closest_distance then
        closest_distance = distance
        closest_value = interval
      end
    end
    if closest_distance < 0.1 then
      new_value = closest_value
    end
  elseif harmony < LOW_HARMONY_THRESHOLD then
    -- More chaotic relations at low harmony
    new_value = source_value * (1 - harmonic_ratio) + 
                target_value * harmonic_ratio +
                math.random() * 0.1 * (1 - harmony * 2) -- Add randomness
  else
    -- Balanced relations at mid harmony
    new_value = (source_value + target_value) / 2
  end
  
  -- Apply final calculation with constraint
  new_value = math.min(math.max(new_value, 0.0), 1.0)
  
  -- Update the target node
  mandala.nodes[target].value = new_value
  
  -- Update the engine parameter
  update_engine_parameter(target, new_value)
  
  -- Send a pulse response to the engine for audible feedback
  engine.pulse(target, strength)
  
  -- If strong connection, propagate pulses further
  if strength > 0.6 and mandala.connections[target] then
    for next_target, connection_strength in pairs(mandala.connections[target]) do
      if next_target ~= source and connection_strength > 0.5 and math.random() < 0.3 then
        -- Create secondary pulse with reduced strength
        Mandala.create_pulse(mandala, target, next_target, strength * 0.6)
      end
    end
  end
end

-- Update all parameters and handle animations
local function update_parameters(dt)
  -- Default time delta if not provided
  dt = dt or last_time_delta
  
  -- Check for completed pulses
  local source, target, strength = Mandala.update_pulses(mandala, params:get("flow_rate") * dt * 60)
  
  if source and target then
    handle_pulse_arrival(source, target, strength)
  end
  
  -- Generate coherence-based tension if needed
  if not morph_active and math.random() < coherence * 0.05 * dt * 60 then
    Mandala.generate_coherence_tension(mandala, coherence)
  end
  
  -- Update morph if active
  if morph_active then
    morph_position = morph_position + 0.01 * dt * 60
    if morph_position >= 1 then
      morph_active = false
      morph_position = 0
    else
      Mandala.morph_values(mandala, snapshots[morph_start_snapshot], snapshots[morph_end_snapshot], morph_position)
      
      -- Update engine parameters based on morphed values
      for i=1,NUM_PARAMS do
        update_engine_parameter(i, mandala.nodes[i].value)
      end
    end
  end
end

-- Save current state as a snapshot
local function save_snapshot()
  -- Save current mandala state
  snapshots[current_snapshot] = Mandala.get_snapshot(mandala)
  
  -- Feedback notification
  local message = "Snapshot " .. current_snapshot .. " saved"
  print(message)
  
  -- Rotate to next slot
  current_snapshot = (current_snapshot % MAX_SNAPSHOTS) + 1
end

-- Begin morphing between snapshots
local function start_morph()
  -- Only morph if we have at least two snapshots
  local count = 0
  for i=1,MAX_SNAPSHOTS do
    if snapshots[i] then count = count + 1 end
  end
  
  if count < 2 then
    print("Need at least 2 snapshots to morph")
    return
  end
  
  -- Find start and end snapshots
  local start_idx = current_snapshot - 1
  if start_idx < 1 then start_idx = MAX_SNAPSHOTS end
  
  local end_idx = (current_snapshot % MAX_SNAPSHOTS) + 1
  
  -- Ensure both exist
  if not snapshots[start_idx] or not snapshots[end_idx] then
    print("Cannot morph: invalid snapshots")
    return
  end
  
  -- Begin morphing
  morph_active = true
  morph_position = 0
  morph_start_snapshot = start_idx
  morph_end_snapshot = end_idx
  
  print("Morphing from snapshot " .. start_idx .. " to " .. end_idx)
end

-- Toggle freeze state
local function toggle_freeze()
  local freeze_state = params:get("freeze")
  params:set("freeze", 1 - freeze_state)
  Mandala.set_freeze(mandala, freeze_state == 0)
  print("System " .. (freeze_state == 0 and "frozen" or "unfrozen"))
end

-- Reset system to defaults
local function reset_system()
  -- Reset engine
  engine.reset()
  
  -- Reset mandala
  Mandala.reset(mandala)
  
  -- Update engine parameters with default values
  for i=1,NUM_PARAMS do
    update_engine_parameter(i, mandala.nodes[i].value)
  end
  
  -- Reset control parameters
  harmony = HARMONY_DEFAULT
  coherence = COHERENCE_DEFAULT
  pattern_mode = 1
  Mandala.apply_pattern(mandala, pattern_mode)
  
  print("System reset to defaults")
end

-- Handle encoder interactions
function enc(n, d)
  if n == 1 then
    -- E1: Pattern Mode
    pattern_mode = util.clamp(pattern_mode + d, 1, #PATTERN_MODES)
    Mandala.apply_pattern(mandala, pattern_mode)
    print("Pattern: " .. PATTERN_MODES[pattern_mode])
  elseif n == 2 then
    -- E2: Harmony
    harmony = util.clamp(harmony + d * 0.01, 0, 1)
  elseif n == 3 then
    -- E3: Coherence
    coherence = util.clamp(coherence + d * 0.01, 0, 1)
  end
end

-- Handle button interactions
function key(n, z)
  if n == 1 then
    -- K1: Alt modifier
    alt_key = (z == 1)
  elseif n == 2 and z == 1 then
    if alt_key then
      -- K1+K2: Freeze/unfreeze
      toggle_freeze()
    else
      -- K2: Save snapshot
      save_snapshot()
    end
  elseif n == 3 and z == 1 then
    if alt_key then
      -- K1+K3: Reset system
      reset_system()
    else
      -- K3: Morph between snapshots
      start_morph()
    end
  end
end

-- Draw interface
function redraw()
  screen.clear()
  
  -- Draw mandala visualization
  Mandala.draw(mandala)
  
  -- Draw mode and status 
  screen.move(2, 8)
  screen.level(15)
  screen.text(PATTERN_MODES[pattern_mode])
  
  -- Draw harmony level
  screen.move(2, 62)
  screen.level(5)
  screen.text("H")
  screen.move(10, 62)
  screen.level(harmony * 15)
  screen.rect(10, 60, harmony * 20, 2)
  screen.fill()
  
  -- Draw coherence level
  screen.move(35, 62)
  screen.level(5)
  screen.text("C")
  screen.move(43, 62)
  screen.level(coherence * 15)
  screen.rect(43, 60, coherence * 20, 2)
  screen.fill()
  
  -- Draw morph progress if active
  if morph_active then
    screen.move(80, 62)
    screen.level(15)
    screen.text("Morph")
    screen.move(110, 62)
    screen.rect(110, 60, morph_position * 15, 2)
    screen.fill()
  end
  
  -- Draw snapshot indicator
  screen.move(125, 8)
  screen.level(8)
  screen.text(current_snapshot .. "/" .. MAX_SNAPSHOTS)
  
  screen.update()
end

-- Handle MIDI input
local function midi_event(data)
  local msg = midi.to_msg(data)
  
  if msg.type == "cc" then
    -- Handle control change messages
    if msg.cc == MIDI_CC_MAP.HARMONY then
      harmony = util.clamp(msg.val / 127, 0, 1)
    elseif msg.cc == MIDI_CC_MAP.COHERENCE then
      coherence = util.clamp(msg.val / 127, 0, 1)
    elseif msg.cc == MIDI_CC_MAP.MORPH and msg.val > 64 then
      start_morph()
    elseif msg.cc == MIDI_CC_MAP.FREEZE and msg.val > 64 then
      toggle_freeze()
    elseif msg.cc >= 1 and msg.cc <= NUM_PARAMS then
      -- Direct parameter control via MIDI CCs 1-8
      local value = msg.val / 127
      Mandala.update_node_value(mandala, msg.cc, value, harmony)
      update_engine_parameter(msg.cc, value)
    end
  end
end

-- Initialize the script
function init()
  -- Set up parameters
  params:add_separator("Refract Engine")
  
  for i=1, NUM_PARAMS do
    local id = "param_" .. i
    local name = PARAM_NAMES[i]
    
    -- Set up parameter ranges based on parameter type
    local param_spec
    if i == 1 then
      -- Harmonic Center (MIDI note)
      param_spec = controlspec.new(36, 96, "lin", 0, 60, "")
    elseif i == 2 or i == 6 then
      -- Orbital Period and Flow Rate (beats)
      param_spec = controlspec.new(0.25, 4.0, "exp", 0, 1.0, "")
    else
      -- Standard normalized parameters
      param_spec = controlspec.new(0, 1, "lin", 0, 0.5, "")
    end
    
    params:add_control(id, name, param_spec)
    params:set_action(id, function(value)
      -- Convert to normalized value for mandala
      local normalized_value
      if i == 1 then
        normalized_value = util.linlin(36, 96, 0, 1, value)
      elseif i == 2 or i == 6 then
        normalized_value = util.linlin(0.25, 4.0, 0, 1, value)
      else
        normalized_value = value
      end
      
      -- Update mandala
      Mandala.update_node_value(mandala, i, normalized_value, harmony)
      
      -- Update engine directly
      update_engine_parameter(i, normalized_value)
    end)
  end
  
  -- Add freeze toggle
  params:add_option("freeze", "Freeze", {"Off", "On"}, 1)
  params:set_action("freeze", function(value)
    engine.freeze(value - 1)
    Mandala.set_freeze(mandala, value == 2)
  end)
  
  -- Initialize mandala
  mandala = Mandala.new(NUM_PARAMS)
  Mandala.apply_pattern(mandala, pattern_mode)
  
  -- Initialize snapshots
  for i=1,MAX_SNAPSHOTS do
    snapshots[i] = nil
  end
  
  -- Create initial snapshot
  snapshots[1] = Mandala.get_snapshot(mandala)
  
  -- Initialize MIDI
  for i=1,#midi.vports do
    local device = midi.connect(i)
    device.event = midi_event
  end
  
  -- Set up clock for animation updates
  clock.run(function()
    while true do
      local current_time = util.time()
      local dt = current_time - last_time
      last_time = current_time
      last_time_delta = dt
      
      update_parameters(dt)
      clock.sleep(1/30) -- Update physics at 30Hz
    end
  end)
  
  -- Set up screen refresh metro
  redraw_metro = metro.init()
  redraw_metro.time = 1/SCREEN_FRAMERATE
  redraw_metro.event = function()
    redraw()
  end
  redraw_metro:start()
  
  -- Initial parameter settings
  for i=1,NUM_PARAMS do
    update_engine_parameter(i, mandala.nodes[i].value)
  end
end

-- Clean up when script is stopped
function cleanup()
  -- Stop redraw metro
  redraw_metro:stop()
  
  -- Clear snapshots
  for i=1,MAX_SNAPSHOTS do
    snapshots[i] = nil
  end
  
  -- Clean up MIDI connections
  for i=1,#midi.vports do
    midi.vports[i].event = nil
  end
end
