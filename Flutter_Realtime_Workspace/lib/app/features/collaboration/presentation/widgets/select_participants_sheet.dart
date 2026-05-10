import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';
import 'package:flutter_realtime_workspace/shared/styles/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';

class SelectParticipantsSheet extends ConsumerStatefulWidget {
  final List<Map<String, String>> initiallySelected;
  const SelectParticipantsSheet({super.key, this.initiallySelected = const []});

  @override
  ConsumerState<SelectParticipantsSheet> createState() => _SelectParticipantsSheetState();
}

class _SelectParticipantsSheetState extends ConsumerState<SelectParticipantsSheet> {
  late List<Map<String, String>> _selected;
  bool _didFetch = false;

  @override
  void initState() {
    super.initState();
    _selected = List<Map<String, String>>.from(widget.initiallySelected);
    // Fetch all users when the modal opens
    Future.microtask(() async {
      await ref.read(userProvider.notifier).fetchAllUsers();
      if (mounted) setState(() => _didFetch = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final userState = ref.watch(userProvider);

    final users = (userState.userInfo?['users'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDarkMode ? TColors.cardColorDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? TColors.borderDark : TColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Participants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : TColors.backgroundDark,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: isDarkMode ? TColors.lightBlue : TColors.buttonPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (userState.isLoading || !_didFetch)
            const Center(child: CircularProgressIndicator())
          else if (users == null || users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No users found.',
                style: TextStyle(
                  color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final fullName = user['fullName'] ?? '';
                  final email = user['email'] ?? '';
                  final isSelected = _selected.any((p) => p['email'] == email);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? TColors.backgroundDarkAlt
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDarkMode
                            ? TColors.borderDark
                            : TColors.borderLight,
                        width: 0.8,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selected.add({'fullName': fullName, 'email': email});
                          } else {
                            _selected.removeWhere((p) => p['email'] == email);
                          }
                        });
                      },
                      title: Text(
                        fullName,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : TColors.backgroundDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: TextStyle(
                          color: isDarkMode
                              ? TColors.textSecondaryDark
                              : TColors.textTertiaryLight,
                          fontSize: 12,
                        ),
                      ),
                      activeColor: isDarkMode
                          ? TColors.lightBlue
                          : TColors.buttonPrimary,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
