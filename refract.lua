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
--
-- Hold K1 while turning E1: Switch to MIDI mapping page
-- In MIDI mapping page:
--   E2: Select parameter
--   K3: MIDI learn for selected parameter
--   K1: Return to main page

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

-- MIDI mapping variables
local pages = {"Main", "MIDI Map"}
local current_page = 1
local selected_param = 1
local midi_learn_active = false
local midi_learn_target = nil

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

-- Start MIDI learn for a parameter
function start_midi_learn(target_param)
  midi_learn_active = true
  midi_learn_target = target_param
  print("MIDI learn active for " .. target_param)
end

-- Save MIDI mappings to file
function save_midi_mappings(filename)
  local data = {}
  
  for i=1, NUM_PARAMS do
    data["midi_cc_" .. i] = params:get("midi_cc_" .. i)
  end
  
  data.midi_cc_harmony = params:get("midi_cc_harmony")
  data.midi_cc_coherence = params:get("midi_cc_coherence")
  data.midi_cc_morph = params:get("midi_cc_morph")
  data.midi_cc_freeze = params:get("midi_cc_freeze")
  
  tab.save(data, filename)
  print("MIDI mappings saved to " .. filename)
end

-- Load MIDI mappings from file
function load_midi_mappings(filename)
  if util.file_exists(filename) then
    local data = tab.load(filename)
    
    for i=1, NUM_PARAMS do
      if data["midi_cc_" .. i] then
        params:set("midi_cc_" .. i, data["midi_cc_" .. i])
      end
    end
    
    if data.midi_cc_harmony then params:set("midi_cc_harmony", data.midi_cc_harmony) end
    if data.midi_cc_coherence then params:set("midi_cc_coherence", data.midi_cc_coherence) end
    if data.midi_cc_morph then params:set("midi_cc_morph", data.midi_cc_morph) end
    if data.midi_cc_freeze then params:set("midi_cc_freeze", data.midi_cc_freeze) end
    
    print("MIDI mappings loaded from " .. filename)
  else
    print("MIDI mapping file not found: " .. filename)
  end
end

-- Handle encoder interactions
function enc(n, d)
  if current_page == 1 then
    -- Main page encoders
    if alt_key and n == 1 then
      -- Switch to MIDI mapping page when holding K1 and turning E1
      current_page = 2
      selected_param = 1
    elseif n == 1 then
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
  else
    -- MIDI mapping page encoders
    if n == 2 then
      -- E2: Select parameter
      local total_params = NUM_PARAMS + 4 -- main params + meta params
      selected_param = util.clamp(selected_param + d, 1, total_params)
    elseif n == 3 then
      -- E3: Manually adjust CC value
      local param_id
      if selected_param <= NUM_PARAMS then
        param_id = "midi_cc_" .. selected_param
      else
        local meta_params = {"harmony", "coherence", "morph", "freeze"}
        param_id = "midi_cc_" .. meta_params[selected_param - NUM_PARAMS]
      end
      
      -- Adjust CC value
      local current_val = params:get(param_id)
      params:set(param_id, util.clamp(current_val + d, 0, 127))
    end
  end
end

-- Handle button interactions
function key(n, z)
  if n == 1 then
    -- K1: Alt modifier
    alt_key = (z == 1)
    
    -- Return to main page when pressing K1 on MIDI mapping page
    if z == 1 and current_page == 2 then
      current_page = 1
      midi_learn_active = false
      midi_learn_target = nil
    end
  elseif current_page == 1 then
    -- Main page keys
    if n == 2 and z == 1 then
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
  else
    -- MIDI mapping page keys
    if n == 3 and z == 1 then
      -- K3: Start MIDI learn for selected parameter
      if selected_param <= NUM_PARAMS then
        start_midi_learn(tostring(selected_param))
      else
        local meta_params = {"harmony", "coherence", "morph", "freeze"}
        start_midi_learn(meta_params[selected_param - NUM_PARAMS])
      end
    end
  end
end

