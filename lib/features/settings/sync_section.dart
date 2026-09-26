import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/sync/sync_providers.dart';

/// Profile "Sync" section: configuration status → sign-in form → signed-in
/// controls (sync now / sign out). Everything degrades to a plain status
/// tile when Supabase wasn't configured at build time.
class SyncSection extends ConsumerStatefulWidget {
  const SyncSection({super.key});

  @override
  ConsumerState<SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends ConsumerState<SyncSection> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      _message = e.message;
    } catch (e) {
      _message = '$e';
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _signIn() => _run(() async {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        await ref.read(syncControllerProvider.notifier).syncNow();
      });

  Future<void> _signUp() => _run(() async {
        final res = await Supabase.instance.client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (res.session == null) {
          _message = 'Check your inbox to confirm your account, then sign in.';
        } else {
          await ref.read(syncControllerProvider.notifier).syncNow();
        }
      });

  Future<void> _signOut() => _run(() async {
        await Supabase.instance.client.auth.signOut();
      });

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(supabaseConfiguredProvider);
    final auth = ref.watch(authStateProvider).value;
    if (!configured) return _notConfigured();

    final session = auth?.session ?? Supabase.instance.client.auth.currentSession;
    if (session == null) return _signInForm(context);
    return _account(context, session.user.email ?? session.user.id);
  }

  Widget _notConfigured() => const ListTile(
        leading: Icon(Icons.cloud_off_rounded),
        title: Text('Cloud sync not configured'),
        subtitle: Text(
          'Rebuild with --dart-define=SUPABASE_URL=… and '
          '--dart-define=SUPABASE_ANON_KEY=… to enable sync.',
        ),
      );

  Widget _signInForm(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            key: const Key('sync-email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            key: const Key('sync-password'),
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _message!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('sync-sign-up'),
                onPressed: _busy ? null : _signUp,
                child: const Text('Create account'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('sync-sign-in'),
                onPressed: _busy ? null : _signIn,
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _account(BuildContext context, String who) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncControllerProvider);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_done_rounded),
          title: const Text('Signed in'),
          subtitle: Text(who),
        ),
        ListTile(
          key: const Key('sync-now'),
          leading: sync.running
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded),
          title: const Text('Sync now'),
          subtitle: Text(
            _syncSubtitle(sync),
            style: TextStyle(
              fontSize: 12,
              color: sync.hasError ? theme.colorScheme.error : null,
            ),
          ),
          enabled: !sync.running && !_busy,
          onTap: () => ref.read(syncControllerProvider.notifier).syncNow(),
        ),
        ListTile(
          key: const Key('sync-sign-out'),
          leading: const Icon(Icons.logout_rounded),
          title: const Text('Sign out'),
          subtitle: const Text('Local data stays on this device'),
          enabled: !_busy,
          onTap: _signOut,
        ),
      ],
    );
  }

  String _syncSubtitle(SyncState state) {
    if (state.lastError != null) return 'Error: ${state.lastError}';
    if (state.running) return 'Syncing…';
    if (state.lastSyncAt != null) {
      return 'Last sync ${DateFormat('MMM d, HH:mm').format(state.lastSyncAt!.toLocal())}';
    }
    return 'Pulls remote changes, then uploads local ones.';
  }
}
