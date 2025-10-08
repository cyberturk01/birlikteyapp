// lib/pages/privacy_policy_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// Yeni API: bu üç import önemli
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  static const String policyUrl =
      'https://cyberturk01.github.io/togetherly-privacy/';

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    // 4.x: platforma göre "creation params"
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // iOS
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      // Android / default
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    // Android'e özel ayarlar (opsiyonel)
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            final insidePolicy = req.url.startsWith(
              PrivacyPolicyPage.policyUrl,
            );
            if (!insidePolicy) {
              launchUrl(
                Uri.parse(req.url),
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(PrivacyPolicyPage.policyUrl));

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => launchUrl(
              Uri.parse(PrivacyPolicyPage.policyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
