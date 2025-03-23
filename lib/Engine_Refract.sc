// Engine_Refract.sc
// Simplified version that will work reliably

Engine_Refract : CroneEngine {
  var <synth, <params;
  
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }
  
  alloc {
    // Initialize parameters
    params = Dictionary.newFrom([
      \harmonic, 60,      // MIDI note
      \orbital, 1,        // Beats
      \symmetry, 0.5,     // Normalized
      \resonance, 0.3,    // Normalized
      \radiance, 0.5,     // Normalized
      \flow, 1,           // Beats
      \propagation, 0.4,  // Normalized
      \reflection, 0.3    // Normalized
    ]);
    
    // Create a simple but stable FM SynthDef
    SynthDef(\fm_voice, {
      arg out=0, amp=0.3, gate=1, 
          harmonic=60, orbital=1, symmetry=0.5, resonance=0.3,
          radiance=0.5, flow=1, propagation=0.4, reflection=0.3;
      
      var sig, env;
      var carrier_freq, modulator_freq, mod_index;
      
      // Convert MIDI note to Hz
      carrier_freq = harmonic.midicps;
      modulator_freq = carrier_freq * orbital.linexp(0.25, 4, 0.5, 2);
      mod_index = radiance * 5 * symmetry;
      
      // Simple FM synthesis
      sig = SinOsc.ar(
        carrier_freq + (SinOsc.ar(modulator_freq) * mod_index * carrier_freq),
        0, 
        0.5
      );
      
      // Apply filter based on resonance
      sig = RLPF.ar(sig, carrier_freq * resonance.linexp(0, 1, 1, 8) * (1 + (SinOsc.kr(propagation * 5) * 0.5)), 0.5);
      
      // Apply envelope
      env = EnvGen.kr(
        Env.adsr(
          flow.linexp(0.25, 4, 0.01, 2),
          flow.linexp(0.25, 4, 0.05, 2),
          0.7,
          flow.linexp(0.25, 4, 0.05, 2)
        ), 
        gate, 
        doneAction: 2
      );
      
      // Pan and output
      sig = Pan2.ar(sig * env * amp, reflection * 2 - 1);
      Out.ar(out, sig);
    }).add;
    
    // Wait for SynthDef to be compiled
    context.server.sync;
    
    // Create synth
    synth = Synth.new(\fm_voice, [
      \out, context.out_b.index,
      \amp, 0.3,
      \harmonic, params[\harmonic],
      \orbital, params[\orbital],
      \symmetry, params[\symmetry],
      \resonance, params[\resonance],
      \radiance, params[\radiance],
      \flow, params[\flow],
      \propagation, params[\propagation],
      \reflection, params[\reflection]
    ], context.xg);
    
    // Add commands
    this.addCommand("controlParam", "if", { arg msg;
      var index = msg[1].asInteger;
      var value = msg[2].asFloat;
      var param;
      
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
      
      if(param.notNil, {
        params[param] = value;
        synth.set(param, value);
      });
    });
    
    this.addCommand("freeze", "i", { arg msg;
      var state = msg[1].asInteger;
      if(state == 1, {
        synth.set(\gate, 0);
        synth = Synth.new(\fm_voice, [
          \out, context.out_b.index,
          \amp, 0.2,
          \gate, 1,
          \harmonic, params[\harmonic],
          \orbital, params[\orbital] * 0.5,
          \symmetry, params[\symmetry],
          \resonance, params[\resonance] * 0.8,
          \radiance, params[\radiance] * 0.5,
          \flow, params[\flow] * 2,
          \propagation, params[\propagation],
          \reflection, params[\reflection]
        ], context.xg);
      }, {
        synth.set(\gate, 0);
        synth = Synth.new(\fm_voice, [
          \out, context.out_b.index,
          \amp, 0.3,
          \harmonic, params[\harmonic],
          \orbital, params[\orbital],
          \symmetry, params[\symmetry],
          \resonance, params[\resonance],
          \radiance, params[\radiance],
          \flow, params[\flow],
          \propagation, params[\propagation],
          \reflection, params[\reflection]
        ], context.xg);
      });
    });
    
    this.addCommand("reset", "", { 
      params[\harmonic] = 60;
      params[\orbital] = 1;
      params[\symmetry] = 0.5;
      params[\resonance] = 0.3;
      params[\radiance] = 0.5;
      params[\flow] = 1;
      params[\propagation] = 0.4;
      params[\reflection] = 0.3;
      
      synth.set(
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
    
    this.addCommand("pulse", "f", { arg msg;
      var strength = msg[1].asFloat;
      Synth.new(\fm_voice, [
        \out, context.out_b.index,
        \amp, strength * 0.3,
        \gate, 0,
        \harmonic, 60,
        \flow, 0.25
      ], context.xg);
    });
  }
  
  free {
    if(synth.notNil, { synth.free; });
  }
}