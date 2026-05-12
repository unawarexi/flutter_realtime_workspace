import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/store/team_provider.dart';
import 'package:flutter_realtime_workspace/store/user_provider.dart';
import 'package:flutter_realtime_workspace/app/components/common/toast_alerts.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  String teamName = '';
  String description = '';
  List<Map<String, dynamic>> selectedUsers = [];

  // For search
  String _searchQuery = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchLoading = false;
  String? _searchError;

  void _showInviteUserSheet(BuildContext context) async {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                Future<void> _searchUser(String query) async {
                  setModalState(() {
                    _searchLoading = true;
                    _searchError = null;
                  });
                  try {
                    final user = await ref
                        .read(userProvider.notifier)
                        .fetchUserByInviteCodeOrEmail(
                          inviteCode: query.contains('@') ? null : query,
                          email: query.contains('@') ? query : null,
                        );
                    setModalState(() {
                      _searchResults = [];
                      if (user != null) {
                        _searchResults = [user];
                      }
                      _searchLoading = false;
                    });
                  } catch (e) {
                    setModalState(() {
                      _searchError = e.toString();
                      _searchLoading = false;
                    });
                  }
                }

                return Padding(
                  padding: EdgeInsets.only(
                    left: 18,
                    right: 18,
                    top: 18,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        "Add Team Members",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDarkMode ? Colors.white : TColors.backgroundDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Search bar
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Search by email or invite code",
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          // Add a search button inside the input field
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded),
                            tooltip: "Search",
                            onPressed: _searchQuery.isNotEmpty && !_searchLoading
                                ? () {
                                    _searchUser(_searchQuery);
                                  }
                                : null,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                        onChanged: (v) {
                          setModalState(() {
                            _searchQuery = v.trim();
                          });
                          // Do NOT call _searchUser here; only update the query.
                          // Clear results if input is empty
                          if (v.trim().isEmpty) {
                            setModalState(() {
                              _searchResults = [];
                              _searchError = null;
                            });
                          }
                        },
                        onSubmitted: (_) {
                          // Optionally, allow pressing enter to search
                          if (_searchQuery.isNotEmpty && !_searchLoading) {
                            _searchUser(_searchQuery);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_searchLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (_searchError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _searchError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      if (_searchResults.isNotEmpty)
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final user = _searchResults[idx];
                              final alreadySelected = selectedUsers.any((u) => u['_id'] == user['_id']);
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: (user['profilePicture'] ?? '').toString().isNotEmpty
                                      ? NetworkImage(user['profilePicture'])
                                      : const AssetImage("assets/images/avatar.png") as ImageProvider,
                                ),
                                title: Text(
                                  user['fullName'] ?? user['displayName'] ?? user['email'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDarkMode ? Colors.white : TColors.backgroundDark,
                                  ),
                                ),
                                subtitle: Text(
                                  "${user['email'] ?? ''} • ${user['roleTitle'] ?? ''}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDarkMode ? TColors.textSecondaryDark : TColors.textTertiaryLight,
                                  ),
                                ),
                                trailing: alreadySelected
                                    ? Icon(Icons.check_circle, color: TColors.green)
                                    : Icon(Icons.add_circle_outline, color: TColors.buttonPrimaryLight),
                                onTap: alreadySelected
                                    ? null
                                    : () {
                                        setState(() {
                                          selectedUsers.add(user);
                                        });
                                        setModalState(() {});
                                      },
                              );
                            },
                          ),
                        ),
                      if (_searchResults.isEmpty && _searchQuery.isNotEmpty && !_searchLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "No user found.",
                            style: TextStyle(
                              color: isDarkMode ? Colors.white54 : Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Selected users chips
                      if (selectedUsers.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: selectedUsers
                              .map((user) => Chip(
                                    label: Text(
                                      user['fullName'] ?? user['displayName'] ?? user['email'] ?? '',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    avatar: CircleAvatar(
                                      radius: 10,
                                      backgroundImage: (user['profilePicture'] ?? '').toString().isNotEmpty
                                          ? NetworkImage(user['profilePicture'])
                                          : const AssetImage("assets/images/avatar.png") as ImageProvider,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        selectedUsers.removeWhere((u) => u['_id'] == user['_id']);
                                      });
                                      setModalState(() {});
                                    },
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? TColors.buttonPrimary
                                : TColors.buttonPrimaryLight,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final teamState = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Team'),
        backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : TColors.backgroundDark,
        ),
      ),
      backgroundColor: isDarkMode ? TColors.backgroundDarkAlt : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (isDarkMode
                                ? TColors.buttonPrimary
                                : TColors.buttonPrimaryLight)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        Icons.group_add_rounded,
                        color: isDarkMode
                            ? TColors.buttonPrimary
                            : TColors.buttonPrimaryLight,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Create New Team',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : TColors.backgroundDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Team Name Field
                _buildInputField(
                  label: 'Team Name',
                  hint: 'Enter team name',
                  icon: Icons.badge_outlined,
                  onChanged: (v) => setState(() => teamName = v),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Team name required' : null,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                // Description Field
                _buildInputField(
                  label: 'Description',
                  hint: 'Brief description (optional)',
                  icon: Icons.description_outlined,
                  onChanged: (v) => setState(() => description = v),
                  maxLines: 2,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                // Invite Members Field (single field)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Members',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : TColors.backgroundDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showInviteUserSheet(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? TColors.cardColorDark : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: selectedUsers.isEmpty
                              ? Text(
                                  "Tap to add team members",
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? TColors.textSecondaryDark
                                        : TColors.textTertiaryLight,
                                    fontSize: 12,
                                  ),
                                )
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: selectedUsers
                                      .map((user) => Chip(
                                            label: Text(
                                              user['fullName'] ??
                                                  user['displayName'] ??
                                                  user['email'] ??
                                                  '',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            avatar: CircleAvatar(
                                              radius: 10,
                                              backgroundImage: (user['profilePicture'] ?? '').toString().isNotEmpty
                                                  ? NetworkImage(user['profilePicture'])
                                                  : const AssetImage("assets/images/avatar.png") as ImageProvider,
                                            ),
                                            onDeleted: () {
                                              setState(() {
                                                selectedUsers.removeWhere((u) => u['_id'] == user['_id']);
                                              });
                                            },
                                          ))
                                      .toList(),
                                ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? TColors.buttonPrimary
                          : TColors.buttonPrimaryLight,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadowColor: (isDarkMode
                              ? TColors.buttonPrimary
                              : TColors.buttonPrimaryLight)
                          .withOpacity(0.3),
                    ),
                    onPressed: teamState.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              final members = [
                                for (final user in selectedUsers)
                                  {
                                    "userId": user['_id'],
                                    "role": "member",
                                    "status": "active",
                                  }
                              ];
                              final data = {
                                "name": teamName,
                                "description": description,
                                "members": members,
                              };
                              try {
                                await ref.read(teamProvider.notifier).createTeam(data);
                                if (context.mounted) {
                                  context.showToast(
                                    "Team created successfully!",
                                    type: ToastType.success,
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  context.showToast(
                                    "Failed to create team. ${e.toString()}",
                                    type: ToastType.error,
                                  );
                                }
                              }
                            }
                          },
                    child: teamState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Create Team',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                if (teamState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      teamState.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDarkMode
              ? TColors.textSecondaryDark
              : TColors.textTertiaryLight,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : TColors.backgroundDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? TColors.textSecondaryDark
                : TColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          style: TextStyle(
            color: isDarkMode ? Colors.white : TColors.backgroundDark,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode
                  ? TColors.textTertiaryLight
                  : TColors.textSecondaryDark,
              fontSize: 12,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 16,
                color:
                    isDarkMode ? TColors.lightBlue : TColors.buttonPrimaryLight,
              ),
            ),
            filled: true,
            fillColor: isDarkMode ? TColors.cardColorDark : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                width: 0.8,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode ? TColors.borderDark : TColors.borderLight,
                width: 0.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode
                    ? TColors.buttonPrimary
                    : TColors.buttonPrimaryLight,
                width: 1.2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
