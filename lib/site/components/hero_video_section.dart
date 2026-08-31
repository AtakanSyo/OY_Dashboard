import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../theme/site_responsive.dart';
import '../theme/site_tokens.dart';
import '../theme/site_typography.dart';

/// Tam genişlikte, arka planında video oynayan hero bölümü.
///
/// Video her zaman bir poster görselinin üzerine biner; poster şu durumlarda
/// tek başına kalır:
///
/// * mobil genişlik (veri ve performans),
/// * `MediaQuery.disableAnimations` / azaltılmış hareket tercihi,
/// * video henüz hazır değilken veya hiç yüklenemediğinde.
///
/// İçerik ([child]) solda hizalı, okunabilirlik için koyu gradyan scrim'in
/// üzerinde durur.
class HeroVideoSection extends StatefulWidget {
  final Widget child;

  final String videoAsset;
  final String posterAsset;

  /// Görünür alan yüksekliğinin kaçta kaçı hedeflenecek (desktop).
  final double desktopHeightFactor;

  const HeroVideoSection({
    super.key,
    required this.child,
    this.videoAsset = 'assets/video/hero.mp4',
    this.posterAsset = 'assets/images/hero/hero_poster.webp',
    this.desktopHeightFactor = 0.88,
  });

  @override
  State<HeroVideoSection> createState() => _HeroVideoSectionState();
}

class _HeroVideoSectionState extends State<HeroVideoSection> {
  Player? _player;
  VideoController? _videoController;

  bool _ready = false;
  bool _setupDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_setupDone) return;
    _setupDone = true;

    if (!_shouldPlayVideo) return;

    _start();
  }

  Future<void> _start() async {
    try {
      // Player/VideoController kurulumu da try içinde: media_kit hazır
      // değilse (ör. widget testleri) bölüm sessizce poster'a düşer.
      final player = Player();
      _player = player;
      _videoController = VideoController(player);

      await player.setVolume(0);
      await player.setPlaylistMode(PlaylistMode.loop);
      await player.open(Media('asset:///${widget.videoAsset}'));

      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error) {
      // Poster zaten görünür durumda; onunla devam edilir. Hata yine de
      // loglanır: sessizce poster'a düşmek sorunu fark etmeyi zorlaştırıyor.
      debugPrint('HERO_VIDEO: başlatılamadı ($error) — poster gösteriliyor');
      if (!mounted) return;
      setState(() => _ready = false);
    }
  }

  bool get _shouldPlayVideo {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return !reduceMotion && !context.device.isMobile;
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  /// Hero yüksekliği: desktop'ta ekranın büyük bölümü, dar ekranlarda içerik
  /// kadar. Sabit yükseklik yerine alt sınır kullanılır; içerik büyürse
  /// (büyük yazı tipi tercihi, uzun çeviri) bölüm taşmadan uzar.
  double _minHeight(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).height;
    final device = context.device;

    switch (device) {
      case SiteDevice.mobile:
        return (viewport * 0.72).clamp(480, 720);
      case SiteDevice.tablet:
        return (viewport * 0.80).clamp(520, 820);
      case SiteDevice.desktop:
        return (viewport * widget.desktopHeightFactor).clamp(600, 900);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = context.device;
    final controller = _videoController;
    final showVideo = _ready && controller != null;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: _minHeight(context)),
      child: ColoredBox(
        color: SiteColors.surfaceInverse,
        child: Stack(
          // Stack konumlandırılmamış çocuğu varsayılan olarak sol üste yaslar;
          // içerik dikeyde ortalanıp hafif yukarı alınıyor.
          alignment: const Alignment(0, -0.08),
          children: [
            Positioned.fill(child: _HeroPoster(asset: widget.posterAsset)),
            if (showVideo)
              Positioned.fill(
                child: ExcludeSemantics(
                  // media_kit'in Video widget'ı ölçeklemeyi kendi yapar;
                  // ayrıca FittedBox/SizedBox sarmalayıcısına gerek yok.
                  child: Video(
                    controller: controller,
                    fit: BoxFit.cover,
                    controls: NoVideoControls,
                    fill: Colors.transparent,
                  ),
                ),
              ),
            const Positioned.fill(child: _HeroScrim()),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: device.gutter,
                vertical: device.isMobile ? SiteSpacing.x6 : SiteSpacing.x7,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SiteBreakpoints.contentMaxWidth,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Metnin her koşulda okunabilir kalması için iki katmanlı scrim:
/// soldan sağa koyulaşan yatay gradyan + alttan gelen hafif dikey gölge.
class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    final isCompact = context.device.isCompact;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    SiteColors.surfaceInverse.withValues(alpha: 0.94),
                    SiteColors.surfaceInverse.withValues(
                      alpha: isCompact ? 0.80 : 0.62,
                    ),
                    SiteColors.surfaceInverse.withValues(
                      alpha: isCompact ? 0.62 : 0.22,
                    ),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    SiteColors.surfaceInverse.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPoster extends StatelessWidget {
  final String asset;

  const _HeroPoster({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Yürüyüş sırasında eklem noktalarının izlendiği biyomekanik '
          'ölçüm görüntüsü.',
      image: true,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: SiteColors.surfaceInverse,
          child: Center(
            child: Text(
              'HERO GÖRSELİ',
              style: SiteType.dataLabel(
                context,
                color: SiteColors.primaryOnDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
