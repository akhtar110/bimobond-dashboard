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
import '../utils/login_window_focus.dart';
import '../widgets/login_appearance_controls.dart';

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
  bool _obscurePassword = true;
  bool get _needsApiSetup => ApiConfig.requiresHostedApiSetup();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static _LoginLayoutMetrics _metrics(BuildContext context) =>
      _LoginLayoutMetrics.of(context);

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
    listenWindowFocus(_onWindowFocus);
  }

  void _onWindowFocus() {
    if (!mounted) return;
    context.read<LoginBloc>().add(LoginGoogleSignInAborted());
  }

  @override
  void dispose() {
    cancelWindowFocusListener();
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
          final message = state.message == LoginBloc.googleSignInCancelledKey
              ? context.l10n.t('googleSignInCancelled')
              : state.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            body: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final metrics = _metrics(context);
                    if (metrics.useSideBySide) {
                      return _buildDesktopLayout(context, metrics);
                    }
                    return _buildMobileLayout(context, metrics);
                  },
                ),
                const SafeArea(
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        top: 12,
                        end: 16,
                      ),
                      child: LoginAppearanceControls(),
                    ),
                  ),
                ),
              ],
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

  Widget _buildDesktopLayout(BuildContext context, _LoginLayoutMetrics metrics) {
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: EdgeInsets.all(metrics.panelPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: metrics.brandIconSize,
                              ),
                              SizedBox(width: metrics.isCompactWidth ? 8 : 12),
                              Expanded(
                                child: Text(
                                  l10n.t('bimoBondAdmin'),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: metrics.brandTitleSize,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.t('loginHeroTitle'),
                                      style: theme.textTheme.displayMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                        fontSize: metrics.heroTitleSize,
                                      ),
                                    ),
                                    SizedBox(height: metrics.sectionGap / 2),
                                    Text(
                                      l10n.t('loginHeroSubtitle'),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w400,
                                        fontSize: metrics.heroSubtitleSize,
                                      ),
                                    ),
                                    SizedBox(height: metrics.sectionGap),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 9,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.panelPadding,
                vertical: metrics.verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: metrics.formMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildLoginForm(
                          context,
                          metrics: metrics,
                          isDesktop: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, _LoginLayoutMetrics metrics) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          metrics.horizontalPadding,
          metrics.mobileTopPadding,
          metrics.horizontalPadding,
          metrics.verticalPadding,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: metrics.formMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    elevation: Theme.of(context).cardTheme.elevation ?? 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(metrics.cardRadius),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(metrics.cardPadding),
                      child: _buildLoginForm(
                        context,
                        metrics: metrics,
                        isDesktop: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    BuildContext context, {
    required _LoginLayoutMetrics metrics,
    required bool isDesktop,
  }) {
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
              size: metrics.mobileBrandIconSize,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: metrics.fieldGap),
            Text(
              l10n.t('appTitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: metrics.mobileTitleSize,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('welcomeBack'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: metrics.bodyTextSize,
              ),
            ),
            SizedBox(height: metrics.sectionGap),
          ] else ...[
            Text(
              l10n.t('welcomeBack'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                fontSize: metrics.desktopWelcomeSize,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('signInSubtitle'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: metrics.bodyTextSize,
              ),
            ),
            SizedBox(height: metrics.sectionGap),
          ],

          if (_needsApiSetup) ...[
            _buildHostedApiSetupCard(theme, metrics),
            SizedBox(height: metrics.fieldGap),
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
          SizedBox(height: metrics.fieldGap),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.t('password'),
              hintText: l10n.t('passwordHint'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: Semantics(
                label: _obscurePassword
                    ? l10n.t('showPassword')
                    : l10n.t('hidePassword'),
                button: true,
                child: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return l10n.t('requiredField');
              }
              return null;
            },
          ),
     
          SizedBox(height: metrics.fieldGap),
          
          SizedBox(
            height: metrics.buttonHeight,
            child: BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                final isLoading =
                    state is LoginLoading && !state.isGoogle;
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
                          style: TextStyle(
                            fontSize: metrics.buttonTextSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
          ),
          
          SizedBox(height: metrics.sectionGap),
          
          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerTheme.color)),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.isCompactWidth ? 8 : 12,
                  ),
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
          
          SizedBox(height: metrics.sectionGap),
          
          SizedBox(
            height: metrics.buttonHeight,
            width: double.infinity,
            child: BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                final isGoogleLoading =
                    state is LoginLoading && state.isGoogle;
                final isDisabled = _needsApiSetup || state is LoginLoading;

                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(metrics.buttonRadius),
                    ),
                    side: BorderSide(
                      color: theme.dividerTheme.color ?? Colors.grey.shade300,
                    ),
                  ),
                  onPressed: isDisabled
                      ? null
                      : () {
                          context
                              .read<LoginBloc>()
                              .add(LoginWithGooglePressed());
                        },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.isCompactWidth ? 8 : 12,
                    ),
                    child: isGoogleLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleSignInIcon(
                                color: theme.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  l10n.t('signInWithGoogle'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: metrics.buttonTextSize,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostedApiSetupCard(
    ThemeData theme,
    _LoginLayoutMetrics metrics,
  ) {
    return Container(
      padding: EdgeInsets.all(metrics.isCompactWidth ? 12 : 16),
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
              hintText: 'http://134.209.2.225 or https://api.example.com',
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
    final metrics = _LoginLayoutMetrics.of(context);

    return Material(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: metrics.formMaxWidth),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(metrics.cardRadius),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.cardPadding,
                  metrics.cardPadding + 4,
                  metrics.cardPadding,
                  metrics.fieldGap,
                ),
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
                          minimumSize: Size.fromHeight(metrics.buttonHeight),
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
      ),
    );
  }
}

