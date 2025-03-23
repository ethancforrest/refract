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
  
  -- Wait for engine to load before sending commands
  if init_clock then clock.cancel(init_clock) end
  
  init_clock = clock.run(function()
    clock.sleep(0.5)
    
    -- Initial state setup - wait a bit longer to ensure engine is fully ready
    clock.sleep(0.5)
    reset_engine()
    
    -- NOW we're fully initialized
    initialized = true
    if debug_mode then print("Setup complete") end
    
    -- Start the redraw metro only after initialization is complete
    if screen_metro then screen_metro:stop() end
    screen_metro = metro.init()
    screen_metro.time = 1/10
    screen_metro.event = function() redraw() end
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
  
  -- Original sound parameters
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

function key(n, z)
  if not initialized and n ~= 1 then return end
  
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
        -- K2: Change tab or save snapshot
        local current_tab = Mandala.get_current_tab()
        local new_tab = current_tab - 1
        if new_tab < 1 then new_tab = 4 end
        Mandala.set_tab(new_tab)
      elseif n == 3 then
        -- K3: Change tab or cycle through parameters
        local current_tab = Mandala.get_current_tab()
        if current_tab == 4 then -- TENSION tab
          -- Cycle through parameters
          current_param = util.wrap(current_param + 1, 1, 8)
        else
          -- Switch to next tab
          local new_tab = current_tab + 1
          if new_tab > 4 then new_tab = 1 end
          Mandala.set_tab(new_tab)
        end
      end
    end
    redraw()
  end
end

function enc(n, d)
  if not initialized then return end
  
  -- Get current tab
  local current_tab = Mandala.get_current_tab()
  
  if current_tab == 4 then -- TENSION tab
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
        -- E1: Change current parameter
        current_param = util.wrap(current_param + d, 1, 8)
      else
        -- Map encoder 2 & 3 to the current parameter
        local param_names = {"harmonic", "orbital", "symmetry", "resonance", 
                           "radiance", "flow", "propagation", "reflection"}
        local param_id = param_names[current_param]
        
        if param_id and params:get(param_id) ~= nil then
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
  else
    -- Placeholder for other tabs
    -- Will be implemented as those features are added
    if n == 1 then
      -- E1: Change parameter category in other tabs
    elseif n == 2 then
      -- E2: Coarse parameter adjustment
    elseif n == 3 then
      -- E3: Fine parameter adjustment
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
  
  -- Draw visualization
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
  
  -- Draw relationship lines
  if Mandala.get_current_tab() == 4 then -- Only on TENSION tab
    local active_relationships = TensionWeb.get_active_relationships()
    Mandala.draw_relationships(active_relationships)
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
