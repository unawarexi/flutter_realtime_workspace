import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/core/utils/permission_helper.dart';
import 'package:flutter_realtime_workspace/store/auth_provider.dart';
import 'package:flutter_realtime_workspace/store/ai_provider.dart';
import 'package:flutter_realtime_workspace/app/features/ai/presentation/widgets/ai_message_bubble.dart';
import 'package:flutter_realtime_workspace/app/features/ai/presentation/widgets/ai_tools_panel.dart';
import 'package:flutter_realtime_workspace/app/features/ai/presentation/screens/ai_conversations_screen.dart';
import 'package:flutter_realtime_workspace/app/components/shapes/shapes.dart';

// ── Local chat message model ────────────────────────────────────────────────
class _ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;
  final String? toolName;
  final String? toolStatus;

  const _ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
    this.toolName,
    this.toolStatus,
  });

  _ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    String? toolName,
    String? toolStatus,
  }) =>
      _ChatMessage(
        id: id,
        content: content ?? this.content,
        isUser: isUser,
        timestamp: timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
        toolName: toolName ?? this.toolName,
        toolStatus: toolStatus ?? this.toolStatus,
      );
}

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  String? _conversationId;
  bool _isSending = false;
  bool _showTools = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _userRole =>
      ref.read(currentUserProvider).valueOrNull?.permissionsLevel ?? 'guest';

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    final userMsg = _ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final assistantId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final placeholderMsg = _ChatMessage(
      id: assistantId,
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.addAll([userMsg, placeholderMsg]);
      _isSending = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      final body = <String, dynamic>{
        'message': text,
        if (_conversationId != null) 'conversationId': _conversationId,
      };

      final response = await ref.read(aiRepositoryProvider).chat(body);

      final reply = response['message'] as String? ??
          response['response'] as String? ??
          response['content'] as String? ??
          'I received your message but have no response content.';
      _conversationId =
          response['conversationId'] as String? ?? _conversationId;

      setState(() {
        final idx = _messages.indexWhere((m) => m.id == assistantId);
        if (idx >= 0) {
          _messages[idx] = _messages[idx].copyWith(
            content: reply,
            isStreaming: false,
          );
        }
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == assistantId);
        if (idx >= 0) {
          _messages[idx] = _messages[idx].copyWith(
            content: 'Sorry, something went wrong. Please try again.',
            isStreaming: false,
          );
        }
        _isSending = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _conversationId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final canChat = PermissionHelper.canUseAI(_userRole);

    return Scaffold(
      backgroundColor:
          isDark ? TColors.backgroundDarkAlt : TColors.backgroundLight,
      appBar: _buildAppBar(isDark),
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -80,
            left: -60,
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: TOrbFieldPainter(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  ],
                  orbCount: 2,
                  isDark: isDark,
                  seed: 42,
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildChatList(isDark),
                ),
                if (canChat) _buildInputBar(isDark),
              ],
            ),
          ),
          if (_showTools)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: _buildToolsPanel(isDark),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: isDark ? Colors.white : TColors.textPrimaryLight,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : TColors.textPrimaryLight,
                ),
              ),
              Text(
                _conversationId != null ? 'Active session' : 'Ready to help',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? TColors.darkMuted : TColors.lightMuted,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (PermissionHelper.canExecuteAITools(_userRole))
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _showTools
                    ? const Color(0xFF6366F1)
                    : (isDark ? TColors.darkElevated : TColors.lightElevated),
                borderRadius: BorderRadius.circular(TSizes.radiusSm),
              ),
              child: Icon(
                Icons.extension_rounded,
                size: 14,
                color: _showTools
                    ? Colors.white
                    : (isDark ? TColors.darkMuted : TColors.lightMuted),
              ),
            ),
            onPressed: () => setState(() => _showTools = !_showTools),
          ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? TColors.darkElevated : TColors.lightElevated,
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
            ),
            child: Icon(Icons.history_rounded, size: 14,
              color: isDark ? TColors.darkMuted : TColors.lightMuted),
          ),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AIConversationsScreen())),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? TColors.darkElevated : TColors.lightElevated,
              borderRadius: BorderRadius.circular(TSizes.radiusSm),
            ),
            child: Icon(Icons.add_rounded, size: 14,
              color: isDark ? TColors.darkMuted : TColors.lightMuted),
          ),
          onPressed: _startNewChat,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final suggestions = [
      'Summarize our project status',
      'Create a task for the sprint',
      'Search workspace for design docs',
      'What are my pending tickets?',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.paddingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TSizes.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
            const SizedBox(height: TSizes.paddingLG),
            Text('How can I help you today?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : TColors.textPrimaryLight)),
            const SizedBox(height: TSizes.sm),
            Text('Ask me anything about your workspace,\nprojects, or tasks.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5,
                color: isDark ? TColors.darkMuted : TColors.lightMuted)),
            const SizedBox(height: TSizes.paddingXL),
            Text('SUGGESTIONS', style: TextStyle(fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.2,
              color: isDark ? TColors.darkMuted : TColors.lightMuted)),
            const SizedBox(height: TSizes.paddingSM),
            Wrap(
              spacing: TSizes.sm, runSpacing: TSizes.sm,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) {
                return GestureDetector(
                  onTap: () {
                    _inputController.text = s;
                    _sendMessage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? TColors.darkCard : TColors.lightSurface,
                      borderRadius: BorderRadius.circular(TSizes.radiusMd),
                      border: Border.all(
                        color: isDark ? TColors.darkBorder : TColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_outlined, size: 12,
                          color: const Color(0xFF6366F1).withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(s, style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (PermissionHelper.canUseRAG(_userRole)) ...[
              const SizedBox(height: TSizes.paddingXL),
              _buildRAGStatusCard(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRAGStatusCard(bool isDark) {
    final ragStatus = ref.watch(aiRagStatusProvider);
    return ragStatus.when(
      data: (data) {
        final docCount = data['documentCount'] ?? 0;
        final status = data['status'] as String? ?? 'unknown';
        final isReady = status == 'ready' || status == 'active';
        return Container(
          padding: const EdgeInsets.all(TSizes.paddingSM + 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(TSizes.radiusMd),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8,
                decoration: BoxDecoration(
                  color: isReady ? TColors.success : TColors.warning,
                  shape: BoxShape.circle)),
              const SizedBox(width: TSizes.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Knowledge Base', style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                  Text('$docCount documents indexed', style: TextStyle(fontSize: 9,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted)),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildChatList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: TSizes.sm, bottom: TSizes.sm),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return AIMessageBubble(
          content: msg.content,
          isUser: msg.isUser,
          timestamp: msg.timestamp,
          isStreaming: msg.isStreaming,
          toolName: msg.toolName,
          toolStatus: msg.toolStatus,
        );
      },
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(TSizes.paddingMD, TSizes.paddingSM,
          TSizes.paddingMD, MediaQuery.of(context).padding.bottom + TSizes.paddingSM),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkCard : TColors.lightSurface,
        border: Border(top: BorderSide(
          color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.8)),
      ),
      child: Row(
        children: [
          if (PermissionHelper.canUseRAG(_userRole))
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: TSizes.sm),
              decoration: BoxDecoration(
                color: isDark ? TColors.darkElevated : TColors.lightElevated,
                borderRadius: BorderRadius.circular(TSizes.radiusSm),
              ),
              child: Icon(Icons.library_books_rounded, size: 16,
                color: isDark ? TColors.darkMuted : TColors.lightMuted),
            ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDark ? TColors.darkSurface : TColors.lightElevated,
                borderRadius: BorderRadius.circular(TSizes.radiusLg),
                border: Border.all(
                  color: isDark ? TColors.darkBorder : TColors.lightBorder, width: 0.8),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                maxLines: 4, minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(fontSize: 13,
                  color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: TextStyle(fontSize: 13,
                    color: isDark ? TColors.darkMuted : TColors.lightMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: TSizes.sm),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: _isSending ? null
                    : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                color: _isSending
                    ? (isDark ? TColors.darkElevated : TColors.lightElevated) : null,
                borderRadius: BorderRadius.circular(TSizes.radiusMd),
                boxShadow: _isSending ? null : [
                  BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: _isSending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsPanel(bool isDark) {
    final toolsAsync = ref.watch(aiToolsProvider);
    return toolsAsync.when(
      data: (tools) => AIToolsPanel(
        tools: tools, isDark: isDark,
        onExecute: (toolName) {
          setState(() => _showTools = false);
          _inputController.text = 'Execute tool: $toolName';
          _sendMessage();
        },
      ),
      loading: () => Container(
        padding: const EdgeInsets.all(TSizes.paddingXL),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkCard : TColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(TSizes.radiusLg)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(TSizes.paddingXL),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkCard : TColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(TSizes.radiusLg)),
        ),
        child: Center(child: Text('Failed to load tools',
          style: TextStyle(color: isDark ? TColors.darkMuted : TColors.lightMuted))),
      ),
    );
  }
}
