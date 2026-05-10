import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/utils/file_picker.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';
import 'package:flutter_realtime_workspace/shared/components/custom_bottom_navigiation.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

enum UserInfoMode { create, join }

class UserInformationScreen extends ConsumerStatefulWidget {
  final UserInfoMode mode;
  const UserInformationScreen({super.key, required this.mode});

  @override
  ConsumerState<UserInformationScreen> createState() =>
      _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Section 1: Basic Profile Information
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _profilePictureController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  // Section 2: Workspace Role & Preferences
  final TextEditingController _roleTitleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  String? _workType; // <-- ensure this is String?
  final TextEditingController _timezoneController = TextEditingController();
  final TextEditingController _workingHoursStartController =
      TextEditingController();
  final TextEditingController _workingHoursEndController =
      TextEditingController();

  // Section 3: Company or Organization
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyWebsiteController =
      TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  String? _teamSize; // <-- ensure this is String?
  final TextEditingController _officeLocationController =
      TextEditingController();

  // Section 4: Collaboration Details
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _teamProjectNameController =
      TextEditingController();
  String? _permissionsLevel; // <-- ensure this is String?

  // Section 5: Optional Onboarding Enhancements
  final TextEditingController _interestsSkillsController =
      TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _linkedInController = TextEditingController();
  final TextEditingController _githubController = TextEditingController();

  int _currentPage = 0;
  File? _pickedImageFile;
  bool _isUploadingImage = false;

