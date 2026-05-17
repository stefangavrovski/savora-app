import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:savora_app/core/router.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/business/providers/business_provider.dart';

class BusinessOnboardingScreen extends ConsumerStatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  ConsumerState<BusinessOnboardingScreen> createState() =>
      _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState
    extends ConsumerState<BusinessOnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1 fields
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _openCtrl = TextEditingController();
  final _closeCtrl = TextEditingController();
  String _category = 'bakery';
  final _step1Key = GlobalKey<FormState>();

  // Step 2 fields
  final _edbCtrl = TextEditingController();
  final _embsCtrl = TextEditingController();
  final _step2Key = GlobalKey<FormState>();
  PlatformFile? _edbFile;
  PlatformFile? _embsFile;

  bool _submitting = false;
  String? _businessId;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _descCtrl, _addressCtrl, _latCtrl, _lngCtrl,
      _phoneCtrl, _openCtrl, _closeCtrl, _edbCtrl, _embsCtrl,
    ]) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (!_step1Key.currentState!.validate()) return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage--);
  }

  Future<void> _pickFile(bool isEdb) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      if (isEdb) {
        _edbFile = result.files.first;
      } else {
        _embsFile = result.files.first;
      }
    });
  }

  Future<void> _submit() async {
    if (!_step2Key.currentState!.validate()) return;
    if (_edbFile == null || _embsFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both documents.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // 1. Insert the business row
      final businessId = await ref
          .read(businessOnboardingProvider.notifier)
          .registerBusiness(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            latitude: double.parse(_latCtrl.text.trim()),
            longitude: double.parse(_lngCtrl.text.trim()),
            category: _category,
            edb: _edbCtrl.text.trim(),
            embs: _embsCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            openingTime: _openCtrl.text.trim().isEmpty ? null : _openCtrl.text.trim(),
            closingTime: _closeCtrl.text.trim().isEmpty ? null : _closeCtrl.text.trim(),
          );
      _businessId = businessId;

      // 2. Upload EDB document
      final edbPath = '$businessId/edb_${DateTime.now().millisecondsSinceEpoch}.${_edbFile!.extension}';
      await supabase.storage
          .from('business-documents')
          .uploadBinary(edbPath, _edbFile!.bytes!);

      await ref.read(businessOnboardingProvider.notifier).uploadDocument(
            businessId: businessId,
            documentType: 'edb_certificate',
            storagePath: edbPath,
          );

      // 3. Upload EMBS document
      final embsPath = '$businessId/embs_${DateTime.now().millisecondsSinceEpoch}.${_embsFile!.extension}';
      await supabase.storage
          .from('business-documents')
          .uploadBinary(embsPath, _embsFile!.bytes!);

      await ref.read(businessOnboardingProvider.notifier).uploadDocument(
            businessId: businessId,
            documentType: 'embs_certificate',
            storagePath: embsPath,
          );

      if (!mounted) return;
      // Go to final confirmation page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = 2);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Register Your Business'),
        leading: _currentPage > 0 && _currentPage < 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _prevPage,
              )
            : const BackButton(),
      ),
      body: Column(
        children: [
          // Progress indicator
          if (_currentPage < 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: List.generate(2, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3Confirmation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Info', style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tell us about your business.',
              style:
                  AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Business name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: const [
                DropdownMenuItem(value: 'bakery', child: Text('Bakery')),
                DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
                DropdownMenuItem(value: 'cafe', child: Text('Café')),
                DropdownMenuItem(value: 'market', child: Text('Market')),
                DropdownMenuItem(value: 'deli', child: Text('Deli')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _addressCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Address *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Latitude *'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Longitude *'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tip: Open Google Maps, long-press your location, and copy the coordinates.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration:
                  const InputDecoration(labelText: 'Phone (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _openCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Opening time', hintText: '08:00'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _closeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Closing time', hintText: '20:00'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Continue'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verification', style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'We need to verify your business. This takes 1–2 business days.',
              style:
                  AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _edbCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'EDB (Unique Tax Number) *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _embsCtrl,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                  labelText: 'EMBS (Business ID Number) *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Documents', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Upload proof of EDB and EMBS (PDF, JPG, or PNG).',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            _DocumentPickerTile(
              label: 'EDB Document *',
              file: _edbFile,
              onPick: () => _pickFile(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DocumentPickerTile(
              label: 'EMBS Document *',
              file: _embsFile,
              onPick: () => _pickFile(false),
            ),

            const SizedBox(height: AppSpacing.xl),

            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Text('Submit Application'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Confirmation() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Application Submitted!', style: AppTextStyles.displayMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your business is under review. We\'ll notify you once it\'s approved. Usually within 1–2 business days.',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(myBusinessProvider);
              context.go(AppRoutes.businessDashboard);
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }
}

class _DocumentPickerTile extends StatelessWidget {
  final String label;
  final PlatformFile? file;
  final VoidCallback onPick;

  const _DocumentPickerTile({
    required this.label,
    required this.file,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.primarySurface : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasFile ? AppColors.primary : AppColors.border,
            style: hasFile ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.insert_drive_file_outlined : Icons.upload_file,
              color: hasFile ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelLarge),
                  if (hasFile)
                    Text(
                      file!.name,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Tap to upload',
                      style: AppTextStyles.bodySmall,
                    ),
                ],
              ),
            ),
            if (hasFile)
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ],
        ),
      ),
    );
  }
}