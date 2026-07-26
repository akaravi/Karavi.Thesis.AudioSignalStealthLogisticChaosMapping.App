using AudioStegano.Core.Audio;

namespace AudioStegano.Core.Stego;

/// <summary>Result of <see cref="EmbedIntegrity.Verify"/>.</summary>
public sealed class EmbedIntegrityResult
{
    public bool Ok { get; }
    public string? FailureReason { get; }

    private EmbedIntegrityResult(bool ok, string? failureReason)
    {
        Ok = ok;
        FailureReason = failureReason;
    }

    public static EmbedIntegrityResult Success() => new(true, null);
    public static EmbedIntegrityResult Fail(string reason) => new(false, reason);
}

/// <summary>Immediate round-trip / cover-fidelity checks after LSB embed.</summary>
public static class EmbedIntegrity
{
    public static EmbedIntegrityResult Verify(
        WavFile cover,
        WavFile stego,
        byte[] originalBits,
        byte[] extractedBits,
        double berPercent,
        double r,
        double x0,
        MessageBlockAutoencoder autoencoder)
    {
        if (berPercent != 0.0)
            return EmbedIntegrityResult.Fail($"BER is {berPercent}% (must be 0 after embed)");

        if (extractedBits.Length != originalBits.Length)
            return EmbedIntegrityResult.Fail("Extracted bit length does not match embedded bits");

        for (var i = 0; i < originalBits.Length; i++)
        {
            if ((extractedBits[i] & 1) != (originalBits[i] & 1))
                return EmbedIntegrityResult.Fail($"Bit mismatch at index {i}");
        }

        var coverMono = StegoAudioHelper.ToMatlabInt16(cover.ToMono().Samples);
        var stegoMono = stego.ToMono().Samples;
        if (coverMono.Length != stegoMono.Length)
            return EmbedIntegrityResult.Fail("Stego length differs from cover (mono)");

        var positions = LogisticPositions.Compute(originalBits.Length, coverMono.Length, x0, r);
        var posSet = new HashSet<int>(positions);
        for (var i = 0; i < coverMono.Length; i++)
        {
            if (posSet.Contains(i))
            {
                if ((coverMono[i] & ~1) != (stegoMono[i] & ~1))
                    return EmbedIntegrityResult.Fail($"Non-LSB sample changed at index {i}");
            }
            else if (coverMono[i] != stegoMono[i])
            {
                return EmbedIntegrityResult.Fail($"Cover sample altered outside embed positions at {i}");
            }
        }

        byte[] afterWav;
        try
        {
            var reloaded = WavFile.Decode(stego.Encode());
            var extract = new ExtractMessage(r, x0, autoencoder);
            var bits = extract.RunBits(reloaded, originalBits.Length);
            if (bits is null)
                return EmbedIntegrityResult.Fail("Extract after WAV encode/decode returned null");
            afterWav = bits;
        }
        catch (Exception ex)
        {
            return EmbedIntegrityResult.Fail($"WAV round-trip extract failed: {ex.Message}");
        }

        for (var i = 0; i < originalBits.Length; i++)
        {
            if ((afterWav[i] & 1) != (originalBits[i] & 1))
                return EmbedIntegrityResult.Fail("Payload bits corrupted after WAV encode/decode");
        }

        var expected = PayloadEnvelope.UnpackBits(originalBits);
        var recovered = PayloadEnvelope.UnpackBits(afterWav);
        if (expected.Type != recovered.Type || expected.IsLegacy != recovered.IsLegacy)
            return EmbedIntegrityResult.Fail("Recovered payload type does not match original");

        if (expected.Text is not null && expected.Text != recovered.Text)
            return EmbedIntegrityResult.Fail($"Recovered text does not match original (got: {recovered.Text})");

        if (expected.Audio is not null)
        {
            var a = expected.Audio;
            var b = recovered.Audio;
            if (b is null || a.SampleRate != b.SampleRate || a.Samples.Length != b.Samples.Length)
                return EmbedIntegrityResult.Fail("Recovered audio meta does not match original payload");
            for (var i = 0; i < a.Samples.Length; i++)
            {
                if (a.Samples[i] != b.Samples[i])
                    return EmbedIntegrityResult.Fail($"Recovered audio sample mismatch at {i}");
            }
        }

        return EmbedIntegrityResult.Success();
    }

    public static void AssertOk(EmbedIntegrityResult result)
    {
        if (!result.Ok)
            throw new InvalidOperationException(result.FailureReason ?? "Embed integrity check failed");
    }
}
