-- refract: mandala FM synthesizer
-- v0.1.1 (Claude Edited) @yourusername

-- Include libraries
engine.name = "Refract"
local TensionWeb = include('lib/tension_web')
local RhythmEngine = include('lib/rhythm_engine')

-- New views for better visualization
VIEW = {
  PARAMS = 1,  -- Show all param values cleanly
  VISUALIZER = 2 -- Abstract visualization
}
current_view = VIEW.VISUALIZER -- Default to visualizer

-- Variables for state tracking
local initialized = false
local current_param = 1
local debug_mode = true
local screen_metro = nil
local init_clock = nil
local rhythm_active = false

function init()
  -- Print debug information
  if debug_mode then print("Initializing Refract script") end
  
  -- Set up a flag to track initialization state
  initialized = false
  
  -- Set default values
  current_param = 1
  alt_key_held = false
  
  -- First set up parameters
  setup_params()
  
  -- Initialize TensionWeb
  TensionWeb.init()

  -- Connect pattern mode parameter to the Tension Web
  params:set_action("pattern_mode", function(v)
    TensionWeb.set_pattern(v)
  end)
  
  -- Connect harmony parameter
  params:set_action("harmony", function(v)
    TensionWeb.set_harmony(v)
  end)
  
  -- Connect coherence parameter
  params:set_action("coherence", function(v)
    TensionWeb.set_coherence(v)
  end)
  
  -- Connect freeze parameter
  params:set_action("freeze", function(v)
    TensionWeb.set_frozen(v == 1)
  end)
  
  -- Initialize rhythm engine
  RhythmEngine.init(function()
    -- This callback is called on significant pulses
    if debug_mode then print("Rhythm pulse") end
  end)
  RhythmEngine.set_debug(debug_mode)
  
  -- Wait for engine to load before sending commands
  if init_clock then clock.cancel(init_clock) end
  
  init_clock = clock.run(function()
    clock.sleep(0.5)
    
    -- Initial state setup - wait a bit longer to ensure engine is fully ready
    clock.sleep(0.5)
    reset_engine()
    
    -- Register parameters with rhythm engine
    RhythmEngine.register_param("harmonic", {
      depth_scale = 0.8,
      range = {20, 120}
    })
    
    RhythmEngine.register_param("orbital", {
      depth_scale = 0.5,
      phase_offset = 0.25 -- Quarter note offset
    })
    
    -- NOW we're fully initialized
    initialized = true
    if debug_mode then print("Setup complete") end
    
    -- Start the redraw metro only after initialization is complete
    if screen_metro then screen_metro:stop() end
    screen_metro = metro.init()
    screen_metro.time = 1/10
    screen_metro.event = function() 
      -- Apply rhythmic modulation before redraw
      if initialized and rhythm_active then
        RhythmEngine.apply_modulation()
      end
      redraw() 
    end
    screen_metro:start()
  end)
  
  -- Do an initial redraw to show loading
  screen.clear()
  screen.level(15)
  screen.move(64, 32)
  screen.text_center("Loading Refract...")
  screen.update()
end