class _LoginLayoutMetrics {
  const _LoginLayoutMetrics({
    required this.width,
    required this.height,
    required this.viewPadding,
  });

  final double width;
  final double height;
  final EdgeInsets viewPadding;

  factory _LoginLayoutMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return _LoginLayoutMetrics(
      width: size.width,
      height: size.height,
      viewPadding: MediaQuery.paddingOf(context),
    );
  }

  bool get isCompactWidth => width < 360;
  bool get isMobileWidth => width < 600;
  bool get isShortHeight => height < 640;
  bool get useSideBySide => width >= 900 && height >= 520;

  double get horizontalPadding =>
      isCompactWidth ? 16 : (isMobileWidth ? 20 : 48);
  double get verticalPadding => isShortHeight ? 16 : (isMobileWidth ? 24 : 48);
  double get panelPadding => isShortHeight ? 24 : (isMobileWidth ? 32 : 48);
  double get formMaxWidth =>
      (width - horizontalPadding * 2).clamp(260, 420);
  double get appearanceControlsTopPadding => isShortHeight ? 8 : 12;
  double get mobileTopPadding =>
      viewPadding.top + appearanceControlsTopPadding + 52;
  double get cardPadding => isCompactWidth ? 20 : (isMobileWidth ? 24 : 32);
  double get cardRadius => isCompactWidth ? 20 : 24;
  double get fieldGap => isCompactWidth ? 16 : 20;
  double get sectionGap => isShortHeight ? 24 : (isCompactWidth ? 28 : 32);
  double get buttonHeight => isCompactWidth ? 48 : 56;
  double get buttonRadius => isCompactWidth ? 14 : 16;
  double get buttonTextSize => isCompactWidth ? 15 : 16;
  double get bodyTextSize => isCompactWidth ? 14 : 16;
  double get mobileBrandIconSize => isCompactWidth ? 48 : 56;
  double get mobileTitleSize => isCompactWidth ? 22 : 24;
  double get desktopWelcomeSize => isShortHeight ? 26 : 28;
  double get brandIconSize => isShortHeight ? 32 : 40;
  double get brandTitleSize => isShortHeight ? 22 : 24;
  double get heroTitleSize {
    if (width >= 1200) return 48;
    if (width >= 900) return isShortHeight ? 32 : 40;
    return 28;
  }

  double get heroSubtitleSize => isShortHeight ? 16 : 18;
}