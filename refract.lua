-- refract: mandala FM synthesizer
-- v0.1.0 @yourusername

-- Include libraries
engine.name = "Refract"
local Mandala = include('lib/mandala')

-- Variables for state tracking
local initialized = false
local current_param = 1
local debug_mode = true
local screen_metro = nil
local init_clock = nil

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
  
  params:add_control("harmonic", "Harmonic", controlspec.new(20, 120, 'lin', 0.1, 60, ""))
  params:set_action("harmonic", function(v) 
    if initialized then
      if debug_mode then print("Setting harmonic: "..v) end
      engine.controlParam(1, v) 
    end
  end)
  
  params:add_control("orbital", "Orbital", controlspec.new(0.25, 4, 'exp', 0.01, 1, ""))
  params:set_action("orbital", function(v) 
    if initialized then
      if debug_mode then print("Setting orbital: "..v) end
      engine.controlParam(2, v) 
    end
  end)
  
  params:add_control("symmetry", "Symmetry", controlspec.new(0, 1, 'lin', 0.01, 0.5, ""))
  params:set_action("symmetry", function(v) 
    if initialized then
      if debug_mode then print("Setting symmetry: "..v) end
      engine.controlParam(3, v) 
    end
  end)
  
  params:add_control("resonance", "Resonance", controlspec.new(0, 1, 'lin', 0.01, 0.3, ""))
  params:set_action("resonance", function(v) 
    if initialized then
      if debug_mode then print("Setting resonance: "..v) end
      engine.controlParam(4, v) 
    end
  end)
  
  params:add_control("radiance", "Radiance", controlspec.new(0, 1, 'lin', 0.01, 0.5, ""))
  params:set_action("radiance", function(v) 
    if initialized then
      if debug_mode then print("Setting radiance: "..v) end
      engine.controlParam(5, v) 
    end
  end)
  
  params:add_control("flow", "Flow", controlspec.new(0.25, 4, 'exp', 0.01, 1, ""))
  params:set_action("flow", function(v) 
    if initialized then
      if debug_mode then print("Setting flow: "..v) end
      engine.controlParam(6, v) 
    end
  end)
  
  params:add_control("propagation", "Propagation", controlspec.new(0, 1, 'lin', 0.01, 0.4, ""))
  params:set_action("propagation", function(v) 
    if initialized then
      if debug_mode then print("Setting propagation: "..v) end
      engine.controlParam(7, v) 
    end
  end)
  
  params:add_control("reflection", "Reflection", controlspec.new(0, 1, 'lin', 0.01, 0.3, ""))
  params:set_action("reflection", function(v) 
    if initialized then
      if debug_mode then print("Setting reflection: "..v) end
      engine.controlParam(8, v) 
    end
  end)
  
  params:add_binary("freeze", "Freeze", "toggle")
  params:set_action("freeze", function(v) 
    if initialized then
      if debug_mode then print("Setting freeze: "..v) end
      engine.freeze(v) 
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
  if z == 1 then -- on key down
    if n == 2 then
      -- Previous parameter
      current_param = util.wrap(current_param - 1, 1, 8)
    elseif n == 3 then
      -- Next parameter
      current_param = util.wrap(current_param + 1, 1, 8)
    elseif n == 1 then
      -- Reset or alternate function
      if z == 1 then
        reset_engine()
      end
    end
    redraw()
  end
end

function enc(n, d)
  if n == 1 then
    -- Global parameter (could be output volume)
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
  redraw()
end

function redraw()
  screen.clear()
  
  -- Draw parameter name and value
  local param_names = {"harmonic", "orbital", "symmetry", "resonance", 
                       "radiance", "flow", "propagation", "reflection"}
  local param_display_names = {"Harmonic", "Orbital", "Symmetry", "Resonance", 
                              "Radiance", "Flow", "Propagation", "Reflection"}
  
  local param_id = param_names[current_param]
  local param_name = param_display_names[current_param]
  
  if param_id and param_name then
    screen.level(15)
    screen.move(64, 10)
    screen.text_center(param_name)
    
    screen.level(10)
    screen.move(64, 30)
    screen.text_center(string.format("%.2f", params:get(param_id)))
    
    -- Draw simple visualization if Mandala.draw exists
    if Mandala and Mandala.draw then
      Mandala.draw(
        params:get("harmonic"), 
        params:get("orbital"),
        params:get("symmetry"), 
        params:get("resonance"),
        params:get("radiance"), 
        params:get("flow"),
        params:get("propagation"), 
        params:get("reflection")
      )
    end
  end
  
  screen.update()
end

function cleanup()
  -- Stop any running processes
  if screen_metro then screen_metro:stop() end
  if init_clock then clock.cancel(init_clock) end
  init_clock = nil
  initialized = false
end
