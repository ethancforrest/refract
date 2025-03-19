-- mandala.lua
-- Helper functions for the Refract synthesizer
--
-- Manages the visual representation and algorithms for the mandala-like structure

local Mandala = {}

-- Constants for screen dimensions and visualization
local CONSTANTS = {
  SCREEN = {
    CENTER_X = 64,
    CENTER_Y = 32
  },
  NODES = {
    RADIUS = 25,
    MIN_SIZE = 2,
    MAX_SIZE = 5
  },
  CONNECTIONS = {
    CURVE_FACTOR = 0.3,
    MIN_STRENGTH = 0.1
  },
  PULSES = {
    MAX_SIZE = 3
  },
  MATH = {
    EPSILON = 1e-6,  -- For floating point comparisons
    GOLDEN_RATIO = 1.618033988749895
  }
}

-- Initialize a new mandala with specified number of nodes
function Mandala.new(num_nodes)
  -- Input validation
  if num_nodes <= 0 then
    print("Error: Mandala requires at least 1 node")
    return nil
  end

  local m = {
    nodes = {},
    connections = {},
    pulses = {},
    active_pulses = {}, -- Tracking only active pulses for performance
    energy = 0,
    freeze = false
  }
  
  -- Initialize nodes in a circular arrangement
  for i=1,num_nodes do
    local angle = (i-1) * (2 * math.pi / num_nodes)
    m.nodes[i] = {
      x = CONSTANTS.SCREEN.CENTER_X + math.cos(angle) * CONSTANTS.NODES.RADIUS,
      y = CONSTANTS.SCREEN.CENTER_Y + math.sin(angle) * CONSTANTS.NODES.RADIUS,
      size = 3,
      brightness = 15,
      value = 0.5  -- normalized parameter value
    }
  end
  
  -- Initialize connection matrix
  for i=1,num_nodes do
    m.connections[i] = {}
    for j=1,num_nodes do
      m.connections[i][j] = 0
    end
  end
  
  -- Initialize pulse matrix
  for i=1,num_nodes do
    m.pulses[i] = {}
    for j=1,num_nodes do
      m.pulses[i][j] = {
        active = false,
        progress = 0,
        energy = 0,
        strength = 0
      }
    end
  end
  
  return m
end

-- Create different connection patterns
function Mandala.create_radial_connections(m)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return
  end

  local num_nodes = #m.nodes
  
  for i=1,num_nodes do
    for j=1,num_nodes do
      if i == j then
        m.connections[i][j] = 0  -- No self-connection
      else
        -- Calculate angular distance
        local distance = math.abs(i-j)
        if distance > num_nodes/2 then 
          distance = num_nodes - distance 
        end
        
        -- Create strong connections to opposite and adjacent nodes
        if distance == num_nodes/2 then
          m.connections[i][j] = 0.8  -- Strong to opposite
        elseif distance == 1 then
          m.connections[i][j] = 0.6  -- Medium to adjacent
        else
          m.connections[i][j] = 0.3 * (1 - (distance/(num_nodes/2)))  -- Weaker to others
        end
      end
    end
  end
end

function Mandala.create_spiral_connections(m)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return
  end

  local num_nodes = #m.nodes
  
  for i=1,num_nodes do
    for j=1,num_nodes do
      if i == j then
        m.connections[i][j] = 0  -- No self-connection
      else
        -- Create unidirectional connections following a spiral
        if j == ((i % num_nodes) + 1) then
          m.connections[i][j] = 0.8  -- Strong to next in sequence
        else
          m.connections[i][j] = 0.2  -- Weak to others
        end
      end
    end
  end
end

function Mandala.create_reflection_connections(m)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return
  end

  local num_nodes = #m.nodes
  
  for i=1,num_nodes do
    for j=1,num_nodes do
      if i == j then
        m.connections[i][j] = 0  -- No self-connection
      else
        -- Connect strongly to the reflection point
        local reflection = ((i + num_nodes/2 - 1) % num_nodes) + 1
        if j == reflection then
          m.connections[i][j] = 0.9  -- Strong to reflection
        else
          m.connections[i][j] = 0.2  -- Weak to others
        end
      end
    end
  end
end

