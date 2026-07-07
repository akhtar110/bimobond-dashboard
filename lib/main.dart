import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/localization.dart';
import 'core/routing/app_router.dart';
import 'core/settings/app_settings_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();
  await di.sl<SettingsCubit>().load();
  await AppLocalizations.preloadBundles();
  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<SettingsCubit>()),
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (previous, current) =>
            previous.locale != current.locale ||
            previous.themeMode != current.themeMode,
        builder: (context, settings) {
          final locale = settings.locale;
          final textDirection = locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr;

          return MaterialApp(
            navigatorKey: AppRouter.rootNavigatorKey,
            debugShowCheckedModeBanner: false,
            restorationScopeId: null,
            onGenerateTitle: (context) =>
                AppLocalizations.ofLocale(locale).t('appTitle'),
            theme: AppTheme.lightTheme(locale),
            darkTheme: AppTheme.darkTheme(locale),
            themeMode: settings.themeMode,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRoutes.root,
            builder: (context, child) {
              return AppSettingsWrapper(
                child: Directionality(
                  textDirection: textDirection,
                  child: AuthGate(
                    navigator: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