function setup_params()
  params:add_separator("REFRACT")
  
  -- Add the pattern_mode, harmony, and coherence parameters
  params:add_option("pattern_mode", "Pattern Mode", {"Radial", "Spiral", "Reflection", "Fractal"}, 1)
  
  params:add_control("harmony", "Harmony", controlspec.new(0, 1, 'lin', 0.01, 0.5, ""))
  
  params:add_control("coherence", "Coherence", controlspec.new(0, 1, 'lin', 0.01, 0.7, ""))
  
  -- Add rhythmic parameters
  params:add_separator("RHYTHM")
  
  params:add_option("rhythm_active", "Rhythm Active", {"Off", "On"}, 1)
  params:set_action("rhythm_active", function(v)
    rhythm_active = (v == 2)
    RhythmEngine.set_active(rhythm_active)
    if debug_mode then print("Rhythm active: " .. (rhythm_active and "yes" or "no")) end
  end)
  
  params:add_option("rhythm_pattern", "Rhythm Pattern", {"Sine", "Triangle", "Square", "Random"}, 1)
  params:set_action("rhythm_pattern", function(v)
    RhythmEngine.set_pattern(v)
  end)
  
  params:add_control("rhythm_rate", "Rhythm Rate", controlspec.new(0.25, 4, 'exp', 0.01, 1, "x"))
  params:set_action("rhythm_rate", function(v)
    RhythmEngine.set_rate(v)
  end)
  
  params:add_control("rhythm_depth", "Rhythm Depth", controlspec.new(0, 1, 'lin', 0.01, 0.2, ""))
  params:set_action("rhythm_depth", function(v)
    RhythmEngine.set_depth(v)
  end)
  
  -- Original sound parameters
    params:add_control("output", "Output", controlspec.new(0, 1, 'lin', 0.01, 0.5, ""))
  params:set_action("output", function(v)
    if initialized then
      engine.amp(v)  -- This actually sets the output level
    end
  end)

  params:add_control("harmonic", "Harmonic", controlspec.new(20, 120, 'lin', 0.1, 60, ""))
  params:set_action("harmonic", function(v) 
    if initialized then
      if debug_mode and math.random() < 0.2 then 
        print("Setting harmonic: " .. v) 
      end
      engine.controlParam(1, v) 
      TensionWeb.process_param_change("harmonic", v, "user")
    end
  end)
  
  params:add_control("orbital", "Orbital", controlspec.new(0.25, 4, 'exp', 0.01, 1, ""))
  params:set_action("orbital", function(v) 
      if initialized then
    if debug_mode and math.random() < 0.2 then 
      print("Setting orbital: " .. v) 
    end
    engine.controlParam(2, v) 
    TensionWeb.process_param_change("orbital", v, "user")
  end
  end)
  
  params:add_control("symmetry", "Symmetry", controlspec.new(0, 1, 'lin', 0.01, 0.5, ""))
  params:set_action("symmetry", function(v) 
  if initialized then
    if debug_mode and math.random() < 0.2 then 
      print("Setting symmetry: " .. v) 
    end
    engine.controlParam(3, v) 
    TensionWeb.process_param_change("symmetry", v, "user")
  end

  end)
  
  params:add_control("resonance", "Resonance", controlspec.new(0, 1, 'lin', 0.01, 0.3, ""))
  params:set_action("resonance", function(v) 
  if initialized then
    if debug_mode and math.random() < 0.2 then 
      print("Setting resonance: " .. v) 
    end
    engine.controlParam(4, v) 
    TensionWeb.process_param_change("resonance", v, "user")
  end
  end)
  
  params:add_control("radiance", "Radiance", controlspec.new(0, 1, 'lin', 0.01, 0.5, ""))
  params:set_action("radiance", function(v) 
  if initialized then
    if debug_mode and math.random() < 0.2 then 
      print("Setting radiance: " .. v) 
    end
    engine.controlParam(5, v) 
    TensionWeb.process_param_change("radiance", v, "user")
  end
  end)
  
  params:add_control("flow", "Flow", controlspec.new(0.25, 4, 'exp', 0.01, 1, ""))
  params:set_action("flow", function(v) 
  if initialized then
    if debug_mode and math.random() < 0.2 then 
      print("Setting flow: " .. v) 
    end
    engine.controlParam(6, v) 
    TensionWeb.process_param_change("flow", v, "user")
  end
  end)
  
  params:add_control("propagation", "Propagation", controlspec.new(0, 1, 'lin', 0.01, 0.4, ""))
  params:set_action("propagation", function(v) 
  if initialized then
    if debug_mode and math.random() < 0.2 then 
      print("Setting propagation: " .. v) 
    end
    engine.controlParam(7, v) 
    TensionWeb.process_param_change("propagation", v, "user")
  end
  end)
  
  params:add_control("reflection", "Reflection", controlspec.new(0, 1, 'lin', 0.01, 0.3, ""))
  params:set_action("reflection", function(v) 
  if initialized then
    if debug_mode and math.random() < 0.2 then 
      print("Setting reflection: " .. v) 
    end
    engine.controlParam(8, v) 
    TensionWeb.process_param_change("reflection", v, "user")
  end
  end)
  
  params:add_binary("freeze", "Freeze", "toggle")
  params:set_action("freeze", function(v) 
    if initialized then
      if debug_mode then print("Setting freeze: "..v) end
      engine.freeze(v) 
      print("FREEZE COMMAND SENT: " .. v)
    end
  end)
  
  params:bang()
