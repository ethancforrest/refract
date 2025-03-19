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

-- State variables
local mandala = Mandala.new(NUM_PARAMS)
local params_dirty = false
local alt_key = false
local current_param = 1
local pattern_mode = 1
local harmony = 0.5
local coherence = 0.5
local snapshots = {}
local current_snapshot = 1
local morph_active = false
local morph_position = 0
local morph_start_snapshot = 1
local morph_end_snapshot = 2
local midi_in_device = nil
local midi_out_device = nil
local redraw_metro

-- Forward declarations
local update_parameters
local update_engine_parameter
local save_snapshot
local morph_snapshots
local reset_system
local poll_callback
local create_parameter_web
local handle_pulse_arrival

function init()
  -- Create the parameter interface
  params:add_separator("Refract Synthesizer")
  
  -- Add parameters for each node in the mandala
  for i=1, NUM_PARAMS do
    params:add_control(
      "param_" .. i,
      PARAM_NAMES[i],
      controlspec.new(0, 1, "lin", 0.01, 0.5, "")
    )
    params:set_action("param_" .. i, function(value)
      Mandala.set_node_value(mandala, i, value)
      update_engine_parameter(i, value)
      params_dirty = true
    end)
  end
  
  -- Global parameters
  params:add_separator("Global Settings")
  
  params:add_option("pattern_mode", "Pattern Mode", PATTERN_MODES, 1)
  params:set_action("pattern_mode", function(value)
    pattern_mode = value
    create_parameter_web()
  end)
  
  params:add_control("harmony", "Harmony", controlspec.new(0, 1, "lin", 0.01, 0.5, ""))
  params:set_action("harmony", function(value)
    harmony = value
  end)
  
  params:add_control("coherence", "Coherence", controlspec.new(0, 1, "lin", 0.01, 0.5, ""))
  params:set_action("coherence", function(value)
    coherence = value
  end)
  
  params:add_trigger("freeze", "Freeze System")
  params:set_action("freeze", function()
    local freeze_state = params:get("freeze") == 1 and 0 or 1
    engine.freeze(freeze_state)
  end)
  
  params:add_trigger("reset", "Reset System")
  params:set_action("reset", function()
    reset_system()
  end)
  
  -- MIDI settings
  params:add_separator("MIDI")
  
  params:add{
    type = "number",
    id = "midi_device",
    name = "MIDI Device",
    min = 1, max = 16, default = 1,
    action = function(value)
      if midi_in_device then
        midi_in_device:cleanup()
      end
      midi_in_device = midi.connect(value)
      midi_in_device.event = function(data)
        handle_midi_event(data)
      end
    end
  }

  -- Initialize the pattern connections
  create_parameter_web()
  
  -- Set up engine polls
  poll_spectral = poll.set("spectral_centroid")
  poll_spectral.callback = function(value)
    poll_callback("spectral", value)
  end
  poll_spectral:start()
  
  poll_amplitude = poll.set("amplitude")
  poll_amplitude.callback = function(value)
    poll_callback("amplitude", value)
  end
  poll_amplitude:start()
  
  -- Create initial empty snapshots
  for i=1,4 do
    snapshots[i] = Mandala.get_node_values(mandala)
  end
  
  -- Start screen redraw metro
  redraw_metro = metro.init()
  redraw_metro.time = 1/SCREEN_FRAMERATE
  redraw_metro.event = function()
    update_parameters()
    redraw()
  end
  redraw_metro:start()
  
  -- Set up MIDI if selected
  if params:get("midi_device") > 0 then
    midi_in_device = midi.connect(params:get("midi_device"))
    midi_in_device.event = function(data)
      handle_midi_event(data)
    end
  end
  
  -- Initialize parameter values
  for i=1,NUM_PARAMS do
    update_engine_parameter(i, params:get("param_" .. i))
  end
end

function handle_midi_event(data)
  local msg = midi.to_msg(data)
  
  if msg.type == "cc" then
    -- Map MIDI CC 1-8 to parameters
    if msg.cc >= 1 and msg.cc <= NUM_PARAMS then
      local param_value = util.linlin(0, 127, 0, 1, msg.val)
      params:set("param_" .. msg.cc, param_value)
    elseif msg.cc == 9 then
      -- CC 9 for harmony
      local harm_value = util.linlin(0, 127, 0, 1, msg.val)
      params:set("harmony", harm_value)
    elseif msg.cc == 10 then
      -- CC 10 for coherence
      local coh_value = util.linlin(0, 127, 0, 1, msg.val)
      params:set("coherence", coh_value)
    end
  end
end

function create_parameter_web()
  -- Create connection pattern based on selected mode
  if pattern_mode == 1 then
    Mandala.create_radial_connections(mandala)
  elseif pattern_mode == 2 then
    Mandala.create_spiral_connections(mandala)
  elseif pattern_mode == 3 then
    Mandala.create_reflection_connections(mandala)
  elseif pattern_mode == 4 then
    Mandala.create_fractal_connections(mandala)
  end
end

function update_parameters()
  -- Check for completed pulses
  local source, target, strength = Mandala.update_pulses(mandala, params:get("param_6")) -- Flow rate
  
  if source and target then
    handle_pulse_arrival(source, target, strength)
  end
  
  -- Generate coherence-based tension if needed
  if not morph_active and math.random() < coherence * 0.05 then
    Mandala.generate_coherence_tension(mandala, coherence)
  end
  
  -- Update morph if active
  if morph_active then
    morph_position = morph_position + 0.01
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

