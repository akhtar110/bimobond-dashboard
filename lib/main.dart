import 'package:bimo_bond_dashboard/features/auth/presentation/pages/login_page.dart';
import 'package:bimo_bond_dashboard/features/users/presentation/bloc/user_detail_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/localization.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';
import 'features/users/presentation/bloc/users_bloc.dart';
import 'features/posts/presentation/bloc/posts_bloc.dart';
import 'features/videos/presentation/bloc/videos_bloc.dart';
import 'features/auctions/presentation/bloc/auctions_bloc.dart';
import 'features/categories/presentation/bloc/categories_bloc.dart';
import 'features/gifts/presentation/bloc/gifts_bloc.dart';
import 'features/reports/presentation/bloc/reports_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();
  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<SettingsCubit>()),
        BlocProvider(create: (_) => di.sl<UsersBloc>()),
        BlocProvider(create: (_) => di.sl<PostsBloc>()),
        BlocProvider(create: (_) => di.sl<VideosBloc>()),
        BlocProvider(create: (_) => di.sl<UserDetailBloc>()),
        BlocProvider(create: (_) => di.sl<AuctionsBloc>()),
        BlocProvider(create: (_) => di.sl<GiftsBloc>()),
        BlocProvider(create: (_) => di.sl<ReportsBloc>()),
        BlocProvider(
          create: (_) =>
              di.sl<CategoriesBloc>()..add(LoadCategoriesEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(create: (_) => di.sl<NotificationsBloc>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (_, settings) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.l10n.t('appTitle'),
            theme: AppTheme.lightTheme(settings.locale),
            darkTheme: AppTheme.darkTheme(settings.locale),
            themeMode: settings.themeMode,
            locale: settings.locale,
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
              return BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated) {
                    return child!;
                  }
                  if (state is Unauthenticated) {
                    return const LoginPage();
                  }
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
