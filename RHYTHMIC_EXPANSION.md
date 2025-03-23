# Refract Rhythmic Expansion

## Overview

This document outlines the development plan for adding rhythmic elements to the Refract synthesizer while maintaining its core design philosophy of interconnected parameters and mandala-based visualization.

The implementation will follow a modular approach, integrating with the existing tension web system and maintaining the refractive nature of the instrument. Rhythmic elements will not be treated as separate entities but as pulses of energy propagating through the interconnected parameter system.

## Core Design Principles

1. **Holistic System**: All rhythmic elements must integrate with the existing parameter relationship model
2. **Mandala-Centric**: Visualizations and controls should extend the mandala metaphor and aesthetic
3. **Parameter Propagation**: Rhythmic pulses should flow through the tension web connections
4. **Progressive Complexity**: Start with subtle implementations and allow for scaling complexity
5. **Debug-Friendly**: Implement with clear logging, state tracking, and observable behavior

## Implementation Phases

### Phase 1: Core Rhythmic Engine

#### 1.1 Pulsation Framework
- Create a `rhythm_engine.lua` module
- Implement a clock-synced pulsation system using `clock` library
- Design an API for registering parameters for rhythmic modulation
- Add state management and debugging hooks

```lua
-- Example rhythm_engine.lua module interface
local RhythmEngine = {}

-- Initialize the rhythm engine with global settings
function RhythmEngine.init(bpm, depth)
  -- ...
end

-- Register a parameter for rhythmic modulation
function RhythmEngine.register_param(param_id, modulation_type)
  -- ...
end

-- Get current state for debugging
function RhythmEngine.get_state()
  -- ...
end

-- Toggle debug mode
function RhythmEngine.set_debug(enabled)
  -- ...
end

return RhythmEngine
```

#### 1.2 Tension Web Integration
- Extend `tension_web.lua` to include rhythmic relationships
- Add rhythmic coherence concept that builds on existing coherence parameter
- Create functions for rhythmic pulse propagation through the web

```lua
-- Extensions to tension_web.lua
-- Add rhythmic pulse handling
function TensionWeb.process_pulse(source_param, pulse_strength)
  -- Propagate pulse through connected parameters
  -- Apply coherence and pattern rules
  -- Return affected parameters and strengths
end

-- Set rhythmic coherence (might be separate from or linked to existing coherence)
function TensionWeb.set_rhythmic_coherence(value)
  -- ...
end
```

#### 1.3 Parameter Modulation System
- Create a parameter modulation system in `param_modulation.lua`
- Implement different modulation shapes (sine, triangle, random, etc.)
- Support multiple time divisions (quarter notes, eighths, triplets)
- Add parameter bounds protection and scaling

```lua
-- Example param_modulation.lua interface
local ParamModulation = {}

-- Initialize modulation system
function ParamModulation.init()
  -- ...
end

-- Apply modulation to a parameter
function ParamModulation.apply(param_id, shape, depth, division)
  -- ...
end

-- Get current modulation values for visualization
function ParamModulation.get_modulation_values()
  -- ...
end

return ParamModulation
```

### Phase 2: Visualization & UI

#### 2.1 Mandala Visualization Enhancement
- Extend `mandala.lua` to show rhythmic pulses
- Add visualization for pulse propagation through parameters
- Implement subtle animations that match intensity and timing

```lua
-- Extensions to mandala.lua
-- Draw rhythmic pulses
function Mandala.draw_pulses(active_pulses)
  -- Render pulses on the mandala visualization
  -- Show propagation through parameters
end

-- Animate parameter changes from rhythmic modulation
function Mandala.animate_param_change(param_id, current_value, target_value)
  -- ...
end
```

#### 2.2 RHYTHM Tab Implementation
- Add functionality to the currently placeholder RHYTHM tab
- Design controls for rhythmic parameters
- Create visual feedback for active patterns

