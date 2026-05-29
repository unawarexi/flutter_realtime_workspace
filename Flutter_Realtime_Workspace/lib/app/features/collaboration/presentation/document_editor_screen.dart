import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_realtime_workspace/app/components/ui/button.dart';
import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/core/utils/helpers/helper_functions.dart';
import 'package:flutter_realtime_workspace/store/document_provider.dart';
import 'package:flutter_realtime_workspace/store/workspace_provider.dart';

class DocumentEditorScreen extends ConsumerStatefulWidget {
  const DocumentEditorScreen({super.key});
  @override
  ConsumerState<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  String _query = '';
  String? _typeFilter;

  static const _types = ['all', 'doc', 'pdf', 'spreadsheet', 'presentation', 'other'];

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final hPad = TResponsive.pagePadding(context);
    final workspace = ref.watch(activeWorkspaceProvider);
    final docsAsync = ref.watch(documentsProvider({'workspaceId': workspace?.id, 'projectId': null}));

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: SAppBar(
        title: 'Documents',
        showBack: false,
        actions: [
          IconButton(icon: const Icon(Iconsax.add), onPressed: () => _showUploadSheet(context, isDark)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, TSizes.sm, hPad, 0),
          child: TSearchBar(hint: 'Search documents...', onChanged: (v) => setState(() => _query = v)),
        ),
        const SizedBox(height: TSizes.sm),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            scrollDirection: Axis.horizontal,
            itemCount: _types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = _types[i];
              final selected = _typeFilter == null ? t == 'all' : _typeFilter == t;
              return ChoiceChip(
                label: Text(t[0].toUpperCase() + t.substring(1)),
                selected: selected,
                onSelected: (_) => setState(() => _typeFilter = t == 'all' ? null : t),
                selectedColor: TColors.primary.withValues(alpha: 0.15),
                backgroundColor: isDark ? TColors.darkElevated : TColors.lightElevated,
                labelStyle: TextStyle(
                  fontSize: TResponsive.sp(context, 12),
                  color: selected ? TColors.primary : (isDark ? TColors.textDarkSecondary : TColors.textLightSecondary),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: TSizes.sm),
        Expanded(
          child: docsAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.all(hPad),
              child: Column(children: List.generate(5, (_) => const Padding(
                padding: EdgeInsets.only(bottom: TSizes.sm),
                child: TSkeleton(height: 78),
              ))),
            ),
            error: (_, __) => const Center(child: Text('Failed to load documents')),
            data: (docs) {
              var filtered = docs.where((d) {
                final q = _query.toLowerCase();
                final matchQ = q.isEmpty || d.title.toLowerCase().contains(q);
                final matchT = _typeFilter == null || d.type.toLowerCase() == _typeFilter;
                return matchQ && matchT;
              }).toList();

              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Iconsax.document, size: 56, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                  const SizedBox(height: TSizes.sm),
                  Text('No documents found', style: TextStyle(
                    fontSize: TResponsive.sp(context, 16),
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.textDark : TColors.textLight,
                  )),
                  const SizedBox(height: 6),
                  TButton(text: 'Upload Document', prefixIcon: Iconsax.document_upload, onPressed: () => _showUploadSheet(context, isDark)),
                ]));
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(documentsProvider({'workspaceId': workspace?.id, 'projectId': null})),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: TSizes.sm),
                  itemBuilder: (_, i) {
                    final doc = filtered[i];
                    return TCard(
                      hasBorder: true,
                      padding: EdgeInsets.all(TResponsive.sp(context, TSizes.md)),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _typeColor(doc.type).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(TSizes.radiusMd),
                          ),
                          child: Icon(_typeIcon(doc.type), size: 22, color: _typeColor(doc.type)),
                        ),
                        const SizedBox(width: TSizes.sm),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: TResponsive.sp(context, 14),
                            fontWeight: FontWeight.w600,
                            color: isDark ? TColors.textDark : TColors.textLight,
                          )),
                          const SizedBox(height: 4),
                          Row(children: [
                            // Visibility badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: (doc.visibility == 'public' ? TColors.success : TColors.warning).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(TSizes.radiusFull),
                              ),
                              child: Text(doc.visibility, style: TextStyle(
                                fontSize: TResponsive.sp(context, 10),
                                fontWeight: FontWeight.w600,
                                color: doc.visibility == 'public' ? TColors.success : TColors.warning,
                              )),
                            ),
                            if (doc.tags.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(child: Text(doc.tags.take(2).join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: TResponsive.sp(context, 11),
                                color: isDark ? TColors.darkMuted : TColors.lightMuted,
                              ))),
                            ],
                          ]),
                        ])),
                        Icon(Iconsax.arrow_right_3, size: 16, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                      ]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return Iconsax.document;
      case 'spreadsheet': return Iconsax.data;
      case 'presentation': return Iconsax.chart_square;
      default: return Iconsax.document_text;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return TColors.error;
      case 'spreadsheet': return TColors.success;
      case 'presentation': return TColors.warning;
      default: return TColors.primary;
    }
  }

  void _showUploadSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? TColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.all(TResponsive.pagePadding(context)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Document', style: TextStyle(
            fontSize: TResponsive.sp(context, 18),
            fontWeight: FontWeight.w700,
            color: isDark ? TColors.textDark : TColors.textLight,
          )),
          const SizedBox(height: TSizes.lg),
          _UploadOption(icon: Iconsax.document_upload, label: 'Upload File', isDark: isDark),
          const SizedBox(height: TSizes.sm),
          _UploadOption(icon: Iconsax.document_text, label: 'Create New Doc', isDark: isDark),
          const SizedBox(height: TSizes.lg),
        ]),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _UploadOption({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(TSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: isDark ? TColors.darkElevated : TColors.lightElevated,
          borderRadius: BorderRadius.circular(TSizes.radiusMd),
          border: Border.all(color: isDark ? TColors.darkBorder : TColors.lightBorder),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: TColors.primary),
          const SizedBox(width: TSizes.sm),
          Text(label, style: TextStyle(
            fontSize: TResponsive.sp(context, 14),
            fontWeight: FontWeight.w600,
            color: isDark ? TColors.textDark : TColors.textLight,
          )),
        ]),
      ),
    );
  }
}
