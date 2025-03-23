-- refract: mandala FM synthesizer
-- v0.1.1 (Claude Edited) @yourusername

-- Include libraries
engine.name = "Refract"
local Mandala = include('lib/mandala')
local TensionWeb = include('lib/tension_web')
local RhythmEngine = include('lib/rhythm_engine')

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
    local current_tab = Mandala.get_current_tab()
    
    if debug_mode then print("Key press: K" .. n .. ", tab: " .. current_tab) end
    
    -- Safety check - force tab to valid value if somehow invalid
    if current_tab < 1 or current_tab > 4 then
      if debug_mode then print("Correcting invalid tab: " .. current_tab) end
      Mandala.set_tab(1)
      current_tab = 1
    end
    
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
        -- K2: Always navigates to previous tab, with optional additional action
        local new_tab = current_tab - 1
        if new_tab < 1 then new_tab = 4 end
        
        if current_tab == 2 then -- RHYTHM tab
          -- Toggle rhythm on/off if alt isn't held
          local rhythm_state = params:get("rhythm_active")
          params:set("rhythm_active", rhythm_state == 1 and 2 or 1)
        end
        
        -- Always navigate regardless of tab
        Mandala.set_tab(new_tab)
        if debug_mode then print("Tab changed to: " .. new_tab) end
      elseif n == 3 then
        -- K3: Has dual function depending on tab
        if current_tab == 2 then -- RHYTHM tab
          -- Cycle through rhythm patterns
          params:delta("rhythm_pattern", 1)
        elseif current_tab == 4 then -- TENSION tab
          -- Cycle through parameters
          current_param = util.wrap(current_param + 1, 1, 8)
          -- But ALSO navigate to next tab for consistency
          local new_tab = current_tab + 1
          if new_tab > 4 then new_tab = 1 end
          Mandala.set_tab(new_tab)
          if debug_mode then print("Tab changed to: " .. new_tab) end
          return -- early return to avoid double tab change
        end
        
        -- Switch to next tab (all tabs except TENSION already handled above)
        local new_tab = current_tab + 1
        if new_tab > 4 then new_tab = 1 end
        Mandala.set_tab(new_tab)
        if debug_mode then print("Tab changed to: " .. new_tab) end
      end
    end
    redraw()
  end
end

function enc(n, d)
  if not initialized then return end
  
  -- Get current tab
  local current_tab = Mandala.get_current_tab()
  
  -- Add debug print to track encoder action
  if debug_mode and n == 1 and math.abs(d) > 0 then 
    print("Encoder " .. n .. " (value " .. d .. ") on tab " .. current_tab)
  end
  
  -- Safety check - force tab to valid value if somehow invalid
  if current_tab < 1 or current_tab > 4 then
    if debug_mode then print("Correcting invalid tab: " .. current_tab) end
    Mandala.set_tab(1)
    current_tab = 1
  end
  
  if current_tab == 2 then -- RHYTHM tab
    if alt_key_held then
      -- Alt+encoder combinations in rhythm tab
      if n == 1 then
        -- Alt+E1: Rhythm On/Off
        params:delta("rhythm_active", d)
      elseif n == 2 then
        -- Alt+E2: Change tabs directly (safety feature)
        if d > 0 then
          local new_tab = current_tab + 1
          if new_tab > 4 then new_tab = 1 end
          Mandala.set_tab(new_tab)
          if debug_mode then print("Alt+E2: Tab changed to: " .. new_tab) end
        else
          local new_tab = current_tab - 1
          if new_tab < 1 then new_tab = 4 end
          Mandala.set_tab(new_tab)
          if debug_mode then print("Alt+E2: Tab changed to: " .. new_tab) end
        end
      elseif n == 3 then
        -- Alt+E3: Advanced rhythm settings 
        -- For now just reset to tab 1 as a safety valve
        Mandala.set_tab(1)
        if debug_mode then print("Alt+E3: Tab changed to: 1") end
      end
    else
      -- Normal encoder functions for rhythm tab
      if n == 1 then
        -- E1: Select rhythm pattern, but also allow tab change with big movements
        if d > 2 then
          -- Large clockwise movement changes tab
          local new_tab = current_tab + 1
          if new_tab > 4 then new_tab = 1 end
          Mandala.set_tab(new_tab)
          if debug_mode then print("Emergency tab change: " .. new_tab) end
        elseif d < -2 then
          -- Large counter-clockwise movement changes tab
          local new_tab = current_tab - 1
          if new_tab < 1 then new_tab = 4 end
          Mandala.set_tab(new_tab)
          if debug_mode then print("Emergency tab change: " .. new_tab) end
        else
          -- Normal behavior
          params:delta("rhythm_pattern", d)
        end
      elseif n == 2 then
        -- E2: Adjust rhythm rate
        params:delta("rhythm_rate", d * 0.01)
      elseif n == 3 then
        -- E3: Adjust rhythm depth
        params:delta("rhythm_depth", d * 0.01)
      end
    end
  
  elseif current_tab == 4 then -- TENSION tab
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
        -- E1: Change current parameter or tab with large movements
        if d > 2 then
          -- Large clockwise movement changes tab
          local new_tab = current_tab + 1
          if new_tab > 4 then new_tab = 1 end
          Mandala.set_tab(new_tab)
          if debug_mode then print("Emergency tab change: " .. new_tab) end
        elseif d < -2 then
          -- Large counter-clockwise movement changes tab
          local new_tab = current_tab - 1
          if new_tab < 1 then new_tab = 4 end
          Mandala.set_tab(new_tab)
          if debug_mode then print("Emergency tab change: " .. new_tab) end
        else
          -- Normal parameter selection
          current_param = util.wrap(current_param + d, 1, 8)
        end
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
    -- For other tabs, add safety valve for tab navigation
    if n == 1 then
      -- E1: Allow tab navigation with encoder 1
      if d > 0 then
        local new_tab = current_tab + 1
        if new_tab > 4 then new_tab = 1 end
        Mandala.set_tab(new_tab)
        if debug_mode then print("Tab changed to: " .. new_tab) end
      elseif d < 0 then
        local new_tab = current_tab - 1
        if new_tab < 1 then new_tab = 4 end
        Mandala.set_tab(new_tab)
        if debug_mode then print("Tab changed to: " .. new_tab) end
      end
    elseif n == 2 then
      -- E2: Placeholder
    elseif n == 3 then
      -- E3: Placeholder
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

