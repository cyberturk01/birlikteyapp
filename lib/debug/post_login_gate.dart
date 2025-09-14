// lib/debug/post_login_gate.dart (yeni dosya)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/login_page.dart';
import '../pages/family/family_onboarding_page.dart';
import '../providers/family_provider.dart';

class PostLoginGate extends StatelessWidget {
  const PostLoginGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, auth) {
        if (auth.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('DEBUG — PostLoginGate')),
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                },
                child: const Text('Go to Login'),
              ),
            ),
          );
        }
        if (auth.data == null) {
          return const Scaffold(body: Center(child: Text('Not signed in')));
        }

        return Consumer<FamilyProvider>(
          builder: (_, fam, __) {
            return Scaffold(
              appBar: AppBar(title: const Text('DEBUG — PostLoginGate')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text('User: ${auth.data?.uid}'),
                    const SizedBox(height: 8),
                    Text('familyId: ${fam.familyId ?? "(null)"}'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        await fam.loadActiveFamily();
                        // ekranda hemen güncellenecek
                      },
                      child: const Text('Load active family'),
                    ),
                    const SizedBox(height: 8),
                    if (fam.familyId == null)
                      FilledButton.tonal(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FamilyOnboardingPage(),
                            ),
                          );
                        },
                        child: const Text('Go to Onboarding'),
                      ),
                    if (fam.familyId != null)
                      FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Family OK: ${fam.familyId}'),
                            ),
                          );
                        },
                        child: const Text('Family OK (stay here)'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
