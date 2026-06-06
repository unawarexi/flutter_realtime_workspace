import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/bg_patterns.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/decorative_painters.dart';
import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/features/authentication/presentation/widgets/avatar_picker.dart';
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
  late final SlideUpFadeAnim _enterAnim;

  final _formKey        = GlobalKey<FormState>();
  final _pageController = PageController();
  int  _currentPage     = 0;
  bool _isLoading       = false;

  // Page 0
  final _fullName      = TextEditingController();
  final _displayName   = TextEditingController();
  final _profilePicUrl = TextEditingController();
  final _email         = TextEditingController();
  final _phone         = TextEditingController();
  File? _pickedImage;

  // Page 1
  final _roleTitle  = TextEditingController();
  final _department = TextEditingController();
  String? _workType;
  final _timezone   = TextEditingController();
  final _workStart  = TextEditingController();
  final _workEnd    = TextEditingController();

  // Page 2 create
  final _orgName     = TextEditingController();
  final _orgSlug     = TextEditingController();
  final _orgIndustry = TextEditingController();
  String? _orgSize;
  final _orgDomain   = TextEditingController();
  final _orgCountry  = TextEditingController();
  bool _slugEditable = false;

  // Page 2 join
  final _inviteCode = TextEditingController();

  // Page 3 create
  final _workspaceName = TextEditingController();
  final _workspaceDesc = TextEditingController();
  String? _permissionsLevel;
  String? _workspaceVisibility = 'private';
  String? _workspaceTemplate   = 'kanban';

  // Page 4/3
  final _bio        = TextEditingController();
  final _skillInput = TextEditingController();
  final List<String> _skillTags = [];
  final _linkedIn   = TextEditingController();
  final _github     = TextEditingController();
  final _twitter    = TextEditingController();
  final _website    = TextEditingController();

  int get _totalPages => widget.mode == UserInfoMode.create ? 5 : 4;

  @override
  void initState() {
    super.initState();
    _enterAnim = SlideUpFadeAnim(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      beginOffset: const Offset(0, 0.06),
    )..forward();
    _orgName.addListener(_autoSlug);
  }

  void _autoSlug() {
    if (_slugEditable) return;
    _orgSlug.text = _orgName.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }

  @override
  void dispose() {
    _enterAnim.dispose();
    _pageController.dispose();
    _orgName.removeListener(_autoSlug);
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _allControllers => [
        _fullName, _displayName, _profilePicUrl, _email, _phone,
        _roleTitle, _department, _timezone, _workStart, _workEnd,
        _orgName, _orgSlug, _orgIndustry, _orgDomain, _orgCountry,
        _inviteCode, _workspaceName, _workspaceDesc,
        _bio, _skillInput, _linkedIn, _github, _twitter, _website,
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
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final payload = UserInfoUseCase.buildPayload(
      fullName:          _fullName.text,
      displayName:       _displayName.text,
      profilePictureUrl: _profilePicUrl.text,
      email:             _email.text,
      phone:             _phone.text,
      roleTitle:         _roleTitle.text,
      department:        _department.text,
      workType:          _workType,
      timezone:          _timezone.text,
      workingHoursStart: _workStart.text,
      workingHoursEnd:   _workEnd.text,
      companyName:       _orgName.text,
      companyWebsite:    _orgDomain.text,
      industry:          _orgIndustry.text,
      teamSize:          _orgSize,
      officeLocation:    _orgCountry.text,
      orgSlug:           _orgSlug.text,
      inviteCode:        _inviteCode.text,
      teamProjectName:   _workspaceName.text,
      permissionsLevel:  _permissionsLevel,
      interestsSkills:   _skillTags.join(', '),
      bio:               _bio.text,
      linkedIn:          _linkedIn.text,
      github:            _github.text,
    );
    final tw = _twitter.text.trim();
    final ws = _website.text.trim();
    if (tw.isNotEmpty || ws.isNotEmpty) {
      final existing = (payload['socialLinks'] as Map<String, dynamic>?) ?? {};
      payload['socialLinks'] = {
        ...existing,
        if (tw.isNotEmpty) 'twitter': tw,
        if (ws.isNotEmpty) 'website': ws,
      };
    }
    if (_workspaceVisibility != null) payload['workspaceVisibility'] = _workspaceVisibility;
    if (_workspaceTemplate != null)   payload['workspaceTemplate']   = _workspaceTemplate;
    await UserInfoUseCase.submit(
      context: context,
      ref: ref,
      payload: payload,
      imagePath: _pickedImage?.path,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  void _addSkillTag() {
    final tag = _skillInput.text.trim();
    if (tag.isNotEmpty && !_skillTags.contains(tag)) {
      setState(() { _skillTags.add(tag); _skillInput.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad   = TResponsive.pagePadding(context);
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
                    colors: [TColors.primary, TColors.blue700],
                    orbCount: 4, isDark: isDark, seed: 13,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: TDotGridPainter(
                    dotColor: (isDark ? TColors.darkBorder : TColors.lightBorder).withValues(alpha: 0.55),
                    spacing: 28, dotRadius: 1.0,
                  ),
                ),
              ),
              Positioned(
                top: 0, right: 0,
                child: SizedBox(
                  width: 180, height: 180,
                  child: CustomPaint(
                    painter: TCornerArcPainter(
                      color: TColors.primary.withValues(alpha: 0.12),
                      radius: 160, corner: CornerPosition.topRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0,
                child: SizedBox(
                  width: 120, height: 120,
                  child: CustomPaint(
                    painter: TCornerArcPainter(
                      color: TColors.blue700.withValues(alpha: isDark ? 0.07 : 0.05),
                      radius: 100, corner: CornerPosition.bottomLeft,
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
                          _buildTopBar(isDark, hPad),
                          _buildProgressBar(isDark, hPad),
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: widget.mode == UserInfoMode.create
                                  ? [
                                      _pageBasicProfile(isDark, hPad),
                                      _pageYourRole(isDark, hPad),
                                      _pageOrganisation(isDark, hPad),
                                      _pageWorkspace(isDark, hPad),
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

  Widget _buildTopBar(bool isDark, double hPad) {
    final isJoin = widget.mode == UserInfoMode.join;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.sm, hPad, 0),
      child: Row(
        children: [
          _IconBtn(icon: TIcons.back, isDark: isDark, onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile Setup',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3,
                    color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight,
                  ),
                ),
                Text(
                  isJoin ? 'Joining an organisation' : 'Creating your organisation',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: isDark ? 0.15 : 0.10),
              borderRadius: BorderRadius.circular(TSizes.radiusFull),
              border: Border.all(color: TColors.primary.withValues(alpha: 0.30)),
            ),
            child: Text(
              '${_currentPage + 1} / $_totalPages',
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: TColors.primary, letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark, double hPad) {
    final labels = widget.mode == UserInfoMode.create
        ? ['Basic Profile', 'Your Role', 'Organisation', 'Workspace', 'About You']
        : ['Basic Profile', 'Your Role', 'Join Organisation', 'About You'];
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.sm, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              minHeight: 3,
              backgroundColor: isDark ? TColors.darkBorder : TColors.lightBorder,
              color: TColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: Text(
              labels[_currentPage],
              key: ValueKey(_currentPage),
              style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 0.6, color: TColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                    text: 'Complete Setup',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                    prefixIcon: Icons.check_rounded,
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

  Widget _pageHeader({
    required String stepLabel,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepLabel.toUpperCase(),
          style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            letterSpacing: 1.1, color: TColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        TWidgetAnimations.fadeIn(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800,
              letterSpacing: -0.5, height: 1.15,
              color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13, height: 1.45,
            color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: TSizes.sm),
        Divider(
          height: 1,
          color: isDark ? TColors.darkBorder.withValues(alpha: 0.60) : TColors.lightBorder,
        ),
      ],
    );
  }

  // PAGE 0 — Basic Profile
  Widget _pageBasicProfile(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.xl + TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            stepLabel: 'Step 1 of $_totalPages',
            title: 'Basic Profile',
            subtitle: 'Start with your personal information.',
            isDark: isDark,
          ),
          const SizedBox(height: TSizes.md),
          Center(
            child: AvatarPicker(
              pickedFile: _pickedImage,
              networkUrl: _profilePicUrl.text,
              isDarkMode: isDark,
              onImagePicked: (f) => setState(() => _pickedImage = f),
            ),
          ),
          const SizedBox(height: TSizes.xs),
          Center(
            child: Text(
              'Tap to upload a profile photo',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(height: TSizes.md),
          TInput(
            controller: _fullName, label: 'Full Name', hint: 'e.g. Alex Johnson',
            prefixIcon: TIcons.profile,
            validator: (v) => UserInfoUseCase.requiredField(v, 'Full name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _displayName, label: 'Display Name',
            hint: 'How others see you (optional)', prefixIcon: Iconsax.user_tag,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _email, label: 'Work Email', hint: 'work@company.com',
            prefixIcon: TIcons.email, keyboardType: TextInputType.emailAddress,
            validator: (v) => UserInfoUseCase.requiredField(v, 'Email'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _phone, label: 'Phone Number',
            hint: '+1 555 000 0000  (optional)', prefixIcon: Iconsax.call,
            keyboardType: TextInputType.phone, textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  // PAGE 1 — Your Role
  Widget _pageYourRole(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.xl + TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            stepLabel: 'Step 2 of $_totalPages',
            title: 'Your Role',
            subtitle: 'Your position and working preferences.',
            isDark: isDark,
          ),
          const SizedBox(height: TSizes.md),
          TInput(
            controller: _roleTitle, label: 'Role Title',
            hint: 'e.g. Senior Designer, Lead Engineer', prefixIcon: Iconsax.medal_star,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _department, label: 'Department',
            hint: 'e.g. Product, Engineering, Design', prefixIcon: Iconsax.building_3,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.md),
          _SectionLabel(label: 'Work Type', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          _OptionGrid(
            options: const [
              _Opt('Full-time',  'Full-time',  Iconsax.monitor),
              _Opt('Part-time',  'Part-time',  Iconsax.clock),
              _Opt('Freelancer', 'Freelancer', Iconsax.flash),
              _Opt('Intern',     'Intern',     Iconsax.teacher),
              _Opt('Contractor', 'Contractor', Iconsax.people),
            ],
            selected: _workType, isDark: isDark,
            onSelect: (v) => setState(() => _workType = v),
          ),
          const SizedBox(height: TSizes.md),
          TInput(
            controller: _timezone, label: 'Timezone',
            hint: 'e.g. America/New_York, Europe/London',
            prefixIcon: Icons.public_rounded, textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.md),
          _SectionLabel(label: 'Working Hours', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          Row(
            children: [
              Expanded(
                child: TInput(
                  controller: _workStart, label: 'Start', hint: '09:00',
                  readOnly: true, prefixIcon: Icons.schedule_rounded,
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context, initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (t != null && mounted) {
                      setState(() => _workStart.text =
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
                child: Text(
                  'to',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
                  ),
                ),
              ),
              Expanded(
                child: TInput(
                  controller: _workEnd, label: 'End', hint: '17:00',
                  readOnly: true, prefixIcon: Icons.schedule_rounded,
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context, initialTime: const TimeOfDay(hour: 17, minute: 0),
                    );
                    if (t != null && mounted) {
                      setState(() => _workEnd.text =
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PAGE 2 create — Organisation
  Widget _pageOrganisation(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.xl + TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            stepLabel: 'Step 3 of $_totalPages',
            title: 'Organisation',
            subtitle: 'Set up your organisation on TeamSpot.',
            isDark: isDark,
          ),
          const SizedBox(height: TSizes.md),
          _InfoBanner(
            text: 'This creates your tenant workspace. An invite link will be generated for your team.',
            isDark: isDark,
          ),
          const SizedBox(height: TSizes.md),
          TInput(
            controller: _orgName, label: 'Organisation Name', hint: 'e.g. Acme Corp',
            prefixIcon: Iconsax.building_4,
            validator: (v) => UserInfoUseCase.requiredField(v, 'Organisation name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TInput(
                  controller: _orgSlug, label: 'URL Slug  (auto-generated)',
                  hint: 'acme-corp', readOnly: !_slugEditable, prefixIcon: Iconsax.hashtag,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]'))],
                ),
              ),
              const SizedBox(width: TSizes.xs),
              GestureDetector(
                onTap: () => setState(() => _slugEditable = !_slugEditable),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 50, width: 44, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _slugEditable
                        ? TColors.primary.withValues(alpha: 0.10)
                        : (isDark ? TColors.darkCard : TColors.lightSurface),
                    borderRadius: BorderRadius.circular(TSizes.radiusMd),
                    border: Border.all(
                      color: _slugEditable
                          ? TColors.primary.withValues(alpha: 0.40)
                          : (isDark ? TColors.darkBorder : TColors.lightBorder),
                    ),
                  ),
                  child: Icon(
                    _slugEditable ? Icons.lock_open_rounded : Icons.edit_rounded,
                    size: 16,
                    color: _slugEditable
                        ? TColors.primary
                        : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _orgIndustry, label: 'Industry',
            hint: 'e.g. SaaS, Fintech, Healthcare', prefixIcon: Iconsax.category,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.md),
          _SectionLabel(label: 'Organisation Size', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          _OptionGrid(
            options: const [
              _Opt('1-10',     '1–10',     Iconsax.people,     'Startup'),
              _Opt('11-50',    '11–50',    Iconsax.people,     'Small'),
              _Opt('51-200',   '51–200',   Iconsax.building_3, 'Medium'),
              _Opt('201-500',  '201–500',  Iconsax.building_3, 'Growing'),
              _Opt('501-1000', '501–1000', Iconsax.building_4, 'Large'),
              _Opt('1000+',    '1000+',    Iconsax.building_4, 'Enterprise'),
            ],
            selected: _orgSize, isDark: isDark,
            onSelect: (v) => setState(() => _orgSize = v), columns: 3,
          ),
          const SizedBox(height: TSizes.md),
          TInput(
            controller: _orgDomain, label: 'Website / Domain', hint: 'https://acme.com',
            prefixIcon: Icons.link_rounded, keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _orgCountry, label: 'Country / HQ Location',
            hint: 'e.g. United States, London UK', prefixIcon: Icons.location_on_outlined,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  // PAGE 3 create — Workspace
  Widget _pageWorkspace(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.xl + TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            stepLabel: 'Step 4 of $_totalPages',
            title: 'Workspace',
            subtitle: 'Configure your first project workspace.',
            isDark: isDark,
          ),
          const SizedBox(height: TSizes.md),
          _InfoBanner(
            text: 'Workspaces organise your projects and teams. You can create more at any time.',
            isDark: isDark,
          ),
          const SizedBox(height: TSizes.md),
          TInput(
            controller: _workspaceName, label: 'Workspace Name',
            hint: 'e.g. Product Team, Engineering Hub', prefixIcon: Iconsax.element_4,
            validator: (v) => UserInfoUseCase.requiredField(v, 'Workspace name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _workspaceDesc, label: 'Description',
            hint: 'What this workspace is for  (optional)',
            prefixIcon: Iconsax.note_text, maxLines: 2, textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.md),
          _SectionLabel(label: 'Visibility', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          _OptionGrid(
            options: const [
              _Opt('private',     'Private',   Iconsax.lock,        'Invite only'),
              _Opt('public',      'Public',    Iconsax.global,      'Anyone in org'),
              _Opt('invite_only', 'Link Only', Iconsax.link_circle, 'Via link'),
            ],
            selected: _workspaceVisibility, isDark: isDark,
            onSelect: (v) => setState(() => _workspaceVisibility = v), columns: 3,
          ),
          const SizedBox(height: TSizes.md),
          _SectionLabel(label: 'Default Project Template', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          _OptionGrid(
            options: const [
              _Opt('kanban', 'Kanban', Iconsax.kanban,       'Card-based'),
              _Opt('scrum',  'Scrum',  Iconsax.chart_square, 'Sprint-based'),
              _Opt('blank',  'Blank',  Iconsax.document,     'Start fresh'),
            ],
            selected: _workspaceTemplate, isDark: isDark,
            onSelect: (v) => setState(() => _workspaceTemplate = v), columns: 3,
          ),
          const SizedBox(height: TSizes.md),
          _SectionLabel(label: 'Your Permission Level', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          _PermissionSelector(
            selected: _permissionsLevel, isDark: isDark,
            options: const [
              _PermOpt('admin',    'Admin',    'Full access — members, projects, billing & settings.', Iconsax.shield_tick),
              _PermOpt('manager',  'Manager',  'Manage projects, tasks & team. No billing access.',    Iconsax.briefcase),
              _PermOpt('employee', 'Employee', 'Create & manage own tasks and projects.',              Iconsax.user_octagon),
              _PermOpt('member',   'Member',   'View and contribute to projects.',                     Iconsax.people),
            ],
            onSelect: (v) => setState(() => _permissionsLevel = v),
          ),
        ],
      ),
    );
  }

  // PAGE 2 join — Join Organisation
  Widget _pageJoinOrg(bool isDark, double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.xl + TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            stepLabel: 'Step 3 of $_totalPages',
            title: 'Join Organisation',
            subtitle: 'Enter your invite code to get started.',
            isDark: isDark,
          ),
          const SizedBox(height: TSizes.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(TSizes.radiusMd),
              border: Border.all(color: TColors.primary.withValues(alpha: 0.22)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: TColors.primary, size: 26),
                ),
                const SizedBox(height: TSizes.sm),
                Text(
                  'Invite Code Required',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ask your organisation admin for the invite code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12, height: 1.4,
                    color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: TSizes.md),
                TInput(
                  controller: _inviteCode, label: 'Invite Code', hint: 'INV-XXXXXXXX',
                  prefixIcon: Icons.vpn_key_rounded,
                  validator: UserInfoUseCase.validateInviteCode,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                    TextInputFormatter.withFunction(
                      (_, newVal) => TextEditingValue(
                        text: newVal.text.toUpperCase(), selection: newVal.selection,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: TSizes.md),
          _InfoBanner(
            text: 'Company details will be automatically populated once you join.',
            isDark: isDark,
          ),
          const SizedBox(height: TSizes.md),
          _SectionLabel(label: 'Requested Permission Level', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          _PermissionSelector(
            selected: _permissionsLevel, isDark: isDark,
            options: const [
              _PermOpt('manager',  'Manager',  'Manage projects & tasks. Suggested for leads.', Iconsax.briefcase),
              _PermOpt('employee', 'Employee', 'Standard access to tasks and projects.',        Iconsax.user_octagon),
              _PermOpt('member',   'Member',   'View and contribute to projects.',              Iconsax.people),
              _PermOpt('guest',    'Guest',    'Read-only access. Limited contributions.',      Iconsax.eye),
            ],
            onSelect: (v) => setState(() => _permissionsLevel = v),
          ),
        ],
      ),
    );
  }

  // PAGE 4/3 — About You
  Widget _pageAboutYou(bool isDark, double hPad) {
    final isCreate = widget.mode == UserInfoMode.create;
    const maxBio   = 500;
    final bioLen   = _bio.text.length;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.xl + TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            stepLabel: 'Step ${isCreate ? 5 : 4} of $_totalPages',
            title: 'About You',
            subtitle: 'Optional details that help your team know you better.',
            isDark: isDark,
          ),
          const SizedBox(height: TSizes.md),
          Stack(
            children: [
              TInput(
                controller: _bio, label: 'Short Bio',
                hint: 'A sentence or two about yourself...',
                maxLines: 4, textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              Positioned(
                bottom: 8, right: 10,
                child: Text(
                  '$bioLen / $maxBio',
                  style: TextStyle(
                    fontSize: 10,
                    color: bioLen > maxBio
                        ? TColors.error
                        : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),
          _SectionLabel(label: 'Skills & Interests', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          Row(
            children: [
              Expanded(
                child: TInput(
                  controller: _skillInput, label: 'Add a skill',
                  hint: 'Design, Flutter, Figma...', prefixIcon: Iconsax.tag,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: TSizes.xs),
              GestureDetector(
                onTap: _addSkillTag,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 50, width: 44, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _skillInput.text.trim().isNotEmpty
                        ? TColors.primary.withValues(alpha: 0.12)
                        : (isDark ? TColors.darkCard : TColors.lightSurface),
                    borderRadius: BorderRadius.circular(TSizes.radiusMd),
                    border: Border.all(
                      color: _skillInput.text.trim().isNotEmpty
                          ? TColors.primary.withValues(alpha: 0.45)
                          : (isDark ? TColors.darkBorder : TColors.lightBorder),
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded, size: 18,
                    color: _skillInput.text.trim().isNotEmpty
                        ? TColors.primary
                        : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight),
                  ),
                ),
              ),
            ],
          ),
          if (_skillTags.isNotEmpty) ...[
            const SizedBox(height: TSizes.sm),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _skillTags.map((tag) {
                return GestureDetector(
                  onTap: () => setState(() => _skillTags.remove(tag)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: TColors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                      borderRadius: BorderRadius.circular(TSizes.radiusFull),
                      border: Border.all(color: TColors.primary.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: TColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.close_rounded, size: 12, color: TColors.primary),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a tag to remove it',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? TColors.textSecondaryDark.withValues(alpha: 0.70)
                    : TColors.textSecondaryLight.withValues(alpha: 0.70),
              ),
            ),
          ],
          const SizedBox(height: TSizes.md),
          _SectionLabel(label: 'Social Links', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          TInput(
            controller: _linkedIn, label: 'LinkedIn', hint: 'https://linkedin.com/in/you',
            prefixIcon: Icons.link_rounded, keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _github, label: 'GitHub', hint: 'https://github.com/you',
            prefixIcon: TIcons.github, keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _twitter, label: 'X / Twitter', hint: 'https://x.com/yourhandle',
            prefixIcon: Icons.alternate_email_rounded, keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: TSizes.sm + 2),
          TInput(
            controller: _website, label: 'Personal Website', hint: 'https://yoursite.com',
            prefixIcon: Icons.language_rounded, keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _Opt {
  final String value;
  final String label;
  final IconData icon;
  final String? subtitle;
  const _Opt(this.value, this.label, this.icon, [this.subtitle]);
}

class _PermOpt {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  const _PermOpt(this.value, this.label, this.description, this.icon);
}

// ─────────────────────────────────────────────────────────────────────────────
// _OptionGrid — tile selector, single brand colour
// ─────────────────────────────────────────────────────────────────────────────

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.isDark,
    required this.onSelect,
    this.columns = 2,
  });

  final List<_Opt> options;
  final String? selected;
  final bool isDark;
  final ValueChanged<String> onSelect;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    for (int i = 0; i < options.length; i += columns) {
      final rowItems = options.sublist(i, (i + columns).clamp(0, options.length));
      rows.add(Row(
        children: [
          for (int j = 0; j < rowItems.length; j++) ...[
            Expanded(
              child: _OptionTile(
                opt: rowItems[j],
                isSelected: selected == rowItems[j].value,
                isDark: isDark,
                onTap: () => onSelect(rowItems[j].value),
              ),
            ),
            if (j < rowItems.length - 1) const SizedBox(width: TSizes.sm - 2),
          ],
          for (int k = rowItems.length; k < columns; k++) ...[
            const SizedBox(width: TSizes.sm - 2),
            const Expanded(child: SizedBox()),
          ],
        ],
      ));
      if (i + columns < options.length) rows.add(const SizedBox(height: TSizes.sm - 2));
    }
    return Column(children: rows);
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.opt,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final _Opt opt;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: TSizes.sm + 2, horizontal: TSizes.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? TColors.primary.withValues(alpha: isDark ? 0.16 : 0.09)
              : (isDark ? TColors.darkSurface : TColors.lightElevated),
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(
            color: isSelected
                ? TColors.primary.withValues(alpha: 0.50)
                : (isDark ? TColors.darkBorder : TColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              opt.icon, size: 17,
              color: isSelected
                  ? TColors.primary
                  : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight),
            ),
            const SizedBox(height: 4),
            Text(
              opt.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? TColors.primary
                    : (isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight),
              ),
            ),
            if (opt.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                opt.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PermissionSelector — role cards, single brand colour
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionSelector extends StatelessWidget {
  const _PermissionSelector({
    required this.options,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  final List<_PermOpt> options;
  final String? selected;
  final bool isDark;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((opt) {
        final sel = selected == opt.value;
        return GestureDetector(
          onTap: () => onSelect(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: TSizes.sm - 2),
            padding: const EdgeInsets.all(TSizes.sm + 2),
            decoration: BoxDecoration(
              color: sel
                  ? TColors.primary.withValues(alpha: isDark ? 0.14 : 0.08)
                  : (isDark ? TColors.darkSurface : TColors.lightElevated),
              borderRadius: BorderRadius.circular(TSizes.radiusMd),
              border: Border.all(
                color: sel
                    ? TColors.primary.withValues(alpha: 0.50)
                    : (isDark ? TColors.darkBorder : TColors.lightBorder),
                width: sel ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sel
                        ? TColors.primary.withValues(alpha: isDark ? 0.22 : 0.13)
                        : (isDark ? TColors.darkCard : TColors.lightSurface),
                    borderRadius: BorderRadius.circular(TSizes.radiusSm),
                  ),
                  child: Icon(
                    opt.icon, size: 16,
                    color: sel
                        ? TColors.primary
                        : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight),
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: sel
                              ? TColors.primary
                              : (isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        opt.description,
                        style: TextStyle(
                          fontSize: 11, height: 1.4,
                          color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (sel)
                  const Icon(Icons.check_circle_rounded, size: 16, color: TColors.primary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    return Row(
      children: [
        Expanded(child: Divider(color: muted.withValues(alpha: 0.30), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: muted,
            ),
          ),
        ),
        Expanded(child: Divider(color: muted.withValues(alpha: 0.30), height: 1)),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm + 2),
      decoration: BoxDecoration(
        color: TColors.primary.withValues(alpha: isDark ? 0.09 : 0.06),
        borderRadius: BorderRadius.circular(TSizes.radiusMd),
        border: Border.all(color: TColors.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: TColors.primary),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12, height: 1.5,
                color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.isDark, required this.onTap});
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(TSizes.sm),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkCard : TColors.lightSurface,
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder),
        ),
        child: Icon(
          icon, size: TSizes.iconSm + 2,
          color: isDark ? TColors.textDark : TColors.textLight,
        ),
      ),
    );
  }
}
