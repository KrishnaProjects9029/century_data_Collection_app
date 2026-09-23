import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../models/student_model.dart';
import '../../models/pending_submission_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/student_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/photo_picker_card.dart';

class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key});

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  // Text controllers
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _siblingCtrl = TextEditingController();
  final _motherCtrl = TextEditingController();
  final _fatherCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _otherAreaCtrl = TextEditingController();
  final _otherLandmarkCtrl = TextEditingController();

  // Dropdown values
  String? _parents;
  String? _area;
  String? _landmark;

  // Photo
  File? _photoFile;
  String? _photoError;

  bool _submitting = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _middleNameCtrl, _surnameCtrl, _schoolCtrl,
      _siblingCtrl, _motherCtrl, _fatherCtrl, _addressCtrl,
      _otherAreaCtrl, _otherLandmarkCtrl,
    ]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────

  bool _validate() {
    bool valid = _formKey.currentState!.validate();

    // Photo is optional per spec — no hard block
    // But validate size if selected
    if (_photoFile != null) {
      final error = Validators.photoSize(_photoFile!.lengthSync());
      if (error != null) {
        setState(() => _photoError = error);
        valid = false;
      } else {
        setState(() => _photoError = null);
      }
    }

    if (!valid) {
      // Scroll to top to show errors
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
    }
    return valid;
  }

  // ── Duplicate check ──────────────────────────

  Future<bool> _checkDuplicate() async {
    final fs = StudentService();
    return fs.checkDuplicate(
      firstName: _firstNameCtrl.text.trim(),
      surname: _surnameCtrl.text.trim(),
      schoolName: _schoolCtrl.text.trim(),
      motherContact: _motherCtrl.text.trim(),
      fatherContact: _fatherCtrl.text.trim(),
    );
  }

  // ── Submit ───────────────────────────────────

  Future<void> _submit() async {
    if (!_validate()) return;

    // Confirm dialog
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Submit Record',
      message: 'Are you sure you want to submit this student record?',
      confirmText: 'SUBMIT',
      icon: Icons.check_circle_outline,
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);

    try {
      final userAsync = ref.read(currentUserModelProvider);
      final user = userAsync.valueOrNull;
      if (user == null) throw Exception('Not authenticated');

      final isOnline = await ref
          .read(connectivityManagerProvider)
          .isConnected;

      // Check duplicate
      final isDuplicate = await _checkDuplicate();
      if (isDuplicate && mounted) {
        final proceed = await showConfirmationDialog(
          context: context,
          title: 'Possible Duplicate',
          message:
              'A similar student record already exists. Do you want to continue?',
          confirmText: 'CONTINUE',
          icon: Icons.warning_amber_outlined,
        );
        if (proceed != true) {
          setState(() => _submitting = false);
          return;
        }
      }

      String photoUrl = '';

      if (!isOnline) {
        // Save to offline queue
        final pending = PendingSubmissionModel(
          localId: const Uuid().v4(),
          studentData: _buildStudentData(user.id, user.name, ''),
          localPhotoPath: _photoFile?.path,
          createdLocally: DateFormatter.nowIST(),
        );
        final offlineService = OfflineQueueService(
          StudentService(),
          StorageService(),
        );
        await offlineService.save(pending);
        if (mounted) _showSuccess(isOffline: true);
        return;
      }

      // Online — upload photo first
      if (_photoFile != null) {
        final storageService = StorageService();
        final (url, error) = await storageService.uploadStudentPhoto(
          imageFile: _photoFile!,
          makerUid: user.id,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        if (error != null) throw Exception(error);
        photoUrl = url ?? '';
      }

      // Save to Firestore
      final fs = StudentService();
      final now = DateTime.now().toUtc();
      final student = StudentModel(
        id: '',
        serialNumber: 0,
        firstName: _firstNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim(),
        surname: _surnameCtrl.text.trim(),
        schoolName: _schoolCtrl.text.trim(),
        siblingClass: _siblingCtrl.text.trim(),
        parents: _parents ?? '',
        motherContact: _motherCtrl.text.trim(),
        fatherContact: _fatherCtrl.text.trim(),
        fullAddress: _addressCtrl.text.trim(),
        area: _area ?? '',
        otherArea: _area == 'Other' ? _otherAreaCtrl.text.trim() : '',
        landmark: _landmark ?? '',
        otherLandmark: _landmark == 'Other' ? _otherLandmarkCtrl.text.trim() : '',
        photoUrl: photoUrl,
        makerUserId: user.id,
        makerName: user.name,
        submittedAt: now,
      );

      final (_, error) = await fs.addStudent(student);
      if (error != null) throw Exception(error);

      if (mounted) _showSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Map<String, dynamic> _buildStudentData(
      String uid, String name, String photoUrl) {
    return {
      'firstName': _firstNameCtrl.text.trim(),
      'middleName': _middleNameCtrl.text.trim(),
      'surname': _surnameCtrl.text.trim(),
      'schoolName': _schoolCtrl.text.trim(),
      'siblingClass': _siblingCtrl.text.trim(),
      'parents': _parents ?? '',
      'motherContact': _motherCtrl.text.trim(),
      'fatherContact': _fatherCtrl.text.trim(),
      'fullAddress': _addressCtrl.text.trim(),
      'area': _area ?? '',
      'otherArea': _area == 'Other' ? _otherAreaCtrl.text.trim() : '',
      'landmark': _landmark ?? '',
      'otherLandmark':
          _landmark == 'Other' ? _otherLandmarkCtrl.text.trim() : '',
      'photoUrl': photoUrl,
      'makerUserId': uid,
      'makerName': name,
      'submittedAt': DateTime.now().toUtc().toIso8601String(),
      'isDeleted': false,
    };
  }

  void _showSuccess({bool isOffline = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 60),
        title: const Text('Success!', textAlign: TextAlign.center),
        content: Text(
          isOffline
              ? 'Form saved locally. Will be submitted when internet is available.'
              : 'Student record submitted successfully.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // dialog
                  _resetForm();
                },
                child: const Text('Add Another Student'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // dialog
                  Navigator.pop(context); // form
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _parents = null;
      _area = null;
      _landmark = null;
      _photoFile = null;
      _photoError = null;
      _uploadProgress = 0;
    });
    for (final c in [
      _firstNameCtrl, _middleNameCtrl, _surnameCtrl, _schoolCtrl,
      _siblingCtrl, _motherCtrl, _fatherCtrl, _addressCtrl,
      _otherAreaCtrl, _otherLandmarkCtrl,
    ]) {
      c.clear();
    }
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  // ── Build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),

          // Upload progress
          if (_submitting && _uploadProgress > 0 && _uploadProgress < 1)
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),

          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('Personal Information'),
                    const SizedBox(height: 12),

                    // 1. First Name
                    _buildTextField(
                      controller: _firstNameCtrl,
                      label: 'Student First Name *',
                      validator: (v) =>
                          Validators.required(v, 'Student First Name'),
                    ),
                    const SizedBox(height: 14),

                    // 2. Middle Name
                    _buildTextField(
                      controller: _middleNameCtrl,
                      label: 'Middle Name',
                    ),
                    const SizedBox(height: 14),

                    // 3. Surname
                    _buildTextField(
                      controller: _surnameCtrl,
                      label: 'Surname *',
                      validator: (v) => Validators.required(v, 'Surname'),
                    ),
                    const SizedBox(height: 14),

                    // 4. School Name
                    _buildTextField(
                      controller: _schoolCtrl,
                      label: 'School Name *',
                      validator: (v) => Validators.required(v, 'School Name'),
                    ),
                    const SizedBox(height: 14),

                    // 5. Bro/Sis In Class
                    _buildTextField(
                      controller: _siblingCtrl,
                      label: 'Bro/Sis In Class (STD & DIV)',
                      hint: 'e.g. Brother - 8 A',
                    ),
                    const SizedBox(height: 22),

                    _sectionHeader('Family Information'),
                    const SizedBox(height: 12),

                    // 6. Parents
                    _buildDropdown(
                      label: 'Parents *',
                      value: _parents,
                      items: AppConstants.parentOptions,
                      onChanged: (v) => setState(() => _parents = v),
                      validator: (v) =>
                          Validators.dropdown(v, 'Parents'),
                    ),
                    const SizedBox(height: 14),

                    // 7. Mother Contact
                    _buildTextField(
                      controller: _motherCtrl,
                      label: 'Mother Contact No.',
                      hint: '10-digit mobile number',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      validator: (v) => Validators.mobileNumber(v),
                    ),
                    const SizedBox(height: 14),

                    // 8. Father Contact
                    _buildTextField(
                      controller: _fatherCtrl,
                      label: 'Father Contact No.',
                      hint: '10-digit mobile number',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      validator: (v) => Validators.mobileNumber(v),
                    ),
                    const SizedBox(height: 22),

                    _sectionHeader('Address Details'),
                    const SizedBox(height: 12),

                    // 9. Full Address
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address In Full *',
                        hintText:
                            'Room No. --- Chawl / Building No. --- Room No. / Area',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          Validators.required(v, 'Address In Full'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 14),

                    // 10. Area
                    _buildDropdown(
                      label: 'Area *',
                      value: _area,
                      items: AppConstants.areaOptions,
                      onChanged: (v) =>
                          setState(() => _area = v),
                      validator: (v) => Validators.dropdown(v, 'an Area'),
                    ),

                    // 11. Other Area (conditional)
                    if (_area == 'Other') ...[
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _otherAreaCtrl,
                        label: 'Other Area *',
                        validator: (v) =>
                            Validators.required(v, 'Other Area'),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // 12. Landmark
                    _buildDropdown(
                      label: 'Landmark *',
                      value: _landmark,
                      items: AppConstants.landmarkOptions,
                      onChanged: (v) => setState(() => _landmark = v),
                      validator: (v) =>
                          Validators.dropdown(v, 'a Landmark'),
                    ),

                    // 13. Other Landmark (conditional)
                    if (_landmark == 'Other') ...[
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _otherLandmarkCtrl,
                        label: 'Other Landmark *',
                        validator: (v) =>
                            Validators.required(v, 'Other Landmark'),
                      ),
                    ],
                    const SizedBox(height: 22),

                    _sectionHeader('Student Photo'),
                    const SizedBox(height: 12),

                    // 14. Photo picker
                    PhotoPickerCard(
                      imageFile: _photoFile,
                      onImageSelected: (file) =>
                          setState(() => _photoFile = file),
                      errorText: _photoError,
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SpinKitThreeBounce(
                                color: Colors.white, size: 22)
                            : const Text('SUBMIT RECORD'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
