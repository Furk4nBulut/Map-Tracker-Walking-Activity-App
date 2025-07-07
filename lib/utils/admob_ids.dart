import 'package:flutter/foundation.dart';

class AdmobIds {
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else {
      return 'ca-app-pub-9589008379442992/9705088256';
    }
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else {
      return 'ca-app-pub-9589008379442992/8122180327';
    }
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917'; // AdMob test rewarded ID
    } else {
      return 'ca-app-pub-9589008379442992/1723458787';
    }
  }
} 