-- mandala.lua
-- Helper functions for the Refract synthesizer
--
-- Manages the visual representation and algorithms for the mandala-like structure

local Mandala = {}

-- Initialize a new mandala with specified number of nodes
function Mandala.new(num_nodes)
  local m = {
    nodes = {},
    connections = {},
    pulses = {},
    energy = 0,
    freeze = false
  }
  
  -- Initialize nodes in a circular arrangement
  for i=1,num_nodes do
    local angle = (i-1) * (2 * math.pi / num_nodes)
    m.nodes[i] = {
      x = 64 + math.cos(angle) * 25,
      y = 32 + math.sin(angle) * 25,
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
        local golden_ratio = 1.618033988749895
        local strength = 1 / (1 + distance / golden_ratio)
        m.connections[i][j] = strength * 0.8
      end
    end
  end
end

-- Create a pulse between two nodes
function Mandala.create_pulse(m, source, target, strength)
  m.pulses[source][target] = {
    active = true,
    progress = 0,
    energy = strength * m.connections[source][target],
    strength = strength
  }
end

-- Update all active pulses
function Mandala.update_pulses(m, flow_rate)
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if m.pulses[i][j].active then
        -- Update pulse progress
        local speed = 0.05 * flow_rate
        m.pulses[i][j].progress = m.pulses[i][j].progress + speed
        
        -- Check if pulse reached destination
        if m.pulses[i][j].progress >= 1 then
          m.pulses[i][j].active = false
          
          -- Pulse arrived at destination - could trigger effects here
          return i, j, m.pulses[i][j].strength
        end
      end
    end
  end
  
  return nil, nil, nil
end

-- Calculate total energy in the system
function Mandala.calculate_energy(m)
  local total_energy = 0
  
  for i=1,#m.nodes do
    total_energy = total_energy + m.nodes[i].value
    
    for j=1,#m.nodes do
      if m.pulses[i][j].active then
        total_energy = total_energy + m.pulses[i][j].energy
      end
    end
  end
  
  m.energy = total_energy
  return total_energy
end

-- Draw the mandala on screen
function Mandala.draw(m)
  -- Draw connections
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if i ~= j and m.connections[i][j] > 0.1 then
        -- Connection brightness based on strength
        local brightness = math.floor(m.connections[i][j] * 7)
        screen.level(brightness)
        
        -- Draw curved connection
        screen.move(m.nodes[i].x, m.nodes[i].y)
        local mid_x = 64 + (m.nodes[i].x - 64) * 0.3 + (m.nodes[j].x - 64) * 0.3
        local mid_y = 32 + (m.nodes[i].y - 32) * 0.3 + (m.nodes[j].y - 32) * 0.3
        screen.curve(mid_x, mid_y, mid_x, mid_y, m.nodes[j].x, m.nodes[j].y)
        screen.stroke()
      end
    end
  end
  
  -- Draw active pulses
  for i=1,#m.nodes do
    for j=1,#m.nodes do
      if m.pulses[i][j].active then
        -- Calculate pulse position along path
        local progress = m.pulses[i][j].progress
        local xi = m.nodes[i].x
        local yi = m.nodes[i].y
        local xj = m.nodes[j].x
        local yj = m.nodes[j].y
        
        -- Interpolate with slight curve toward center
        local t = progress
        local mt = 1 - t
        local cx = 64
        local cy = 32
        
        local x = mt*mt*xi + 2*mt*t*cx + t*t*xj
        local y = mt*mt*yi + 2*mt*t*cy + t*t*yj
        
        -- Draw pulse
        local energy = m.pulses[i][j].energy
        local size = 1 + energy * 2
        screen.level(15)
        screen.circle(x, y, size)
        screen.fill()
      end
    end
  end
  
  -- Draw nodes
  for i=1,#m.nodes do
    screen.level(m.nodes[i].brightness)
    screen.circle(m.nodes[i].x, m.nodes[i].y, m.nodes[i].size)
    screen.fill()
  end
end

return Mandala
