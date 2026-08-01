import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/services/api_service.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
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
          .get('/terms', options: Options(headers: {'Accept': 'text/html'}));
      if (mounted) {
        setState(() {
          _htmlContent = response.data.toString();
          _isLoading = false;
        });
      }
    } on DioException {
      if (mounted) {
        setState(() {
          _error = 'Failed to load terms & conditions. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load terms & conditions. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        titleWidget: Text('Terms & Conditions'),
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
