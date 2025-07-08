import 'package:flutter/material.dart';
import 'package:map_tracker/widgets/admob_banner.dart';
import 'package:map_tracker/services/ad_service.dart';

class AppBannerAd extends StatefulWidget {
  const AppBannerAd({Key? key}) : super(key: key);

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  late Future<bool> _isBannerBlockedFuture;

  @override
  void initState() {
    super.initState();
    _isBannerBlockedFuture = AdService.isBannerBlocked();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isBannerBlockedFuture,
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