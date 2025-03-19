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
