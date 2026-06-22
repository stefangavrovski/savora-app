import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/constants.dart';
import 'package:savora_app/core/router.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/core/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:savora_app/features/auth/providers/auth_provider.dart';
import 'package:savora_app/features/profile/providers/profile_provider.dart';

final customerStatsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final data = await supabase
      .rpc('get_customer_stats', params: {'p_user_id': userId})
      .maybeSingle();

  return data != null ? Map<String, dynamic>.from(data as Map) : null;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final statsAsync = ref.watch(customerStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context, ref, profileAsync.value),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentProfileProvider);
              ref.invalidate(customerStatsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Avatar + name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primarySurface,
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.fullName.isNotEmpty
                                    ? profile.fullName[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.displayMedium
                                    .copyWith(color: AppColors.primary),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(profile.fullName, style: AppTextStyles.titleLarge),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          profile.role == 'business_owner'
                              ? 'Business Owner'
                              : profile.role == 'admin'
                                  ? 'Admin'
                                  : 'Customer',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Stats row — only for customers
                if (profile.isCustomer)
                  statsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (stats) {
                      final bagsRescued = stats?['total_bags_rescued'] ?? 0;
                      final weightKg = stats?['total_weight_saved_grams'] != null
                          ? (stats!['total_weight_saved_grams'] as num).toDouble() / 1000
                          : 0.0;
                      final moneySaved = stats?['total_money_saved'] != null
                          ? (stats!['total_money_saved'] as num).toDouble()
                          : 0.0;

                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              value: '$bagsRescued',
                              label: 'Bags\nRescued',
                            ),
                            Container(
                                width: 1,
                                height: 40,
                                color: AppColors.white.withValues(alpha: 0.3)),
                            _StatItem(
                              value: '${weightKg.toStringAsFixed(1)} kg',
                              label: 'Food\nSaved',
                            ),
                            Container(
                                width: 1,
                                height: 40,
                                color: AppColors.white.withValues(alpha: 0.3)),
                            _StatItem(
                              value: AppConstants.formatMKD(moneySaved),
                              label: 'Money\nSaved',
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: AppSpacing.md),

                // Info section
                _SectionHeader(title: 'Account'),
                _InfoTile(
                  icon: Icons.person_outline,
                  label: 'Full name',
                  value: profile.fullName,
                ),
                if (profile.phone != null && profile.phone!.isNotEmpty)
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: profile.phone!,
                  )
                else
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: 'Not set',
                    valueColor: AppColors.textDisabled,
                  ),

                const SizedBox(height: AppSpacing.md),

                // Navigation section
                _SectionHeader(title: 'Quick Access'),

                if (profile.isCustomer) ...[
                  _NavTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'My Reservations',
                    onTap: () => context.go(AppRoutes.myReservations),
                  ),
                  _NavTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => context.go(AppRoutes.notifications),
                  ),
                ],

                if (profile.isBusinessOwner) ...[
                  _NavTile(
                    icon: Icons.storefront_outlined,
                    label: 'My Business',
                    onTap: () => context.push(AppRoutes.businessDashboard),
                  ),
                  _NavTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => context.go(AppRoutes.notifications),
                  ),
                ],

                if (profile.isAdmin)
                  _NavTile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin Panel',
                    onTap: () => context.push(AppRoutes.adminPanel),
                  ),

                const SizedBox(height: AppSpacing.md),

                // Sign out
                _SectionHeader(title: 'Account Actions'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      'Sign out',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.error),
                    ),
                    onTap: () async {
                      await supabase.auth.signOut();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, profile) {
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.fullName);
    final phoneController = TextEditingController(text: profile.phone ?? '');
    XFile? pickedAvatar;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 600);
                  if (image != null) {
                    setDialogState(() => pickedAvatar = image);
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primarySurface,
                  backgroundImage: pickedAvatar != null
                      ? FileImage(File(pickedAvatar!.path))
                      : (profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null) as ImageProvider?,
                  child: pickedAvatar == null && profile.avatarUrl == null
                      ? const Icon(Icons.camera_alt_outlined,
                          color: AppColors.primary)
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);

                String? avatarUrl;
                if (pickedAvatar != null) {
                  final bytes = await pickedAvatar!.readAsBytes();
                  final ext = pickedAvatar!.name.split('.').last;
                  final userId = supabase.auth.currentUser!.id;
                  final path =
                      '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
                  await supabase.storage.from('avatars').uploadBinary(
                        path,
                        bytes,
                        fileOptions: FileOptions(contentType: 'image/$ext'),
                      );
                  avatarUrl =
                      supabase.storage.from('avatars').getPublicUrl(path);
                }

                await ref.read(profileNotifierProvider.notifier).updateProfile(
                      fullName: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      avatarUrl: avatarUrl,
                    );
                ref.invalidate(currentProfileProvider);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.8)),
          textAlign: TextAlign.center,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: AppTextStyles.bodyMedium),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}