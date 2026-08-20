import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/video.dart';
import '../../data/repositories/video_repository.dart';
import '../../providers.dart';
import '../../widgets/status_views.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoId;
  final String title;
  const VideoPlayerScreen({super.key, required this.videoId, required this.title});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  StreamTokenResponse? _tokenResponse;
  bool _initialized = false;
  String? _error;
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final r = await ref.read(videoRepositoryProvider).stream(widget.videoId);
      _tokenResponse = r;
      if (r.streamUrl == null) {
        setState(() {
          _error = 'لا يوجد رابط بث حالياً لهذا الفيديو.';
        });
        return;
      }
      _controller = VideoPlayerController.networkUrl(Uri.parse(r.streamUrl!));
      await _controller!.initialize();
      await _controller!.setLooping(false);
      if (!mounted) return;
      setState(() => _initialized = true);
      _controller!.addListener(_onTick);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'تعذّر تشغيل الفيديو. حاول لاحقاً.');
    }
  }

  Duration _lastMarkDuration = Duration.zero;
  void _onTick() async {
    final c = _controller;
    if (c == null) return;
    final pos = c.value.position;
    if (pos.inSeconds - _lastMarkDuration.inSeconds >= 30) {
      _lastMarkDuration = pos;
      try {
        await ref.read(videoRepositoryProvider).markViewed(widget.videoId);
      } catch (_) {/* ignore */}
    }
  }

  Future<void> _markViewedNow() async {
    if (_marking) return;
    setState(() => _marking = true);
    try {
      final r = await ref.read(videoRepositoryProvider).markViewed(widget.videoId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل المشاهدة: ${r.viewCount}/${r.maxViews}'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _requestDownload() async {
    try {
      final r = await ref.read(videoRepositoryProvider).downloadToken(widget.videoId);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => _DownloadSheet(token: r),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Center(
                child: ErrorView(
                  title: 'لا يمكن تشغيل الفيديو',
                  message: _error,
                  onRetry: () {
                    setState(() {
                      _error = null;
                    });
                    _bootstrap();
                  },
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: _initialized && _controller != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              ),
                              _WatermarkOverlay(watermark: _tokenResponse!.watermark),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: _ColdOverlay(
                                  controller: _controller!,
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: _PlayerBar(controller: _controller!),
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                if (_initialized && _tokenResponse != null)
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _markViewedNow,
                          icon: Icon(Icons.check_circle_outline,
                              color: _marking ? Colors.grey : AppColors.accent),
                          tooltip: 'تأكيد المشاهدة',
                        ),
                        IconButton(
                          onPressed: _requestDownload,
                          icon: const Icon(Icons.cloud_download_outlined,
                              color: Colors.white),
                          tooltip: 'تنزيل للمشاهدة أوفلاين',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ColdOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  const _ColdOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.isPlaying) {
          return const SizedBox.shrink();
        }
        return InkWell(
          onTap: () => controller.play(),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient.withOpacity(0.9),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
          ),
        );
      },
    );
  }
}

class _WatermarkOverlay extends StatelessWidget {
  final WatermarkInfo watermark;
  const _WatermarkOverlay({required this.watermark});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: -0.35,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              watermark.display,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final VideoPlayerController controller;
  const _PlayerBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    return VideoProgressIndicator(
      controller,
      allowScrubbing: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      colors: const VideoProgressColors(
        playedColor: AppColors.accent,
        bufferedColor: Colors.white24,
        backgroundColor: Colors.white10,
      ),
    );
  }
}

class _DownloadSheet extends StatelessWidget {
  final DownloadToken token;
  const _DownloadSheet({required this.token});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'توكين التنزيل',
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'صالح لمدة ${token.downloadDays} أيام، ينتهي في '
              '${token.expiresAt.toLocal()}',
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: SelectableText(
                token.token,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('موافق'),
            ),
          ],
        ),
      ),
    );
  }
}
