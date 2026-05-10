import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';

class ProjectBoards extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onShowAttachmentOptions;
  final void Function(bool) onShowTaskCreationModal;

  static const Color accentBlue = TColors.accentBlue;
  static const Color primaryBlue = TColors.primaryBlue;
  static const Color lightBlue = TColors.lightBlue;
  static const Color cardColorLight = TColors.cardColorLight;
  static const Color cardColorDark = TColors.cardColorDark;
  static const Color textPrimaryLight = TColors.textPrimaryLight;
  static const Color textPrimaryDark = TColors.textPrimaryDark;
  static const Color textSecondaryLight = TColors.textSecondaryLight;
  static const Color textSecondaryDark = TColors.textSecondaryDark;

  const ProjectBoards({
    super.key,
    required this.isDarkMode,
    required this.onShowAttachmentOptions,
    required this.onShowTaskCreationModal,
  });

  @override
  State<ProjectBoards> createState() => _ProjectBoardsState();
}

class _ProjectBoardsState extends State<ProjectBoards> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDarkMode ? TColors.cardColorDark : TColors.cardColorLight;
    final textPrimary = widget.isDarkMode ? TColors.textPrimaryDark : TColors.textPrimaryLight;
    final textSecondary = widget.isDarkMode ? TColors.textSecondaryDark : TColors.textSecondaryLight;
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildModernBoardScreen("To Do", Icons.radio_button_unchecked, cardColor, textPrimary, textSecondary),
              _buildModernBoardScreen("In Progress", Icons.hourglass_empty, cardColor, textPrimary, textSecondary),
              _buildModernBoardScreen("Done", Icons.check_circle_outline, cardColor, textPrimary, textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildPageIndicator(cardColor),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPageIndicator(Color cardColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? TColors.primaryBlue : TColors.lightBlue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  Widget _buildModernBoardScreen(
    String title,
    IconData icon,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TColors.lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: TColors.lightBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.more_vert, color: textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 56, color: textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first task to get started with this board',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(height: 32),
                      if (_currentPage == 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swipe_left, color: textSecondary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Swipe for more boards',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: TColors.lightBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.attach_file, color: TColors.lightBlue),
                            onPressed: widget.onShowAttachmentOptions,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onShowTaskCreationModal(widget.isDarkMode),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Create Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isDarkMode ? TColors.accentBlue : TColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
