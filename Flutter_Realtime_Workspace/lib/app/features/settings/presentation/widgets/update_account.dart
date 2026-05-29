import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/settings_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpdateAccount extends ConsumerStatefulWidget {
  final Map<String, dynamic> userInfo;
  const UpdateAccount({super.key, required this.userInfo});

  @override
  ConsumerState<UpdateAccount> createState() => _UpdateAccountState();
}

class _UpdateAccountState extends ConsumerState<UpdateAccount> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _departmentController;
  late TextEditingController _companyController;
  late TextEditingController _websiteController;
  late TextEditingController _industryController;
  late TextEditingController _teamProjectController;
  late TextEditingController _teamSizeController;
  late TextEditingController _officeLocationController;
  late TextEditingController _workTypeController;
  late TextEditingController _timezoneController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final u = widget.userInfo;
    _displayNameController =
        TextEditingController(text: u['displayName'] ?? '');
    _emailController = TextEditingController(text: u['email'] ?? '');
    _phoneController = TextEditingController(text: u['phoneNumber'] ?? '');
    _roleController = TextEditingController(text: u['roleTitle'] ?? '');
    _departmentController = TextEditingController(text: u['department'] ?? '');
    _companyController = TextEditingController(text: u['companyName'] ?? '');
    _websiteController = TextEditingController(text: u['companyWebsite'] ?? '');
    _industryController = TextEditingController(text: u['industry'] ?? '');
    _teamProjectController =
        TextEditingController(text: u['teamProjectName'] ?? '');
    _teamSizeController = TextEditingController(text: u['teamSize'] ?? '');
    _officeLocationController =
        TextEditingController(text: u['officeLocation'] ?? '');
    _workTypeController = TextEditingController(text: u['workType'] ?? '');
    _timezoneController = TextEditingController(text: u['timezone'] ?? '');
    _bioController = TextEditingController(text: u['bio'] ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    _companyController.dispose();
    _websiteController.dispose();
    _industryController.dispose();
    _teamProjectController.dispose();
    _teamSizeController.dispose();
    _officeLocationController.dispose();
    _workTypeController.dispose();
    _timezoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final data = {
      'fullName': _displayNameController.text.trim(),
      'displayName': _displayNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'roleTitle': _roleController.text.trim(),
      'department': _departmentController.text.trim(),
      'companyName': _companyController.text.trim(),
      'companyWebsite': _websiteController.text.trim(),
      'industry': _industryController.text.trim(),
      'teamProjectName': _teamProjectController.text.trim(),
      'teamSize': _teamSizeController.text.trim(),
      'officeLocation': _officeLocationController.text.trim(),
      'workType': _workTypeController.text.trim(),
      'timezone': _timezoneController.text.trim(),
      'bio': _bioController.text.trim(),
    };
    final ok = await SettingsUseCase.updateAccount(
      context: context,
      ref: ref,
      updates: data,
    );
    if (mounted && ok) Navigator.of(context).pop();
  }

  void _handleHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final state = ref.watch(currentUserProvider);

    // Match signup screen background
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return GestureDetector(
      onHorizontalDragEnd: _handleHorizontalDrag,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Update Profile',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _smallField(_displayNameController, 'Display Name',
                      Icons.person, isDark),
                  _smallField(_emailController, 'Email', Icons.email, isDark,
                      enabled: false),
                  _smallField(_phoneController, 'Phone', Icons.phone, isDark),
                  _smallField(
                      _roleController, 'Role Title', Icons.work, isDark),
                  _smallField(_departmentController, 'Department',
                      Icons.apartment, isDark),
                  _smallField(
                      _companyController, 'Company', Icons.business, isDark),
                  _smallField(
                      _websiteController, 'Website', Icons.language, isDark),
                  _smallField(
                      _industryController, 'Industry', Icons.category, isDark),
                  _smallField(_teamProjectController, 'Team/Project',
                      Icons.group, isDark),
                  _smallField(
                      _teamSizeController, 'Team Size', Icons.people, isDark),
                  _smallField(_officeLocationController, 'Office Location',
                      Icons.location_on, isDark),
                  _smallField(
                      _workTypeController, 'Work Type', Icons.schedule, isDark),
                  _smallField(_timezoneController, 'Timezone',
                      Icons.access_time, isDark),
                  _smallField(_bioController, 'Bio', Icons.info, isDark,
                      maxLines: 2),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon:
                          const Icon(Icons.save, size: 16, color: Colors.white),
                      label: state.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Update',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: state.isLoading ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallField(
      TextEditingController c, String label, IconData icon, bool isDark,
      {bool enabled = true, int maxLines = 1}) {
    // Match signup screen input style
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: TextFormField(
        controller: c,
        enabled: enabled,
        maxLines: maxLines,
        style: TextStyle(
            fontSize: 13, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          filled: true,
          fillColor:
              isDark ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white,
          hintText: "Enter $label".toLowerCase(),
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF64748B),
            fontSize: 12,
          ),
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon,
              size: 16,
              color: isDark ? Colors.white70 : const Color(0xFF475569)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        ),
        validator: (v) => (label == 'Email' || label == 'Display Name') &&
                (v == null || v.isEmpty)
            ? 'Required'
            : null,
      ),
    );
  }
}
