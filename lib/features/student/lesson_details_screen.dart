import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../data/models/student_stats.dart';
import '../../data/models/video.dart';
import '../../data/models/subject.dart';
import '../../providers.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/status_views.dart';

final lessonDetailsProvider =
    FutureProvider.family<LessonDetailsResponse, String>((ref, id) {
  return ref.read(videoRepositoryProvider).getVideoDetails(id);
});

class LessonDetailsScreen extends ConsumerStatefulWidget {
  final String videoId;
  final List<SubjectVideoItem>? playlist;
  final Duration? initialPosition;

  const LessonDetailsScreen({
    super.key,
    required this.videoId,
    this.playlist,
    this.initialPosition,
  });

  @override
  ConsumerState<LessonDetailsScreen> createState() =>
      _LessonDetailsScreenState();
}

enum PlayerType { native, youtube, web }

class _LessonDetailsScreenState extends ConsumerState<LessonDetailsScreen> {
  VideoPlayerController? _controller;
  YoutubePlayerController? _ytController;
  WebViewController? _webController;
  PlayerType _playerType = PlayerType.native;
  bool _initialized = false;
  bool _isFullScreen = false;
  bool _isLocal = false;
  double _downloadProgress = -1;
  Duration _lastMarkDuration = Duration.zero;
  StreamSubscription? _downloadSub;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _enableSecureMode();
    _setupScreenRecordingListener();
    _checkConnectivity();
    _listenToDownloads();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = result.contains(ConnectivityResult.none);
    });
    
    // Listen for changes
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOffline = results.contains(ConnectivityResult.none);
        });
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _listenToDownloads() {
    // Set initial progress if already downloading
    final manager = ref.read(downloadManagerProvider);
    final current = manager.getProgress(widget.videoId);
    if (current != null) {
      _downloadProgress = current;
    }

    _downloadSub = manager.progressStream.listen((event) {
      if (event.containsKey(widget.videoId) && mounted) {
        setState(() {
          _downloadProgress = event[widget.videoId]!;
        });
      }
    });
  }

  void _setupScreenRecordingListener() {
    ScreenProtector.addListener(() {
      _handleScreenRecordingDetected();
    }, (isRecording) {
      if (isRecording == true) {
        _handleScreenRecordingDetected();
      }
    });
  }

  void _handleScreenRecordingDetected() {
    if (!mounted) return;
    
    // Pause native video
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
    }
    
    // Pause YouTube video
    if (_ytController != null && _ytController!.value.isPlaying) {
      _ytController!.pause();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إيقاف التشغيل. تسجيل الشاشة غير مسموح به.', 
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enableSecureMode() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (_) {}
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    ScreenProtector.removeListener();
    _disableSecureMode();
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _ytController?.dispose();

    // Reset orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  Future<void> _disableSecureMode() async {
    try {
      await ScreenProtector.preventScreenshotOff();
    } catch (_) {}
  }

  Future<void> _initVideo(String? streamUrl) async {
    if (_initialized) return;

    final download = await ref.read(offlineStorageProvider).getDownload(widget.videoId);
    final localPath = await ref.read(videoRepositoryProvider).getLocalPath(widget.videoId);
    StreamTokenResponse? streamInfo;
    
    int startPos = widget.initialPosition?.inSeconds ?? download?.lastPositionSec ?? 0;

    // Determine whether to play local or stream based on connectivity and availability
    bool useLocal = localPath != null && (_isOffline || download?.status == 2);
    // If online, prefer streaming as per requirements, unless explicitly playing from downloads
    if (!_isOffline && localPath != null) {
      // Logic: if we have internet, we CAN stream.
      // But prompt says "If offline copy exists Play local MP4 automatically"
      // This is slightly contradictory with "If internet available Stream from HLS".
      // Usually, "Play local automatically" means "if you have it, use it".
      useLocal = true; 
    }

    if (useLocal && localPath != null) {
      _isLocal = true;
      _playerType = PlayerType.native;
      _controller = VideoPlayerController.file(File(localPath));
    } else {
      _isLocal = false;
      // Fetch stream info if not local
      try {
        // Use future to avoid blocking, handle error if offline
        streamInfo = await ref.read(streamTokenProvider(widget.videoId).future);
      } catch (e) {
        debugPrint('Stream info fetch failed (likely offline): $e');
      }

      final url = streamInfo?.streamUrl ?? streamUrl;
      if (url != null) {
        String finalUrl = url;
        if (!finalUrl.startsWith('http')) {
          final baseUrl = AppConfig.apiBaseUrl.replaceFirst('/api', '');
          finalUrl = '$baseUrl${finalUrl.startsWith('/') ? '' : '/'}$finalUrl';
        }

        if (finalUrl.contains('youtube.com') || finalUrl.contains('youtu.be')) {
          _playerType = PlayerType.youtube;
          final videoId = YoutubePlayer.convertUrlToId(finalUrl);
          if (videoId != null) {
            _ytController = YoutubePlayerController(
              initialVideoId: videoId,
              flags: YoutubePlayerFlags(
                autoPlay: true,
                mute: false,
                startAt: startPos,
              ),
            );
          }
        } else if (_isDirectVideo(finalUrl)) {
          _playerType = PlayerType.native;
          _controller = VideoPlayerController.networkUrl(Uri.parse(finalUrl));
        } else {
          _playerType = PlayerType.web;
          _webController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0x00000000))
            ..loadRequest(Uri.parse(finalUrl));
        }
      }
    }

    if (_playerType == PlayerType.native && _controller != null) {
      try {
        await _controller!.initialize();
        if (startPos > 0) {
          await _controller!.seekTo(Duration(seconds: startPos));
        }
        await _controller!.play();
        _controller!.addListener(_onTick);
      } catch (e) {
        debugPrint('Video initialization error: $e');
        if (mounted) {
          setState(() {
            _initialized = true; // Mark as initialized so we stop showing loader
            // Note: We don't set a global error here to allow other parts of the screen to work
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تعذّر تشغيل الفيديو. قد يكون الملف تالفاً.')),
            );
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() => _initialized = true);
      // Notify server immediately that the student started this lesson
      ref.read(videoRepositoryProvider).markViewed(widget.videoId).then((_) {
        // Refresh dashboard data
        ref.invalidate(dashboardDataProvider);
        ref.invalidate(lastLessonProvider);
      }).catchError((_) {});

      // Local tracking: Save as last opened lesson immediately
      _saveProgress();
    }
  }

  bool _isDirectVideo(String url) {
    final path = url.toLowerCase();
    return path.contains('.mp4') ||
        path.contains('.m3u8') ||
        path.contains('.mov') ||
        path.contains('.avi') ||
        path.contains('.mkv');
  }

  String _resolveMuxDownloadUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('stream.mux.com')) return url;

    final segments = List<String>.from(uri.pathSegments);
    if (segments.isEmpty) return url;

    final last = segments.removeLast();
    String newLast;
    if (last.endsWith('.mp4')) {
      return url; // Already mp4
    } else if (last.endsWith('.m3u8')) {
      final playbackId = last.substring(0, last.length - '.m3u8'.length);
      newLast = '$playbackId/high.mp4';
    } else {
      newLast = '$last/high.mp4';
    }

    return uri.replace(path: '/${[...segments, newLast].join('/')}').toString();
  }

  void _onTick() async {
    final c = _controller;
    if (c == null) return;
    final pos = c.value.position;
    
    // Save locally on each tick for responsiveness
    _saveProgress();

    // Save to Offline DB if it's a download
    if (pos.inSeconds % 5 == 0) {
      ref.read(offlineStorageProvider).updatePosition(widget.videoId, pos.inSeconds);
    }

    if (pos.inSeconds - _lastMarkDuration.inSeconds >= 30) {
      _lastMarkDuration = pos;
      try {
        final r = await ref.read(videoRepositoryProvider).markViewed(widget.videoId);
        if (r.triggerQuiz != null && mounted) {
          _showQuiz(r.triggerQuiz!);
        }
      } catch (_) {/* ignore */}
    }
  }

  void _saveProgress() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    final details = ref.read(lessonDetailsProvider(widget.videoId)).valueOrNull;
    if (details == null) return;

    final pos = c.value.position;
    final total = c.value.duration;
    if (total.inSeconds == 0) return;

    final progressPercent = (pos.inSeconds / total.inSeconds * 100).toInt();
    final timeLeftMin = (total.inSeconds - pos.inSeconds) ~/ 60;

    final lastLesson = ContinueLearning(
      videoId: widget.videoId,
      videoTitle: details.video.title,
      subjectName: details.video.subHeader,
      unitName: details.video.unitName,
      lessonText: details.video.title,
      durationSec: details.video.durationSec,
      timeLeftMin: timeLeftMin,
      progressPercent: progressPercent,
    );

    await ref.read(cacheStorageProvider).saveLastLesson(lastLesson.toJson());
  }

  void _showQuiz(TriggerQuiz quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuizSheet(quiz: quiz),
    );
  }

  Future<void> _download() async {
    final download = await ref.read(offlineStorageProvider).getDownload(widget.videoId);
    
    if (download != null) {
      if (download.status == 2) {
        // Already downloaded, confirm delete
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف الدرس'),
            content: const Text('هل تريد حذف هذا الدرس من الجهاز؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(downloadManagerProvider).cancelDownload(widget.videoId);
          setState(() {
            _isLocal = false;
            _downloadProgress = -1;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الدرس من التحميلات')));
        }
      } else if (download.status == 1) {
        // Currently downloading, allow pause/cancel/resume
        final isPaused = download.status == 1 && _downloadProgress == -2; // We can use a special value for paused if we want, or check task status
        
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('استئناف التحميل'),
                  onTap: () => Navigator.pop(context, 'resume'),
                ),
                ListTile(
                  leading: const Icon(Icons.pause),
                  title: const Text('إيقاف مؤقت'),
                  onTap: () => Navigator.pop(context, 'pause'),
                ),
                ListTile(
                  leading: const Icon(Icons.close, color: AppColors.danger),
                  title: const Text('إلغاء التحميل'),
                  onTap: () => Navigator.pop(context, 'cancel'),
                ),
              ],
            ),
          ),
        );
        if (action == 'resume') {
          await ref.read(downloadManagerProvider).resumeDownload(widget.videoId);
        } else if (action == 'pause') {
          await ref.read(downloadManagerProvider).pauseDownload(widget.videoId);
        } else if (action == 'cancel') {
          await ref.read(downloadManagerProvider).cancelDownload(widget.videoId);
          setState(() => _downloadProgress = -1);
        }
      }
      return;
    }

    // Check if offline
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب الاتصال بالإنترنت لبدء التحميل')),
      );
      return;
    }

    final res = await ref.read(lessonDetailsProvider(widget.videoId).future);
    
    // Attempt to get stream info for the best possible URL
    StreamTokenResponse? streamInfo;
    try {
      streamInfo = await ref.read(streamTokenProvider(widget.videoId).future);
    } catch (_) {}

    String? url = streamInfo?.streamUrl ?? res.video.streamUrl;
    if (url == null) return;

    // Fetch download token
    String? downloadToken;
    try {
      final tokenData = await ref.read(videoRepositoryProvider).downloadToken(widget.videoId);
      downloadToken = tokenData.token;
    } catch (_) {}

    setState(() => _downloadProgress = 0);
    
    try {
      String finalUrl = url;
      if (!finalUrl.startsWith('http')) {
        final baseUrl = AppConfig.apiBaseUrl.replaceFirst('/api', '');
        finalUrl = '$baseUrl${finalUrl.startsWith('/') ? '' : '/'}$finalUrl';
      }

      // Try to get MP4 rendition for Mux
      finalUrl = _resolveMuxDownloadUrl(finalUrl);

      // Add token if needed
      final isOurServer = finalUrl.contains(AppConfig.apiBaseUrl.replaceFirst('/api', ''));
      Map<String, String> headers = {};
      if (isOurServer && downloadToken != null) {
        final connector = finalUrl.contains('?') ? '&' : '?';
        finalUrl = '$finalUrl${connector}token=$downloadToken';
      }

      await ref.read(downloadManagerProvider).startDownload(
        videoId: widget.videoId,
        url: finalUrl,
        title: res.video.title,
        subHeader: res.video.subHeader,
        unitName: res.video.unitName,
        durationSec: res.video.durationSec,
        headers: headers,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بدأ التحميل في الخلفية')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل بدء التحميل: $e')),
        );
        setState(() => _downloadProgress = -1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(lessonDetailsProvider(widget.videoId));
    final streamInfo = ref.watch(streamTokenProvider(widget.videoId));
    final downloadInfo = ref.watch(downloadStatusProvider(widget.videoId));

    final download = downloadInfo.valueOrNull;
    final isDownloaded = download?.status == 2;
    final isDownloading = download?.status == 1;

    // If it's downloading but we don't have progress yet, show 0
    double displayProgress = _downloadProgress;
    if (isDownloading && displayProgress < 0) {
      displayProgress = 0;
    }

    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: const Text('مشغل الدروس'),
              centerTitle: true,
            ),
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: ErrorView(
            title: 'تعذر تحميل الدرس',
            onRetry: () {
              ref.refresh(lessonDetailsProvider(widget.videoId));
              ref.refresh(streamTokenProvider(widget.videoId));
            },
          ),
        ),
        data: (data) {
          if (!_initialized) {
            _initVideo(data.video.streamUrl);
          }

          final download = downloadInfo.valueOrNull;
          final isDownloaded = download?.status == 2;
          final isDownloading = download?.status == 1;

          final player = _VideoPlayerArea(
            controller: _controller,
            ytController: _ytController,
            webController: _webController,
            playerType: _playerType,
            initialized: _initialized,
            watermark: data.watermark,
            isLocal: _isLocal,
            playbackRates: streamInfo.valueOrNull?.playbackRates,
            isFullScreen: _isFullScreen,
            onToggleFullScreen: _toggleFullScreen,
          );

          if (_isFullScreen) {
            return Container(
              color: Colors.black,
              child: player,
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                player,
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LessonHeader(video: data.video),
                      const SizedBox(height: AppDimensions.lg),
                      _ActionButtons(
                        video: data.video,
                        onDownload: _download,
                        downloadProgress: displayProgress,
                        isDownloaded: isDownloaded,
                        isDownloading: isDownloading,
                      ),
                      if (data.chapters.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.xl),
                        _ChaptersList(
                          chapters: data.chapters,
                          onChapterTap: (chapter) {
                            if (chapter.status != ChapterStatus.LOCKED) {
                              _controller?.seekTo(Duration(seconds: chapter.startSec));
                              _controller?.play();
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: AppDimensions.xl),
                      _NextLessonsList(
                        playlist: widget.playlist,
                        relatedVideos: data.relatedVideos,
                        currentVideoId: widget.videoId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuizSheet extends StatefulWidget {
  final TriggerQuiz quiz;
  const _QuizSheet({required this.quiz});

  @override
  State<_QuizSheet> createState() => _QuizSheetState();
}

class _QuizSheetState extends State<_QuizSheet> {
  int _qIdx = 0;
  String? _selected;
  bool _answered = false;
  int _score = 0;

  @override
  Widget build(BuildContext context) {
    final q = widget.quiz.questions[_qIdx];
    final isLast = _qIdx == widget.quiz.questions.length - 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سؤال ${_qIdx + 1}/${widget.quiz.questions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.quiz.title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            q.text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...q.options.map((opt) {
            final isCorrect = opt == q.answer;
            final isSelected = opt == _selected;
            Color color = AppColors.outline.withOpacity(0.3);
            if (_answered) {
              if (isCorrect) color = AppColors.success.withOpacity(0.2);
              else if (isSelected) color = AppColors.danger.withOpacity(0.2);
            } else if (isSelected) {
              color = AppColors.primary.withOpacity(0.1);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: _answered
                    ? null
                    : () => setState(() => _selected = opt),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _answered && isCorrect
                          ? AppColors.success
                          : (isSelected ? AppColors.primary : Colors.transparent),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_answered)
                        Icon(
                          isCorrect ? Icons.check_circle : (isSelected ? Icons.cancel : Icons.circle_outlined),
                          color: isCorrect ? AppColors.success : (isSelected ? AppColors.danger : Colors.grey),
                        )
                      else
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _answered && isCorrect ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (!_answered)
            AppPrimaryButton(
              label: 'تأكيد الإجابة',
              onPressed: _selected == null
                  ? null
                  : () {
                      setState(() {
                        _answered = true;
                        if (_selected == q.answer) _score++;
                      });
                    },
            )
          else
            AppPrimaryButton(
              label: isLast ? 'عرض النتيجة' : 'السؤال التالي',
              onPressed: () {
                if (isLast) {
                  _showResult();
                } else {
                  setState(() {
                    _qIdx++;
                    _selected = null;
                    _answered = false;
                  });
                }
              },
            ),
        ],
      ),
    );
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('نتيجة الاختبار', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_score / ${widget.quiz.questions.length}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            const Text('عمل رائع! استمر في التقدم.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerArea extends StatefulWidget {
  final VideoPlayerController? controller;
  final YoutubePlayerController? ytController;
  final WebViewController? webController;
  final PlayerType playerType;
  final bool initialized;
  final WatermarkInfo watermark;
  final bool isLocal;
  final List<double>? playbackRates;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  const _VideoPlayerArea({
    this.controller,
    this.ytController,
    this.webController,
    required this.playerType,
    required this.initialized,
    required this.watermark,
    required this.isLocal,
    this.playbackRates,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  @override
  State<_VideoPlayerArea> createState() => _VideoPlayerAreaState();
}

class _VideoPlayerAreaState extends State<_VideoPlayerArea> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    _setupYoutubeListener();
  }

  void _setupYoutubeListener() {
    widget.ytController?.addListener(_ytListener);
  }

  void _ytListener() {
    if (mounted &&
        widget.ytController != null &&
        widget.ytController!.value.isFullScreen != widget.isFullScreen) {
      widget.onToggleFullScreen();
    }
  }

  @override
  void didUpdateWidget(_VideoPlayerArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ytController != widget.ytController) {
      oldWidget.ytController?.removeListener(_ytListener);
      _setupYoutubeListener();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.ytController?.removeListener(_ytListener);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (widget.playerType == PlayerType.native) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && widget.controller?.value.isPlaying == true) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    if (widget.playerType != PlayerType.native) return;
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startHideTimer();
    });
  }

  void _toggleFullScreen() {
    widget.onToggleFullScreen();
  }

  void _skipForward() {
    if (widget.controller == null) return;
    final pos = widget.controller!.value.position;
    widget.controller!.seekTo(pos + const Duration(seconds: 10));
    _startHideTimer();
    setState(() {});
  }

  void _skipBackward() {
    if (widget.controller == null) return;
    final pos = widget.controller!.value.position;
    widget.controller!.seekTo(pos - const Duration(seconds: 10));
    _startHideTimer();
    setState(() {});
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        _buildPlayer(),
        _MovingWatermark(watermark: widget.watermark),
        if (widget.isLocal)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_pin, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('مشاهدة اوفلاين',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
      ],
    );

    if (widget.isFullScreen) {
      return content;
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: content,
    );
  }

  Widget _buildPlayer() {
    if (!widget.initialized) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    switch (widget.playerType) {
      case PlayerType.youtube:
        if (widget.ytController == null) {
          return const Center(
              child: Text('خطأ في تحميل فيديو يوتيوب',
                  style: TextStyle(color: Colors.white)));
        }
        return YoutubePlayer(
          controller: widget.ytController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primary,
          onEnded: (meta) {
            if (widget.isFullScreen) _toggleFullScreen();
          },
        );
      case PlayerType.web:
        if (widget.webController == null) {
          return const Center(
              child: Text('خطأ في تحميل الموقع',
                  style: TextStyle(color: Colors.white)));
        }
        return WebViewWidget(controller: widget.webController!);
      case PlayerType.native:
        if (widget.controller == null) {
          return const Center(
              child: Text('خطأ في مشغل الفيديو',
                  style: TextStyle(color: Colors.white)));
        }
        return Directionality(
          textDirection: TextDirection.ltr,
          child: GestureDetector(
            onTap: _toggleControls,
            onDoubleTapDown: (details) {
              final width = context.size?.width ?? 0;
              if (details.localPosition.dx < width / 3) {
                _skipBackward();
              } else if (details.localPosition.dx > width * 2 / 3) {
                _skipForward();
              }
            },
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: widget.controller!.value.aspectRatio,
                    child: VideoPlayer(widget.controller!),
                  ),
                  // Overlay controls
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      color: Colors.black45,
                      child: Stack(
                        children: [
                          // Center controls
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.replay_10,
                                      color: Colors.white, size: 40),
                                  onPressed: _skipBackward,
                                ),
                                ValueListenableBuilder(
                                  valueListenable: widget.controller!,
                                  builder: (context, value, child) {
                                    return IconButton(
                                      icon: Icon(
                                        value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: Colors.white,
                                        size: 72,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          value.isPlaying
                                              ? widget.controller!.pause()
                                              : widget.controller!.play();
                                        });
                                        _startHideTimer();
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.forward_10,
                                      color: Colors.white, size: 40),
                                  onPressed: _skipForward,
                                ),
                              ],
                            ),
                          ),
                          // Bottom controls
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {}, // Prevent toggle controls when clicking on bottom bar
                              child: Container(
                                padding: const EdgeInsets.only(top: 10),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black87],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ValueListenableBuilder(
                                            valueListenable: widget.controller!,
                                            builder: (context, value, child) {
                                              return Text(
                                                "${_formatDuration(value.position)} / ${_formatDuration(value.duration)}",
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold),
                                              );
                                            },
                                          ),
                                          Row(
                                            children: [
                                              _PlaybackSpeedButton(
                                                controller: widget.controller!,
                                                onChanged: () => setState(() {}),
                                                availableRates: widget.playbackRates,
                                              ),
                                              const SizedBox(width: 16),
                                              IconButton(
                                                icon: Icon(
                                                  widget.isFullScreen
                                                      ? Icons.fullscreen_exit
                                                      : Icons.fullscreen,
                                                  color: Colors.white,
                                                ),
                                                onPressed: _toggleFullScreen,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    ValueListenableBuilder(
                                      valueListenable: widget.controller!,
                                      builder: (context, value, child) {
                                        final position = value.position.inSeconds.toDouble();
                                        final duration = value.duration.inSeconds.toDouble();
                                        if (duration <= 0) return const SizedBox.shrink();
                                        return SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                            activeTrackColor: AppColors.primary,
                                            inactiveTrackColor: Colors.white24,
                                            thumbColor: AppColors.primary,
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Slider(
                                            value: position.clamp(0, duration),
                                            min: 0,
                                            max: duration,
                                            onChanged: (v) {
                                              widget.controller!.seekTo(Duration(seconds: v.toInt()));
                                              _startHideTimer();
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _PlaybackSpeedButton extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onChanged;
  final List<double>? availableRates;

  const _PlaybackSpeedButton({
    required this.controller,
    required this.onChanged,
    this.availableRates,
  });

  @override
  Widget build(BuildContext context) {
    final rates = availableRates ?? const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return PopupMenuButton<double>(
      initialValue: controller.value.playbackSpeed,
      tooltip: 'سرعة التشغيل',
      onSelected: (speed) {
        controller.setPlaybackSpeed(speed);
        onChanged();
      },
      itemBuilder: (context) => rates
          .map((rate) => PopupMenuItem(
                value: rate,
                child: Text('${rate}x'),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "${controller.value.playbackSpeed}x",
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _MovingWatermark extends StatefulWidget {
  final WatermarkInfo watermark;
  const _MovingWatermark({required this.watermark});

  @override
  State<_MovingWatermark> createState() => _MovingWatermarkState();
}

class _MovingWatermarkState extends State<_MovingWatermark>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _top;
  late Animation<double> _left;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..addListener(() {
        setState(() {});
      })
      ..repeat(reverse: true);

    _top = Tween<double>(begin: 0.05, end: 0.85).animate(CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.0, 1.0, curve: Curves.linear),
    ));
    _left = Tween<double>(begin: 0.05, end: 0.75).animate(CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.0, 1.0, curve: Curves.linear),
    ));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Positioned(
            top: constraints.maxHeight * _top.value,
            left: constraints.maxWidth * _left.value,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.35,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.watermark.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                      ),
                    ),
                    Text(
                      widget.watermark.phone,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _LessonHeader extends StatelessWidget {
  final LessonVideoDetail video;
  const _LessonHeader({required this.video});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                video.subHeader,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (video.isCompleted == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF059669), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'تمت المشاهدة',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          video.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.person_outline, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              video.teacherName ?? 'غير محدد',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final LessonVideoDetail video;
  final VoidCallback onDownload;
  final double downloadProgress;
  final bool isDownloaded;
  final bool isDownloading;

  const _ActionButtons({
    required this.video,
    required this.onDownload,
    required this.downloadProgress,
    required this.isDownloaded,
    required this.isDownloading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showProgress = isDownloading;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: video.pdfUrl != null ? () {} : null,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('المذكرة PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: theme.colorScheme.outline),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDownload,
                icon: showProgress
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: downloadProgress > 0.05 ? downloadProgress : null,
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(isDownloaded ? Icons.delete_outline : Icons.download_for_offline_outlined),
                label: Text(showProgress
                    ? (downloadProgress > 0.05 ? '${(downloadProgress * 100).toInt()}%' : 'بدء...')
                    : (isDownloaded ? 'حذف من الجهاز' : 'تنزيل الدرس')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDownloaded ? AppColors.danger : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NextLessonsList extends StatelessWidget {
  final List<SubjectVideoItem>? playlist;
  final List<RelatedVideo>? relatedVideos;
  final String currentVideoId;

  const _NextLessonsList({
    this.playlist,
    this.relatedVideos,
    required this.currentVideoId,
  });

  @override
  Widget build(BuildContext context) {
    if (playlist != null && playlist!.isNotEmpty) {
      final currentIndex = playlist!.indexWhere((v) => v.id == currentVideoId);
      final nextLessons = playlist!.sublist(currentIndex + 1);

      if (nextLessons.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الدروس التالية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppDimensions.md),
            ...nextLessons.map((v) => _PlaylistVideoTile(video: v, playlist: playlist!)),
          ],
        );
      }
    }

    if (relatedVideos != null && relatedVideos!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'دروس مقترحة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppDimensions.md),
          ...relatedVideos!.map((v) => _RelatedVideoTile(video: v)),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _ChaptersList extends StatelessWidget {
  final List<LessonChapter> chapters;
  final Function(LessonChapter) onChapterTap;

  const _ChaptersList({required this.chapters, required this.onChapterTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'فصول الدرس',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppDimensions.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chapters.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            final isLocked = chapter.status == ChapterStatus.LOCKED;
            final isPlaying = chapter.status == ChapterStatus.PLAYING;

            return InkWell(
              onTap: () => onChapterTap(chapter),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppColors.primary.withOpacity(0.05)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPlaying
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isPlaying ? AppColors.primary : AppColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked
                            ? Icons.lock_outline
                            : (isPlaying ? Icons.play_arrow : Icons.segment),
                        size: 16,
                        color: isPlaying ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.title,
                            style: TextStyle(
                              fontWeight: isPlaying ? FontWeight.w800 : FontWeight.w600,
                              color: isLocked ? AppColors.textTertiary : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            chapter.durationText,
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    if (chapter.status == ChapterStatus.COMPLETED)
                      const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RelatedVideoTile extends StatelessWidget {
  final RelatedVideo video;
  const _RelatedVideoTile({required this.video});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LessonDetailsScreen(videoId: video.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.md),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${video.subjectName} • ${video.unitName}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistVideoTile extends StatelessWidget {
  final SubjectVideoItem video;
  final List<SubjectVideoItem> playlist;
  const _PlaylistVideoTile({required this.video, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final locked = video.locked;
    final isCompleted = video.isCompleted;

    return InkWell(
      onTap: locked
          ? null
          : () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => LessonDetailsScreen(
                    videoId: video.id,
                    playlist: playlist,
                  ),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.md),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981).withOpacity(0.3)
                : AppColors.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: locked
                    ? AppColors.surfaceAlt
                    : (isCompleted
                        ? const Color(0xFFD1FAE5)
                        : AppColors.primarySurface),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                locked
                    ? Icons.lock_outline
                    : (isCompleted ? Icons.check : Icons.play_arrow_rounded),
                color: locked
                    ? AppColors.textTertiary
                    : (isCompleted ? const Color(0xFF059669) : AppColors.primary),
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: locked
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.check_circle,
                            size: 14, color: Color(0xFF10B981)),
                    ],
                  ),
                  Text(
                    'الوحدة ${video.unitNumber}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
