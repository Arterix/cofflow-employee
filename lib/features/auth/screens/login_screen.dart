import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/brew_button.dart';
import '../../../shared/widgets/brew_text_field.dart';
import '../../orders/state/incoming_badge_controller.dart';
import '../services/auth_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    // Trigger rebuild for button enabled state + clear stale error.
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      !_submitting;

  void _fillMockAccount(String email, String password) {
    if (_submitting) return;
    _emailController.text = email;
    _passwordController.text = password;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AuthApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Upload FCM token (non-fatal).
      try {
        final fcm = await FirebaseMessaging.instance.getToken();
        if (fcm != null) {
          await AuthApiService.updateFcmToken(fcm);
        }
      } catch (_) {
        // FCM may be unavailable in dev — ignore.
      }

      // Warm up badge counter for incoming orders.
      // ignore: discarded_futures
      IncomingBadgeController.instance.refresh();

      if (!mounted) return;
      context.go('/pos');
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Login gagal: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Logo(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Selamat Datang',
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Masuk dengan akun kasir Anda',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  BrewTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'kasir@koncospace.id',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                    enabled: !_submitting,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BrewTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    enabled: !_submitting,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BrewButton(
                    label: 'Masuk',
                    onPressed: _canSubmit ? _submit : null,
                    isLoading: _submitting,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ErrorBanner(message: _errorMessage!),
                  ],
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _MockAccountsPanel(
                      enabled: !_submitting,
                      onSelect: _fillMockAccount,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Akun dibuat oleh admin. Hubungi admin jika belum punya akun.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/koncospace_logo.svg',
          width: 220,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _MockAccountsPanel extends StatelessWidget {
  const _MockAccountsPanel({required this.enabled, required this.onSelect});

  final bool enabled;
  final void Function(String email, String password) onSelect;

  static const _accounts = <_MockAccount>[
    _MockAccount(
      label: 'Admin',
      email: 'admin@cofflow.test',
      password: 'password',
      icon: Icons.admin_panel_settings_outlined,
    ),
    _MockAccount(
      label: 'Kasir',
      email: 'kasir@cofflow.test',
      password: 'password',
      icon: Icons.point_of_sale_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flash_on_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Mock accounts (dev)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _accounts.map((acc) {
              return _MockAccountChip(
                account: acc,
                enabled: enabled,
                onTap: () => onSelect(acc.email, acc.password),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Password: password',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockAccount {
  const _MockAccount({
    required this.label,
    required this.email,
    required this.password,
    required this.icon,
  });
  final String label;
  final String email;
  final String password;
  final IconData icon;
}

class _MockAccountChip extends StatelessWidget {
  const _MockAccountChip({
    required this.account,
    required this.enabled,
    required this.onTap,
  });

  final _MockAccount account;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: enabled ? AppColors.onPrimary : AppColors.onPrimary.withValues(alpha: 0.5),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(account.icon, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${account.label} · ${account.email}',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.alert.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.alert.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.alert, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body2.copyWith(color: AppColors.alert),
            ),
          ),
        ],
      ),
    );
  }
}