-- Define HEADER_HEIGHT for use in drawing functions
HEADER_HEIGHT = 10

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
  
  -- Get current tab
  local current_tab = Mandala.get_current_tab()
  
  -- Draw based on current tab
  if current_tab == 2 then -- RHYTHM tab
    draw_rhythm_tab()
  else 
    -- Draw visualization for other tabs
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
    if current_tab == 4 then -- Only on TENSION tab
      local active_relationships = TensionWeb.get_active_relationships()
      Mandala.draw_relationships(active_relationships)
    end
  end
  
  screen.update()
end

-- Draw rhythm tab contents
function draw_rhythm_tab()
  -- Main title
  screen.level(15)
  screen.move(64, HEADER_HEIGHT + 7)
  screen.text_center("RHYTHM")
  
  local active_text = rhythm_active and "ACTIVE" or "INACTIVE"
  local active_level = rhythm_active and 15 or 5
  screen.level(active_level)
  screen.move(64, HEADER_HEIGHT + 16)
  screen.text_center(active_text)
  
  -- Display current rhythm settings
  screen.level(10)
  -- Pattern
  screen.move(32, 32)
  screen.text_center("Pattern")
  screen.move(32, 40)
  screen.level(rhythm_active and 15 or 7)
  screen.text_center(params:string("rhythm_pattern"))
  
  -- Rate
  screen.level(10)
  screen.move(96, 32)
  screen.text_center("Rate")
  screen.move(96, 40)
  screen.level(rhythm_active and 15 or 7)
  screen.text_center(string.format("%.2f", params:get("rhythm_rate")) .. "x")
  
  -- Depth
  screen.level(10)
  screen.move(64, 50)
  screen.text_center("Depth")
  screen.move(64, 58)
  screen.level(rhythm_active and 15 or 7)
  screen.text_center(string.format("%.0f%%", params:get("rhythm_depth") * 100))
  
  -- Draw rhythm pulse indicator
  if rhythm_active then
    local phase = RhythmEngine.get_phase() -- 0-1 value
    local indicator_width = 60
    local x_center = 64
    local y_pos = 25
    local indicator_x = x_center - indicator_width/2 + phase * indicator_width
    
    screen.level(15)
    screen.move(indicator_x, y_pos)
    screen.line_width(2)
    screen.line_rel(0, 3)
    screen.stroke()
    screen.line_width(1)
  end
end

function cleanup()
  -- Stop any running processes
  if screen_metro then screen_metro:stop() end
  if init_clock then clock.cancel(init_clock) end
  init_clock = nil
  initialized = false
end