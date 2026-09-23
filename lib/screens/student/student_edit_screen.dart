import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/student_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/photo_picker_card.dart';

class StudentEditScreen extends ConsumerStatefulWidget {
  final StudentModel student;

  const StudentEditScreen({super.key, required this.student});

  @override
  ConsumerState<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends ConsumerState<StudentEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _middleNameCtrl;
  late final TextEditingController _surnameCtrl;
  late final TextEditingController _schoolCtrl;
  late final TextEditingController _siblingCtrl;
  late final TextEditingController _motherCtrl;
  late final TextEditingController _fatherCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _otherAreaCtrl;
  late final TextEditingController _otherLandmarkCtrl;

  late String? _parents;
  late String? _area;
  late String? _landmark;

  File? _newPhotoFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _firstNameCtrl = TextEditingController(text: s.firstName);
    _middleNameCtrl = TextEditingController(text: s.middleName);
    _surnameCtrl = TextEditingController(text: s.surname);
    _schoolCtrl = TextEditingController(text: s.schoolName);
    _siblingCtrl = TextEditingController(text: s.siblingClass);
    _motherCtrl = TextEditingController(text: s.motherContact);
    _fatherCtrl = TextEditingController(text: s.fatherContact);
    _addressCtrl = TextEditingController(text: s.fullAddress);
    _otherAreaCtrl = TextEditingController(text: s.otherArea);
    _otherLandmarkCtrl = TextEditingController(text: s.otherLandmark);
    _parents = s.parents.isNotEmpty ? s.parents : null;
    _area = s.area.isNotEmpty ? s.area : null;
    _landmark = s.landmark.isNotEmpty ? s.landmark : null;
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _middleNameCtrl, _surnameCtrl, _schoolCtrl,
      _siblingCtrl, _motherCtrl, _fatherCtrl, _addressCtrl,
      _otherAreaCtrl, _otherLandmarkCtrl,
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Save Changes',
      message: 'Are you sure you want to save the changes to this record?',
      confirmText: 'SAVE',
      icon: Icons.save_outlined,
    );
    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      final user = ref.read(currentUserModelProvider).valueOrNull;
      if (user == null) throw Exception('Not authenticated');

      String photoUrl = widget.student.photoUrl;

      // If new photo selected, upload it
      if (_newPhotoFile != null) {
        final ss = StorageService();
        final (url, error) = await ss.uploadStudentPhoto(
          imageFile: _newPhotoFile!,
          makerUid: user.id,
        );
        if (error != null) throw Exception(error);
        photoUrl = url ?? photoUrl;
      }

      final changes = <String, dynamic>{
        'first_name': _firstNameCtrl.text.trim(),
        'middle_name': _middleNameCtrl.text.trim(),
        'surname': _surnameCtrl.text.trim(),
        'school_name': _schoolCtrl.text.trim(),
        'sibling_class': _siblingCtrl.text.trim(),
        'parents': _parents ?? '',
        'mother_contact': _motherCtrl.text.trim(),
        'father_contact': _fatherCtrl.text.trim(),
        'full_address': _addressCtrl.text.trim(),
        'area': _area ?? '',
        'other_area': _area == 'Other' ? _otherAreaCtrl.text.trim() : '',
        'landmark': _landmark ?? '',
        'other_landmark':
            _landmark == 'Other' ? _otherLandmarkCtrl.text.trim() : '',
        'photo_url': photoUrl,
      };

      final fs = StudentService();
      final error = await fs.updateStudent(
          widget.student.id, changes, user.name);

      if (error != null) throw Exception(error);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Record'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Maker (read-only)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Original Maker: ${widget.student.makerName}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _field(_firstNameCtrl, 'Student First Name *',
                  validator: (v) => Validators.required(v, 'Student First Name')),
              const SizedBox(height: 14),
              _field(_middleNameCtrl, 'Middle Name'),
              const SizedBox(height: 14),
              _field(_surnameCtrl, 'Surname *',
                  validator: (v) => Validators.required(v, 'Surname')),
              const SizedBox(height: 14),
              _field(_schoolCtrl, 'School Name *',
                  validator: (v) => Validators.required(v, 'School Name')),
              const SizedBox(height: 14),
              _field(_siblingCtrl, 'Bro/Sis In Class (STD & DIV)'),
              const SizedBox(height: 14),

              _dropdown('Parents *', _parents, AppConstants.parentOptions,
                  (v) => setState(() => _parents = v),
                  validator: (v) => Validators.dropdown(v, 'Parents')),
              const SizedBox(height: 14),

              _field(_motherCtrl, 'Mother Contact No.',
                  type: TextInputType.phone,
                  validator: (v) => Validators.mobileNumber(v)),
              const SizedBox(height: 14),
              _field(_fatherCtrl, 'Father Contact No.',
                  type: TextInputType.phone,
                  validator: (v) => Validators.mobileNumber(v)),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address In Full *',
                  alignLabelWithHint: true,
                ),
                validator: (v) => Validators.required(v, 'Address In Full'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 14),

              _dropdown('Area *', _area, AppConstants.areaOptions,
                  (v) => setState(() => _area = v),
                  validator: (v) => Validators.dropdown(v, 'an Area')),
              if (_area == 'Other') ...[
                const SizedBox(height: 14),
                _field(_otherAreaCtrl, 'Other Area *',
                    validator: (v) => Validators.required(v, 'Other Area')),
              ],
              const SizedBox(height: 14),

              _dropdown('Landmark *', _landmark, AppConstants.landmarkOptions,
                  (v) => setState(() => _landmark = v),
                  validator: (v) => Validators.dropdown(v, 'a Landmark')),
              if (_landmark == 'Other') ...[
                const SizedBox(height: 14),
                _field(_otherLandmarkCtrl, 'Other Landmark *',
                    validator: (v) =>
                        Validators.required(v, 'Other Landmark')),
              ],
              const SizedBox(height: 20),

              PhotoPickerCard(
                imageFile: _newPhotoFile,
                existingUrl: widget.student.photoUrl,
                onImageSelected: (f) => setState(() => _newPhotoFile = f),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SpinKitThreeBounce(color: Colors.white, size: 22)
                      : const Text('SAVE CHANGES'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType type = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _dropdown(String label, String? value, List<String> items,
      void Function(String?) onChanged,
      {String? Function(String?)? validator}) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
