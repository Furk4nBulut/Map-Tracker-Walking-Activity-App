import 'package:flutter/material.dart';
import 'package:map_tracker/widgets/admob_banner.dart';
import 'package:map_tracker/services/ad_service.dart';

class AppBannerAd extends StatelessWidget {
  const AppBannerAd({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdService.isBannerBlocked(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        }
        if (snapshot.data == true) {
          return SizedBox.shrink();
        }
        return AdmobBanner();
      },
    );
  }
} 