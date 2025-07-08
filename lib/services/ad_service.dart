import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/admob_ids.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static Future<bool> isBannerBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt('bannerAdBlockUntil');
    if (until == null) return false;
    return DateTime.now().isBefore(DateTime.fromMillisecondsSinceEpoch(until));
  }

  static Future<bool> isInterstitialBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt('interstitialAdBlockUntil');
    if (until == null) return false;
    return DateTime.now().isBefore(DateTime.fromMillisecondsSinceEpoch(until));
  }

  static Future<void> showRewardedAd(BuildContext context, {VoidCallback? onRewarded, VoidCallback? onClosed}) async {
    RewardedAd.load(
      adUnitId: AdmobIds.rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (onClosed != null) onClosed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ad could not be shown.')),
              );
              if (onClosed != null) onClosed();
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              if (onRewarded != null) onRewarded();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Thank you for your support!')),
              );
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ad failed to load: \\${error.message}')),
          );
          if (onClosed != null) onClosed();
        },
      ),
    );
  }

  static Future<void> showInterstitialAd(BuildContext context, {VoidCallback? onClosed}) async {
    if (await isInterstitialBlocked()) {
      onClosed?.call();
      return;
    }
    InterstitialAd.load(
      adUnitId: AdmobIds.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (onClosed != null) onClosed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (onClosed != null) onClosed();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (onClosed != null) onClosed();
        },
      ),
    );
  }
} 