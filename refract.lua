-- refract: mandala FM synthesizer
-- v0.1.0 @yourusername

-- Include libraries
engine.name = "Refract"
local Mandala = include('lib/mandala')
local TensionWeb = include('lib/tension_web')

-- Variables for state tracking
local initialized = false
local current_param = 1
local debug_mode = true
local screen_metro = nil
local init_clock = nil
local alt_key_held = false

function init()
  -- Print debug information
  if debug_mode then print("Initializing Refract script") end
  
  -- Wait for engine to load before sending commands
  if init_clock then clock.cancel(init_clock) end
  
  init_clock = clock.run(function()
    clock.sleep(0.5)
    initialized = true
    if debug_mode then print("Engine initialized") end
    
    -- Setup parameters
    setup_params()
    
    -- Initialize TensionWeb
    TensionWeb.init()
    
    -- Initial state setup - wait a bit longer to ensure engine is fully ready
    clock.sleep(0.5)
    reset_engine()
    
    if debug_mode then print("Setup complete") end
  end)
  
  -- Setup metro for screen redraw
  if screen_metro then screen_metro:stop() end
  screen_metro = metro.init()
  screen_metro.time = 1/15
  screen_metro.event = function() redraw() end
  screen_metro:start()
end

function setup_params()
  params:add_separator("REFRACT")
  
  -- Add new parameters for tension web control
  params:add_option("pattern_mode", "Pattern Mode", {"Radial", "Spiral", "Reflection", "Fractal"}, 1)
  params:set_action("pattern_mode", function(v) 
    if initialized then
      if debug_mode then print("Setting pattern mode: "..v) end
      TensionWeb.set_pattern(v)
    end
  end)
  
  params:add_control("harmony", "Harmony", controlspec.new(0, 1, 'lin', 0.01, 0.5, ""))
  params:set_action("harmony", function(v) 
    if initialized then
      if debug_mode then print("Setting harmony: "..v) end
      TensionWeb.set_harmony(v)
    end
  end)
  
  params:add_control("coherence", "Coherence", controlspec.new(0, 1, 'lin', 0.01, 0.7, ""))
  params:set_action("coherence", function(v) 
    if initialized then
      if debug_mode then print("Setting coherence: "..v) end
      TensionWeb.set_coherence(v)
    end
  end)
  
  -- Original sound parameters
  params:add_control("harmonic", "Harmonic", controlspec.new(20, 120, 'lin', 0.1, 60, ""))
  params:set_action("harmonic", function(v) 
    if initialized then
      if debug_mode then print("Setting harmonic: "..v) end
      engine.controlParam(1, v)
      -- Connect to tension web
      TensionWeb.process_param_change("harmonic", v, "user")
    end
  end)
  
  params:add_control("orbital", "Orbital", controlspec.new(0.25, 4, 'exp', 0.01, 1, ""))
  params:set_action("orbital", function(v) 
    if initialized then
      if debug_mode then print("Setting orbital: "..v) end
      engine.controlParam(2, v)
      -- Connect to tension web
      TensionWeb.process_param_change("orbital", v, "user")
    end
  end)
  
  params:add_control("symmetry", "Symmetry", controlspec.new(0, 1, 'lin', 0.01, 0.5, ""))
  params:set_action("symmetry", function(v) 
    if initialized then
      if debug_mode then print("Setting symmetry: "..v) end
      engine.controlParam(3, v)
      -- Connect to tension web
      TensionWeb.process_param_change("symmetry", v, "user")
    end
  end)
  
  params:add_control("resonance", "Resonance", controlspec.new(0, 1, 'lin', 0.01, 0.3, ""))
  params:set_action("resonance", function(v) 
    if initialized then
      if debug_mode then print("Setting resonance: "..v) end
      engine.controlParam(4, v)
      -- Connect to tension web
      TensionWeb.process_param_change("resonance", v, "user")
    end
  end)
  
  params:add_control("radiance", "Radiance", controlspec.new(0, 1, 'lin', 0.01, 0.5, ""))
  params:set_action("radiance", function(v) 
    if initialized then
      if debug_mode then print("Setting radiance: "..v) end
      engine.controlParam(5, v)
      -- Connect to tension web
      TensionWeb.process_param_change("radiance", v, "user")
    end
  end)
  
  params:add_control("flow", "Flow", controlspec.new(0.25, 4, 'exp', 0.01, 1, ""))
  params:set_action("flow", function(v) 
    if initialized then
      if debug_mode then print("Setting flow: "..v) end
      engine.controlParam(6, v)
      -- Connect to tension web
      TensionWeb.process_param_change("flow", v, "user")
    end
  end)
  
  params:add_control("propagation", "Propagation", controlspec.new(0, 1, 'lin', 0.01, 0.4, ""))
  params:set_action("propagation", function(v) 
    if initialized then
      if debug_mode then print("Setting propagation: "..v) end
      engine.controlParam(7, v)
      -- Connect to tension web
      TensionWeb.process_param_change("propagation", v, "user")
    end
  end)
  
  params:add_control("reflection", "Reflection", controlspec.new(0, 1, 'lin', 0.01, 0.3, ""))
  params:set_action("reflection", function(v) 
    if initialized then
      if debug_mode then print("Setting reflection: "..v) end
      engine.controlParam(8, v)
      -- Connect to tension web
      TensionWeb.process_param_change("reflection", v, "user")
    end
  end)
  
  params:add_binary("freeze", "Freeze", "toggle")
  params:set_action("freeze", function(v) 
    if initialized then
      if debug_mode then print("Setting freeze: "..v) end
      engine.freeze(v)
      -- Also freeze the tension web
      TensionWeb.set_frozen(v == 1)
    end
  end)
  
  params:bang()
