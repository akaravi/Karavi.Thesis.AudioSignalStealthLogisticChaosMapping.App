using AudioStegano.Core.Audio;

namespace AudioStegano.Desktop.Services;

/// <summary>
/// One isolated engine per UI play surface — method-based exclusivity.
/// </summary>
public enum PlaybackSessionId
{
    EmbedCover,
    EmbedStego,
    EmbedPayloadOriginal,
    EmbedPayloadRecovered,
    ExtractCover,
    ExtractPayload,
}

/// <summary>
/// Each session owns its <see cref="AudioPlaybackService"/>; Play pauses others first.
/// </summary>
public sealed class PlaybackHub
{
    public static PlaybackHub Instance { get; } = new();

    private readonly Dictionary<PlaybackSessionId, AudioPlaybackService> _engines = new();

    public static readonly PlaybackSessionId[] EmbedSessions =
    [
        PlaybackSessionId.EmbedCover,
        PlaybackSessionId.EmbedStego,
        PlaybackSessionId.EmbedPayloadOriginal,
        PlaybackSessionId.EmbedPayloadRecovered,
    ];

    public static readonly PlaybackSessionId[] ExtractSessions =
    [
        PlaybackSessionId.ExtractCover,
        PlaybackSessionId.ExtractPayload,
    ];

    public static readonly PlaybackSessionId[] AbSessions =
    [
        PlaybackSessionId.EmbedCover,
        PlaybackSessionId.EmbedStego,
    ];

    private PlaybackHub()
    {
    }

    public AudioPlaybackService Engine(PlaybackSessionId id)
    {
        if (!_engines.TryGetValue(id, out var engine))
        {
            engine = new AudioPlaybackService();
            _engines[id] = engine;
        }
        return engine;
    }

    public bool IsPlaying(PlaybackSessionId id) =>
        _engines.TryGetValue(id, out var e) && e.IsPlaying;

    public bool HasSource(PlaybackSessionId id) =>
        _engines.TryGetValue(id, out var e) && e.HasSource;

    public bool IsPaused(PlaybackSessionId id) =>
        _engines.TryGetValue(id, out var e) && e.IsPaused;

    /// <summary>Play [wav] on [id]; pause every other session first.</summary>
    public void Play(PlaybackSessionId id, WavFile wav)
    {
        PauseOthers(id);
        Engine(id).Play(wav);
    }

    /// <summary>
    /// Toggle: playing → pause; paused with source → resume; else load+play.
    /// </summary>
    public void PlayOrToggle(PlaybackSessionId id, WavFile wav)
    {
        var e = Engine(id);
        if (e.IsPlaying)
        {
            e.Pause();
            return;
        }
        if (e.HasSource && e.IsPaused)
        {
            PauseOthers(id);
            e.Resume();
            return;
        }
        Play(id, wav);
    }

    /// <summary>Do not restart when already playing this session.</summary>
    public void PlayIfNotPlaying(PlaybackSessionId id, WavFile wav)
    {
        var e = Engine(id);
        if (e.IsPlaying) return;
        if (e.HasSource && e.IsPaused)
        {
            PauseOthers(id);
            e.Resume();
            return;
        }
        Play(id, wav);
    }

    public void Pause(PlaybackSessionId id)
    {
        if (_engines.TryGetValue(id, out var e))
            e.Pause();
    }

    public void Stop(PlaybackSessionId id)
    {
        if (_engines.TryGetValue(id, out var e))
            e.Stop();
    }

    public void PauseOthers(PlaybackSessionId keep)
    {
        foreach (var (sessionId, engine) in _engines)
        {
            if (sessionId == keep) continue;
            if (engine.IsPlaying)
                engine.Pause();
        }
    }

    public void StopSessions(IEnumerable<PlaybackSessionId> ids)
    {
        foreach (var id in ids)
            Stop(id);
    }

    public void StopAll() => StopSessions(Enum.GetValues<PlaybackSessionId>());

    public void PauseAbSessions()
    {
        foreach (var id in AbSessions)
            Pause(id);
    }

    public void StopAbSessions()
    {
        foreach (var id in AbSessions)
            Stop(id);
    }
}
