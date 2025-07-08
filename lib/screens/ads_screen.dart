import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../widgets/admob_banner.dart';
import 'package:map_tracker/utils/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:map_tracker/localization/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:map_tracker/widgets/app_banner_ad.dart';
import 'package:map_tracker/screens/partials/appbar.dart';
import 'package:map_tracker/widgets/language_switcher.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({Key? key}) : super(key: key);

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  int _coins = 0;
  int _totalCoins = 0;
  DateTime? _adFreeUntil;
  bool _isLoadingCoin = true;
  DateTime? _bannerBlockUntil;
  DateTime? _interstitialBlockUntil;
  int _adsWatched = 0;

  static const int coinsRequired = 4; // 4 coin = 1 gün reklamsız
  static const int bannerBlockCost = 2;
  static const int interstitialBlockCost = 4;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCoinState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {}); // Süreleri güncelle
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCoinState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coins = prefs.getInt('coins') ?? 0;
      _totalCoins = prefs.getInt('totalCoins') ?? 0;
      final adFreeMillis = prefs.getInt('adFreeUntil');
      _adFreeUntil = adFreeMillis != null ? DateTime.fromMillisecondsSinceEpoch(adFreeMillis) : null;
      final bannerMillis = prefs.getInt('bannerAdBlockUntil');
      _bannerBlockUntil = bannerMillis != null ? DateTime.fromMillisecondsSinceEpoch(bannerMillis) : null;
      final interstitialMillis = prefs.getInt('interstitialAdBlockUntil');
      _interstitialBlockUntil = interstitialMillis != null ? DateTime.fromMillisecondsSinceEpoch(interstitialMillis) : null;
      _adsWatched = prefs.getInt('adsWatched') ?? 0;
      _isLoadingCoin = false;
    });
  }

  Future<void> _addCoin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coins++;
      _totalCoins++;
      _adsWatched++;
    });
    await prefs.setInt('coins', _coins);
    await prefs.setInt('totalCoins', _totalCoins);
    await prefs.setInt('adsWatched', _adsWatched);
  }

  Future<void> _blockBannerAds() async {
    if (_coins < bannerBlockCost) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final current = _bannerBlockUntil != null && _bannerBlockUntil!.isAfter(now) ? _bannerBlockUntil! : now;
    final newUntil = current.add(const Duration(days: 1));
    setState(() {
      _coins -= bannerBlockCost;
      _bannerBlockUntil = newUntil;
    });
    await prefs.setInt('coins', _coins);
    await prefs.setInt('bannerAdBlockUntil', newUntil.millisecondsSinceEpoch);
  }

  Future<void> _blockInterstitialAds() async {
    if (_coins < interstitialBlockCost) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final current = _interstitialBlockUntil != null && _interstitialBlockUntil!.isAfter(now) ? _interstitialBlockUntil! : now;
    final newUntil = current.add(const Duration(days: 1));
    setState(() {
      _coins -= interstitialBlockCost;
      _interstitialBlockUntil = newUntil;
    });
    await prefs.setInt('coins', _coins);
    await prefs.setInt('interstitialAdBlockUntil', newUntil.millisecondsSinceEpoch);
  }

  Future<void> _resetAdBlocks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adFreeUntil = null;
      _bannerBlockUntil = null;
      _interstitialBlockUntil = null;
    });
    await prefs.remove('adFreeUntil');
    await prefs.remove('bannerAdBlockUntil');
    await prefs.remove('interstitialAdBlockUntil');
  }

  bool get _isBannerBlocked => _bannerBlockUntil != null && _bannerBlockUntil!.isAfter(DateTime.now());
  bool get _isInterstitialBlocked => _interstitialBlockUntil != null && _interstitialBlockUntil!.isAfter(DateTime.now());

  String get _bannerBlockTimeLeft {
    if (!_isBannerBlocked) return '';
    final diff = _bannerBlockUntil!.difference(DateTime.now());
    return _formatDuration(diff);
  }

  String get _interstitialBlockTimeLeft {
    if (!_isInterstitialBlocked) return '';
    final diff = _interstitialBlockUntil!.difference(DateTime.now());
    return _formatDuration(diff);
  }

  String _formatDuration(Duration diff) {
    if (diff.isNegative) return '0 saniye';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days gün');
    if (hours > 0) parts.add('$hours saat');
    if (minutes > 0) parts.add('$minutes dakika');
    if (seconds > 0 || parts.isEmpty) parts.add('$seconds saniye');
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Constants.kykGray800 : Constants.white,
      appBar: CustomAppBar(
        title: LocaleKeys.ad_info_title.tr(),
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          // COIN GÖSTERGESİ
          Padding(
            padding: const EdgeInsets.only(top: 18.0, left: 18, right: 18, bottom: 8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Constants.kykGray700 : Constants.kykGray100,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.08) : Constants.kykGray400.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: isDark ? Constants.kykGray600 : Constants.kykGray200, width: 1),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on_rounded, color: Constants.kykPrimary, size: 28),
                  SizedBox(width: 8),
                  Text('$_coins', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 22, color: Constants.kykPrimary)),
                  SizedBox(width: 8),
                  Text(LocaleKeys.ad_info_coin.tr(), style: GoogleFonts.inter(fontSize: 16, color: isDark ? Constants.kykGray200 : Constants.kykGray700)),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Constants.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- EN BAŞTA TANITIM ---
                  Text(
                    LocaleKeys.ad_info_about.tr(),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: isDark ? Constants.kykGray100 : Constants.kykGray900),
                  ),
                  SizedBox(height: 8),
                  Text(
                    LocaleKeys.ad_info_about_desc.tr(),
                    style: GoogleFonts.inter(fontSize: 15, color: isDark ? Constants.kykGray400 : Constants.kykGray700),
                  ),
                  SizedBox(height: 20),
                  // --- Bilgi Kartları ---
                  _infoRow(Icons.view_stream_rounded, LocaleKeys.ad_info_banner.tr(), LocaleKeys.ad_info_banner_desc.tr()),
                  SizedBox(height: 8),
                  _infoRow(Icons.flip_to_front_rounded, LocaleKeys.ad_info_interstitial.tr(), LocaleKeys.ad_info_interstitial_desc.tr()),
                  SizedBox(height: 8),
                  _infoRow(Icons.monetization_on_rounded, LocaleKeys.ad_info_coin.tr(), LocaleKeys.ad_info_coin_desc.tr()),
                  SizedBox(height: 28),
                  // 1. Reklamlar ve Coin Yönetimi başlığı
                  _buildSectionTitle(context, LocaleKeys.ads_section.tr(), isDark),
                  SizedBox(height: Constants.space3),
                  _buildSettingsCard(
                    context: context,
                    isDark: isDark,
                    child: Column(
                      children: [
                        // --- Reklam İzle, Coin Kazan ---
                        _buildSettingsItem(
                          context: context,
                          isDark: isDark,
                          icon: Icons.play_circle_fill_rounded,
                          title: LocaleKeys.ad_info_watch_ad.tr(),
                          subtitle: LocaleKeys.ad_info_watch_ad_desc.tr(),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on_rounded, color: Constants.kykPrimary, size: 18),
                              SizedBox(width: 4),
                              Text('$_coins', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Constants.kykPrimary)),
                            ],
                          ),
                          onTap: _isLoadingCoin ? null : () async {
                            await AdService.showRewardedAd(
                              context,
                              onRewarded: () async {
                                await _addCoin();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(LocaleKeys.ad_info_thanks.tr()),
                                      backgroundColor: Constants.kykSuccess,
                                    ),
                                  );
                                }
                              },
                              onClosed: () {},
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        const Divider(height: 1),
                        SizedBox(height: 8),
                        // --- Banner Reklam Engelle ---
                        _buildSettingsItem(
                          context: context,
                          isDark: isDark,
                          icon: Icons.visibility_off_rounded,
                          title: LocaleKeys.ad_info_block_banner.tr(),
                          subtitle: LocaleKeys.ad_info_block_banner_desc.tr() + ' ' + (_bannerBlockTimeLeft.isNotEmpty ? _bannerBlockTimeLeft : LocaleKeys.ad_info_none.tr()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on_rounded, color: _coins >= bannerBlockCost ? Constants.kykPrimary : Constants.kykGray400, size: 18),
                              SizedBox(width: 4),
                              Text('$bannerBlockCost', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _coins >= bannerBlockCost ? Constants.kykPrimary : Constants.kykGray400)),
                            ],
                          ),
                          onTap: _isLoadingCoin || _coins < bannerBlockCost || _isBannerBlocked ? null : () async {
                            await _blockBannerAds();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(LocaleKeys.ad_info_block_banner_success.tr()),
                                  backgroundColor: Constants.kykSuccess,
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(height: 8),
                        const Divider(height: 1),
                        SizedBox(height: 8),
                        // --- Geçiş Reklam Engelle ---
                        _buildSettingsItem(
                          context: context,
                          isDark: isDark,
                          icon: Icons.block,
                          title: LocaleKeys.ad_info_block_interstitial.tr(),
                          subtitle: LocaleKeys.ad_info_block_interstitial_desc.tr() + ' ' + (_interstitialBlockTimeLeft.isNotEmpty ? _interstitialBlockTimeLeft : LocaleKeys.ad_info_none.tr()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on_rounded, color: _coins >= interstitialBlockCost ? Constants.kykPrimary : Constants.kykGray400, size: 18),
                              SizedBox(width: 4),
                              Text('$interstitialBlockCost', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _coins >= interstitialBlockCost ? Constants.kykPrimary : Constants.kykGray400)),
                            ],
                          ),
                          onTap: _isLoadingCoin || _coins < interstitialBlockCost || _isInterstitialBlocked ? null : () async {
                            await _blockInterstitialAds();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(LocaleKeys.ad_info_block_interstitial_success.tr()),
                                  backgroundColor: Constants.kykSuccess,
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(height: 8),
                        const Divider(height: 1),
                        SizedBox(height: 8),
                        // --- SÜRELERİ SIFIRLA BUTONU ---
                        _buildSettingsItem(
                          context: context,
                          isDark: isDark,
                          icon: Icons.refresh_rounded,
                          title: LocaleKeys.ad_info_reset.tr(),
                          subtitle: LocaleKeys.ad_info_reset_confirm.tr(),
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(LocaleKeys.ad_info_reset.tr()),
                                content: Text(LocaleKeys.ad_info_reset_confirm.tr()),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text(LocaleKeys.cancel.tr()),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text(LocaleKeys.ad_info_reset.tr()),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await _resetAdBlocks();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(LocaleKeys.ad_info_reset_success.tr())),
                                );
                              }
                            }
                          },
                        ),
                        SizedBox(height: 8),
                        const Divider(height: 1),
                        SizedBox(height: 8),
                        // --- GELİŞTİRİCİYE DESTEK OL (Buy Me a Coffee) ---
                        _buildSettingsItem(
                          context: context,
                          isDark: isDark,
                          icon: Icons.coffee_rounded,
                          title: LocaleKeys.ad_info_support.tr(),
                          subtitle: LocaleKeys.ad_info_support_desc.tr() + '\n' + '(Buy Me a Coffee: ' + LocaleKeys.soon.tr() + ')',
                          onTap: null,
                        ),
                        SizedBox(height: 8),
                        const Divider(height: 1),
                        SizedBox(height: 8),
                        // --- HATA BİLDİRİMİ ---
                        _buildSettingsItem(
                          context: context,
                          isDark: isDark,
                          icon: Icons.bug_report_rounded,
                          title: LocaleKeys.ad_info_bug.tr(),
                          subtitle: LocaleKeys.ad_info_bug_desc.tr(),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('github.com/bulutsoft-dev | bulutsoftdev@gmail.com')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Constants.space4),
                  // --- UYARI ---
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border:Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            LocaleKeys.ad_info_warning_text.tr(),
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- Açıklama ve banner reklam ---
                  Text(
                    LocaleKeys.ads_section_explanation.tr(),
                    style: GoogleFonts.inter(fontSize: Constants.textXs, color: isDark ? Constants.kykGray400 : Constants.kykGray600),
                  ),
                  SizedBox(height: Constants.space4),
                  // Banner gösteriminde:
                  FutureBuilder<bool>(
                    future: AdService.isBannerBlocked(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox.shrink();
                      }
                      if (snapshot.data == true) {
                        return SizedBox.shrink();
                      }
                      return Center(child: AppBannerAd());
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Constants.kykPrimary, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(desc, style: GoogleFonts.inter(fontSize: 13, color: Constants.kykGray500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: Constants.textLg,
        fontWeight: FontWeight.bold,
        color: isDark ? Constants.kykGray100 : Constants.kykGray900,
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.10) : Constants.kykGray400.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: isDark ? Constants.kykGray700 : Constants.kykGray200, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Constants.kykPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Constants.kykPrimary,
                  size: 22,
                ),
              ),
              SizedBox(width: Constants.space3 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: Constants.textBase,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Constants.kykGray200 : Constants.kykGray800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: Constants.textSm,
                        color: isDark ? Constants.kykGray400 : Constants.kykGray600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 8),
                trailing,
              ],
              if (onTap != null && trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Constants.kykGray400 : Constants.kykGray500,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 