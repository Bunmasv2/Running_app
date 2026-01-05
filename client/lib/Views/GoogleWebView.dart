import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleWebView extends StatefulWidget {
  const GoogleWebView({super.key});

  @override
  State<GoogleWebView> createState() => _GoogleWebViewState();
}

class _GoogleWebViewState extends State<GoogleWebView> {
  late final WebViewController _controller;

  // Link API Backend Login Google của bạn
  final String _loginUrl = 'https://running-app-ywpg.onrender.com/user/signin-google';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Đây là cái scheme ảo mà Backend phải redirect về: runningapp://auth-success?token=...
            if (request.url.startsWith('http://localhost:3000/project?success=true')) {

              final Uri uri = Uri.parse(request.url);
              final String? token = uri.queryParameters['token'];

              if (token != null) {
                // Trả token về cho UserService
                Navigator.pop(context, token);
              } else {
                Navigator.pop(context, null);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập Google")),
      body: WebViewWidget(controller: _controller),
    );
  }
}