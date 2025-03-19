// Engine_Refract.sc
// An FM synthesis engine with mandala-like parameter relationships

Engine_Refract : CroneEngine {
  var <synths;
  var <params;
  var <bus;
  var <groups;
  var <operators;
  var <fftBuf;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {
    // Initialize variables
    synths = Dictionary.new;
    params = Dictionary.new;
    bus = Dictionary.new;
    groups = Dictionary.new;
    operators = Dictionary.new;
    
    // Create groups for controlling execution order
    groups[\main] = Group.new(context.xg);
    groups[\fx] = Group.after(groups[\main]);
    
    // Create busses for audio routing
    bus[\fx] = Bus.audio(context.server, 2);
    
    // Define parameter ranges for validation
    var paramRanges = Dictionary.new;
    paramRanges[\harmonic] = [20, 120];    // MIDI note range
    paramRanges[\orbital] = [0.25, 4];     // Beats
    paramRanges[\symmetry] = [0, 1];       // Normalized
    paramRanges[\resonance] = [0, 1];      // Normalized
    paramRanges[\radiance] = [0, 1];       // Normalized
    paramRanges[\flow] = [0.25, 4];        // Beats
    paramRanges[\propagation] = [0, 1];    // Normalized
    paramRanges[\reflection] = [0, 1];     // Normalized
    
    // Initialize parameters with default values
    params[\harmonic] = 60;        // Harmonic center (MIDI note)
    params[\orbital] = 1;          // Orbital period (in beats)
    params[\symmetry] = 0.5;       // Symmetry (0-1)
    params[\resonance] = 0.3;      // Resonance (0-1)
    params[\radiance] = 0.5;       // Radiance (0-1)
    params[\flow] = 1;             // Flow rate (in beats)
    params[\propagation] = 0.4;    // Propagation (0-1)
    params[\reflection] = 0.3;     // Reflection (0-1)
    params[\freeze] = 0;           // Freeze (0 or 1)
    
    // Helper function to clamp values to valid ranges
    var clampValue = { |param, value|
      var range = paramRanges[param];
      if(range.notNil, {
        value.clip(range[0], range[1]);
      }, {
        value;
      });
    };
    
    // FM operator setup (in a mandala-like arrangement)
    6.do { |i|
      var index = i + 1;
      operators[index] = Dictionary.new;
      operators[index][\carriers] = List.new;
      operators[index][\modulators] = List.new;
    };
    
    // Define operator relationships
    // 1 is center, 2-7 surround it in a ring
    operators[1][\modulators] = [2, 3, 4, 5, 6, 7];  // Center modulated by all
    operators[2][\carriers] = [1]; operators[2][\modulators] = [3, 7];
    operators[3][\carriers] = [1, 2]; operators[3][\modulators] = [4];
    operators[4][\carriers] = [1, 3]; operators[4][\modulators] = [5];
    operators[5][\carriers] = [1, 4]; operators[5][\modulators] = [6];
    operators[6][\carriers] = [1, 5]; operators[6][\modulators] = [7];
    operators[7][\carriers] = [1, 6]; operators[7][\modulators] = [2];
    
    // SynthDefs
    SynthDef(\fm_op, {
      arg out=0, freq=440, phase=0, mul=1, add=0, gate=1;
      var sig, env;
      
      env = EnvGen.kr(Env.adsr(0.01, 0.1, 0.9, 0.1), gate, doneAction: 2);
      sig = SinOsc.ar(freq, phase, mul, add);
      
      Out.ar(out, sig * env);
    }).add;
    
    SynthDef(\fm_voice, {
      arg out=0, amp=0.5, gate=1, 
          harmonic=60, orbital=1, symmetry=0.5, resonance=0.3,
          radiance=0.5, flow=1, propagation=0.4, reflection=0.3;
      
      var carriers, modulators, sig, env, mod_freqs, carr_freqs;
      var base_freq, harmonicity, mod_indices, feedback;
      var num_ops = 6;
      
      // Convert MIDI note to Hz for the base frequency
      base_freq = harmonic.midicps;
      
      // Calculate modulator frequencies based on harmonic relationships
      harmonicity = Array.fill(num_ops, {|i| 
        var ratio = i + 1 / (i % 3 + 1); // Create harmonically related ratios
        ratio = ratio * orbital.linexp(0.25, 4, 0.5, 2); // Orbital affects ratios
        ratio
      });
      
      // Calculate modulation indices based on radiance and symmetry
      mod_indices = Array.fill(num_ops, {|i|
        var index = radiance * 10;
        // Symmetry affects how evenly distributed the indices are
        index = index * (1 - symmetry + symmetry * (i / num_ops));
        index
      });
      
      // Feedback amount based on reflection parameter
      feedback = reflection * 0.9;
      
      // Create modulator signals
      modulators = Array.fill(num_ops, {|i|
        var mod_freq = base_freq * harmonicity[i];
        var mod_sig = SinOsc.ar(
          mod_freq, 
          LocalIn.ar(1) * feedback * (i+1/num_ops), 
          mod_indices[i]
        );
        mod_sig
      });
      
      // Apply cross-modulation based on propagation
      modulators = modulators.collect({|mod, i|
        var next_mod = modulators.wrapAt(i+1);
        var cross_mod = LinXFade2.ar(mod, next_mod, propagation * 2 - 1);
        cross_mod
      });
      
      // Send one modulator back as feedback
      LocalOut.ar(modulators[0]);
      
      // Create carrier signals with different modulator routings
      carriers = Array.fill(num_ops, {|i|
        var carr_freq = base_freq * harmonicity[i].reciprocal;
        var mod_sum = modulators.sum / num_ops;
        
        // Each carrier receives modulation from different modulators
        var mod_amount = modulators.wrapAt(i) * 0.5 + 
                        modulators.wrapAt(i+2) * 0.3 + 
                        modulators.wrapAt(i+4) * 0.2;
        
        // Symmetry determines how much unique modulation vs common modulation
        mod_amount = LinXFade2.ar(mod_amount, mod_sum, symmetry * 2 - 1);
        
        SinOsc.ar(carr_freq + (mod_amount * carr_freq))
      });
      
      // Mix carriers with balanced levels
      sig = Mix.ar(carriers) / (num_ops.sqrt);
      
      // Apply filtering based on resonance
      sig = RLPF.ar(sig, base_freq * resonance.linexp(0, 1, 1, 12), resonance.linexp(0, 1, 1, 0.1));
      
      // Apply amplitude envelope
      env = EnvGen.kr(
        Env.adsr(
          flow.linexp(0.25, 4, 0.01, 0.5),  // Flow affects envelope times
          flow.linexp(0.25, 4, 0.1, 1),
          0.8,
          flow.linexp(0.25, 4, 0.1, 2)
        ), 
        gate, 
        doneAction: 2
      );
      
      // Apply gentle limiting to prevent extreme values
      sig = Limiter.ar(sig, 0.95);
      
      // Output with stereo spread based on reflection
      Out.ar(out, Pan2.ar(sig * env * amp, reflection * 2 - 1));
    }).add;
    
    SynthDef(\pulse_response, {
      arg out=0, strength=0.5, target=1;
      var sig, env, freq;
      
      // Generate a short pulse that changes character based on target parameter
      env = EnvGen.kr(Env.perc(0.001, 0.1 + (target/10)), doneAction: 2);
      freq = (target * 100) + 300;
      
      sig = SinOsc.ar(freq, 0, strength * env);
      
      Out.ar(out, sig ! 2);
    }).add;
    
    SynthDef(\fx_processor, {
      arg in, out=0, mix=0.5;
      var sig, wet;
      
      sig = In.ar(in, 2);
      
      // Simple reverb effect
      wet = FreeVerb.ar(sig, 0.5, 0.8, 0.2);
      
      // Mix dry and wet signals
      sig = (sig * (1-mix)) + (wet * mix);
      
      // Apply gentle limiting to prevent extreme values
      sig = Limiter.ar(sig, 0.95);
      
      Out.ar(out, sig);
    }).add;
    
    // Wait for SynthDefs to be built
    context.server.sync;
    
    // Create FFT buffer for analysis
    fftBuf = Buffer.alloc(context.server, 1024);
    
    // Create main synth voice
    synths[\voice] = Synth.new(\fm_voice, [
      \out, bus[\fx].index,
      \amp, 0.5,
      \harmonic, params[\harmonic],
      \orbital, params[\orbital],
      \symmetry, params[\symmetry],
      \resonance, params[\resonance],
      \radiance, params[\radiance],
      \flow, params[\flow],
      \propagation, params[\propagation],
      \reflection, params[\reflection]
    ], groups[\main]);
    
    // Create FX processor
    synths[\fx] = Synth.new(\fx_processor, [
      \in, bus[\fx].index,
      \out, context.out_b.index,
      \mix, 0.3
    ], groups[\fx]);
    
    // Command to control FM parameters
    this.addCommand("controlParam", "if", { arg msg;
      var index = msg[1].asInteger;
      var value = msg[2].asFloat;
      var param;
      
      if(index.inclusivelyBetween(1, 8).not, {
        "Invalid parameter index: %".format(index).warn;
        ^this;
      });
      
      // Get parameter name based on index
      param = switch(index,
        1, { \harmonic },
        2, { \orbital },
        3, { \symmetry },
        4, { \resonance },
        5, { \radiance },
        6, { \flow },
        7, { \propagation },
        8, { \reflection }
      );
      
      // Clamp value to valid range
      value = clampValue.(param, value);
      
      // Update parameter value
      params[param] = value;
      
      // If synth exists, update it
      if(synths[\voice].notNil, {
        synths[\voice].set(param, value);
      });
      
      // If drone synth exists, update it too
      if(synths[\drone].notNil, {
        synths[\drone].set(param, value);
      });
    });
    
    // Command to trigger a pulse response
    this.addCommand("pulse", "if", { arg msg;
      var target = msg[1].asInteger;
      var strength = msg[2].asFloat;
      
      if(target.inclusivelyBetween(1, 8).not, {
        "Invalid pulse target: %".format(target).warn;
        ^this;
      });
      
      strength = strength.clip(0, 1);
      
      Synth.new(\pulse_response, [
        \out, context.out_b.index,
        \strength, strength,
        \target, target
      ], groups[\fx], \addToTail);
    });
    
    // Command to freeze/unfreeze the synth
    this.addCommand("freeze", "i", { arg msg;
      var state = msg[1].asInteger;
      
      if(state != 0 && state != 1, {
        "Invalid freeze state: %, must be 0 or 1".format(state).warn;
        ^this;
      });
      
      params[\freeze] = state;
      
      if(state == 1, {
        // Freeze the synth by setting gate to 0 but not freeing it
        if(synths[\voice].notNil, {
          synths[\voice].set(\gate, 0);
        });
        
        // Create a new sustained drone
        synths[\drone] = Synth.new(\fm_voice, [
          \out, bus[\fx].index,
          \amp, 0.3,
          \gate, 1,
          \harmonic, params[\harmonic],
          \orbital, params[\orbital] * 0.5,  // Slower for drone
          \symmetry, params[\symmetry],
          \resonance, params[\resonance] * 0.8,  // Less resonant for drone
          \radiance, params[\radiance] * 0.5,    // Less modulation for drone
          \flow, params[\flow] * 2,              // Slower envelope for drone
          \propagation, params[\propagation],
          \reflection, params[\reflection]
        ], groups[\main]);
      }, {
        // Unfreeze by releasing drone and creating new main voice
        if(synths[\drone].notNil, {
          synths[\drone].set(\gate, 0);
          synths[\drone] = nil;
        });
        
        synths[\voice] = Synth.new(\fm_voice, [
          \out, bus[\fx].index,
          \amp, 0.5,
          \harmonic, params[\harmonic],
          \orbital, params[\orbital],
          \symmetry, params[\symmetry],
          \resonance, params[\resonance],
          \radiance, params[\radiance],
          \flow, params[\flow],
          \propagation, params[\propagation],
          \reflection, params[\reflection]
        ], groups[\main]);
      });
    });
    
    // Command to reset parameters to default
    this.addCommand("reset", "", { 
      params[\harmonic] = 60;
      params[\orbital] = 1;
      params[\symmetry] = 0.5;
      params[\resonance] = 0.3;
      params[\radiance] = 0.5;
      params[\flow] = 1;
      params[\propagation] = 0.4;
      params[\reflection] = 0.3;
      
      // Update synth if it exists
      if(synths[\voice].notNil, {
        synths[\voice].set(
          \harmonic, params[\harmonic],
          \orbital, params[\orbital],
          \symmetry, params[\symmetry],
          \resonance, params[\resonance],
          \radiance, params[\radiance],
          \flow, params[\flow],
          \propagation, params[\propagation],
          \reflection, params[\reflection]
        );
      });
      
      // Update drone synth if it exists
      if(synths[\drone].notNil, {
        synths[\drone].set(
          \harmonic, params[\harmonic],
          \orbital, params[\orbital] * 0.5,
          \symmetry, params[\symmetry],
          \resonance, params[\resonance] * 0.8,
          \radiance, params[\radiance] * 0.5,
          \flow, params[\flow] * 2,
          \propagation, params[\propagation],
          \reflection, params[\reflection]
        );
      });
    });
    
    // SynthDef for spectral analysis
    SynthDef(\spectral_analyzer, {
      arg in, out, fftbuf;
      var sig, chain, centroid;
      
      sig = Mix.ar(In.ar(in, 2));
      chain = FFT(fftbuf, sig);
      centroid = SpecCentroid.kr(chain);
      
      // Send centroid value to a control bus
      Out.kr(out, centroid.explin(20, 20000, 0, 1));
    }).add;
    
    // Create analysis synth and control bus
    bus[\analysis] = Bus.control(context.server, 1);
    context.server.sync;
    
    synths[\analyzer] = Synth.new(\spectral_analyzer, [
      \in, bus[\fx].index,
      \out, bus[\analysis].index,
      \fftbuf, fftBuf
    ], groups[\fx], \addAfter);
    
    // Register polling functions for analysis data
    this.addPoll("spectral_centroid", {
      var value = 0;
      if(bus[\analysis].notNil, {
        value = bus[\analysis].getSynchronous;
      });
      value;
    });
    
    this.addPoll("amplitude", {
      var value = 0;
      if(bus[\fx].notNil, {
        // This is an approximation - a proper implementation would use amplitude analysis
        value = bus[\fx].getSynchronous.abs.mean;
      });
      value;
    });
  }
  
  free {
    // Free FFT buffer
    if(fftBuf.notNil, { fftBuf.free; });
    
    // Free all synths and busses with proper error handling
    synths.keysValuesDo({ arg key, synth; 
      if(synth.notNil, { synth.free; });
    });
    
    bus.keysValuesDo({ arg key, b; 
      if(b.notNil, { b.free; });
    });
    
    groups.keysValuesDo({ arg key, group; 
      if(group.notNil, { group.free; });
    });
    
    synths = nil;
    params = nil;
    bus = nil;
    groups = nil;
    operators = nil;
    fftBuf = nil;
  }
}
