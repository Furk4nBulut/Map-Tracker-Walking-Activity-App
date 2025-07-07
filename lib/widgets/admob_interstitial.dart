import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:map_tracker/utils/admob_ids.dart';

class AdmobInterstitial {
  InterstitialAd? _interstitialAd;
  final String? adUnitId;

  AdmobInterstitial({
    this.adUnitId,
  });

  void loadAd({VoidCallback? onLoaded, Function(LoadAdError)? onFailed}) {
    InterstitialAd.load(
      adUnitId: adUnitId ?? AdmobIds.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          onFailed?.call(error);
        },
      ),
    );
  }

  void showAd({VoidCallback? onDismissed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          onDismissed?.call();
        },
      );
      _interstitialAd!.show();
    }
  }
} 