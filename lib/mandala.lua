-- mandala.lua
-- Visualization module for Refract with Expandable Focus UI

local Mandala = {}

-- Center coordinates for the screen
local center_x = 64
local center_y = 32
local HEADER_HEIGHT = 10
local FOOTER_HEIGHT = 10
local MAIN_AREA_HEIGHT = 44  -- 64 - (10 + 10)

-- Tab configuration
local tabs = {"VOICE", "MOD", "RHYTHM", "TENSION"}
local current_tab = 4  -- Default to TENSION tab
local tab_width = 32   -- 128/4 = 32 pixels per tab

-- Function to draw tabs
function Mandala.draw_tabs()
  screen.level(3)
  screen.line_width(1)
  
  -- Draw tab separator
  screen.move(0, HEADER_HEIGHT)
  screen.line(128, HEADER_HEIGHT)
  screen.stroke()
  
  -- Draw tabs
  for i, tab in ipairs(tabs) do
    local x = (i-1) * tab_width
    if i == current_tab then
      screen.level(15)
    else
      screen.level(3)
    end
    screen.move(x + tab_width/2, 7)
    screen.text_center(tab)
  end
  
  -- Draw footer separator
  screen.level(3)
  screen.move(0, 64 - FOOTER_HEIGHT)
  screen.line(128, 64 - FOOTER_HEIGHT)
  screen.stroke()
end

-- Function to draw param values in the central area
function Mandala.draw_param_focus(current_param, params_values, param_names)
  -- Get the current parameter and its value
  local current_param_name = param_names[current_param]
  local current_param_value = params_values[current_param]
  
  -- Draw the current parameter at the top
  screen.level(15)
  screen.move(64, HEADER_HEIGHT + 7)
  screen.text_center(current_param_name)
  screen.move(64, HEADER_HEIGHT + 15)
  screen.text_center(string.format("%.1f", current_param_value))
  
  -- Draw the central focus box
  local box_size = 32
  local box_x = center_x - box_size/2
  local box_y = center_y - box_size/2 + 2  -- Slight vertical adjustment
  
  screen.level(5)
  screen.rect(box_x, box_y, box_size, box_size)
  screen.stroke()
  
  -- Draw parameter visualization inside the box
  -- This will change based on param type
  screen.level(10)
  if current_param == 1 then -- Harmonic
    -- Draw a waveform-like indicator
    for i = 0, box_size do
      local y = math.sin(i/box_size * 2 * math.pi * 2) * (box_size/6)
      screen.pixel(box_x + i, box_y + box_size/2 + y)
      screen.fill()
    end
  elseif current_param == 2 then -- Orbital
    -- Draw a circular orbit indicator
    screen.circle(center_x, center_y + 2, box_size/4)
    screen.stroke()
    -- Draw orbiting dot
    local angle = (os.time() * 2) % (2 * math.pi)
    local orbit_x = center_x + math.cos(angle) * (box_size/4)
    local orbit_y = center_y + 2 + math.sin(angle) * (box_size/4)
    screen.circle(orbit_x, orbit_y, 2)
    screen.fill()
  else
    -- Default visualization for other params
    local brightness = math.floor(util.linlin(0, 1, 5, 15, params_values[current_param]))
    screen.level(brightness)
    screen.circle(center_x, center_y + 2, box_size/4)
    screen.fill()
  end
  
  -- Draw related parameters around the central box
  -- Determine adjacent parameters
  local left_param = current_param - 1
  if left_param < 1 then left_param = 8 end
  
  local right_param = current_param + 1
  if right_param > 8 then right_param = 1 end
  
  local up_param = current_param - 3
  if up_param < 1 then up_param = up_param + 8 end
  
  local down_param = current_param + 3
  if down_param > 8 then down_param = down_param - 8 end
  
  -- Draw related parameters with arrows
  -- Left
  screen.level(10)
  screen.move(box_x - 5, box_y + box_size/2)
  screen.line(box_x, box_y + box_size/2)
  screen.stroke()
  screen.move(box_x - 15, box_y + box_size/2)
  screen.text_right(param_names[left_param])
  screen.move(box_x - 25, box_y + box_size/2 + 8)
  screen.text_right(string.format("%.1f", params_values[left_param]))
  
  -- Right
  screen.move(box_x + box_size + 5, box_y + box_size/2)
  screen.line(box_x + box_size, box_y + box_size/2)
  screen.stroke()
  screen.move(box_x + box_size + 15, box_y + box_size/2)
  screen.text(param_names[right_param])
  screen.move(box_x + box_size + 15, box_y + box_size/2 + 8)
  screen.text(string.format("%.1f", params_values[right_param]))
  
  -- Up
  screen.move(center_x, box_y - 5)
  screen.line(center_x, box_y)
  screen.stroke()
  screen.move(center_x, box_y - 7)
  screen.text_center(param_names[up_param])
  
  -- Down
  screen.move(center_x, box_y + box_size + 5)
  screen.line(center_x, box_y + box_size)
  screen.stroke()
  screen.move(center_x, box_y + box_size + 12)
  screen.text_center(param_names[down_param])