end

function reset_engine()
  if initialized then
    if debug_mode then print("Resetting engine") end
    engine.reset()
  end
end

function key(n, z)
  if n == 1 then
    -- Handle alt key
    alt_key_held = z == 1
  elseif z == 1 then -- on key down
    if alt_key_held then
      -- Alt+key combinations
      if n == 2 then
        -- Alt+K2: Freeze/unfreeze the system
        local freeze_state = params:get("freeze")
        params:set("freeze", freeze_state == 1 and 0 or 1)
      elseif n == 3 then
        -- Alt+K3: Reset system to defaults
        reset_engine()
      end
    else
      -- Normal key functions
      if n == 2 then
        -- K2: Save snapshot (placeholder)
        print("Save snapshot (not implemented)")
      elseif n == 3 then
        -- K3: Cycle through parameters
        current_param = util.wrap(current_param + 1, 1, 8)
      end
    end
    redraw()
  end
end

function enc(n, d)
  if alt_key_held then
    -- Alt+encoder combinations
    if n == 1 then
      -- Alt+E1: Pattern Mode
      params:delta("pattern_mode", d)
    elseif n == 2 then
      -- Alt+E2: Harmony
      params:delta("harmony", d * 0.01)
    elseif n == 3 then
      -- Alt+E3: Coherence
      params:delta("coherence", d * 0.01)
    end
  else
    -- Normal encoder functions
    if n == 1 then
      -- E1: Pattern Mode
      params:delta("pattern_mode", d)
    else
      -- Map encoder 2 & 3 to the current parameter
      local param_names = {"harmonic", "orbital", "symmetry", "resonance", 
                         "radiance", "flow", "propagation", "reflection"}
      local param_id = param_names[current_param]
      
      if param_id then
        if n == 2 then
          -- Coarse adjustment
          params:delta(param_id, d)
        elseif n == 3 then
          -- Fine adjustment
          params:delta(param_id, d * 0.1)
        end
      end
    end
  end
  redraw()
end

function redraw()
  screen.clear()
  
  -- Get current pattern name for display
  local pattern_names = {"Radial", "Spiral", "Reflection", "Fractal"}
  local current_pattern = pattern_names[params:get("pattern_mode")]
  
  -- Draw parameter name and value
  local param_names = {"harmonic", "orbital", "symmetry", "resonance", 
                       "radiance", "flow", "propagation", "reflection"}
  local param_display_names = {"Harmonic", "Orbital", "Symmetry", "Resonance", 
                              "Radiance", "Flow", "Propagation", "Reflection"}
  
  local param_id = param_names[current_param]
  local param_name = param_display_names[current_param]
  
  -- Display pattern mode at top
  screen.level(5)
  screen.move(64, 7)
  screen.text_center("Mode: " .. current_pattern)
  
  -- Show if currently using alt controls
  if alt_key_held then
    screen.level(15)
    screen.move(5, 7)
    screen.text("ALT")
  end
  
  -- Draw harmony and coherence values when in alt mode
  if alt_key_held then
    screen.level(15)
    screen.move(5, 20)
    screen.text("Harmony: " .. string.format("%.2f", params:get("harmony")))
    screen.move(5, 30)
    screen.text("Coherence: " .. string.format("%.2f", params:get("coherence")))
  end
  
  if param_id and param_name then
    -- Draw parameter name and value
    if not alt_key_held then
      screen.level(15)
      screen.move(64, 20)
      screen.text_center(param_name)
      
      screen.level(10)
      screen.move(64, 30)
      screen.text_center(string.format("%.2f", params:get(param_id)))
    end
    
    -- Draw visualization if Mandala.draw exists
    if Mandala and Mandala.draw then
      Mandala.draw(
        params:get("harmonic"), 
        params:get("orbital"),
        params:get("symmetry"), 
        params:get("resonance"),
        params:get("radiance"), 
        params:get("flow"),
        params:get("propagation"), 
        params:get("reflection"),
        current_param
      )
    end
  end
  
  screen.update()
end

function cleanup()
  -- Stop any running processes
  if screen_metro then screen_metro:stop() end
  if init_clock then clock.cancel(init_clock) end
  
  -- Clean up Tension Web processes
  if TensionWeb and TensionWeb.prop_clock then
    clock.cancel(TensionWeb.prop_clock)
  end
  
  init_clock = nil
  initialized = false
end