function Mandala.create_fractal_connections(m)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return
  end

  local num_nodes = #m.nodes
  
  for i=1,num_nodes do
    for j=1,num_nodes do
      if i == j then
        m.connections[i][j] = 0  -- No self-connection
      else
        -- Calculate connection based on fractal pattern
        local distance = math.abs(i-j)
        if distance > num_nodes/2 then 
          distance = num_nodes - distance 
        end
        
        -- Golden ratio influences connection strength
        local strength = 1 / (1 + distance / CONSTANTS.MATH.GOLDEN_RATIO)
        m.connections[i][j] = strength * 0.8
      end
    end
  end
end

-- Apply connection pattern based on pattern mode
function Mandala.apply_pattern(m, pattern_mode)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return
  end
  
  -- Reset connections
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      m.connections[i][j] = 0
    end
  end
  
  -- Apply selected pattern
  if pattern_mode == 1 then
    Mandala.create_radial_connections(m)
  elseif pattern_mode == 2 then
    Mandala.create_spiral_connections(m)
  elseif pattern_mode == 3 then
    Mandala.create_reflection_connections(m)
  elseif pattern_mode == 4 then
    Mandala.create_fractal_connections(m)
  else
    print("Error: Unknown pattern mode: " .. tostring(pattern_mode))
    Mandala.create_radial_connections(m) -- Default to radial
  end
end