  void _nextPage() {
    // If on section 4 (index 3) and joining, validate invite code before moving to section 5
    if (_currentPage == 3 && widget.mode == UserInfoMode.join) {
      if (_inviteCodeController.text.trim().isEmpty) {
        context.showToast(
          "Invite code is required to join an organisation.",
          type: ToastType.error,
        );
        // Optionally trigger validator for the field
        _formKey.currentState?.validate();
        return;
      }
    }
    if (_currentPage < 4) {
      setState(() => _currentPage++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  /// Build a clean user info payload for backend (no empty fields, proper nesting)
  Map<String, dynamic> _buildUserInfoPayload() {
    final Map<String, dynamic> data = {};

    // Section 1: Basic Profile
    if (_fullNameController.text.trim().isNotEmpty)
      data['fullName'] = _fullNameController.text.trim();
    if (_displayNameController.text.trim().isNotEmpty)
      data['displayName'] = _displayNameController.text.trim();
    if (_profilePictureController.text.trim().isNotEmpty)
      data['profilePicture'] = _profilePictureController.text.trim();
    if (_emailController.text.trim().isNotEmpty)
      data['email'] = _emailController.text.trim();
    if (_phoneNumberController.text.trim().isNotEmpty)
      data['phoneNumber'] = _phoneNumberController.text.trim();

    // Section 2: Workspace Role & Preferences
    if (_roleTitleController.text.trim().isNotEmpty)
      data['roleTitle'] = _roleTitleController.text.trim();
    if (_departmentController.text.trim().isNotEmpty)
      data['department'] = _departmentController.text.trim();
    if (_workType != null && _workType!.isNotEmpty)
      data['workType'] = _workType;
    if (_timezoneController.text.trim().isNotEmpty)
      data['timezone'] = _timezoneController.text.trim();
    if (_workingHoursStartController.text.trim().isNotEmpty ||
        _workingHoursEndController.text.trim().isNotEmpty) {
      final start = _workingHoursStartController.text.trim();
      final end = _workingHoursEndController.text.trim();
      if (start.isNotEmpty || end.isNotEmpty) {
        data['workingHours'] = {};
        if (start.isNotEmpty) data['workingHours']['start'] = start;
        if (end.isNotEmpty) data['workingHours']['end'] = end;
      }
    }

    // Section 3: Company/Organization
    if (_companyNameController.text.trim().isNotEmpty)
      data['companyName'] = _companyNameController.text.trim();
    if (_companyWebsiteController.text.trim().isNotEmpty)
      data['companyWebsite'] = _companyWebsiteController.text.trim();
    if (_industryController.text.trim().isNotEmpty)
      data['industry'] = _industryController.text.trim();
    if (_teamSize != null && _teamSize!.isNotEmpty)
      data['teamSize'] = _teamSize;
    if (_officeLocationController.text.trim().isNotEmpty)
      data['officeLocation'] = _officeLocationController.text.trim();

    // Section 4: Collaboration
    if (_inviteCodeController.text.trim().isNotEmpty)
      data['inviteCode'] = _inviteCodeController.text.trim();
    if (_teamProjectNameController.text.trim().isNotEmpty)
      data['teamProjectName'] = _teamProjectNameController.text.trim();
    if (_permissionsLevel != null && _permissionsLevel!.isNotEmpty)
      data['permissionsLevel'] = _permissionsLevel;

    // Section 5: Optional Onboarding
    // Ensure interestsSkills is always a List<String> and not a string or repeated keys
    final interestsSkillsList = _interestsSkillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (interestsSkillsList.isNotEmpty) {
      data['interestsSkills'] = interestsSkillsList;
    }
    if (_bioController.text.trim().isNotEmpty)
      data['bio'] = _bioController.text.trim();

    // Social links as nested object
    final linkedIn = _linkedInController.text.trim();
    final github = _githubController.text.trim();
    if (linkedIn.isNotEmpty || github.isNotEmpty) {
      data['socialLinks'] = {};
      if (linkedIn.isNotEmpty) data['socialLinks']['linkedIn'] = linkedIn;
      if (github.isNotEmpty) data['socialLinks']['github'] = github;
    }

    return data;
  }

//--------------------------- function to handle continue button press ---------------------------
  Future<void> _onContinuePressed() async {
    // If joining, validate invite code is not empty
    if (widget.mode == UserInfoMode.join &&
        (_inviteCodeController.text.trim().isEmpty)) {
      context.showToast(
        "Invite code is required to join an organisation.",
        type: ToastType.error,
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Build clean payload
    final userInfoData = _buildUserInfoPayload();

    print('[UserInformation] Sending data: $userInfoData');

    // Use the picked image file if available
    String? imagePath = _pickedImageFile?.path;

    await ref
        .read(userProvider.notifier)
        .saveUserInfo(userInfoData, imagePath: imagePath);

    final state = ref.read(userProvider);
    if (state.error != null) {
      context.showToast(
        "Failed to save: ${state.error}",
        type: ToastType.error,
      );
      return;
    }

    // Optionally update controllers with returned data for consistency
    if (state.userInfo != null) {
      _profilePictureController.text = state.userInfo!['profilePicture'] ?? '';
      // ...update other controllers if needed...
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const BottomNavigationBarWidget()),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await pickImageFromGallery(imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = pickedFile;
      });
      // await _uploadProfileImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final userInfoState = ref.watch(userProvider);

    // Banner message and gradient based on mode and theme
    final bool isJoin = widget.mode == UserInfoMode.join;
    final String bannerText = isJoin
        ? "🔑 Enter your invite code above. Your company name will be filled in automatically!"
        : "🚀 No invite code needed. You're starting a new company. Once created, share your auto-generated invite code with employees to let them join!";
    final Gradient bannerGradient = isDarkMode
        ? const LinearGradient(
            colors: [
              TColors.blue900,
              TColors.buttonPrimary,
              TColors.cardColorDark
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : const LinearGradient(
            colors: [
              TColors.backgroundDark,
              TColors.accentBlue,
              TColors.darkCard
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDarkMode ? TColors.backgroundDarkAlt : TColors.backgroundLight,
          resizeToAvoidBottomInset:
              true, // Allow scaffold to resize for keyboard
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: isDarkMode
                                  ? Colors.white
                                  : TColors.backgroundDark),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              isDarkMode ? TColors.cardColorDark : Colors.white,
                          child: Icon(Icons.person,
                              color: isDarkMode
                                  ? TColors.lightBlue
                                  : TColors.buttonPrimaryLight,
                              size: 28),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Profile Setup",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode
                                ? Colors.white
                                : TColors.backgroundDark,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${_currentPage + 1}/5",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? TColors.textSecondaryDark
                                : TColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Wrap the PageView in Expanded and SingleChildScrollView to avoid overflow
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height *
                            0.75, // Ensure enough height for PageView
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // Section 1: Basic Profile Information
                            _modernInputCard(
                              isDarkMode: isDarkMode,
                              title: "Basic Profile",
                              subtitle: "Let's start with your basic info.",
                              child: Column(
                                children: [
                                  _modernTextField(
                                    controller: _fullNameController,
                                    label: "Full Name",
                                    isDarkMode: isDarkMode,
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Required"
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _displayNameController,
                                    label: "Display Name",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  // Profile Picture Picker
                                  Row(
                                    children: [
                                      _pickedImageFile != null
                                          ? CircleAvatar(
                                              radius: 28,
                                              backgroundImage:
                                                  FileImage(_pickedImageFile!),
                                            )
                                          : (_profilePictureController
                                                  .text.isNotEmpty
                                              ? CircleAvatar(
                                                  radius: 28,
                                                  backgroundImage: NetworkImage(
                                                      _profilePictureController
                                                          .text),
                                                )
                                              : CircleAvatar(
                                                  radius: 28,
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  child: const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 28),
                                                )),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _isUploadingImage
                                              ? null
                                              : () async {
                                                  if (_pickedImageFile !=
                                                      null) {
                                                    // Show bottom modal for change/remove
                                                    showModalBottomSheet(
                                                      context: context,
                                                      shape:
                                                          const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                                top: Radius
                                                                    .circular(
                                                                        18)),
                                                      ),
                                                      builder: (context) {
                                                        return SafeArea(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              ListTile(
                                                                leading: const Icon(
                                                                    Icons
                                                                        .photo_library),
                                                                title: const Text(
                                                                    "Select New Photo"),
                                                                onTap:
                                                                    () async {
                                                                  Navigator.pop(
                                                                      context);
                                                                  await _pickImage();
                                                                },
                                                              ),
                                                              ListTile(
                                                                leading: const Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    color: Colors
                                                                        .red),
                                                                title: const Text(
                                                                    "Remove Photo",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .red)),
                                                                onTap: () {
                                                                  setState(() {
                                                                    _pickedImageFile =
                                                                        null;
                                                                    _profilePictureController
                                                                        .text = '';
                                                                  });
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    await _pickImage();
                                                  }
                                                },
                                          icon: const Icon(Icons.upload),
                                          label: Text(
                                            _isUploadingImage
                                                ? "Uploading..."
                                                : (_pickedImageFile != null
                                                    ? "Change Photo"
                                                    : "Select Photo"),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDarkMode
                                                ? TColors.buttonPrimary
                                                : TColors.buttonPrimaryLight,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _profilePictureController,
                                    label: "Profile Picture URL (optional)",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _emailController,
                                    label: "Email",
                                    isDarkMode: isDarkMode,
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Required"
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _phoneNumberController,
                                    label: "Phone Number",
                                    isDarkMode: isDarkMode,
                                  ),
                                ],
                              ),
                            ),
                            // Section 2: Workspace Role & Preferences
                            _modernInputCard(
                              isDarkMode: isDarkMode,
                              title: "Workspace Role",
                              subtitle:
                                  "Your role and preferences in the workspace.",
                              child: Column(
                                children: [
                                  _modernTextField(
                                    controller: _roleTitleController,
                                    label:
                                        "Role Title (e.g. Designer, Developer)",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _departmentController,
                                    label: "Department",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernDropdown(
                                    label: "Work Type",
                                    value: _workType,
                                    items: const [
                                      "Full-time",
                                      "Part-time",
                                      "Freelancer",
                                      "Intern"
                                    ],
                                    isDarkMode: isDarkMode,
                                    onChanged: (val) =>
                                        setState(() => _workType = val),
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _timezoneController,
                                    label: "Timezone",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _modernTextField(
                                          controller:
                                              _workingHoursStartController,
                                          label: "Working Hours Start",
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _modernTextField(
                                          controller:
                                              _workingHoursEndController,
                                          label: "End",
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Section 3: Company or Organization
                            _modernInputCard(
                              isDarkMode: isDarkMode,
                              title: "Company/Organization",
                              subtitle: "Tell us about your company.",
                              child: Column(
                                children: [
                                  _modernTextField(
                                    controller: _companyNameController,
                                    label: "Company Name",
                                    isDarkMode: isDarkMode,
                                    enabled: widget.mode != UserInfoMode.join,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _companyWebsiteController,
                                    label: "Company Website",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _industryController,
                                    label: "Industry",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernDropdown(
                                    label: "Team Size",
                                    value: _teamSize,
                                    items: const [
                                      "1-10",
                                      "11-50",
                                      "51-100",
                                      "100+"
                                    ],
                                    isDarkMode: isDarkMode,
                                    onChanged: (val) =>
                                        setState(() => _teamSize = val),
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _officeLocationController,
                                    label: "Office Location",
                                    isDarkMode: isDarkMode,
                                  ),
                                ],
                              ),
                            ),
                            // Section 4: Collaboration Details
                            _modernInputCard(
                              isDarkMode: isDarkMode,
                              title: "Collaboration",
                              subtitle: "Team and permissions.",
                              child: Column(
                                children: [
                                  _modernTextField(
                                    controller: _inviteCodeController,
                                    label: "Invite Code",
                                    isDarkMode: isDarkMode,
                                    enabled: widget.mode == UserInfoMode.join,
                                    validator: widget.mode == UserInfoMode.join
                                        ? (v) => (v == null || v.trim().isEmpty)
                                            ? "Invite code is required"
                                            : null
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _teamProjectNameController,
                                    label: "Team/Project Name",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  // Permissions Level Dropdown
                                  _modernDropdown(
                                    label: "Permissions Level",
                                    value: _permissionsLevel,
                                    items: const [
                                      "admin",
                                      "manager",
                                      "employee",
                                      "member"
                                    ],
                                    isDarkMode: isDarkMode,
                                    onChanged: (val) =>
                                        setState(() => _permissionsLevel = val),
                                  ),
                                ],
                              ),
                            ),
                            // Section 5: Optional Onboarding Enhancements
                            _modernInputCard(
                              isDarkMode: isDarkMode,
                              title: "About You",
                              subtitle: "Enhance your profile (optional).",
                              child: Column(
                                children: [
                                  _modernTextField(
                                    controller: _interestsSkillsController,
                                    label: "Interests/Skills (comma separated)",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _bioController,
                                    label: "Short Bio",
                                    isDarkMode: isDarkMode,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _linkedInController,
                                    label: "LinkedIn URL",
                                    isDarkMode: isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  _modernTextField(
                                    controller: _githubController,
                                    label: "GitHub URL",
                                    isDarkMode: isDarkMode,
                                  ),
                                ],
                              ),
                            ),
                            // Removed Technical Metadata Section
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Navigation Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    child: Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousPage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDarkMode
                                    ? TColors.buttonPrimary
                                    : TColors.buttonPrimaryLight,
                                side: BorderSide(
                                  color: isDarkMode
                                      ? TColors.buttonPrimary
                                      : TColors.buttonPrimaryLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Previous",
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _currentPage < 4
                              ? ElevatedButton(
                                  onPressed: _nextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode
                                        ? TColors.buttonPrimary
                                        : TColors.buttonPrimaryLight,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: const Text("Next",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                )
                              : ElevatedButton(
                                  onPressed: userInfoState.isLoading
                                      ? null
                                      : _onContinuePressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode
                                        ? TColors.buttonPrimary
                                        : TColors.buttonPrimaryLight,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                  child: userInfoState.isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Text("Continue",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700)),
                                ),
                        ),
                      ],
                    ),
                  ),
                  // Banner at the bottom
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: bannerGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.08)
                                : Colors.grey.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon(
                          //   isJoin ? Icons.info_outline : Icons.rocket_launch_outlined,
                          //   color: isDarkMode ? Colors.white : Colors.white,
                          //   size: 14,
                          // ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bannerText,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white : Colors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (userInfoState.isLoading)
          Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _modernInputCard({
    required Widget child,
    required bool isDarkMode,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white : TColors.backgroundDark,
              )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode
                    ? TColors.textSecondaryDark
                    : TColors.textTertiaryLight,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? TColors.cardColorDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.black : Colors.grey)
                      .withOpacity(0.04),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _modernTextField({
    required TextEditingController controller,
    required String label,
    required bool isDarkMode,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true, // <-- add this line
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled, // <-- add this line
      style: TextStyle(
        color: isDarkMode ? Colors.white : TColors.backgroundDark,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode
              ? TColors.textTertiaryLight
              : TColors.textSecondaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor:
            isDarkMode ? TColors.backgroundDarkAlt : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color:
                isDarkMode ? TColors.buttonPrimary : TColors.buttonPrimaryLight,
            width: 1.3,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  Widget _modernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required bool isDarkMode,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode
              ? TColors.textTertiaryLight
              : TColors.textSecondaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor:
            isDarkMode ? TColors.backgroundDarkAlt : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? TColors.borderDark : TColors.borderLight,
            width: 1,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      dropdownColor: isDarkMode ? TColors.backgroundDarkAlt : Colors.white,
      style: TextStyle(
        color: isDarkMode ? Colors.white : TColors.backgroundDark,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      items: items
          .map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: (val) => onChanged(val), // <-- always pass string value
    );
  }
}

