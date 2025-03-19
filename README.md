# Refract

A mandala-like FM synthesizer for norns, designed for expressive performance through intricate parameter relationships.

## Overview

Refract creates a system where eight parameters are interrelated through a dynamic "tension web" that creates rhythmic feedback loops between parameters. The synthesizer is designed as a fractal-like structure where changes to one parameter ripple through the system in musical ways, creating a complex but coherent sonic landscape.

## Requirements

- norns
- MIDI controller with 8 knobs (optional but recommended)

## Features

- FM synthesis engine with mandala-like parameter relationships
- Dynamic, rhythmic feedback between parameters
- Visual representation of the parameter relationships
- Snapshots for capturing and morphing between states

## Controls

### Encoders
- E1: Pattern Mode (Radial, Spiral, Reflection, Fractal)
- E2: Harmony (adjusts harmonic relationships between parameters)
- E3: Coherence (controls how strictly the system maintains musical coherence)

### Keys
- K2: Save snapshot
- K3: Morph between snapshots
- K1+K2: Freeze/unfreeze the system
- K1+K3: Reset system to defaults

### MIDI Controller
The eight knobs on a MIDI controller map to:

1. **Harmonic Center** - Controls the central frequency/harmonic structure
2. **Orbital Period** - Controls the primary rhythm/cycle duration
3. **Symmetry** - Controls how symmetrical the parameter relationships become
4. **Resonance** - Controls filter resonance and harmonic emphasis
5. **Radiance** - Controls modulation depth across the system
6. **Flow Rate** - Controls how quickly modulations move through the mandala
7. **Propagation** - Controls how modulations spread through the system
8. **Reflection** - Controls how modulations bounce back from their destinations

## Conceptual Design

Refract is inspired by the concept of interconnected parameters forming a mandala-like structure, where each parameter reflects and influences all others. The system creates a rhythmic web of relationships that maintains musical coherence while allowing for deep exploration of a complex parameter space.

When you turn a knob, you not only adjust that parameter but also modify the tension web that connects all parameters, creating pulses that propagate through the system according to the current pattern mode. This creates a living, breathing instrument that responds in complex but musically meaningful ways.

## Performance Tips

- Start with the Radial pattern mode for most predictable results
- Use the Coherence control to adjust how strictly parameters adhere to musical relationships
- When exploring, try different Pattern Modes to change how parameters influence each other
- Use K1+K2 (Freeze) to temporarily lock the current sound while you adjust the tension web
- Save snapshots of interesting states and morph between them for evolving textures
- Try setting Flow Rate and Orbital Period to complementary values for rhythmically coherent pulses
