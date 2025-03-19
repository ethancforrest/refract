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

-- Forward declarations
local function update_parameters(dt)
  -- Default time delta if not provided
  dt = dt or last_time_delta
  
  -- Check for completed pulses
  local source, target, strength = Mandala.update_pulses(mandala, params:get("param_6") * dt * 60)
  
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
  elseif harmony < LOW_HARMONY_THRESHOLD then
    -- More chaotic relations at low harmony
    new_value = source_value *
