-- lib/tension_web.lua
-- Manages parameter relationships for Refract

local TensionWeb = {}

-- Relationship patterns
TensionWeb.PATTERNS = {
  RADIAL = 1,
  SPIRAL = 2,  
  REFLECTION = 3,
  FRACTAL = 4
}

-- Parameter names for easy reference
TensionWeb.PARAM_NAMES = {
  "harmonic",
  "orbital",
  "symmetry",
  "resonance",
  "radiance", 
  "flow",
  "propagation",
  "reflection"
}

-- Current state
TensionWeb.current_pattern = TensionWeb.PATTERNS.RADIAL
TensionWeb.harmony = 0.5 -- Controls harmonic relationships
TensionWeb.coherence = 0.7 -- Controls how strictly the system maintains coherence
TensionWeb.is_frozen = false
TensionWeb.pending_changes = {}

-- Initialize the tension web
function TensionWeb.init()
  print("Initializing TensionWeb")
  -- Start the propagation clock
  TensionWeb.start_propagation()
  return TensionWeb
end

function TensionWeb.start_propagation()
  if TensionWeb.prop_clock then
    clock.cancel(TensionWeb.prop_clock)
  end
  
  TensionWeb.prop_clock = clock.run(function()
    while true do
      TensionWeb.process_pending_changes()
      -- Process changes every 0.2 seconds instead of 0.1
      clock.sleep(0.2)
    end
  end)
end

-- Process a parameter change and queue related changes
function TensionWeb.process_param_change(param_name, value, source)
  if TensionWeb.is_frozen then return end
  
  -- Find parameter index
  local param_index = nil
  for i, name in ipairs(TensionWeb.PARAM_NAMES) do
    if name == param_name then
      param_index = i
      break
    end
  end
  
  if not param_index then return end
  
  -- Skip if this is already a propagated change to avoid feedback loops
  if source == "propagation" then return end
  
  -- Queue related parameter changes based on the current pattern
  if TensionWeb.current_pattern == TensionWeb.PATTERNS.RADIAL then
    TensionWeb.radial_propagation(param_index, value)
  elseif TensionWeb.current_pattern == TensionWeb.PATTERNS.SPIRAL then
    TensionWeb.spiral_propagation(param_index, value)
  elseif TensionWeb.current_pattern == TensionWeb.PATTERNS.REFLECTION then
    TensionWeb.reflection_propagation(param_index, value)
  elseif TensionWeb.current_pattern == TensionWeb.PATTERNS.FRACTAL then
    TensionWeb.fractal_propagation(param_index, value)
  end
end

function TensionWeb.get_active_relationships()
  -- Generate relationships based on current pattern
  local active_relationships = {}
  
  -- Create a visual representation of the current pattern
  if TensionWeb.current_pattern == TensionWeb.PATTERNS.RADIAL then
    -- Radial pattern: connect adjacent parameters
    for i = 1, 8 do
      local next_i = i + 1
      if next_i > 8 then next_i = 1 end
      
      table.insert(active_relationships, {
        from = i,
        to = next_i,
        strength = TensionWeb.coherence * TensionWeb.harmony
      })
    end
  elseif TensionWeb.current_pattern == TensionWeb.PATTERNS.SPIRAL then
    -- Spiral pattern: connect parameters in a spiral
    for i = 1, 7 do
      table.insert(active_relationships, {
        from = i,
        to = i + 1,
        strength = TensionWeb.coherence * TensionWeb.harmony
      })
    end
    -- Complete the spiral
    table.insert(active_relationships, {
      from = 8,
      to = 1,
      strength = TensionWeb.coherence * TensionWeb.harmony
    })
  elseif TensionWeb.current_pattern == TensionWeb.PATTERNS.REFLECTION then
    -- Reflection pattern: connect opposite parameters
    for i = 1, 4 do
      table.insert(active_relationships, {
        from = i,
        to = i + 4,
        strength = TensionWeb.coherence * TensionWeb.harmony
      })
    end
  elseif TensionWeb.current_pattern == TensionWeb.PATTERNS.FRACTAL then
    -- Fractal pattern: connect all parameters to all others with varying strengths
    for i = 1, 8 do
      for j = i + 1, 8 do
        -- Calculate a strength based on parameter distance
        local strength = TensionWeb.coherence * TensionWeb.harmony * (1.0 - (j - i) / 8)
        if strength > 0.1 then -- Only show significant relationships
          table.insert(active_relationships, {
            from = i,
            to = j,
            strength = strength
          })
        end
      end
    end
  end
  
  return active_relationships
end


