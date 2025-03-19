-- mandala.lua
-- Helper functions for the Refract synthesizer
--
-- Manages the visual representation and algorithms for the mandala-like structure

local Mandala = {}

-- Constants for screen dimensions and visualization
local SCREEN_CENTER_X = 64
local SCREEN_CENTER_Y = 32
local NODE_RADIUS = 25
local CONNECTION_CURVE_FACTOR = 0.3
local MIN_CONNECTION_STRENGTH = 0.1
local PULSE_MAX_SIZE = 3
local EPSILON = 1e-6 -- For floating point comparisons

-- Initialize a new mandala with specified number of nodes
function Mandala.new(num_nodes)
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
      x = SCREEN_CENTER_X + math.cos(angle) * NODE_RADIUS,
      y = SCREEN_CENTER_Y + math.sin(angle) * NODE_RADIUS,
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
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if i == j then
        m.connections[i][j] = 0  -- No self-connection
      else
        -- Calculate angular distance
        local distance = math.abs(i-j)
        if distance > #m.nodes/2 then 
          distance = #m.nodes - distance 
        end
        
        -- Create strong connections to opposite and adjacent nodes
        if distance == #m.nodes/2 then
          m.connections[i][j] = 0.8  -- Strong to opposite
        elseif distance == 1 then
          m.connections[i][j] = 0.6  -- Medium to adjacent
        else
          m.connections[i][j] = 0.3 * (1 - (distance/(#m.nodes/2)))  -- Weaker to others
        end
      end
    end
  end
end

function Mandala.create_spiral_connections(m)
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if i == j then
        m.connections[i][j] = 0  -- No self-connection
      else
        -- Create unidirectional connections following a spiral
        if j == ((i % #m.nodes) + 1) then
          m.connections[i][j] = 0.8  -- Strong to next in sequence
        else
          m.connections[i][j] = 0.2  -- Weak to others
        end
      end
    end
  end
end

function Mandala.create_reflection_connections(m)
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if i == j then
        m.connections[i][j] = 0  -- No self-connection
      else
        -- Connect strongly to the reflection point
        local reflection = ((i + #m.nodes/2 - 1) % #m.nodes) + 1
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
  local golden_ratio = 1.618033988749895
  
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if i == j then
        m.connections[i][j] = 0  -- No self-connection
      else
        -- Calculate connection based on fractal pattern
        local distance = math.abs(i-j)
        if distance > #m.nodes/2 then 
          distance = #m.nodes - distance 
        end
        
        -- Golden ratio influences connection strength
        local strength = 1 / (1 + distance / golden_ratio)
        m.connections[i][j] = strength * 0.8
      end
    end
  end
end

-- Create a pulse between two nodes
function Mandala.create_pulse(m, source, target, strength)
  -- Validate input
  if not (source >= 1 and source <= #m.nodes and
          target >= 1 and target <= #m.nodes) then
    print("Error: Invalid pulse source or target")
    return
  end
  
  -- Ensure strength is within valid range
  strength = math.min(math.max(strength, 0), 1)
  
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

-- Calculate total energy in the system
function Mandala.calculate_energy(m)
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
  -- Group draw calls by brightness level for optimization
  local connection_by_brightness = {}
  local pulse_by_size = {}
  local node_by_brightness = {}
  
  -- Prepare connections by brightness
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if i ~= j and m.connections[i][j] > (MIN_CONNECTION_STRENGTH - EPSILON) then
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
      local mid_x = SCREEN_CENTER_X + (m.nodes[i].x - SCREEN_CENTER_X) * CONNECTION_CURVE_FACTOR + 
                    (m.nodes[j].x - SCREEN_CENTER_X) * CONNECTION_CURVE_FACTOR
      local mid_y = SCREEN_CENTER_Y + (m.nodes[i].y - SCREEN_CENTER_Y) * CONNECTION_CURVE_FACTOR + 
                    (m.nodes[j].y - SCREEN_CENTER_Y) * CONNECTION_CURVE_FACTOR
      screen.curve(mid_x, mid_y, mid_x, mid_y, m.nodes[j].x, m.nodes[j].y)
    end
    screen.stroke()
  end
  
  -- Prepare pulses by size
  for _, pulse in ipairs(m.active_pulses) do
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
    
    local x = mt*mt*xi + 2*mt*t*SCREEN_CENTER_X + t*t*xj
    local y = mt*mt*yi + 2*mt*t*SCREEN_CENTER_Y + t*t*yj
    
    -- Prepare pulse for drawing
    local energy = pulse.energy
    local size = 1 + energy * 2
    pulse_by_size[size] = pulse_by_size[size] or {}
    table.insert(pulse_by_size[size], {x, y})
  end
  
  -- Draw pulses grouped by size
  for size, pulses in pairs(pulse_by_size) do
    screen.level(15)
    for _, p in ipairs(pulses) do
      screen.circle(p[1], p[2], size)
      screen.fill()
    end
  end
  
  -- Prepare nodes by brightness
  for i=1,#m.nodes do
    local brightness = m.nodes[i].brightness
    node_by_brightness[brightness] = node_by_brightness[brightness] or {}
    table.insert(node_by_brightness[brightness], {
      x = m.nodes[i].x,
      y = m.nodes[i].y,
      size = m.nodes[i].size
    })
  end
  
  -- Draw nodes grouped by brightness
  for brightness, nodes in pairs(node_by_brightness) do
    screen.level(brightness)
    for _, node in ipairs(nodes) do
      screen.circle(node.x, node.y, node.size)
      screen.fill()
    end
  end
end

-- Clear all active pulses
function Mandala.clear_pulses(m)
  -- Reset pulse matrix
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      m.pulses[i][j].active = false
      m.pulses[i][j].progress = 0
      m.pulses[i][j].energy = 0
      m.pulses[i][j].strength = 0
    end
  end
  
  -- Clear active pulses list
  m.active_pulses = {}
end

-- Set node value (when a parameter changes)
function Mandala.set_node_value(m, node_idx, value)
  if node_idx >= 1 and node_idx <= #m.nodes then
    m.nodes[node_idx].value = math.min(math.max(value, 0), 1)
    -- Update node appearance based on value
    m.nodes[node_idx].brightness = 5 + math.floor(value * 10)
    m.nodes[node_idx].size = 2 + value * 2
  end
end

-- Create an interrelated tension pulse pattern
function Mandala.propagate_tension(m, source_node, strength, pattern_type)
  if not pattern_type then pattern_type = "radial" end
  
  local targets = {}
  
  if pattern_type == "radial" then
    -- Propagate to neighbors and opposite
    local opposite = ((source_node + #m.nodes/2 - 1) % #m.nodes) + 1
    table.insert(targets, opposite)
    table.insert(targets, ((source_node) % #m.nodes) + 1)
    table.insert(targets, ((source_node - 2) % #m.nodes) + 1)
    
  elseif pattern_type == "spiral" then
    -- Propagate in spiral pattern
    for i=1,3 do
      table.insert(targets, ((source_node + i - 1) % #m.nodes) + 1)
    end
    
  elseif pattern_type == "reflection" then
    -- Propagate to reflection points
    local reflection = ((source_node + #m.nodes/2 - 1) % #m.nodes) + 1
    table.insert(targets, reflection)
    table.insert(targets, ((reflection) % #m.nodes) + 1)
    table.insert(targets, ((reflection - 2) % #m.nodes) + 1)
    
  elseif pattern_type == "fractal" then
    -- Propagate using golden ratio relationships
    local golden_ratio = 1.618033988749895
    local num_nodes = #m.nodes
    local idx1 = ((source_node + math.floor(golden_ratio) - 1) % num_nodes) + 1
    local idx2 = ((source_node + math.floor(golden_ratio * 2) - 1) % num_nodes) + 1
    local idx3 = ((
        elseif pattern_type == "fractal" then
    -- Propagate using golden ratio relationships
    local golden_ratio = 1.618033988749895
    local num_nodes = #m.nodes
    local idx1 = ((source_node + math.floor(golden_ratio) - 1) % num_nodes) + 1
    local idx2 = ((source_node + math.floor(golden_ratio * 2) - 1) % num_nodes) + 1
    local idx3 = ((source_node + math.floor(golden_ratio * 3) - 1) % num_nodes) + 1
    table.insert(targets, idx1)
    table.insert(targets, idx2)
    table.insert(targets, idx3)
  end
  
  -- Create pulses to all target nodes
  for _, target in ipairs(targets) do
    -- Scale strength by connection strength
    local pulse_strength = strength * m.connections[source_node][target]
    Mandala.create_pulse(m, source_node, target, pulse_strength)
  end
end

-- Get node state for parameter snapshots
function Mandala.get_node_values(m)
  local values = {}
  for i=1,#m.nodes do
    values[i] = m.nodes[i].value
  end
  return values
end

-- Set node states from parameter snapshots
function Mandala.set_node_values(m, values)
  if not values or #values ~= #m.nodes then
    print("Error: Invalid node values array")
    return
  end
  
  for i=1,#m.nodes do
    m.nodes[i].value = values[i]
    -- Update node appearance based on value
    m.nodes[i].brightness = 5 + math.floor(values[i] * 10)
    m.nodes[i].size = 2 + values[i] * 2
  end
end

-- Morph between two snapshots
function Mandala.morph_values(m, values1, values2, t)
  if not (values1 and values2 and #values1 == #m.nodes and #values2 == #m.nodes) then
    print("Error: Invalid node value arrays for morphing")
    return
  end
  
  -- Clamp t to 0-1 range
  t = math.min(math.max(t, 0), 1)
  
  for i=1,#m.nodes do
    -- Linear interpolation between the two sets of values
    local new_value = values1[i] * (1-t) + values2[i] * t
    Mandala.set_node_value(m, i, new_value)
  end
end

-- Generate tension between nodes based on parameter relationships
function Mandala.generate_coherence_tension(m, coherence_amount)
  -- coherence_amount determines how strongly parameters should relate
  coherence_amount = math.min(math.max(coherence_amount, 0), 1)
  
  if coherence_amount < EPSILON then return end
  
  -- Calculate ideal harmonic relationships
  local harmonic_goals = {}
  for i=1,#m.nodes do
    harmonic_goals[i] = {}
    for j=1,#m.nodes do
      if i ~= j then
        -- Simple harmonic ratios (could be made more complex)
        local ratio = (i / j) % 1
        harmonic_goals[i][j] = ratio
      end
    end
  end
  
  -- Create tension pulses where parameters are most out of harmony
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if i ~= j then
        local value_i = m.nodes[i].value
        local value_j = m.nodes[j].value
        local ideal_j = value_i * harmonic_goals[i][j]
        
        -- Calculate dissonance - how far from ideal relationship
        local dissonance = math.abs(value_j - ideal_j)
        
        -- Create tension pulse if dissonance is high enough and connection is strong
        if dissonance > 0.3 and m.connections[i][j] > 0.5 then
          local strength = dissonance * coherence_amount * m.connections[i][j]
          Mandala.create_pulse(m, i, j, strength)
        end
      end
    end
  end
end

return Mandala