-- Handle MIDI input
local function midi_event(data)
  local msg = midi.to_msg(data)
  
  if msg.type == "cc" then
    local cc_num = msg.cc
    local cc_val = msg.val
    
    -- Check if we're in MIDI learn mode
    if midi_learn_active and midi_learn_target then
      -- Handle numeric parameter indices
      if tonumber(midi_learn_target) ~= nil then
        local param_idx = tonumber(midi_learn_target)
        params:set("midi_cc_" .. param_idx, cc_num)
      else
        -- Handle meta parameters
        params:set("midi_cc_" .. midi_learn_target, cc_num)
      end
      
      print("Mapped CC " .. cc_num .. " to " .. midi_learn_target)
      midi_learn_active = false
      midi_learn_target = nil
      return
    end
    
    -- Check each parameter for a matching CC
    for i=1, NUM_PARAMS do
      if params:get("midi_cc_" .. i) == cc_num then
        local normalized_val = cc_val / 127
        Mandala.update_node_value(mandala, i, normalized_val, harmony)
        update_engine_parameter(i, normalized_val)
        return
      end
    end
    
    -- Check meta-parameters
    if params:get("midi_cc_harmony") == cc_num then
      harmony = util.clamp(cc_val / 127, 0, 1)
    elseif params:get("midi_cc_coherence") == cc_num then
      coherence = util.clamp(cc_val / 127, 0, 1)
    elseif params:get("midi_cc_morph") == cc_num and cc_val > 64 then
      start_morph()
    elseif params:get("midi_cc_freeze") == cc_num and cc_val > 64 then
      toggle_freeze()
    end
  end
end

-- Draw interface
function redraw()
  screen.clear()
  
  if current_page == 1 then
    -- Draw main page
    
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
  else
    -- Draw MIDI mapping page
    screen.move(64, 8)
    screen.level(15)
    screen.text_center("MIDI Mapping")
    
    -- Draw parameter list
    local start_idx = math.max(1, selected_param - 4)
    for i=0, 6 do
      local param_idx = start_idx + i
      if param_idx <= NUM_PARAMS + 4 then
        local y = 16 + i * 7
        screen.move(2, y)
        screen.level(param_idx == selected_param and 15 or 5)
        
        -- Parameter name
        local name
        if param_idx <= NUM_PARAMS then
          name = PARAM_NAMES[param_idx]
        else
          name = ({"Harmony", "Coherence", "Morph", "Freeze"})[param_idx - NUM_PARAMS]
        end
        screen.text(name)
        
        -- CC value
        screen.move(126, y)
        local cc_val
        if param_idx <= NUM_PARAMS then
          cc_val = params:get("midi_cc_" .. param_idx)
        else
          local meta_params = {"harmony", "coherence", "morph", "freeze"}
          cc_val = params:get("midi_cc_" .. meta_params[param_idx - NUM_PARAMS])
        end
        
        screen.text_right(cc_val == 0 and "None" or cc_val)
      end
    end
    
    -- Instructions
    screen.move(64, 58)
    screen.level(4)
    if midi_learn_active then
      screen.text_center("Move a MIDI control...")
    else
      screen.text_center("K3: MIDI learn")
    end
  end
  
  screen.update()
end

-- Initialize the script
function init()
  -- Create data directory if it doesn't exist
  if not util.file_exists(_path.data.."refract/") then
    util.make_dir(_path.data.."refract/")
    print("Made refract data directory")
  end
  
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
  
  -- Add MIDI mapping parameters
  params:add_separator("MIDI Mapping")
  
  for i=1, NUM_PARAMS do
    local param_name = PARAM_NAMES[i]
    
    params:add_number("midi_cc_" .. i, param_name .. " CC", 0, 127, 0, 
      function(param) return param:get() == 0 and "None" or param:get() end)
  end
  
  -- Also add mappings for meta-parameters
  params:add_number("midi_cc_harmony", "Harmony CC", 0, 127, 0,
    function(param) return param:get() == 0 and "None" or param:get() end)
  params:add_number("midi_cc_coherence", "Coherence CC", 0, 127, 0,
    function(param) return param:get() == 0 and "None" or param:get() end)
  params:add_number("midi_cc_morph", "Morph Trigger CC", 0, 127, 0,
    function(param) return param:get() == 0 and "None" or param:get() end)
  params:add_number("midi_cc_freeze", "Freeze Toggle CC", 0, 127, 0,
    function(param) return param:get() == 0 and "None" or param:get() end)
  
  -- Add parameter actions for MIDI map save/load
  params:add_trigger("save_midi_map", "Save MIDI Map")
  params:set_action("save_midi_map", function()
    save_midi_mappings(_path.data.."refract/midi_map.json")
  end)
  
  params:add_trigger("load_midi_map", "Load MIDI Map")
  params:set_action("load_midi_map", function()
    load_midi_mappings(_path.data.."refract/midi_map.json")
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
  
  -- Try to load saved MIDI mappings
  if util.file_exists(_path.data.."refract/midi_map.json") then
    load_midi_mappings(_path.data.."refract/midi_map.json")
  end
  
  -- Print instructions
  print("Refract initialized!")
  print("Hold K1 and turn E1 to access MIDI mapping page")
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
