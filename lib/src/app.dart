import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';                    // ✅ neon theme + gradient
import 'state.dart';                    // ✅ authProvider
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WMS Y tế xã',

        // ✅ ép dùng neon dark theme của bạn
        themeMode: ThemeMode.dark,
        theme: buildNeonTheme(Brightness.dark),

        // ✅ phủ nền gradient tím–xanh cho toàn bộ app
        builder: (context, child) =>
            NeonGradientBackground(child: child ?? const SizedBox()),

        // ✅ điều hướng theo trạng thái đăng nhập
        home: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends ConsumerWidget {
  const _RootRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return switch (auth) {
      Unauth()        => const LoginScreen(),
      Authenticated() => const HomeScreen(),
    };
  }
}