end

function reset_engine()
  if initialized then
    if debug_mode then print("Resetting engine") end
    engine.reset()
    
    -- Reset TensionWeb parameters to defaults
    params:set("pattern_mode", 1)
    params:set("harmony", 0.5)
    params:set("coherence", 0.7)
  end
end

function key(n,z)
  if not initialized then return end
  
  if n == 1 then
    alt_key_held = z == 1
  elseif n == 2 and z == 1 then
    -- K2: Toggle between views
    current_view = current_view == VIEW.PARAMS and VIEW.VISUALIZER or VIEW.PARAMS
    redraw()
  elseif n == 3 and z == 1 then
    if alt_key_held then
      -- Alt+K3: Reset to defaults
      reset_engine()
    else
      -- K3: Something else (maybe freeze?)
      params:delta("freeze", 1)
    end
  end
end

function enc(n, d)
  if not initialized then return end
  
  if alt_key_held then
    -- Alt + encoder controls
    if n == 1 then
      params:delta("pattern_mode", d)
    elseif n == 2 then
      params:delta("harmony", d * 0.01)
    elseif n == 3 then
      params:delta("coherence", d * 0.01)
    end
  else
    -- Regular encoder controls
    if n == 1 then
      params:delta("output", d * 0.01)
    elseif n == 2 then
      if rhythm_active then
        params:delta("rhythm_rate", d * 0.01)
      else
        params:delta("harmonic", d) -- Direct control of pattern segments
      end
    elseif n == 3 then
      if rhythm_active then
        params:delta("rhythm_depth", d * 0.01)
      else
        params:delta("resonance", d * 0.01) -- Direct control of line brightness
      end
    end
  end
  
  redraw()
end

function test_tension_web()
  print("Testing Tension Web...")
  
  -- Make a significant change to harmonic parameter
  print("Setting harmonic to 100...")
  params:set("harmonic", 100)
  
  -- Log what pattern mode we're in
  print("Current pattern mode: " .. params:get("pattern_mode"))
  print("Harmony: " .. params:get("harmony"))
  print("Coherence: " .. params:get("coherence"))
  
  -- Wait a bit and check for changes
  clock.run(function()
    clock.sleep(2)
    print("Parameter values after propagation:")
    for _, param in ipairs({"harmonic", "orbital", "symmetry", "resonance", 
                          "radiance", "flow", "propagation", "reflection"}) do
      print(param .. ": " .. params:get(param))
    end
  end)
end

function redraw()
  screen.clear()
  
  -- During initialization, just show loading
  if not initialized then
    screen.level(15)
    screen.move(64, 32)
    screen.text_center("Initializing Refract...")
    screen.update()
    return
  end
  
  if current_view == VIEW.PARAMS then
    draw_params_view()
  else
    draw_visualizer()
  end
end