-- Create a pulse between two nodes
function Mandala.create_pulse(m, source, target, strength)
  -- Validate input
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return
  end
  
  if not (source >= 1 and source <= #m.nodes and
          target >= 1 and target <= #m.nodes) then
    print("Error: Invalid pulse source or target")
    return
  end
  
  -- Ensure strength is within valid range
  strength = math.min(math.max(strength or 0.5, 0), 1)
  
  -- Ensure connection exists
  if m.connections[source][target] < CONSTANTS.CONNECTIONS.MIN_STRENGTH then
    print("Warning: Creating pulse on weak connection")
  end
  
  -- Create pulse data
  local pulse = {
    source = source,
    target = target,
    active = true,
    progress = 0,
    energy = strength * m.connections[source][target],
    strength = strength
  }
  
  -- Store in both the matrix and the active pulses list
  m.pulses[source][target] = pulse
  table.insert(m.active_pulses, pulse)
end

-- Update all active pulses
function Mandala.update_pulses(m, flow_rate)
  if not m or not m.active_pulses then
    print("Error: Invalid mandala object")
    return nil, nil, nil
  end
  
  local completed_source, completed_target, completed_strength = nil, nil, nil
  local new_active_pulses = {}
  
  -- Ensure flow_rate is valid
  flow_rate = flow_rate or 1
  flow_rate = math.max(0.1, flow_rate)
  
  -- Process each active pulse
  for i, pulse in ipairs(m.active_pulses) do
    -- Update pulse progress
    local speed = 0.05 * flow_rate
    pulse.progress = pulse.progress + speed
    
    -- Check if pulse reached destination
    if pulse.progress >= 1 then
      pulse.active = false
      m.pulses[pulse.source][pulse.target].active = false
      
      -- Record the first completed pulse for return
      if completed_source == nil then
        completed_source = pulse.source
        completed_target = pulse.target
        completed_strength = pulse.strength
      end
    else
      -- Keep active pulses
      table.insert(new_active_pulses, pulse)
    end
  end
  
  -- Replace active pulses list with updated one
  m.active_pulses = new_active_pulses
  
  return completed_source, completed_target, completed_strength
end

-- Generate tension based on coherence
function Mandala.generate_coherence_tension(m, coherence)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return
  end
  
  -- Only proceed if not frozen
  if m.freeze then return end
  
  local num_nodes = #m.nodes
  
  -- Calculate average value
  local avg_value = 0
  for i=1,num_nodes do
    avg_value = avg_value + m.nodes[i].value
  end
  avg_value = avg_value / num_nodes
  
  -- Find node furthest from average
  local max_diff = 0
  local furthest_node = 1
  for i=1,num_nodes do
    local diff = math.abs(m.nodes[i].value - avg_value)
    if diff > max_diff then
      max_diff = diff
      furthest_node = i
    end
  end
  
  -- Generate pulse from furthest node to target based on coherence
  local target
  if coherence > 0.7 then
    -- High coherence: send toward average (pick node closest to avg)
    local min_diff = 1
    local closest_node = 1
    for i=1,num_nodes do
      if i ~= furthest_node then
        local diff = math.abs(m.nodes[i].value - avg_value)
        if diff < min_diff then
          min_diff = diff
          closest_node = i
        end
      end
    end
    target = closest_node
  elseif coherence < 0.3 then
    -- Low coherence: send toward random node
    target = math.random(num_nodes)
    while target == furthest_node do
      target = math.random(num_nodes)
    end
  else
    -- Medium coherence: send to node with strong connection
    local max_conn = 0
    for j=1,num_nodes do
      if j ~= furthest_node and m.connections[furthest_node][j] > max_conn then
        max_conn = m.connections[furthest_node][j]
        target = j
      end
    end
  end
  
  -- Create pulse with strength based on coherence
  Mandala.create_pulse(m, furthest_node, target, coherence)
end

-- Morph between two snapshots
function Mandala.morph_values(m, start_snapshot, end_snapshot, position)
  if not m or not m.nodes or not start_snapshot or not end_snapshot then
    print("Error: Invalid morph parameters")
    return
  end
  
  -- Ensure position is valid
  position = math.min(math.max(position or 0, 0), 1)
  
  -- Interpolate values
  for i=1,#m.nodes do
    if start_snapshot[i] and end_snapshot[i] then
      m.nodes[i].value = start_snapshot[i] * (1 - position) + end_snapshot[i] * position
    end
  end
end

-- Calculate total energy in the system
function Mandala.calculate_energy(m)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return 0
  end

  local total_energy = 0
  
  -- Sum node values
  for i=1,#m.nodes do
    total_energy = total_energy + m.nodes[i].value
  end
  
  -- Add energy from active pulses
  for _, pulse in ipairs(m.active_pulses) do
    total_energy = total_energy + pulse.energy
  end
  
  m.energy = total_energy
  return total_energy
end

-- Draw the mandala on screen
function Mandala.draw(m)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return
  end

  -- Group draw calls by brightness level for optimization
  local connection_by_brightness = {}
  local pulse_by_size = {}
  local node_by_brightness = {}
  
  -- Prepare connections by brightness
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if i ~= j and m.connections[i][j] > (CONSTANTS.CONNECTIONS.MIN_STRENGTH - CONSTANTS.MATH.EPSILON) then
        -- Connection brightness based on strength
        local brightness = math.floor(m.connections[i][j] * 7)
        connection_by_brightness[brightness] = connection_by_brightness[brightness] or {}
        table.insert(connection_by_brightness[brightness], {i, j})
      end
    end
  end
  
  -- Draw connections grouped by brightness
  for brightness, connections in pairs(connection_by_brightness) do
    screen.level(brightness)
    for _, conn in ipairs(connections) do
      local i, j = conn[1], conn[2]
      -- Draw curved connection
      screen.move(m.nodes[i].x, m.nodes[i].y)
      local mid_x = CONSTANTS.SCREEN.CENTER_X + 
                    (m.nodes[i].x - CONSTANTS.SCREEN.CENTER_X) * CONSTANTS.CONNECTIONS.CURVE_FACTOR + 
                    (m.nodes[j].x - CONSTANTS.SCREEN.CENTER_X) * CONSTANTS.CONNECTIONS.CURVE_FACTOR
      local mid_y = CONSTANTS.SCREEN.CENTER_Y + 
                    (m.nodes[i].y - CONSTANTS.SCREEN.CENTER_Y) * CONSTANTS.CONNECTIONS.CURVE_FACTOR + 
                    (m.nodes[j].y - CONSTANTS.SCREEN.CENTER_Y) * CONSTANTS.CONNECTIONS.CURVE_FACTOR
      screen.curve(mid_x, mid_y, mid_x, mid_y, m.nodes[j].x, m.nodes[j].y)
    end
    screen.stroke()
  end
  
  -- Prepare pulses by size
  for _, pulse in ipairs(m.active_pulses) do
    if pulse and pulse.source and pulse.target and 
       m.nodes[pulse.source] and m.nodes[pulse.target] then
      -- Calculate pulse position along path
      local progress = pulse.progress
      local i, j = pulse.source, pulse.target
      local xi = m.nodes[i].x
      local yi = m.nodes[i].y
      local xj = m.nodes[j].x
      local yj = m.nodes[j].y
      
      -- Interpolate with slight curve toward center
      local t = progress
      local mt = 1 - t
      
      local x = mt*mt*xi + 2*mt*t*CONSTANTS.SCREEN.CENTER_X + t*t*xj
      local y = mt*mt*yi + 2*mt*t*CONSTANTS.SCREEN.CENTER_Y + t*t*yj
      
      -- Prepare pulse for drawing
      local energy = pulse.energy
      local size = 1 + math.min(math.max(energy * 2, 0), CONSTANTS.PULSES.MAX_SIZE)
      pulse_by_size[size] = pulse_by_size[size] or {}
      table.insert(pulse_by_size[size], {x, y})
    end
  end
  
  -- Draw pulses grouped by size
  for size, pulses in pairs(pulse_by_size) do
    screen.level(15) -- Pulses are always bright
    for _, pos in ipairs(pulses) do
      local x, y = pos[1], pos[2]
      screen.circle(x, y, size)
      screen.fill()
    end
  end
  
  -- Prepare nodes by brightness
  for i=1,#m.nodes do
    -- Node brightness based on value
    local brightness = math.floor(m.nodes[i].value * 15)
    node_by_brightness[brightness] = node_by_brightness[brightness] or {}
    table.insert(node_by_brightness[brightness], i)
  end
  
  -- Draw nodes grouped by brightness
  for brightness, nodes in pairs(node_by_brightness) do
    screen.level(brightness)
    for _, i in ipairs(nodes) do
      -- Size based on value and energy
      local size = CONSTANTS.NODES.MIN_SIZE + 
                  (CONSTANTS.NODES.MAX_SIZE - CONSTANTS.NODES.MIN_SIZE) * m.nodes[i].value
      
      -- Draw node circle
      screen.circle(m.nodes[i].x, m.nodes[i].y, size)
      screen.fill()
    end
  end
  
  -- Draw freeze indicator if system is frozen
  if m.freeze then
    screen.level(4)
    screen.rect(2, 2, 6, 6)
    screen.fill()
  end
end

-- Get snapshot of current parameter values
function Mandala.get_snapshot(m)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return nil
  end
  
  local snapshot = {}
  for i=1,#m.nodes do
    snapshot[i] = m.nodes[i].value
  end
  
  return snapshot
end

-- Set node values from snapshot
function Mandala.set_snapshot(m, snapshot)
  if not m or not m.nodes or not snapshot then
    print("Error: Invalid set_snapshot parameters")
    return
  end
  
  for i=1,#m.nodes do
    if snapshot[i] then
      m.nodes[i].value = snapshot[i]
    end
  end
end

-- Set freeze state
function Mandala.set_freeze(m, freeze)
  if not m then
    print("Error: Invalid mandala object")
    return
  end
  
  m.freeze = freeze and true or false
end

-- Update node value and trigger appropriate pulses
function Mandala.update_node_value(m, index, value, harmony)
  if not m or not m.nodes or index < 1 or index > #m.nodes then
    print("Error: Invalid node update parameters")
    return
  end
  
  -- Only update if not frozen
  if m.freeze then return end
  
  -- Store old value for calculating change
  local old_value = m.nodes[index].value
  
  -- Update with new value
  m.nodes[index].value = math.min(math.max(value, 0), 1)
  
  -- Calculate change amount
  local change = math.abs(m.nodes[index].value - old_value)
  
  -- Only trigger pulses for significant changes
  if change > 0.05 then
    -- Trigger pulses based on connections
    for j=1,#m.nodes do
      if j ~= index and m.connections[index][j] > CONSTANTS.CONNECTIONS.MIN_STRENGTH then
        -- Strength based on connection strength and change amount
        local strength = m.connections[index][j] * change
        
        -- Apply harmony influence to strength
        if harmony then
          harmony = math.min(math.max(harmony, 0), 1)
          strength = strength * (0.5 + harmony * 0.5)
        end
        
        -- Create pulse
        Mandala.create_pulse(m, index, j, strength)
      end
    end
  end
end

-- Reset all node values to default
function Mandala.reset(m)
  if not m or not m.nodes then
    print("Error: Invalid mandala object")
    return
  end
  
  -- Reset node values
  for i=1,#m.nodes do
    m.nodes[i].value = 0.5
  end
  
  -- Clear all pulses
  m.active_pulses = {}
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      m.pulses[i][j] = {
        active = false,
        progress = 0,
        energy = 0,
        strength = 0
      }
    end
  end
end

return Mandala
