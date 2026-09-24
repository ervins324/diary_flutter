import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/ambient_background.dart';
import '../../core/theme/liquid_theme.dart';
import '../../providers/api_client_provider.dart';

/// Server connection configuration screen.
class ServerSetupScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;

  const ServerSetupScreen({super.key, this.isOnboarding = false});

  @override
  ConsumerState<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends ConsumerState<ServerSetupScreen> {
  late final TextEditingController _urlController;
  bool _isTesting = false;
  bool? _testSuccess;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(serverUrlProvider);
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _statusMessage = null;
    });

    ref.read(serverConnectionProvider.notifier).updateServerUrl(rawUrl);
    final ok = await ref.read(serverConnectionProvider.notifier).checkConnection();

    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    final apiErr = ref.read(apiClientProvider).lastHealthCheckError;

    setState(() {
      _isTesting = false;
      _testSuccess = ok;
      _statusMessage = ok
          ? loc.translate('connection_ok')
          : (apiErr != null
              ? '${loc.translate('connection_failed')}\n$apiErr'
              : loc.translate('connection_failed'));
    });
  }

  void _saveAndProceed() {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isNotEmpty) {
      ref.read(serverUrlProvider.notifier).state = rawUrl;
      ref.read(serverConnectionProvider.notifier).updateServerUrl(rawUrl);
    }
    if (widget.isOnboarding) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AmbientBackground(
        isDark: isDark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: LiquidGlassLens(
                style: LiquidTheme.cardStyle(isDark: isDark, radius: 28),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LiquidTheme.accent.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.dns_rounded,
                            size: 40,
                            color: LiquidTheme.accentLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        loc.translate('server_connection'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        loc.translate('server_url_hint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Server URL input field
                      TextField(
                        controller: _urlController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: loc.translate('server_url'),
                          labelStyle: TextStyle(
                            color: isDark ? LiquidTheme.darkTextSecondary : LiquidTheme.lightTextSecondary,
                          ),
                          prefixIcon: const Icon(Icons.link_rounded, color: LiquidTheme.accentLight),
                          filled: true,
                          fillColor: isDark ? const Color(0x261E293B) : const Color(0x26FFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: LiquidTheme.accent, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Test Connection Button
                      ElevatedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0x336366F1),
                          foregroundColor: LiquidTheme.accentLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: _isTesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.network_check_rounded),
                        label: Text(loc.translate('test_connection')),
                      ),

                      // Test Result Banner
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _testSuccess == true
                                ? LiquidTheme.success.withValues(alpha: 0.15)
                                : LiquidTheme.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _testSuccess == true
                                  ? LiquidTheme.success.withValues(alpha: 0.4)
                                  : LiquidTheme.danger.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                                color: _testSuccess == true ? LiquidTheme.success : LiquidTheme.danger,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _statusMessage!,
                                  style: TextStyle(
                                    color: _testSuccess == true ? LiquidTheme.success : LiquidTheme.danger,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Save and Continue Button
                      ElevatedButton(
                        onPressed: _saveAndProceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LiquidTheme.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 2,
                        ),
                        child: Text(
                          loc.translate('save_and_continue'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
