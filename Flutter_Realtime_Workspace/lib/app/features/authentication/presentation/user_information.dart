import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/decorative_painters.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/avatar_picker.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/s_dropdown.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/user_info_page_card.dart';
import 'package:flutter_realtime_workspace/app/domain/usecases/user_info_usecase.dart';
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
  // ── Animations ───────────────────────────────────────────────────────────
  late final SlideUpFadeAnim _enterAnim;

  // ── Paging ───────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // ── Page 0 · Basic Profile ───────────────────────────────────────────────
  final _fullName = TextEditingController();
  final _displayName = TextEditingController();
  final _profilePictureUrl = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  File? _pickedImage;

  // ── Page 1 · Your Role ───────────────────────────────────────────────────
  final _roleTitle = TextEditingController();
  final _department = TextEditingController();
  String? _workType;
  final _timezone = TextEditingController();
  final _workHoursStart = TextEditingController();
  final _workHoursEnd = TextEditingController();

  // ── Page 2 (create) · Organisation ──────────────────────────────────────
  final _orgName = TextEditingController();
  final _orgSlug = TextEditingController();
  final _orgIndustry = TextEditingController();
  String? _orgSize;
  final _orgDomain = TextEditingController();
  final _orgCountry = TextEditingController();
  bool _slugEditable = false;

  // ── Page 2 (join) · Join Organisation ───────────────────────────────────
  final _inviteCode = TextEditingController();

  // ── Page 3 (create) · Workspace ─────────────────────────────────────────
  final _workspaceName = TextEditingController();
  final _workspaceDesc = TextEditingController();
  String? _permissionsLevel;

  // ── Page 4 (create) / 3 (join) · About You ──────────────────────────────
  final _interests = TextEditingController();
  final _bio = TextEditingController();
  final _linkedIn = TextEditingController();
  final _github = TextEditingController();

  // ── Computed ─────────────────────────────────────────────────────────────
  int get _totalPages => widget.mode == UserInfoMode.create ? 5 : 4;

  @override
  void initState() {
    super.initState();
    _enterAnim = SlideUpFadeAnim(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      beginOffset: const Offset(0, 0.08),
    )..forward();
    _orgName.addListener(_autoGenerateSlug);
  }

  void _autoGenerateSlug() {
    if (_slugEditable) return;
    final slug = _orgName.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    _orgSlug.text = slug;
  }

  @override
  void dispose() {
    _enterAnim.dispose();
    _pageController.dispose();
    _orgName.removeListener(_autoGenerateSlug);
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _allControllers => [
        _fullName, _displayName, _profilePictureUrl, _email, _phone,
        _roleTitle, _department, _timezone, _workHoursStart, _workHoursEnd,
        _orgName, _orgSlug, _orgIndustry, _orgDomain, _orgCountry,
        _inviteCode,
        _workspaceName, _workspaceDesc,
        _interests, _bio, _linkedIn, _github,
      ];

  void _next() {
    if (widget.mode == UserInfoMode.join && _currentPage == 2) {
      if (_inviteCode.text.trim().isEmpty) {
        _formKey.currentState?.validate();
        return;
      }
    }
    if (_currentPage < _totalPages - 1) {
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
      companyName: _orgName.text,
      companyWebsite: _orgDomain.text,
      industry: _orgIndustry.text,
      teamSize: _orgSize,
      officeLocation: _orgCountry.text,
      orgSlug: _orgSlug.text,
      inviteCode: _inviteCode.text,
      teamProjectName: _workspaceName.text,
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
                    colors: isJoin
                        ? [
                            TColors.green.withValues(alpha: 0.45),
                            TColors.primary.withValues(alpha: 0.30),
                          ]
                        : [
                            TColors.primary.withValues(alpha: 0.50),
                            TColors.blue700.withValues(alpha: 0.32),
                          ],
                    orbCount: 3,
                    isDark: isDark,
                    seed: isJoin ? 17 : 7,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: TDotGridPainter(
                    dotColor:
                        (isDark ? TColors.darkBorder : TColors.lightBorder)
                            .withValues(alpha: 0.45),
                    spacing: 26,
                    dotRadius: 0.9,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  width: 210,
                  height: 210,
                  child: CustomPaint(
                    painter: TCornerArcPainter(
                      color: (isJoin ? TColors.green : TColors.primary)
                          .withValues(alpha: isDark ? 0.13 : 0.10),
                      radius: 190,
                      corner: CornerPosition.topRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: TCornerArcPainter(
                      color: TColors.blue700
                          .withValues(alpha: isDark ? 0.08 : 0.06),
                      radius: 130,
                      corner: CornerPosition.bottomLeft,
                    ),
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
                          _buildHeader(isDark, hPad, isJoin),
                          _buildStepper(isDark, hPad),
                          const SizedBox(height: TSizes.xs),
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: widget.mode == UserInfoMode.create
                                  ? [
                                      _pageBasicProfile(isDark, hPad),
                                      _pageYourRole(isDark, hPad),
                                      _pageOrganisation(isDark, hPad),
                                      _pageWorkspaceSetup(isDark, hPad),
                                      _pageAboutYou(isDark, hPad),
                                    ]
                                  : [
                                      _pageBasicProfile(isDark, hPad),
                                      _pageYourRole(isDark, hPad),
                                      _pageJoinOrg(isDark, hPad),
                                      _pageAboutYou(isDark, hPad),
                                    ],
                            ),
                          ),
                          _buildNavBar(isDark, hPad),
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
            color: Colors.black.withValues(alpha: 0.40),
            child: const Center(
              child: CircularProgressIndicator(color: TColors.primary),
            ),
          ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, double hPad, bool isJoin) {
    final accentColor = isJoin ? TColors.green : TColors.primary;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TWidgetAnimations.fadeIn(
                  duration: const Duration(milliseconds: 340),
                  child: Text(
                    'Profile Setup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark
                          ? TColors.textPrimaryDark
                          : TColors.textPrimaryLight,
                    ),
                  ),
                ),
                TWidgetAnimations.fadeIn(
                  delay: const Duration(milliseconds: 70),
                  child: Text(
                    isJoin
                        ? 'Joining an organisation'
                        : 'Creating your organisation',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? TColors.textSecondaryDark
                          : TColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TWidgetAnimations.scaleIn(
            duration: const Duration(milliseconds: 340),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(TSizes.radiusFull),
                border: Border.all(
                    color: accentColor.withValues(alpha: 0.40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isJoin
                        ? Icons.group_add_rounded
                        : Icons.rocket_launch_rounded,
                    size: 12,
                    color: accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isJoin ? 'Join' : 'Create',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: TSizes.xs),
          TWidgetAnimations.fadeIn(
            duration: const Duration(milliseconds: 360),
            child: _StepBadge(
              current: _currentPage + 1,
              total: _totalPages,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stepper ──────────────────────────────────────────────────────────────

  Widget _buildStepper(bool isDark, double hPad) {
    final labels = widget.mode == UserInfoMode.create
        ? ['Profile', 'Role', 'Org', 'Workspace', 'About']
        : ['Profile', 'Role', 'Join', 'About'];

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 0),
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 0; i < _totalPages; i++) ...[
                _StepCircle(
                  index: i,
                  current: _currentPage,
                  isDark: isDark,
                  isJoin: widget.mode == UserInfoMode.join,
                ),
                if (i < _totalPages - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: i < _currentPage
                            ? TColors.green.withValues(alpha: 0.75)
                            : (isDark
                                ? TColors.darkBorder
                                : TColors.lightBorder),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              labels[_currentPage],
              key: ValueKey(_currentPage),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
                color: isDark
                    ? TColors.textSecondaryDark
                    : TColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nav bar ──────────────────────────────────────────────────────────────

  Widget _buildNavBar(bool isDark, double hPad) {
    final isLast = _currentPage == _totalPages - 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.xs, hPad, TSizes.md),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: TButton(
                text: 'Back',
                variant: SButtonVariant.outline,
                onPressed: _prev,
                prefixIcon: TIcons.back,
              ),
            ),
            const SizedBox(width: TSizes.sm),
          ],
          Expanded(
            child: isLast
                ? TButton(
                    text: 'Finish Setup',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                    prefixIcon: Icons.check_circle_outline_rounded,
                  )
                : TButton(
                    text: 'Continue',
                    onPressed: _next,
                    suffixIcon: Icons.arrow_forward_rounded,
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 0 · Basic Profile
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pageBasicProfile(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
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
              validator: (v) =>
                  UserInfoUseCase.requiredField(v, 'Full name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _displayName,
              label: 'Display Name',
              hint: 'How others will see you',
              prefixIcon: TIcons.profile,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _email,
              label: 'Email',
              hint: 'work@company.com',
              prefixIcon: TIcons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => UserInfoUseCase.requiredField(v, 'Email'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _phone,
              label: 'Phone Number',
              hint: '+1 555 000 0000  (optional)',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 1 · Your Role
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pageYourRole(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
      child: UserInfoPageCard(
        title: 'Your Role',
        subtitle: 'Your position and working preferences.',
        isDarkMode: isDark,
        animDelay: const Duration(milliseconds: 40),
        child: Column(
          children: [
            TInput(
              controller: _roleTitle,
              label: 'Role Title',
              hint: 'e.g. Senior Designer, Lead Engineer',
              prefixIcon: TIcons.invite,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _department,
              label: 'Department',
              hint: 'e.g. Product, Engineering, Design',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            SDropdown(
              label: 'Work Type',
              value: _workType,
              items: const [
                'Full-time',
                'Part-time',
                'Freelancer',
                'Intern',
                'Contractor',
              ],
              isDarkMode: isDark,
              onChanged: (v) => setState(() => _workType = v),
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _timezone,
              label: 'Timezone',
              hint: 'e.g. America/New_York, Europe/London',
              prefixIcon: Icons.public_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            Row(
              children: [
                Expanded(
                  child: TInput(
                    controller: _workHoursStart,
                    label: 'Work Start',
                    hint: '09:00',
                    prefixIcon: Icons.schedule_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: TInput(
                    controller: _workHoursEnd,
                    label: 'Work End',
                    hint: '17:00',
                    prefixIcon: Icons.schedule_rounded,
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 2 (create) · Organisation
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pageOrganisation(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
      child: UserInfoPageCard(
        title: 'Organisation',
        subtitle: 'Set up your new organisation.',
        isDarkMode: isDark,
        animDelay: const Duration(milliseconds: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoChip(
              icon: Icons.corporate_fare_rounded,
              text:
                  'This creates your organisation. An invite link will be auto-generated for your team.',
              isDark: isDark,
              color: TColors.primary,
            ),
            const SizedBox(height: TSizes.md),
            TInput(
              controller: _orgName,
              label: 'Organisation Name',
              hint: 'e.g. Acme Corp, TeamSpot Inc.',
              prefixIcon: Icons.business_rounded,
              validator: (v) =>
                  UserInfoUseCase.requiredField(v, 'Organisation name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TInput(
                    controller: _orgSlug,
                    label: 'URL Slug  (auto-generated)',
                    hint: 'acme-corp',
                    readOnly: !_slugEditable,
                    prefixIcon: Icons.tag_rounded,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-z0-9-]')),
                    ],
                  ),
                ),
                const SizedBox(width: TSizes.xs),
                GestureDetector(
                  onTap: () =>
                      setState(() => _slugEditable = !_slugEditable),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    width: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _slugEditable
                          ? TColors.primary.withValues(alpha: 0.12)
                          : (isDark
                              ? TColors.darkCard
                              : TColors.lightSurface),
                      borderRadius:
                          BorderRadius.circular(TSizes.radiusMd),
                      border: Border.all(
                        color: _slugEditable
                            ? TColors.primary.withValues(alpha: 0.45)
                            : (isDark
                                ? TColors.darkBorder
                                : TColors.lightBorder),
                      ),
                    ),
                    child: Icon(
                      _slugEditable
                          ? Icons.lock_open_rounded
                          : Icons.edit_rounded,
                      size: 16,
                      color: _slugEditable
                          ? TColors.primary
                          : (isDark
                              ? TColors.textSecondaryDark
                              : TColors.textSecondaryLight),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _orgIndustry,
              label: 'Industry',
              hint: 'e.g. SaaS, Fintech, Healthcare',
              prefixIcon: Icons.category_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            SDropdown(
              label: 'Organisation Size',
              value: _orgSize,
              items: const [
                '1-10',
                '11-50',
                '51-200',
                '201-500',
                '501-1000',
                '1000+',
              ],
              isDarkMode: isDark,
              onChanged: (v) => setState(() => _orgSize = v),
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _orgDomain,
              label: 'Website / Domain',
              hint: 'https://acme.com',
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _orgCountry,
              label: 'Country / HQ Location',
              hint: 'e.g. United States, London UK',
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 3 (create) · Workspace Setup
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pageWorkspaceSetup(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
      child: UserInfoPageCard(
        title: 'Workspace',
        subtitle: 'Configure your first workspace.',
        isDarkMode: isDark,
        animDelay: const Duration(milliseconds: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoChip(
              icon: Icons.workspaces_rounded,
              text:
                  'Workspaces organise your projects and teams. You can create more anytime.',
              isDark: isDark,
              color: TColors.purple,
            ),
            const SizedBox(height: TSizes.md),
            TInput(
              controller: _workspaceName,
              label: 'Workspace Name',
              hint: 'e.g. Product Team, Engineering Hub',
              prefixIcon: Icons.workspaces_outlined,
              validator: (v) =>
                  UserInfoUseCase.requiredField(v, 'Workspace name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _workspaceDesc,
              label: 'Description',
              hint: 'What this workspace is for  (optional)',
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            SDropdown(
              label: 'Your Permission Level',
              value: _permissionsLevel,
              items: const ['admin', 'manager', 'employee', 'member'],
              isDarkMode: isDark,
              onChanged: (v) => setState(() => _permissionsLevel = v),
            ),
            const SizedBox(height: TSizes.sm + 2),
            _PermissionsHintCard(
                isDark: isDark, selected: _permissionsLevel),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 2 (join) · Join Organisation
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pageJoinOrg(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
      child: UserInfoPageCard(
        title: 'Join Organisation',
        subtitle: 'Enter your invite code to get started.',
        isDarkMode: isDark,
        animDelay: const Duration(milliseconds: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TWidgetAnimations.scaleIn(
              duration: const Duration(milliseconds: 360),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      TColors.green
                          .withValues(alpha: isDark ? 0.13 : 0.09),
                      TColors.primary
                          .withValues(alpha: isDark ? 0.09 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(TSizes.radiusLg),
                  border: Border.all(
                    color: TColors.green.withValues(alpha: 0.38),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TColors.green
                            .withValues(alpha: isDark ? 0.20 : 0.13),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.vpn_key_rounded,
                        color: TColors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: TSizes.sm),
                    Text(
                      'Invite Code Required',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? TColors.textPrimaryDark
                            : TColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask your organisation admin for the invite code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? TColors.textSecondaryDark
                            : TColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: TSizes.md),
                    TInput(
                      controller: _inviteCode,
                      label: 'Invite Code',
                      hint: 'INV-XXXXXXXX',
                      prefixIcon: Icons.vpn_key_rounded,
                      validator: UserInfoUseCase.validateInviteCode,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TSizes.md),
            _InfoChip(
              icon: Icons.info_outline_rounded,
              text:
                  'Your company details will be automatically populated once you join.',
              isDark: isDark,
              color: TColors.primary,
            ),
            const SizedBox(height: TSizes.md),
            SDropdown(
              label: 'Requested Permission Level',
              value: _permissionsLevel,
              items: const ['manager', 'employee', 'member', 'guest'],
              isDarkMode: isDark,
              onChanged: (v) => setState(() => _permissionsLevel = v),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 4 (create) / 3 (join) · About You
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pageAboutYou(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: TSizes.xs),
      child: UserInfoPageCard(
        title: 'About You',
        subtitle: 'A little extra detail — all optional.',
        isDarkMode: isDark,
        animDelay: const Duration(milliseconds: 40),
        child: Column(
          children: [
            TInput(
              controller: _bio,
              label: 'Short Bio',
              hint: 'A sentence or two about yourself...',
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _interests,
              label: 'Skills & Interests',
              hint: 'Design, Figma, Swift... (comma-separated)',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _linkedIn,
              label: 'LinkedIn',
              hint: 'https://linkedin.com/in/you',
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: TSizes.sm + 2),
            TInput(
              controller: _github,
              label: 'GitHub',
              hint: 'https://github.com/you',
              prefixIcon: TIcons.github,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Supporting widgets
// ══════════════════════════════════════════════════════════════════════════════

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
        border:
            Border.all(color: TColors.primary.withValues(alpha: 0.30)),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: TColors.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.current,
    required this.isDark,
    required this.isJoin,
  });

  final int index;
  final int current;
  final bool isDark;
  final bool isJoin;

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    final isDone = index < current;
    final activeColor = isJoin ? TColors.green : TColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      width: isActive ? 30 : 24,
      height: isActive ? 30 : 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? TColors.green
            : isActive
                ? activeColor
                : (isDark ? TColors.darkCard : TColors.lightSurface),
        border: Border.all(
          color: isDone
              ? TColors.green
              : isActive
                  ? activeColor
                  : (isDark ? TColors.darkBorder : TColors.lightBorder),
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : (isDark
                          ? TColors.textSecondaryDark
                          : TColors.textSecondaryLight),
                ),
              ),
      ),
    );
  }
}

/// Contextual info banner used on section pages.
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.isDark,
    required this.color,
  });

  final IconData icon;
  final String text;
  final bool isDark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TSizes.md, vertical: TSizes.sm + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark
                    ? TColors.textSecondaryDark
                    : TColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline hint that explains the selected permission level.
class _PermissionsHintCard extends StatelessWidget {
  const _PermissionsHintCard({
    required this.isDark,
    required this.selected,
  });

  final bool isDark;
  final String? selected;

  static const _hints = {
    'admin':
        'Full access — manage members, projects, settings, and billing.',
    'manager':
        'Manage projects, tasks, and team members. Cannot touch billing.',
    'employee':
        'Create and manage own tasks and projects. Standard access.',
    'member': 'View and contribute to projects. Limited creation rights.',
  };

  @override
  Widget build(BuildContext context) {
    final hint = selected != null ? _hints[selected] : null;
    if (hint == null) return const SizedBox.shrink();

    return TWidgetAnimations.fadeIn(
      child: Container(
        padding: const EdgeInsets.all(TSizes.sm + 2),
        decoration: BoxDecoration(
          color:
              TColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(
              color: TColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined,
                size: 14, color: TColors.primary),
            const SizedBox(width: TSizes.xs + 2),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: isDark
                      ? TColors.textSecondaryDark
                      : TColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