```lua
-- Add to mandala.lua or create rhythm_ui.lua
-- Draw rhythm tab content
function draw_rhythm_tab()
  -- Draw controls for:
  -- - Rate (clock division)
  -- - Depth (modulation amount)
  -- - Pattern type (circular, spiral, etc.)
  -- - Rhythmic coherence
end
```

#### 2.3 Key & Encoder Mappings
- Implement controls for the rhythmic system
- Add encoders for rhythmic parameters
- Create key combinations for pattern selection

```lua
-- Add to main script (refract.lua)
-- In the enc() function
if current_tab == 2 then -- RHYTHM tab
  if n == 1 then
    -- Rate control
  elseif n == 2 then
    -- Depth control
  elseif n == 3 then
    -- Pattern selection
  end
end

-- In the key() function
if current_tab == 2 then -- RHYTHM tab
  if n == 2 and z == 1 then
    -- Toggle rhythm on/off
  elseif n == 3 and z == 1 then
    -- Reset/sync rhythm
  end
end
```

### Phase 3: Advanced Features

#### 3.1 Pattern System
- Implement different rhythmic patterns
- Create pattern variation and evolution algorithms
- Add probability-based pattern modification

#### 3.2 State Management
- Add preset system for rhythmic settings
- Implement state save/load for rhythm configurations
- Create initialization sequence for rhythm engine

#### 3.3 Extended Parameter Relationships
- Create more complex parameter relationships for rhythmic propagation
- Implement feedback paths in the rhythmic system
- Add parameter-specific behaviors for different types of parameters

## File Structure

```
refract/
├── refract.lua                  # Main script (extended with rhythmic functionality)
├── lib/
│   ├── mandala.lua              # Visualization (extended with pulse visualization)
│   ├── tension_web.lua          # Parameter relationships (extended with rhythmic relationships)
│   ├── Engine_Refract.sc        # SuperCollider engine
│   ├── rhythm_engine.lua        # NEW: Core rhythmic functionality
│   ├── param_modulation.lua     # NEW: Parameter modulation system
│   ├── rhythm_patterns.lua      # NEW: Pattern definitions and algorithms
│   └── rhythm_ui.lua            # NEW: UI components for rhythmic controls
```

## Development & Testing Approach

### Incremental Implementation
1. Start with a minimal rhythmic engine affecting one parameter
2. Extend to simple propagation through the tension web
3. Add visualization enhancements
4. Implement basic UI controls
5. Extend with additional patterns and features

### Debugging & Testing
- Add debug mode that logs rhythm engine activity
- Create visualization mode that highlights rhythmic activity
- Implement parameter isolation for testing individual components
- Add performance monitoring to ensure CPU efficiency

### Code Quality Guidelines
- Document all functions with clear descriptions
- Use consistent naming conventions
- Maintain separation of concerns between modules
- Create clear interfaces between components
- Avoid tight coupling between visualization and logic
- Use local variables to prevent namespace pollution
- Add error handling for parameter bounds and edge cases

## Integration with Existing Code

The rhythmic system will integrate with the existing codebase through:

1. **Extension points in Tension Web**
   - Add methods for pulse propagation
   - Extend relationship model to include rhythmic characteristics

2. **Visualization hooks in Mandala**
   - Create additional draw layers for rhythmic elements
   - Extend parameter visualization to show modulation

3. **Tab system in main script**
   - Implement the RHYTHM tab functionality
   - Add encoder and key handlers for rhythmic controls

4. **Parameter system extensions**
   - Add modulation targets to existing parameters
   - Create parameter metadata for rhythmic behavior

## Claude Code Notes

When implementing this system:

1. Start with the `rhythm_engine.lua` module as it's the foundation
2. Pay special attention to memory management and CPU usage
3. The tension web extension requires careful understanding of the existing relationship model
4. Test parameter propagation thoroughly to ensure coherent behavior
5. Maintain the aesthetic and feel of the original design while adding rhythmic elements
6. Use debug logging when developing and remove or disable it in production builds
7. Monitor parameter changes to ensure they stay within reasonable bounds