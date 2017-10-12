## -*-Julia-*-
## Test suite for Julia's PulseAudio module
using PulseAudio
using Base.Test

@testset "basic sink construction" begin
    sink = PulseAudioSink()
    # test defaults
    @test nchannels(sink) == 2
    @test samplerate(sink) == 48000
    @test eltype(sink) == Float32
    close(sink)
end
