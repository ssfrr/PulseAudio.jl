PulseAudio.jl
=============

TODO: Add Badges

This is a Julia package to record and play audio using the PulseAudio daemon common on Linux systems. This was originally part of @dancasimiro's WAV.jl package but has been split out and adapted to the JuliaAudio ecosystem.

Note that calling `read` and `write` on a `PulseAudioSource` or `PulseAudioSink` (respectively) will block the whole Julia runtime, not just the current Task.

Getting Started
---------------

PulseAudio.jl supports the [SampledSignals.jl](https://github.com/JuliaAudio/SampledSignals.jl) API, and provides readable and writable streams. Simply create a stream with the `PulseAudioSink` and `PulseAudioSource` constructors. These streams will accept regular `Array`s with each channel as a column, or you can use SampledSignals' `SampleBuf` values to take advantage of automatic sample-rate element type conversions.

Examples
--------

### Hear a test tone:

```julia
sig = sin.(2pi*330*linspace(0, 0.5, 0.5*48000)) * 0.2;
sink = PulseAudioSink()
write(sink, sig)
```

### Play a file:

```julia
buf = load("somefile.wav")
sink = PulseAudioSink()
# if the samplerates don't match the data will be transparently resampled
write(sink, buf)
```

### Listen to the same file downsampled

```julia
buf = load("somefile.wav")
sink = PulseAudioSink(name="Downsampled", description="8kHz", samplerate=8000)
write(sink, buf)
```
