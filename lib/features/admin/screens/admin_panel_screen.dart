import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/admin/providers/admin_provider.dart';
import 'package:savora_app/features/business/providers/business_provider.dart';
import 'package:savora_app/features/business/models/business.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:savora_app/core/supabase_client.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingBusinessesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: Text('Admin Panel', style: AppTextStyles.titleMedium),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign out',
              onPressed: () async {
                await supabase.auth.signOut();
              },
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                child: pendingAsync.when(
                  data: (list) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Pending'),
                      if (list.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${list.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ]
                    ],
                  ),
                  loading: () => const Text('Pending'),
                  error: (_, _) => const Text('Pending'),
                ),
              ),
              const Tab(text: 'All Users'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingBusinessesTab(),
            _AllUsersTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingBusinessesTab extends ConsumerWidget {
  const _PendingBusinessesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingBusinessesProvider);

    return pendingAsync.when(
      loading: () => _buildShimmer(),
      error: (e, _) => Center(
        child: Text('Error: $e', style: AppTextStyles.bodyMedium),
      ),
      data: (businesses) {
        if (businesses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.success),
                const SizedBox(height: AppSpacing.md),
                Text('No pending applications',
                    style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text('All businesses have been reviewed.',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(pendingBusinessesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: businesses.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) =>
                _PendingBusinessCard(business: businesses[i]),
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.white,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}

class _PendingBusinessCard extends StatelessWidget {
  final Business business;

  const _PendingBusinessCard({required this.business});

  @override
  Widget build(BuildContext context) {
    final submitted = DateFormat('dd MMM yyyy').format(business.createdAt);

    return InkWell(
      onTap: () => context.push('/admin/review/${business.id}'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.storefront_outlined,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(business.address,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Chip(
                          label: business.category.toString().split('.').last,
                          color: AppColors.primarySurface,
                          textColor: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Submitted $submitted',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textDisabled, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AllUsersTab extends ConsumerWidget {
  const _AllUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.white,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 8,
          itemBuilder: (_, _) => Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
      error: (e, _) => Center(
        child: Text('Error loading users', style: AppTextStyles.bodyMedium),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text('No users found', style: AppTextStyles.bodyMedium),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(allUsersProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: users.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) => _UserTile(user: users[i]),
          ),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final role = user['role'] as String? ?? 'customer';
    final name = user['full_name'] as String? ?? 'Unknown';
    final joined = user['created_at'] != null
        ? DateFormat('dd MMM yyyy')
            .format(DateTime.parse(user['created_at'] as String))
        : '—';

    Color roleColor;
    switch (role) {
      case 'admin':
        roleColor = AppColors.error;
        break;
      case 'business_owner':
        roleColor = AppColors.primary;
        break;
      default:
        roleColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('Joined $joined',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textDisabled, fontSize: 11)),
              ],
            ),
          ),
          _Chip(
            label: role.replaceAll('_', ' '),
            color: roleColor.withValues(alpha: 0.12),
            textColor: roleColor,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Chip(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}