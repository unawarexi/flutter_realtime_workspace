import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen looping muted video background.
///
/// Tries to load `assets/videos/onboarding_bg.mp4`. If the asset is absent
/// or fails to initialise, falls back to [_AnimatedGradientFallback].
///
/// Drop `onboarding_bg.mp4` into `assets/videos/` to activate the video.
class OnboardingVideoBg extends StatefulWidget {
  final bool isDarkMode;
  final Color accentColor;

  const OnboardingVideoBg({
    super.key,
    required this.isDarkMode,
    required this.accentColor,
  });

  @override
  State<OnboardingVideoBg> createState() => _OnboardingVideoBgState();
}

class _OnboardingVideoBgState extends State<OnboardingVideoBg> {
  VideoPlayerController? _ctrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.asset(
        'assets/videos/onboarding_bg.mp4',
      );
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      ctrl
        ..setVolume(0)
        ..setLooping(true)
        ..play();
      setState(() {
        _ctrl = ctrl;
        _videoReady = true;
      });
    } catch (_) {
      // Asset not found or unreadable — use animated gradient fallback.
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoReady && _ctrl != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _ctrl!.value.size.width,
            height: _ctrl!.value.size.height,
            child: VideoPlayer(_ctrl!),
          ),
        ),
      );
    }
    return _AnimatedGradientFallback(
      isDarkMode: widget.isDarkMode,
      accentColor: widget.accentColor,
    );
  }
}

// ─── Animated gradient fallback (used when no video is present) ──────────────

class _AnimatedGradientFallback extends StatefulWidget {
  final bool isDarkMode;
  final Color accentColor;

  const _AnimatedGradientFallback({
    required this.isDarkMode,
    required this.accentColor,
  });

  @override
  State<_AnimatedGradientFallback> createState() =>
      _AnimatedGradientFallbackState();
}

class _AnimatedGradientFallbackState extends State<_AnimatedGradientFallback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final accent = widget.accentColor;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.lerp(
                const Alignment(-1, -1),
                const Alignment(1, 0.5),
                t,
              )!,
              end: Alignment.lerp(
                const Alignment(1, 1),
                const Alignment(-0.5, -1),
                t,
              )!,
              colors: isDark
                  ? [
                      Color.lerp(
                        const Color(0xFF0F172A),
                        const Color(0xFF1E1B4B),
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFF0A0E1A),
                        accent.withValues(alpha: 0.28),
                        1 - t,
                      )!,
                      const Color(0xFF0C1220),
                    ]
                  : [
                      Color.lerp(
                        const Color(0xFFEFF6FF),
                        const Color(0xFFE0E7FF),
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFFF0F9FF),
                        accent.withValues(alpha: 0.14),
                        1 - t,
                      )!,
                      const Color(0xFFF8FAFC),
                    ],
            ),
          ),
        );
      },
    );
  }
}
