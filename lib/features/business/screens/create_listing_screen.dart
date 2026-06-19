import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:savora_app/core/supabase_client.dart';
import 'package:savora_app/core/theme.dart';
import 'package:savora_app/features/business/providers/business_provider.dart';
import 'package:savora_app/features/listings/providers/listing_provider.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _originalCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _weightCtrl = TextEditingController();

  DateTime _pickupStart = DateTime.now().add(const Duration(hours: 1));
  DateTime _pickupEnd = DateTime.now().add(const Duration(hours: 3));

  XFile? _imageFile;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _descCtrl, _priceCtrl, _originalCtrl, _qtyCtrl, _weightCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (image != null) setState(() => _imageFile = image);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showDateTimePicker(context, isStart ? _pickupStart : _pickupEnd);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _pickupStart = picked;
        if (_pickupEnd.isBefore(_pickupStart)) {
          _pickupEnd = _pickupStart.add(const Duration(hours: 1));
        }
      } else {
        _pickupEnd = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupEnd.isBefore(_pickupStart) ||
        _pickupEnd.isAtSameMomentAs(_pickupStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup end must be after pickup start.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final business = await ref.read(myBusinessProvider.future);

    if (!mounted) return;

    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business not found.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      String? imageUrl;

      // Upload image if selected
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final ext = _imageFile!.name.split('.').last;
        final path =
            '${business.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage
            .from('listing-images')
            .uploadBinary(path, bytes,
                fileOptions: FileOptions(contentType: 'image/$ext'));
        imageUrl = supabase.storage.from('listing-images').getPublicUrl(path);
      }

      await ref.read(createListingProvider.notifier).createListing(
            businessId: business.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            price: double.parse(_priceCtrl.text.trim()),
            originalValue: double.parse(_originalCtrl.text.trim()),
            quantityTotal: int.parse(_qtyCtrl.text.trim()),
            pickupStart: _pickupStart,
            pickupEnd: _pickupEnd,
            estWeightGrams: _weightCtrl.text.trim().isNotEmpty
                ? int.tryParse(_weightCtrl.text.trim())
                : null,
            imageUrl: imageUrl,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created successfully!')),
      );
      context.pop();
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
      appBar: AppBar(title: const Text('Create Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(File(_imageFile!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.primary, size: 40),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Add photo (optional)',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.primary)),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: GestureDetector(
                              onTap: () => setState(() => _imageFile = null),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Bag title *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description (what\'s inside?)'),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: 'Price (MKD) *'),
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
                      controller: _originalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: 'Original value *'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: 'Quantity *'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v) == null || int.parse(v) < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Est. weight (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Pickup Window', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),

              _TimePickerTile(
                label: 'Pickup starts',
                value: _pickupStart,
                onTap: () => _pickTime(true),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TimePickerTile(
                label: 'Pickup ends',
                value: _pickupEnd,
                onTap: () => _pickTime(false),
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
                    : const Text('Publish Listing'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> showDateTimePicker(
    BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 7)),
  );
  if (date == null) return null;

  if (!context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  String _format(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                Text(_format(value), style: AppTextStyles.bodyMedium),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_outlined,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}