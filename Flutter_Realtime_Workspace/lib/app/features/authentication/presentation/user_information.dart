import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/avatar_picker.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/s_dropdown.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/user_info_page_card.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/usecases/user_info_usecase.dart';
import 'package:flutter_realtime_workspace/core/animations/screen_animations.dart';
import 'package:flutter_realtime_workspace/core/animations/widget_animations.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/icons.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

enum UserInfoMode { create, join }

class UserInformationScreen extends ConsumerStatefulWidget {
  const UserInformationScreen({super.key, required this.mode});
  final UserInfoMode mode;

  @override
  ConsumerState<UserInformationScreen> createState() =>
      _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen>
    with SingleTickerProviderStateMixin {
  // Animations
  late final SlideUpFadeAnim _enterAnim;

  // Form / paging
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Section 1: Basic Profile
  final _fullName = TextEditingController();
  final _displayName = TextEditingController();
  final _profilePictureUrl = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  File? _pickedImage;

  // Section 2: Workspace Role
  final _roleTitle = TextEditingController();
  final _department = TextEditingController();
  String? _workType;
  final _timezone = TextEditingController();
  final _workHoursStart = TextEditingController();
  final _workHoursEnd = TextEditingController();

  // Section 3: Company
  final _companyName = TextEditingController();
  final _companyWebsite = TextEditingController();
  final _industry = TextEditingController();
  String? _teamSize;
  final _officeLocation = TextEditingController();

  // Section 4: Collaboration
  final _inviteCode = TextEditingController();
  final _teamProject = TextEditingController();
  String? _permissionsLevel;

  // Section 5: About You
  final _interests = TextEditingController();
  final _bio = TextEditingController();
  final _linkedIn = TextEditingController();
  final _github = TextEditingController();

  @override
  void initState() {
    super.initState();
    _enterAnim = SlideUpFadeAnim(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      beginOffset: const Offset(0, 0.08),
    )..forward();
  }

  @override
  void dispose() {
    _enterAnim.dispose();
    _pageController.dispose();
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _allControllers => [
        _fullName, _displayName, _profilePictureUrl, _email, _phone,
        _roleTitle, _department, _timezone, _workHoursStart, _workHoursEnd,
        _companyName, _companyWebsite, _industry, _officeLocation,
        _inviteCode, _teamProject,
        _interests, _bio, _linkedIn, _github,
      ];

  void _next() {
    if (_currentPage == 3 &&
        widget.mode == UserInfoMode.join &&
        _inviteCode.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      return;
    }
    if (_currentPage < 4) {
      setState(() => _currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final payload = UserInfoUseCase.buildPayload(
      fullName: _fullName.text,
      displayName: _displayName.text,
      profilePictureUrl: _profilePictureUrl.text,
      email: _email.text,
      phone: _phone.text,
      roleTitle: _roleTitle.text,
      department: _department.text,
      workType: _workType,
      timezone: _timezone.text,
      workingHoursStart: _workHoursStart.text,
      workingHoursEnd: _workHoursEnd.text,
      companyName: _companyName.text,
      companyWebsite: _companyWebsite.text,
      industry: _industry.text,
      teamSize: _teamSize,
      officeLocation: _officeLocation.text,
      inviteCode: _inviteCode.text,
      teamProjectName: _teamProject.text,
      permissionsLevel: _permissionsLevel,
      interestsSkills: _interests.text,
      bio: _bio.text,
      linkedIn: _linkedIn.text,
      github: _github.text,
    );
    await UserInfoUseCase.submit(
      context: context,
      ref: ref,
      payload: payload,
      imagePath: _pickedImage?.path,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final isJoin = widget.mode == UserInfoMode.join;
    final hPad = TResponsive.pagePadding(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? TColors.darkBg : TColors.lightBg,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: TOrbFieldPainter(
                    colors: [
                      TColors.primary.withValues(alpha: 0.55),
                      TColors.blue700.withValues(alpha: 0.35),
                    ],
                    orbCount: 3,
                    isDark: isDark,
                    seed: 7,
                  ),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _enterAnim.fade,
                  child: SlideTransition(
                    position: _enterAnim.slide,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildHeader(isDark, hPad),
                          _buildStepDots(isDark),
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _pageBasicProfile(isDark),
                                _pageWorkspaceRole(isDark),
                                _pageCompany(isDark, isJoin),
                                _pageCollaboration(isDark),
                                _pageAboutYou(isDark),
                              ],
                            ),
                          ),
                          _buildNavBar(isDark, hPad),
                          _buildModeBanner(isDark, isJoin, hPad),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.35),
            child: const Center(
              child: CircularProgressIndicator(color: TColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isDark, double hPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.sm),
      child: Row(
        children: [
          _IconBtn(
            icon: TIcons.back,
            isDark: isDark,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: TSizes.sm),
          TWidgetAnimations.scaleIn(
            duration: const Duration(milliseconds: 340),
            child: CircleAvatar(
              radius: 20,
              backgroundColor:
                  isDark ? TColors.darkCard : TColors.lightSurface,
              child: Icon(TIcons.profile, color: TColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          TWidgetAnimations.fadeIn(
            duration: const Duration(milliseconds: 360),
            child: Text(
              'Profile Setup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? TColors.textDark : TColors.textLight,
              ),
            ),
          ),
          const Spacer(),
          TWidgetAnimations.fadeIn(
            duration: const Duration(milliseconds: 360),
            child: _StepBadge(
              current: _currentPage + 1,
              total: 5,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDots(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final active = i == _currentPage;
          final done = i < _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: (done || active)
                  ? TColors.primary
                  : (isDark ? TColors.darkBorder : TColors.lightBorder),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavBar(bool isDark, double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.sm, hPad, TSizes.sm),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: TButton(
                text: 'Previous',
                variant: SButtonVariant.outline,
                onPressed: _prev,
              ),
            ),
            const SizedBox(width: TSizes.sm),
          ],
          Expanded(
            child: _currentPage < 4
                ? TButton(text: 'Next', onPressed: _next)
                : TButton(
                    text: 'Finish Setup',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBanner(bool isDark, bool isJoin, double hPad) {
    final text = isJoin
        ? 'Enter your invite code. Your company info will be filled automatically.'
        : 'You are creating a new workspace. Share your invite code with teammates.';
    return TWidgetAnimations.fadeIn(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: EdgeInsets.fromLTRB(hPad, 0, hPad, TSizes.md),
        padding: const EdgeInsets.symmetric(
            vertical: TSizes.sm, horizontal: TSizes.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TColors.blue900, TColors.primary, TColors.blue700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          boxShadow: [
            BoxShadow(
              color: TColors.primary.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isJoin
                  ? Icons.group_add_outlined
                  : Icons.rocket_launch_outlined,
              color: Colors.white.withValues(alpha: 0.9),
              size: TSizes.iconSm + 4,
            ),
            const SizedBox(width: TSizes.sm),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBasicProfile(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: UserInfoPageCard(
        title: 'Basic Profile',
        subtitle: "Let's start with who you are.",
        isDarkMode: isDark,
        child: Column(
          children: [
            AvatarPicker(
              pickedFile: _pickedImage,
              networkUrl: _profilePictureUrl.text,
              isDarkMode: isDark,
              onImagePicked: (f) => setState(() => _pickedImage = f),
            ),
            const SizedBox(height: TSizes.md),
            TInput(
              controller: _fullName,
              label: 'Full Name',
              hint: 'e.g. Alex Johnson',
              prefixIcon: TIcons.profile,
              validator: (v) => UserInfoUseCase.requiredField(v, 'Full name'),
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _displayName,
              label: 'Display Name',
              hint: 'How others will see you',
              prefixIcon: TIcons.profile,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _email,
              label: 'Email',
              hint: 'work@company.com',
              prefixIcon: TIcons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => UserInfoUseCase.requiredField(v, 'Email'),
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _phone,
              label: 'Phone Number',
              hint: 'Optional',
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageWorkspaceRole(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: UserInfoPageCard(
        title: 'Workspace Role',
        subtitle: 'Your role and work preferences.',
        isDarkMode: isDark,
        animDelay: const Duration(milliseconds: 40),
        child: Column(
          children: [
            TInput(
              controller: _roleTitle,
              label: 'Role Title',
              hint: 'e.g. Senior Designer',
              prefixIcon: TIcons.invite,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _department,
              label: 'Department',
              hint: 'e.g. Product',
            ),
            const SizedBox(height: TSizes.sm + 2),
            SDropdown(
              label: 'Work Type',
              value: _workType,
              items: const ['Full-time', 'Part-time', 'Freelancer', 'Intern'],
              isDarkMode: isDark,
              onChanged: (v) => setState(() => _workType = v),
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _timezone,
              label: 'Timezone',
              hint: 'e.g. UTC+1',
            ),
            const SizedBox(height: TSizes.sm + 2),
            Row(
              children: [
                Expanded(
                  child: TInput(
                    controller: _workHoursStart,
                    label: 'Hours Start',
                    hint: '09:00',
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: TInput(
                    controller: _workHoursEnd,
                    label: 'Hours End',
                    hint: '17:00',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageCompany(bool isDark, bool isJoin) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: UserInfoPageCard(
        title: 'Company',
        subtitle: 'Your organisation details.',
        isDarkMode: isDark,
        animDelay: const Duration(milliseconds: 40),
        child: Column(
          children: [
            TInput(
              controller: _companyName,
              label: 'Company Name',
              hint: isJoin ? 'Auto-filled after joining' : 'Your company name',
              enabled: !isJoin,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _companyWebsite,
              label: 'Website',
              hint: 'https://company.com',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _industry,
              label: 'Industry',
              hint: 'e.g. SaaS, Fintech',
            ),
            const SizedBox(height: TSizes.sm + 2),
            SDropdown(
              label: 'Team Size',
              value: _teamSize,
              items: const ['1-10', '11-50', '51-100', '100+'],
              isDarkMode: isDark,
              onChanged: (v) => setState(() => _teamSize = v),
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _officeLocation,
              label: 'Office Location',
              hint: 'City, Country',
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageCollaboration(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: UserInfoPageCard(
        title: 'Collaboration',
        subtitle: 'Team access and permissions.',
        isDarkMode: isDark,
        animDelay: const Duration(milliseconds: 40),
        child: Column(
          children: [
            if (widget.mode == UserInfoMode.join) ...[
              TInput(
                controller: _inviteCode,
                label: 'Invite Code',
                hint: 'Enter your team invite code',
                prefixIcon: TIcons.invite,
                validator: UserInfoUseCase.validateInviteCode,
              ),
              const SizedBox(height: TSizes.sm + 2),
            ],
            TInput(
              controller: _teamProject,
              label: 'Team / Project Name',
              hint: 'e.g. Core Platform Team',
            ),
            const SizedBox(height: TSizes.sm + 2),
            SDropdown(
              label: 'Permissions Level',
              value: _permissionsLevel,
              items: const ['admin', 'manager', 'employee', 'member'],
              isDarkMode: isDark,
              onChanged: (v) => setState(() => _permissionsLevel = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageAboutYou(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: UserInfoPageCard(
        title: 'About You',
        subtitle: 'A little extra detail, all optional.',
        isDarkMode: isDark,
        animDelay: const Duration(milliseconds: 40),
        child: Column(
          children: [
            TInput(
              controller: _interests,
              label: 'Skills and Interests',
              hint: 'Design, Figma, Swift, comma-separated',
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _bio,
              label: 'Short Bio',
              hint: 'A sentence about yourself',
              maxLines: 3,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _linkedIn,
              label: 'LinkedIn',
              hint: 'https://linkedin.com/in/you',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _github,
              label: 'GitHub',
              hint: 'https://github.com/you',
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(TSizes.sm),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkCard : TColors.lightSurface,
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(
            color: isDark ? TColors.darkBorder : TColors.lightBorder,
          ),
        ),
        child: Icon(
          icon,
          size: TSizes.iconSm + 2,
          color: isDark ? TColors.textDark : TColors.textLight,
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.current,
    required this.total,
    required this.isDark,
  });
  final int current;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TSizes.sm + 2, vertical: 4),
      decoration: BoxDecoration(
        color: TColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TSizes.radiusFull),
        border: Border.all(color: TColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$current / $total',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: TColors.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
