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