function handle_pulse_arrival(source, target, strength)
  -- When a pulse arrives at its destination, cause an effect
  
  -- Calculate new parameter value based on source, target, and harmony
  local source_value = mandala.nodes[source].value
  local target_value = mandala.nodes[target].value
  
  -- Calculate harmonic relationship
  local harmonic_ratio = harmony * 0.5 + 0.5 -- 0.5-1.0 range
  local new_value
  
  if harmony > 0.7 then
    -- More consonant relations at high harmony
    new_value = source_value * harmonic_ratio + target_value * (1-harmonic_ratio)
  else
    -- More chaotic relations at low harmony
    new_value = source_value * 0.8 + math.random() * 0.4 - 0.2
  end
  
  -- Keep in valid range
  new_value = math.min(math.max(new_value, 0), 1)
  
  -- Apply the effect to the target parameter
  params:set("param_" .. target, new_value)
  
  -- Send a pulse message to the engine
  engine.pulse(target, strength)
  
  -- Create new pulses from the target based on pattern mode
  Mandala.propagate_tension(mandala, target, strength * 0.7, PATTERN_MODES[pattern_mode]:lower())
end

function update_engine_parameter(index, value)
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

function poll_callback(name, value)
  if name == "spectral" then
    -- Use spectral information to influence visuals
    -- This is just a placeholder
  elseif name == "amplitude" then
    -- Use amplitude information
    -- This is just a placeholder
  end
end

function save_snapshot()
  snapshots[current_snapshot] = Mandala.get_node_values(mandala)
  print("Saved snapshot " .. current_snapshot)
end

function morph_snapshots()
  morph_active = true
  morph_position = 0
  morph_start_snapshot = current_snapshot
  morph_end_snapshot = (current_snapshot % #snapshots) + 1
  print("Morphing from snapshot " .. morph_start_snapshot .. " to " .. morph_end_snapshot)
end

function reset_system()
  engine.reset()
  
  -- Reset all parameters to defaults
  for i=1,NUM_PARAMS do
    params:set("param_" .. i, 0.5)
  end
  
  -- Reset UI elements
  pattern_mode = 1
  params:set("pattern_mode", 1)
  harmony = 0.5
  params:set("harmony", 0.5)
  coherence = 0.5
  params:set("coherence", 0.5)
  
  -- Reset mandala
  Mandala.clear_pulses(mandala)
  create_parameter_web()
  
  print("System reset to defaults")
end

function enc(n, d)
  if n == 1 then
    -- E1: Pattern Mode
    pattern_mode = util.clamp(pattern_mode + d, 1, #PATTERN_MODES)
    params:set("pattern_mode", pattern_mode)
  elseif n == 2 then
    -- E2: Harmony
    harmony = util.clamp(harmony + d * 0.01, 0, 1)
    params:set("harmony", harmony)
  elseif n == 3 then
    -- E3: Coherence
    coherence = util.clamp(coherence + d * 0.01, 0, 1)
    params:set("coherence", coherence)
  end
  
  redraw()
end

function key(n, z)
  if n == 1 then
    -- K1 as alt key
    alt_key = z == 1
  elseif n == 2 and z == 1 then
    if alt_key then
      -- K1+K2: Freeze/unfreeze
      params:delta("freeze", 1)
    else
      -- K2: Save snapshot
      save_snapshot()
      current_snapshot = (current_snapshot % 4) + 1
    end
  elseif n == 3 and z == 1 then
    if alt_key then
      -- K1+K3: Reset system
      reset_system()
    else
      -- K3: Morph between snapshots
      morph_snapshots()
    end
  end
  
  redraw()
end

function redraw()
  screen.clear()
  
  -- Draw the mandala
  Mandala.draw(mandala)
  
  -- Draw status information
  screen.level(15)
  screen.move(2, 8)
  screen.text(PATTERN_MODES[pattern_mode])
  
  screen.move(2, 60)
  screen.text("H:" .. string.format("%.2f", harmony))
  
  screen.move(64, 60)
  screen.text("C:" .. string.format("%.2f", coherence))
  
  -- Draw snapshot indicators
  for i=1,4 do
    screen.level(i == current_snapshot and 15 or 3)
    screen.rect(96 + (i-1)*8, 5, 6, 4)
    screen.fill()
  end
  
  -- Draw active snapshot data if morphing
  if morph_active then
    screen.level(10)
    screen.move(110, 8)
    screen.text(morph_start_snapshot .. ">" .. morph_end_snapshot)
  end
  
  -- Draw freeze indicator if system is frozen
  if params:get("freeze") == 1 then
    screen.level(10)
    screen.rect(115, 57, 10, 6)
    screen.fill()
    screen.level(0)
    screen.move(120, 63)
    screen.text_center("F")
  end
  
  screen.update()
end

function cleanup()
  -- Stop all metros and polls
  if redraw_metro then redraw_metro:stop() end
  if poll_spectral then poll_spectral:stop() end
  if poll_amplitude then poll_amplitude:stop() end
  
  -- Clean up MIDI
  if midi_in_device then midi_in_device:cleanup() end
  if midi_out_device then midi_out_device:cleanup() end
end