-- Add these new drawing functions
function draw_params_view()
  screen.level(15)
  
  -- Draw 4 params per column, 2 columns
  local col1_x = 5
  local col2_x = 70
  local y_start = 12
  local y_spacing = 13
  
  -- First column
  for i=1,4 do
    local param = TensionWeb.PARAM_NAMES[i]
    local value = params:get(param)
    screen.move(col1_x, y_start + (i-1)*y_spacing)
    screen.text(param:sub(1,3) .. ": " .. string.format("%.2f", value))
  end
  
  -- Second column  
  for i=5,8 do
    local param = TensionWeb.PARAM_NAMES[i]
    local value = params:get(param)
    screen.move(col2_x, y_start + (i-5)*y_spacing)
    screen.text(param:sub(1,3) .. ": " .. string.format("%.2f", value))
  end

  -- Draw small status indicators at bottom
  screen.level(5)
  screen.move(5, 60)
  screen.text("Pattern: " .. params:get("pattern_mode"))
  screen.move(70, 60)
  screen.text(rhythm_active and "R" or "-")
end

function draw_visualizer()
    screen.aa(1) -- Enable anti-aliasing for smoother lines
  screen.level(15) -- Set default brightness

  
  -- Center coordinates
  local cx, cy = 64, 32
  local max_radius = 30
  
  -- Use harmonic parameter to determine number of segments
  local segments = math.floor(util.linlin(20, 120, 4, 16, params:get("harmonic")))
  
  -- Use symmetry parameter to determine number of rings
  local rings = math.floor(util.linlin(0, 1, 2, 6, params:get("symmetry")))
  
  -- Use orbital parameter for rotation
  local rotation = util.linlin(0, 1, 0, math.pi*2, params:get("orbital"))
  
  -- Loop through rings
  for r = 1, rings do
    local ring_radius = (r/rings) * max_radius
    
    -- Draw segments
    for s = 1, segments do
      local angle = (s/segments) * math.pi * 2 + rotation
      local next_angle = ((s+1)/segments) * math.pi * 2 + rotation
      
      -- Calculate points for cross pattern
      local x1 = cx + math.cos(angle) * ring_radius
      local y1 = cy + math.sin(angle) * ring_radius
      local x2 = cx + math.cos(next_angle) * (ring_radius * 0.8)
      local y2 = cy + math.sin(next_angle) * (ring_radius * 0.8)
      
      -- Use resonance to determine line brightness
      local brightness = math.floor(util.linlin(0, 1, 2, 15, params:get("resonance")))
screen.level(brightness)
      
      -- Draw crossing lines
      screen.move(x1, y1)
      screen.line(x2, y2)
      
      -- Add perpendicular lines based on radiance
      if params:get("radiance") > 0.5 then
        local perp_length = ring_radius * 0.2
        local mid_angle = (angle + next_angle) / 2
        local px = cx + math.cos(mid_angle) * (ring_radius * 0.9)
        local py = cy + math.sin(mid_angle) * (ring_radius * 0.9)
        screen.move(px - math.sin(mid_angle) * perp_length, 
                   py + math.cos(mid_angle) * perp_length)
        screen.line(px + math.sin(mid_angle) * perp_length,
                   py - math.cos(mid_angle) * perp_length)
      end
    end
  end
  
  -- Draw central element
  local center_size = util.linlin(0, 1, 2, 8, params:get("flow"))
  for i = 1, 4 do
    local angle = (i/4) * math.pi * 2
    screen.move(cx, cy)
    screen.line(cx + math.cos(angle) * center_size,
                cy + math.sin(angle) * center_size)
  end
  
  -- Add pulsing elements for rhythm if active
  if rhythm_active then
    local phase = RhythmEngine.get_phase()
    local pulse_radius = math.floor(max_radius + 2 + math.sin(phase * math.pi * 2) * 3)
    for i = 1, 8 do
      local angle = (i/8) * math.pi * 2
      local x = cx + math.cos(angle) * pulse_radius
      local y = cy + math.sin(angle) * pulse_radius
      screen.pixel(x, y)
    end
  end
  
  screen.stroke()
end


function cleanup()
  -- Stop any running processes
  if screen_metro then screen_metro:stop() end
  if init_clock then clock.cancel(init_clock) end
  init_clock = nil
  initialized = false
end
