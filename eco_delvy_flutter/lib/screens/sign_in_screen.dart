// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';
import '../core/theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  final Widget child;
  const SignInScreen({super.key, required this.child});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    client.auth.authInfoListenable.addListener(_updateSignedInState);
    _isSignedIn = client.auth.isAuthenticated;
  }

  @override
  void dispose() {
    client.auth.authInfoListenable.removeListener(_updateSignedInState);
    super.dispose();
  }

  void _updateSignedInState() {
    setState(() {
      _isSignedIn = client.auth.isAuthenticated;
    });
  }

  String _authenticationErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('A connection error occurred.')) {
      return 'Cannot reach the EcoDelvy Serverpod API. Check that the backend '
          'is running, SERVER_URL is correct, and this browser origin is '
          'allowed. This is separate from your internet connection.';
    }
    return 'Authentication failed: $message';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _isSignedIn
        ? widget.child
        : Scaffold(
            backgroundColor: AppTheme.canvas,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1000,
                    maxHeight: 680,
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 720;
                        final form = SingleChildScrollView(
                          padding: EdgeInsets.all(compact ? 20 : 36),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: EmailSignInWidget(
                                client: client,
                                startScreen: EmailFlowScreen.login,
                                onAuthenticated: () {
                                  context.showSnackBar(
                                    message: 'User authenticated.',
                                    backgroundColor: colors.primaryContainer,
                                    foregroundColor: colors.onPrimaryContainer,
                                  );
                                },
                                onError: (error) {
                                  context.showSnackBar(
                                    message: _authenticationErrorMessage(error),
                                    backgroundColor: colors.errorContainer,
                                    foregroundColor: colors.onErrorContainer,
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                        if (compact) {
                          return Column(
                            children: [
                              const _SignInBrand(compact: true),
                              Expanded(child: form),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: _SignInBrand(
                                compact: false,
                                short: constraints.maxHeight < 420,
                              ),
                            ),
                            Expanded(flex: 6, child: form),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}

class _SignInBrand extends StatelessWidget {
  const _SignInBrand({required this.compact, this.short = false});

  final bool compact;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.route_rounded, color: Colors.white),
        ),
        const SizedBox(width: 11),
        const Text(
          'EcoDelvy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: AppTheme.sidebar,
        child: brand,
      );
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(short ? 22 : 38),
      decoration: const BoxDecoration(color: AppTheme.sidebar),
      child: short
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                brand,
                const SizedBox(height: 18),
                const Text(
                  'Plan every mile.\nDeliver with confidence.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                brand,
                const Spacer(),
                const Icon(
                  Icons.alt_route_rounded,
                  color: AppTheme.green,
                  size: 38,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Plan every mile.\nDeliver with confidence.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Intelligent route planning for teams moving goods and growing sustainably.',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const Spacer(),
                const Text(
                  'FLEET ROUTE OPTIMIZATION',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
    );
  }
}

extension on BuildContext {
  void showSnackBar({
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: foregroundColor)),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
