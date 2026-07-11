import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../core/config.dart';
import '../providers/premium_provider.dart';

class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({super.key});

  static String get _placementId {
    return Platform.isAndroid ? AppConfig.unityBannerAndroid : AppConfig.unityBannerIOS;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(premiumProvider)) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: UnityBannerAd(
        placementId: _placementId,
        onLoad: (id) => debugPrint('UnityBanner loaded: $id'),
        onClick: (id) => debugPrint('UnityBanner clicked: $id'),
        onShown: (id) => debugPrint('UnityBanner shown: $id'),
        onFailed: (id, error, message) => debugPrint('UnityBanner failed: $id $error $message'),
      ),
    );
  }
}