end

-- Main draw function
function Mandala.draw(harmonic, orbital, symmetry, resonance, radiance, flow, propagation, reflection, current_idx)
  -- Parameter validation
  harmonic = harmonic or 60
  orbital = orbital or 1
  symmetry = symmetry or 0.5
  resonance = resonance or 0.3
  radiance = radiance or 0.5
  flow = flow or 1
  propagation = propagation or 0.4
  reflection = reflection or 0.3
  current_idx = current_idx or 8  -- Default to "Reflection"
  
  -- Clear screen first to prevent artifacts
  screen.clear()
  
  -- Create arrays of parameter values and names for easier access
  local params_values = {harmonic, orbital, symmetry, resonance, radiance, flow, propagation, reflection}
  local param_names = {"HARMONIC", "ORBITAL", "SYMMETRY", "RESONANCE", 
                      "RADIANCE", "FLOW", "PROPAGATION", "REFLECTION"}
  
  -- Draw tabs at the top
  Mandala.draw_tabs()
  
  -- Draw parameter focus view in the center
  Mandala.draw_param_focus(current_idx, params_values, param_names)
  
  -- Draw footer with global settings
  screen.level(10)
  screen.move(32, 64 - 2)
  screen.text_center("RAD")
  screen.move(64, 64 - 2)
  screen.text_center("H:0.5")
  screen.move(96, 64 - 2)
  screen.text_center("C:0.7")
end

-- Draw relationships between parameters
function Mandala.draw_relationships(active_relationships)
  if not active_relationships then return end
  
  -- Only draw relationships if we're on the TENSION tab
  if current_tab ~= 4 then return end
  
  -- Get center of the focus box
  local box_size = 32
  local box_center_x = center_x
  local box_center_y = center_y + 2
  
  -- Draw relationships based on pattern
  screen.level(3)
  for _, rel in ipairs(active_relationships) do
    local from_idx = rel.from
    local to_idx = rel.to
    local strength = rel.strength
    
    -- Calculate position offsets based on parameter index
    local from_x, from_y = get_param_position(from_idx, box_size)
    local to_x, to_y = get_param_position(to_idx, box_size)
    
    -- Make the strength value affect line width
    screen.line_width(strength * 3)
    
    -- Draw line with brightness based on strength
    screen.level(math.floor(strength * 10))
    screen.move(from_x, from_y)
    
    -- Draw curved line for better visual distinction
    local mid_x = (from_x + to_x) / 2
    local mid_y = (from_y + to_y) / 2
    local offset = 5 * strength
    
    -- Adjust midpoint to create a curve
    if math.abs(from_x - to_x) > math.abs(from_y - to_y) then
      -- Horizontal dominant relationship, curve vertically
      mid_y = mid_y + offset
    else
      -- Vertical dominant relationship, curve horizontally
      mid_x = mid_x + offset
    end
    
    screen.curve(mid_x, mid_y, mid_x, mid_y, to_x, to_y)
    screen.stroke()
  end
  
  -- Reset line width
  screen.line_width(1)
end

-- Helper function to calculate parameter position
function get_param_position(param_idx, box_size)
  local box_x = center_x - box_size/2
  local box_y = center_y - box_size/2 + 2
  
  -- Map parameter index to position
  if param_idx == 1 then -- Harmonic - Top
    return center_x, box_y - 5
  elseif param_idx == 2 then -- Orbital - Top Right
    return box_x + box_size + 5, box_y + box_size/4
  elseif param_idx == 3 then -- Symmetry - Right
    return box_x + box_size + 5, box_y + box_size/2
  elseif param_idx == 4 then -- Resonance - Bottom Right
    return box_x + box_size + 5, box_y + 3*box_size/4
  elseif param_idx == 5 then -- Radiance - Bottom
    return center_x, box_y + box_size + 5
  elseif param_idx == 6 then -- Flow - Bottom Left
    return box_x - 5, box_y + 3*box_size/4  
  elseif param_idx == 7 then -- Propagation - Left
    return box_x - 5, box_y + box_size/2
  elseif param_idx == 8 then -- Reflection - Top Left
    return box_x - 5, box_y + box_size/4
  end
  
  -- Default case
  return center_x, center_y
end

-- Set the current tab (called from the main script)
function Mandala.set_tab(tab_idx)
  if tab_idx >= 1 and tab_idx <= #tabs then
    current_tab = tab_idx
  end
end

-- Get current tab
function Mandala.get_current_tab()
  return current_tab
end

return Mandala