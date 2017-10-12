# -*- mode: julia; -*-
module PulseAudio
using Reexport
# reexport so users automatically get SampledSignals API
@reexport using SampledSignals

export PulseAudioSink

# typedef enum pa_sample_format
const PA_SAMPLE_U8        =  0 # Unsigned 8 Bit PCM
const PA_SAMPLE_ALAW      =  1 # 8 Bit a-Law
const PA_SAMPLE_ULAW      =  2 # 8 Bit mu-Law
const PA_SAMPLE_S16LE     =  3 # Signed 16 Bit PCM, little endian (PC)
const PA_SAMPLE_S16BE     =  4 # Signed 16 Bit PCM, big endian
const PA_SAMPLE_FLOAT32LE =  5 # 32 Bit IEEE floating point, little endian (PC), range -1.0 to 1.0
const PA_SAMPLE_FLOAT32BE =  6 # 32 Bit IEEE floating point, big endian, range -1.0 to 1.0
const PA_SAMPLE_S32LE     =  7 # Signed 32 Bit PCM, little endian (PC)
const PA_SAMPLE_S32BE     =  8 # Signed 32 Bit PCM, big endian
const PA_SAMPLE_S24LE     =  9 # Signed 24 Bit PCM packed, little endian (PC). \since 0.9.15
const PA_SAMPLE_S24BE     = 10 # Signed 24 Bit PCM packed, big endian. \since 0.9.15
const PA_SAMPLE_S24_32LE  = 11 # Signed 24 Bit PCM in LSB of 32 Bit words, little endian (PC). \since 0.9.15
const PA_SAMPLE_S24_32BE  = 12 # Signed 24 Bit PCM in LSB of 32 Bit words, big endian. \since 0.9.15

immutable pa_sample_spec
    format::Int32
    rate::UInt32
    channels::UInt8
end

immutable pa_channel_map
    channels::UInt8

    # map data (max 32 channels)
    map0::Cint
    map1::Cint
    map2::Cint
    map3::Cint
    map4::Cint
    map5::Cint
    map6::Cint
    map7::Cint
    map8::Cint
    map9::Cint
    map10::Cint
    map11::Cint
    map12::Cint
    map13::Cint
    map14::Cint
    map15::Cint
    map16::Cint
    map17::Cint
    map18::Cint
    map19::Cint
    map20::Cint
    map21::Cint
    map22::Cint
    map23::Cint
    map24::Cint
    map25::Cint
    map26::Cint
    map27::Cint
    map28::Cint
    map29::Cint
    map30::Cint
    map31::Cint

    pa_channel_map() = new(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
end

immutable pa_buffer_attr
    maxlength::UInt32
    tlength::UInt32
    prebuf::UInt32
    minreq::UInt32
    fragsize::UInt32
end

const pa_simple = Ptr{Void}
const LibPulseSimple = "libpulse-simple"
const PA_STREAM_PLAYBACK = 1
const PA_CHANNEL_MAP_AIFF = 0
const PA_CHANNEL_MAP_DEFAULT = PA_CHANNEL_MAP_AIFF

mutable struct PulseAudioSink{T} <: SampleSink
    pulsesink::pa_simple
    spec::pa_sample_spec

    function PulseAudioSink{T}() where T
        # for now just set defaults
        fs = 48000
        ch = 2
        eltype = PA_SAMPLE_FLOAT32LE

        spec = pa_sample_spec(eltype, fs, ch)
        s = ccall((:pa_simple_new, LibPulseSimple),
                  pa_simple,
                  (Cstring, Cstring, Cint, Cstring, Cstring,
                   Ptr{pa_sample_spec}, Ptr{pa_channel_map}, Ptr{pa_buffer_attr},
                   Ptr{Cint}),
                  C_NULL, # Use the default server
                  "Julia",  # Application name
                  PA_STREAM_PLAYBACK,
                  C_NULL, # Use the default device
                  "PulseAudioSink", # description of stream
                  Ref(spec),
                  C_NULL, # Use default channel map
                  C_NULL, # Use default buffering attributes
                  C_NULL) # Ignore error code
        if s == C_NULL
            error("pa_simple_new failed")
        end

        instance = new(s, spec)
        finalizer(instance, close)

        instance
    end
end

PulseAudioSink() = PulseAudioSink{Float32}()

SampledSignals.nchannels(sink::PulseAudioSink) = Int(sink.spec.channels)
SampledSignals.samplerate(sink::PulseAudioSink) = Float64(sink.spec.rate)
Base.eltype(sink::PulseAudioSink{T}) where T = T

function Base.close(sink::PulseAudioSink)
    if sink.pulsesink != C_NULL
        ccall((:pa_simple_free, LibPulseSimple), Void, (pa_simple,), sink.pulsesink)
        sink.pulsesink = C_NULL
    end

    nothing
end

function SampledSignals.unsafe_write(sink::PulseAudioSink, buf::Array,
                                     frameoffset, framecount)
    # pulseaudio wants interleaved data, so swap axes
    data = buf[(1:framecount) + frameoffset, :]'
    write_ret = ccall((:pa_simple_write, LibPulseSimple),
                      Cint,
                      (pa_simple, Ptr{Void}, Csize_t, Ptr{Cint}),
                      sink.pulsesink, data, sizeof(data), C_NULL)
    if write_ret != 0
        error("pa_simple_write failed with $write_ret")
    end

    # # wait for the audio to finish playing
    # drain_ret = ccall((:pa_simple_drain, LibPulseSimple),
    #                   Cint,
    #                   (pa_simple, Ptr{Cint}), sink.pulsesink, C_NULL)
    # if drain_ret != 0
    #     error("pa_simple_drain failed with $drain_ret")
    # end
    return framecount
end

end # module
