import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_realtime_workspace/app/components/ui/card.dart';
import 'package:flutter_realtime_workspace/app/components/ui/input.dart';
import 'package:flutter_realtime_workspace/app/components/ui/skeleton.dart';
import 'package:flutter_realtime_workspace/app/components/widgets/app_bar.dart';
import 'package:flutter_realtime_workspace/app/features/search/usecases/search_usecase.dart';
import 'package:flutter_realtime_workspace/core/constants/colors.dart';
import 'package:flutter_realtime_workspace/core/constants/responsive.dart';
import 'package:flutter_realtime_workspace/core/constants/sizes.dart';
import 'package:flutter_realtime_workspace/store/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _State();
}

class _State extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _activeResource = 'all';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = TResponsive.pagePadding(context);
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = query.isNotEmpty ? ref.watch(searchResultsProvider(query)) : null;

    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : TColors.backgroundLight,
      appBar: const SAppBar(title: 'Search', showBack: true),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, TSizes.md, hPad, TSizes.sm),
          child: TSearchBar(
            controller: _ctrl,
            hint: 'Search everything...',
            onChanged: (q) => SearchUseCase.updateQuery(ref, q),
          ),
        ),
        // Resource chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            children: ['all', ...SearchUseCase.searchableResources].map((r) {
              final selected = r == _activeResource;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(r == 'all' ? 'All' : SearchUseCase.resourceLabel(r)),
                  selected: selected,
                  onSelected: (_) => setState(() => _activeResource = r),
                  selectedColor: TColors.primary.withValues(alpha: 0.12),
                  labelStyle: TextStyle(fontSize: TResponsive.sp(context, 11), color: selected ? TColors.primary : (isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                  side: BorderSide(color: selected ? TColors.primary : (isDark ? TColors.darkBorder : TColors.lightBorder)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.radiusMd)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: TSizes.sm),
        Expanded(
          child: query.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_rounded, size: 56, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                  const SizedBox(height: TSizes.sm),
                  Text('Type to search', style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                ]))
              : resultsAsync == null
                  ? const SizedBox.shrink()
                  : resultsAsync.when(
                      loading: () => Padding(padding: EdgeInsets.all(hPad), child: Column(children: List.generate(4, (_) => const Padding(padding: EdgeInsets.only(bottom: TSizes.sm), child: TSkeleton(height: 56))))),
                      error: (_, __) => const Center(child: Text('Search failed')),
                      data: (results) {
                        if (results.isEmpty) return Center(child: Text('No results for "$query"', style: TextStyle(color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)));
                        return ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: TSizes.xs),
                          itemBuilder: (_, i) {
                            final r = results[i];
                            return TCard(
                              hasBorder: true,
                              padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                              child: Row(children: [
                                Icon(_resourceIcon(r['type'] ?? ''), size: 20, color: TColors.primary),
                                const SizedBox(width: TSizes.sm),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(r['title'] ?? r['name'] ?? '–', style: TextStyle(fontSize: TResponsive.sp(context, 14), fontWeight: FontWeight.w500, color: isDark ? TColors.textPrimaryDark : TColors.textPrimaryLight)),
                                  if (r['type'] != null) Text(SearchUseCase.resourceLabel(r['type']), style: TextStyle(fontSize: TResponsive.sp(context, 11), color: isDark ? TColors.textSecondaryDark : TColors.textSecondaryLight)),
                                ])),
                                Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? TColors.darkMuted : TColors.lightMuted),
                              ]),
                            );
                          },
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  IconData _resourceIcon(String type) => switch (type) { 'users' => Icons.person_outlined, 'projects' => Icons.folder_outlined, 'tasks' => Icons.task_outlined, 'documents' => Icons.description_outlined, 'channels' => Icons.chat_outlined, 'meetings' => Icons.videocam_outlined, _ => Icons.search_rounded };
}
