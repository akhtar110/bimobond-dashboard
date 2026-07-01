import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/config/api_runtime_actions.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('LoginPage rebuilt');
    return PersistentBlocProvider<LoginBloc>(
      debugLabel: 'LoginPage',
      create: () => sl<LoginBloc>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiUrlController = TextEditingController();
  bool _showAccessDenied = false;
  bool get _needsApiSetup => ApiConfig.requiresHostedApiSetup();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginLoading) {
          if (_showAccessDenied && mounted) {
            setState(() => _showAccessDenied = false);
          }
          return;
        }
        if (state is LoginSuccess) {
          context.read<AuthBloc>().add(AuthUserChanged(state.user));
          return;
        }
        if (state is LoginAccessDenied) {
          if (!mounted) return;
          setState(() => _showAccessDenied = true);
          return;
        }
        if (state is LoginFailure) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return _buildDesktopLayout(context);
                }
                return _buildMobileLayout(context);
              },
            ),
          ),
          if (_showAccessDenied)
            _AccessDeniedOverlay(
              onDismiss: () => setState(() => _showAccessDenied = false),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          flex: 11,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              image: const DecorationImage(
                image: AssetImage('assets/images/auth_illustration.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.t('bimoBondAdmin'),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        l10n.t('loginHeroTitle'),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.t('loginHeroSubtitle'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 9,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginForm(context, isDesktop: true),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Card(
                elevation: Theme.of(context).cardTheme.elevation ?? 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _buildLoginForm(context, isDesktop: false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, {required bool isDesktop}) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDesktop) ...[
            Icon(
              Icons.admin_panel_settings,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.t('appTitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('welcomeBack'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
          ] else ...[
            Text(
              l10n.t('welcomeBack'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('signInSubtitle'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
          ],

          if (_needsApiSetup) ...[
            _buildHostedApiSetupCard(theme),
            const SizedBox(height: 24),
          ],

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.t('email'),
              hintText: l10n.t('emailHint'),
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return l10n.t('requiredField');
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.t('password'),
              hintText: l10n.t('passwordHint'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return l10n.t('requiredField');
              }
              return null;
            },
          ),
     
          const SizedBox(height: 24),
          
          SizedBox(
            height: 56,
            child: BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                final isLoading = state is LoginLoading;
                return FilledButton(
                  onPressed: isLoading || _needsApiSetup
                      ? null
                      : () {
                          final form = _formKey.currentState;
                          if (form == null || !form.validate()) return;
                          context.read<LoginBloc>().add(
                                LoginSubmitted(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                ),
                              );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.t('login'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerTheme.color)),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.t('orContinueWith'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(child: Divider(color: theme.dividerTheme.color)),
            ],
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            height: 56,
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: theme.dividerTheme.color ?? Colors.grey.shade300,
                ),
              ),
              onPressed: _needsApiSetup
                  ? null
                  : () {
                      context.read<LoginBloc>().add(LoginWithGooglePressed());
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GoogleSignInIcon(color: theme.colorScheme.onSurface),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        l10n.t('signInWithGoogle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostedApiSetupCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Backend API URL required',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This hosted dashboard cannot use your LAN API. Enter the public HTTPS '
            'URL of your backend (for example an ngrok or deployed API URL).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _apiUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'API base URL',
              hintText: 'http://192.168.1.123:3000 or https://api.example.com',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              final raw = _apiUrlController.text.trim();
              if (raw.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter your API URL')),
                );
                return;
              }
              final url = ApiConfig.normalize(raw);
              final uri = Uri.tryParse(url);
              if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid API URL')),
                );
                return;
              }
              final isLocalApi = _isLocalApiHost(uri.host);
              if (!isLocalApi && uri.scheme != 'https') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Public APIs must use https://'),
                  ),
                );
                return;
              }
              if (isLocalApi && uri.scheme != 'http') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Local/LAN APIs must use http://'),
                  ),
                );
                return;
              }
              saveHostedApiUrl(url);
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save API URL & reload'),
          ),
        ],
      ),
    );
  }

  bool _isLocalApiHost(String host) {
    final lower = host.toLowerCase();
    if (lower == 'localhost' || lower == '127.0.0.1' || lower == '0.0.0.0') {
      return true;
    }
    return RegExp(r'^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(lower);
  }
}

class _GoogleSignInIcon extends StatelessWidget {
  const _GoogleSignInIcon({required this.color});

  final Color color;

  static const _assetPath = 'assets/images/google.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.g_mobiledata,
        size: 28,
        color: color,
      ),
    );
  }
}

class _AccessDeniedOverlay extends StatelessWidget {
  const _AccessDeniedOverlay({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_person_rounded, color: scheme.error, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('accessDeniedTitle'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.t('accessDeniedMessage'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onDismiss,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(l10n.t('confirmAction')),
                    ),
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