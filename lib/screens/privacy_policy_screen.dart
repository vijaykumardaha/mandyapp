import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/services/api_service.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late ThemeData theme;
  String? _htmlContent;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final response = await ApiService.instance.dio
          .get('/privacy', options: Options(headers: {'Accept': 'text/html'}));
      if (mounted) {
        setState(() {
          _htmlContent = response.data.toString();
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message ?? 'Failed to load privacy policy';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load privacy policy';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        titleWidget: Text('Privacy Policy'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _fetchContent();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Html(
                      data: _htmlContent ?? '',
                      style: {
                        'body': Style(
                          fontSize: FontSize(14),
                          lineHeight: const LineHeight(1.6),
                        ),
                      },
                    ),
                  ),
      ),
    );
  }
}
