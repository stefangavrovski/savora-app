import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/admin/providers/admin_provider.dart';
import 'package:savora_app/features/business/models/business.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessReviewScreen extends ConsumerWidget {
  final String businessId;

  const BusinessReviewScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessDetailProvider(businessId));
    final docsAsync = ref.watch(businessDocumentsProvider(businessId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Review Application', style: AppTextStyles.titleMedium),
      ),
      body: businessAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
        data: (business) {
          if (business == null) {
            return const Center(child: Text('Business not found'));
          }
          return _ReviewBody(
            business: business,
            docsAsync: docsAsync,
            ref: ref,
          );
        },
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  final Business business;
  final AsyncValue<List<Map<String, dynamic>>> docsAsync;
  final WidgetRef ref;

  const _ReviewBody({
    required this.business,
    required this.docsAsync,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BusinessInfoCard(business: business),
          const SizedBox(height: AppSpacing.md),
          const _SectionHeader(title: 'Submitted Documents'),
          const SizedBox(height: AppSpacing.sm),
          _DocumentsSection(docsAsync: docsAsync),
          const SizedBox(height: AppSpacing.xl),
          _ActionButtons(business: business, ref: ref),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _BusinessInfoCard extends StatelessWidget {
  final Business business;

  const _BusinessInfoCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (business.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: CachedNetworkImage(
                    imageUrl: business.logoUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _logoPlaceholder(),
                    errorWidget: (_, __, ___) => _logoPlaceholder(),
                  ),
                )
              else
                _logoPlaceholder(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      business.category.toString().split('.').last.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Address', value: business.address),
          _InfoRow(label: 'EDB', value: business.edb),
          _InfoRow(label: 'EMBS', value: business.embs),
          if (business.phone != null)
            _InfoRow(label: 'Phone', value: business.phone!),
          if (business.description != null)
            _InfoRow(label: 'Description', value: business.description!),
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child:
          Icon(Icons.storefront_outlined, color: AppColors.primary, size: 32),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> docsAsync;

  const _DocumentsSection({required this.docsAsync});

  @override
  Widget build(BuildContext context) {
    return docsAsync.when(
      loading: () => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.white,
        child: Column(
          children: List.generate(
            3,
            (_) => Container(
              height: 64,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => Text('Could not load documents: $e',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
      data: (docs) {
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text('No documents uploaded',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.warning)),
              ],
            ),
          );
        }

        return Column(
          children: docs.map((doc) => _DocumentTile(doc: doc)).toList(),
        );
      },
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final Map<String, dynamic> doc;

  const _DocumentTile({required this.doc});

  String get _label {
    switch (doc['document_type'] as String?) {
      case 'edb_certificate':
        return 'EDB Certificate';
      case 'embs_certificate':
        return 'EMBS Certificate';
      case 'ownership_proof':
        return 'Ownership Proof';
      default:
        return doc['document_type'] as String? ?? 'Document';
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = doc['signed_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.description_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
                Text('Tap to view',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textDisabled)),
              ],
            ),
          ),
          if (url != null)
            IconButton(
              icon:
                  Icon(Icons.open_in_new, color: AppColors.primary, size: 20),
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            )
          else
            Icon(Icons.link_off, color: AppColors.textDisabled, size: 20),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatefulWidget {
  final Business business;
  final WidgetRef ref;

  const _ActionButtons({required this.business, required this.ref});

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _loading = false;

  Future<void> _approve() async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Approve Business?',
      message:
          '${widget.business.name} will be marked as verified and go live on the platform.',
      confirmLabel: 'Approve',
      confirmColor: AppColors.success,
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      await widget.ref
          .read(adminActionsProvider.notifier)
          .approveBusiness(widget.business.id);
      widget.ref.invalidate(pendingBusinessesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.business.name} approved!'),
          backgroundColor: AppColors.success,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Reject Application?',
      message:
          '${widget.business.name} will be rejected. The business owner will be notified.',
      confirmLabel: 'Reject',
      confirmColor: AppColors.error,
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      await widget.ref
          .read(adminActionsProvider.notifier)
          .rejectBusiness(widget.business.id);
      widget.ref.invalidate(pendingBusinessesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.business.name} rejected.'),
          backgroundColor: AppColors.error,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title, style: AppTextStyles.titleMedium),
            content: Text(message, style: AppTextStyles.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel,
                    style: TextStyle(
                        color: confirmColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.business.verificationStatus != 'pending') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Status: ${widget.business.verificationStatus}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _loading ? null : _reject,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: _loading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.error),
                  )
                : const Text('Reject',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton(
            onPressed: _loading ? null : _approve,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Approve',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary, fontWeight: FontWeight.w600));
  }
}