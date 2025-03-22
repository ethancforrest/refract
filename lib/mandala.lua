-- mandala.lua
-- Visualization module for Refract

local Mandala = {}

-- Center coordinates for the screen
local center_x = 64
local center_y = 30

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
  
  -- Draw title - current parameter
  local param_names = {"Harmonic", "Orbital", "Symmetry", "Resonance", 
                      "Radiance", "Flow", "Propagation", "Reflection"}
  local current_param = param_names[current_idx]
  
  screen.level(15) -- Bright white
  screen.font_size(8)
  screen.move(64, 8)
  screen.text_center(current_param)
  
  -- Draw geometric visualization
  -- Map harmonic to a size
  local size = math.floor(util.linlin(20, 120, 5, 20, harmonic))
  
  -- Draw symmetry lines first (background)
  local num_lines = math.floor(util.linlin(0, 1, 4, 12, symmetry))
  screen.level(3) -- Very dim
  for i = 1, num_lines do
    local angle = (i / num_lines) * 2 * math.pi
    local length = size + 12 * resonance
    screen.move(center_x, center_y)
    screen.line(
      center_x + math.cos(angle) * length,
      center_y + math.sin(angle) * length
    )
    screen.stroke()
  end
  
  -- Draw orbital rings
  screen.level(5) -- Medium brightness
  screen.circle(center_x, center_y, size + 8 * orbital)
  screen.stroke()
  
  -- Draw central circle
  local brightness = math.floor(util.linlin(0, 1, 5, 15, radiance))
  screen.level(brightness)
  screen.circle(center_x, center_y, size)
  screen.fill()
  
  -- Draw propagation points
  screen.level(15) -- Bright
  local num_points = math.floor(util.linlin(0, 1, 3, 6, propagation))
  for i = 1, num_points do
    local angle = (i / num_points) * 2 * math.pi + (os.time() * flow * 0.2) % (2 * math.pi)
    local dist = size * 1.5
    local x = center_x + math.cos(angle) * dist
    local y = center_y + math.sin(angle) * dist
    local point_size = math.max(1, math.floor(1 + reflection * 2))
    screen.circle(x, y, point_size)
    screen.fill()
  end
  
  -- Draw parameter values in a clean format at bottom
  screen.level(15) -- Bright white for text
  screen.font_size(8)
  
  -- Format values nicely
  local h_text = string.format("H:%.0f", harmonic)
  local o_text = string.format("O:%.1f", orbital)
  local s_text = string.format("S:%.1f", symmetry)
  local r_text = string.format("R:%.1f", resonance)
  
  -- First row of parameters
  local y_pos = 50
  screen.move(16, y_pos)
  screen.text_center(h_text)
  screen.move(48, y_pos)
  screen.text_center(o_text)
  screen.move(80, y_pos)
  screen.text_center(s_text)
  screen.move(112, y_pos)
  screen.text_center(r_text)
  
  -- Second row
  y_pos = 60
  local ra_text = string.format("Ra:%.1f", radiance)
  local f_text = string.format("F:%.1f", flow)
  local p_text = string.format("P:%.1f", propagation)
  local re_text = string.format("Re:%.1f", reflection)
  
  screen.move(16, y_pos)
  screen.text_center(ra_text)
  screen.move(48, y_pos)
  screen.text_center(f_text)
  screen.move(80, y_pos)
  screen.text_center(p_text)
  screen.move(112, y_pos)
  screen.text_center(re_text)
end

return Mandala
