import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/admob_ids.dart';

class AdmobRewarded {
  static RewardedAd? _rewardedAd;

  static void loadAndShowRewardedAd(BuildContext context, {VoidCallback? onRewarded}) {
    RewardedAd.load(
      adUnitId: AdmobIds.rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reklam gösterilemedi.')),
              );
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              if (onRewarded != null) onRewarded();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Teşekkürler! Desteğiniz için minnettarız.')),
              );
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reklam yüklenemedi: \\${error.message}')),
          );
        },
      ),
    );
  }
} 