-- Radial pattern: changes affect adjacent parameters
function TensionWeb.radial_propagation(source_index, source_value)
  -- Determine which parameters should be affected
  local left_index = source_index - 1
  if left_index < 1 then left_index = 8 end
  
  local right_index = source_index + 1
  if right_index > 8 then right_index = 1 end
  
  -- Calculate change amount based on coherence and harmony - reduced strength
  local change_amount = TensionWeb.coherence * 0.05
  
  -- 50% chance to skip propagation to reduce cascade effects
  if math.random() < 0.5 then
    table.insert(TensionWeb.pending_changes, {
      param_name = TensionWeb.PARAM_NAMES[left_index],
      change = change_amount * (math.random() > 0.5 and 1 or -1) * TensionWeb.harmony,
      delay = 0.2 + 0.3 * math.random(),
      time = util.time() + math.random()
    })
  end
  
  if math.random() < 0.5 then
    table.insert(TensionWeb.pending_changes, {
      param_name = TensionWeb.PARAM_NAMES[right_index],
      change = change_amount * (math.random() > 0.5 and 1 or -1) * TensionWeb.harmony,
      delay = 0.2 + 0.3 * math.random(),
      time = util.time() + math.random()
    })
  end
end

-- Simple implementations for other patterns
function TensionWeb.spiral_propagation(source_index, source_value)
  local next_index = source_index + 1
  if next_index > 8 then next_index = 1 end
  
  table.insert(TensionWeb.pending_changes, {
    param_name = TensionWeb.PARAM_NAMES[next_index],
    change = TensionWeb.coherence * 0.1 * TensionWeb.harmony,
    delay = 0.2,
    time = util.time() + 1
  })
end

function TensionWeb.reflection_propagation(source_index, source_value)
  local opposite_index = source_index + 4
  if opposite_index > 8 then opposite_index = opposite_index - 8 end
  
  table.insert(TensionWeb.pending_changes, {
    param_name = TensionWeb.PARAM_NAMES[opposite_index],
    change = -TensionWeb.coherence * 0.1 * TensionWeb.harmony,
    delay = 0.3,
    time = util.time() + 1
  })
end

function TensionWeb.fractal_propagation(source_index, source_value)
  -- Simple implementation that affects all parameters
  for i = 1, 8 do
    if i ~= source_index then
      table.insert(TensionWeb.pending_changes, {
        param_name = TensionWeb.PARAM_NAMES[i],
        change = TensionWeb.coherence * 0.05 * (math.random() - 0.5) * TensionWeb.harmony,
        delay = 0.2 + 0.3 * math.random(),
        time = util.time() + math.random() * 2
      })
    end
  end
end

-- Process pending parameter changes
function TensionWeb.process_pending_changes()
  if #TensionWeb.pending_changes == 0 or TensionWeb.is_frozen then return end
  
  -- Limit the number of pending changes to prevent memory issues
  if #TensionWeb.pending_changes > 20 then
    -- Keep only the 20 most recent changes
    local temp = {}
    for i = #TensionWeb.pending_changes - 19, #TensionWeb.pending_changes do
      table.insert(temp, TensionWeb.pending_changes[i])
    end
    TensionWeb.pending_changes = temp
  end
  
  local current_time = util.time()
  local changes_to_remove = {}
  
  -- Process at most 2 changes per update to reduce CPU load
  local changes_processed = 0
  
  for i, change in ipairs(TensionWeb.pending_changes) do
    if current_time >= change.time and changes_processed < 2 then
      -- Apply the change
      local param_name = change.param_name
      
      -- Add safety check to ensure param exists
      if params:get(param_name) ~= nil then
        local current_value = params:get(param_name)
        local new_value = current_value + change.change
        
        -- Safer way to get range
        local min_value = 0
        local max_value = 1
        
        -- Try to get range, but use defaults if nil
        local spec = params:lookup_param(param_name).controlspec
        if spec then
          min_value = spec.minval
          max_value = spec.maxval
        end
        
        new_value = math.max(min_value, math.min(max_value, new_value))
        
        -- Only update if the change is significant (increased threshold)
        if math.abs(new_value - current_value) > 0.05 then
          params:set(param_name, new_value)
          -- Only print in debug mode and limit frequency
          if debug_mode and math.random() < 0.2 then
            print("Propagation: " .. param_name .. " = " .. new_value)
          end
          changes_processed = changes_processed + 1
        end
      end
      
      -- Mark for removal
      table.insert(changes_to_remove, i)
    end
  end
  
  -- Remove processed changes
  table.sort(changes_to_remove, function(a, b) return a > b end)
  for _, index in ipairs(changes_to_remove) do
    table.remove(TensionWeb.pending_changes, index)
  end
end

-- Set the current pattern mode
function TensionWeb.set_pattern(pattern)
  if pattern >= 1 and pattern <= 4 then
    TensionWeb.current_pattern = pattern
    print("Pattern set to: " .. pattern)
  end
end

-- Set harmony value
function TensionWeb.set_harmony(value)
  TensionWeb.harmony = util.clamp(value, 0, 1)
  print("Harmony set to: " .. TensionWeb.harmony)
end

-- Set coherence value
function TensionWeb.set_coherence(value)
  TensionWeb.coherence = util.clamp(value, 0, 1)
  print("Coherence set to: " .. TensionWeb.coherence)
end

-- Freeze/unfreeze the tension web
function TensionWeb.set_frozen(state)
  TensionWeb.is_frozen = state
  print("Frozen state: " .. (TensionWeb.is_frozen and "true" or "false"))
end

return TensionWeb
