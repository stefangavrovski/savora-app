import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/reservations/providers/reservation_provider.dart';

class PickupCounterScreen extends ConsumerStatefulWidget {
  const PickupCounterScreen({super.key});

  @override
  ConsumerState<PickupCounterScreen> createState() =>
      _PickupCounterScreenState();
}

class _PickupCounterScreenState extends ConsumerState<PickupCounterScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _lastCompleted;
  String? _errorMessage;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final code = _codeCtrl.text.trim().replaceAll(' ', '').toUpperCase();
    if (code.length != 8) {
      setState(() => _errorMessage = 'Enter the full 8-character code.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _lastCompleted = null;
    });

    try {
      final result = await ref
          .read(reservationNotifierProvider.notifier)
          .completeByPickupCode(code);

      if (!mounted) return;
      setState(() {
        _lastCompleted = result;
        _codeCtrl.clear();
      });
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = msg.contains('not found')
            ? 'Code not found. Check and try again.'
            : msg.contains('already')
                ? 'This reservation is already completed.'
                : msg;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Counter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Ask the customer for their 8-character pickup code, then tap Confirm.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Pickup Code', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),

            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 9, // 8 chars + possible space
              style: AppTextStyles.pickupCode.copyWith(
                fontSize: 22,
                letterSpacing: 6,
              ),
              decoration: InputDecoration(
                hintText: 'XXXX XXXX',
                hintStyle: AppTextStyles.pickupCode.copyWith(
                  fontSize: 22,
                  color: AppColors.textDisabled,
                  letterSpacing: 6,
                ),
                counterText: '',
                errorText: _errorMessage,
                suffixIcon: _codeCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _codeCtrl.clear();
                          setState(() => _errorMessage = null);
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _complete(),
            ),
            const SizedBox(height: AppSpacing.lg),

            ElevatedButton(
              onPressed: _loading ? null : _complete,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Text('Confirm Pickup'),
            ),

            // Success card
            if (_lastCompleted != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 40),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Pickup Confirmed!',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.success),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Code: ${AppConstants.formatPickupCode(_lastCompleted!['pickup_code'] ?? '')}',
                      style: AppTextStyles.pickupCode.copyWith(
                          color: AppColors.success, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}