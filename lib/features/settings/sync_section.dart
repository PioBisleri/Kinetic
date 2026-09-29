import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/settings/settings.dart';
import '../../core/sync/sync_codec.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/theme/app_theme.dart';

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
    final encEnabled = ref.watch(syncEncryptionEnabledProvider);
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
          key: const Key('sync-encryption'),
          leading: Icon(
            encEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
          ),
          title: const Text('Encryption'),
          subtitle: Text(
            encEnabled
                ? 'End-to-end encrypted — server sees only ciphertext.'
                : 'Set a passphrase to encrypt synced data.',
            style: const TextStyle(fontSize: 12),
          ),
          enabled: !_busy,
          onTap: () => _showEncryptionSheet(context),
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

  void _showEncryptionSheet(BuildContext context) {
    final enabled = ref.read(syncEncryptionEnabledProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) => Consumer(
        builder: (sheetContext, ref, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    enabled ? 'Encryption is on' : 'Set sync passphrase',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    enabled
                        ? 'Your synced data is encrypted with AES-256-GCM. '
                            'The server only sees ciphertext.'
                        : 'Your passphrase derives the encryption key. '
                            'It never leaves this device. If you lose it, '
                            'synced data cannot be recovered.',
                    style: TextStyle(
                      fontSize: 13,
                      color: sheetContext.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!enabled) ...[
                    TextField(
                      key: const Key('sync-passphrase'),
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Passphrase',
                        hintText: 'Minimum 8 characters',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('sync-enable-encryption'),
                      onPressed: () async {
                        final passphrase = sheetContext
                            .findAncestorWidgetOfExactType<TextField>()
                            ?.controller
                            ?.text;
                        if (passphrase == null || passphrase.length < 8) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Passphrase must be at least 8 characters.'),
                            ),
                          );
                          return;
                        }
                        final prefs = ref.read(sharedPreferencesProvider);
                        await prefs.setString('sync.passphrase', passphrase);
                        ref.read(syncEncryptionEnabledProvider.notifier).enable();
                        SyncCodec.encryption = null; // will be re-derived
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: const Text('Enable encryption'),
                    ),
                  ] else ...[
                    ListTile(
                      key: const Key('sync-rotate-passphrase'),
                      leading: const Icon(Icons.password_rounded),
                      title: const Text('Rotate passphrase'),
                      subtitle: const Text(
                        'Re-encrypts all synced data with a new passphrase.',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showRotatePassphraseSheet(context);
                      },
                    ),
                    ListTile(
                      key: const Key('sync-reset-encryption'),
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: const Text('Reset sync'),
                      subtitle: const Text(
                        'Deletes all synced data from the server. '
                        'Local data is untouched.',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showResetSyncDialog(context);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRotatePassphraseSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) => Consumer(
        builder: (sheetContext, ref, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Rotate passphrase',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This re-encrypts all your synced data with a new passphrase. '
                    'Other devices will need the new passphrase to sync.',
                    style: TextStyle(
                      fontSize: 13,
                      color: sheetContext.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('sync-new-passphrase'),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New passphrase',
                      hintText: 'Minimum 8 characters',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('sync-confirm-rotate'),
                    onPressed: () async {
                      final field = sheetContext
                          .findAncestorWidgetOfExactType<TextField>();
                      final newPassphrase = field?.controller?.text;
                      if (newPassphrase == null || newPassphrase.length < 8) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                            content: Text('Passphrase must be at least 8 characters.'),
                          ),
                        );
                        return;
                      }
                      final prefs = ref.read(sharedPreferencesProvider);
                      await prefs.setString('sync.passphrase', newPassphrase);
                      SyncCodec.encryption = null; // will be re-derived
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: const Text('Rotate'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showResetSyncDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset sync?'),
        content: const Text(
          'This deletes all your synced data from the server. '
          'Local data on this device is untouched. '
          'You will need to set a new passphrase to sync again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('sync-confirm-reset'),
            onPressed: () async {
              final prefs = ref.read(sharedPreferencesProvider);
              await prefs.remove('sync.passphrase');
              ref.read(syncEncryptionEnabledProvider.notifier).disable();
              SyncCodec.encryption = null;
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
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
