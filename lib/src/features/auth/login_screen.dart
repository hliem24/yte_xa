import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms_yte_xa_ai/src/state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _u = TextEditingController(text: 'admin');
  final _p = TextEditingController(text: '123456');
  String? _err;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: const Color(0xFF18163A), // tone tím đậm
        title: const Row(
          children: [
            Icon(Icons.local_hospital_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Kho Y tế xã',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          if (auth is Authenticated)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF4E46A3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 18, color: Colors.white),
                label: const Text('Đăng xuất',
                    style: TextStyle(fontSize: 13, color: Colors.white)),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            elevation: 6,
            color: cs.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle,
                      size: 64, color: cs.primary.withOpacity(.9)),
                  const SizedBox(height: 12),
                  const Text(
                    'Đăng nhập hệ thống kho',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _u,
                    decoration: InputDecoration(
                      labelText: 'Tài khoản',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _p,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  if (_err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_err!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              final ok = await ref
                                  .read(authProvider.notifier)
                                  .login(_u.text, _p.text);
                              if (!ok) {
                                setState(() =>
                                    _err = 'Sai tài khoản hoặc mật khẩu');
                              } else {
                                setState(() => _err = null);
                              }
                              setState(() => _busy = false);
                            },
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Đăng nhập',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white)),
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
