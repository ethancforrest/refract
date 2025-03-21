// Engine_Refract.sc
Engine_Refract : CroneEngine {
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    SynthDef(\simple, {
      arg out=0, freq=440, amp=0.5;
      var sig = SinOsc.ar(freq) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    this.addCommand("controlParam", "if", { arg msg;
      var freq = msg[2].asFloat;
      Synth(\simple, [\out, context.out_b.index, \freq, freq]);
    });
    
    this.addCommand("pulse", "if", {});
    this.addCommand("freeze", "i", {});
    this.addCommand("reset", "", {});
  }

  free {}
}
