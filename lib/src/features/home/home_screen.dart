// lib/src/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state.dart';
import '../../models.dart';

import '../catalog/catalog_screen.dart';
import '../inventory/inventory_screen.dart';
import '../ai/ai_screen.dart';
import '../../widgets/app_header.dart'; // <-- để dùng AppHeader có nút Đăng xuất

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  late final List<Widget> _pages = const [
    _OverviewTab(),        // Trang chủ (đã gộp báo cáo)
    InventoryScreen(),
    AiScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Tổng quan'),
          NavigationDestination(icon: Icon(Icons.inventory_2_rounded), label: 'Kho'),
          NavigationDestination(icon: Icon(Icons.smart_toy_rounded), label: 'AI'),
        ],
      ),
    );
  }
}

/// -------------------------
/// Trang chủ = Header + Danh mục preview + Báo cáo
/// -------------------------
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv  = ref.watch(inventoryProvider);
    final meds = inv.medicines;

    // --- TÍNH TOÁN DỮ LIỆU BÁO CÁO ---
    final totalStock = meds.fold<int>(0, (s, m) => s + m.totalQuantity);

    bool isNearExpiry(Medicine m) {
      final now = DateTime.now();
      for (final l in m.lots) {
        final d = l.expiry.difference(now).inDays;
        if (d <= 30) return true;
      }
      return false;
    }

    final nearExpiry = meds.where(isNearExpiry).toList();
    final lowStock   = meds.where((m) => m.totalQuantity < 20).toList();

    return CustomScrollView(
      slivers: [
        // Header bo tròn + NÚT ĐĂNG XUẤT (dùng AppHeader)
        const SliverToBoxAdapter(
          child: AppHeader(
            icon: Icons.local_hospital_rounded,
            title: 'Kho Y tế xã',
            showLogout: true, // <-- bắt buộc để hiện nút
          ),
        ),

        // Danh mục preview (carousel nhỏ)
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Danh mục thuốc & vật tư',
            onSeeAll: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CatalogScreen()),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: _HorizontalCards(items: _catalogPreviewData(meds)),
        ),

        // --- BÁO CÁO ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _ReportCard(
              leading: Icons.inventory_2_rounded,
              title: 'Tổng tồn kho',
              subtitle: '$totalStock đơn vị',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _ExpandableReport(
              icon: Icons.warning_amber_rounded,
              title: 'Sắp hết hạn (≤ 30 ngày)',
              children: nearExpiry.isEmpty
                  ? const [ _Empty('Không có mặt hàng sắp hết hạn') ]
                  : nearExpiry.map((m) {
                      final ne = m.nearestExpiry;
                      final hsd = ne != null ? '${ne.day}/${ne.month}/${ne.year}' : '—';
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.medication_rounded),
                        title: Text(m.name),
                        subtitle: Text('Tồn: ${m.totalQuantity} • HSD gần nhất: $hsd'),
                      );
                    }).toList(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _ExpandableReport(
              icon: Icons.trending_down_rounded,
              title: 'Tồn thấp (< 20)',
              children: lowStock.isEmpty
                  ? const [ _Empty('Không có mặt hàng tồn thấp') ]
                  : lowStock.map((m) {
                      final ne = m.nearestExpiry;
                      final hsd = ne != null ? '${ne.day}/${ne.month}/${ne.year}' : '—';
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.inventory_rounded),
                        title: Text(m.name),
                        subtitle: Text('Tồn: ${m.totalQuantity} • HSD gần nhất: $hsd'),
                      );
                    }).toList(),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // Tạo dữ liệu preview hiển thị tối đa 6 item ngang
  List<_PreviewItem> _catalogPreviewData(List<Medicine> meds) {
    final take = meds.length < 6 ? meds.length : 6;
    final slice = meds.take(take).toList();
    return slice.map((m) {
      final ne = m.nearestExpiry;
      final hsd = ne != null ? '${ne.day}/${ne.month}' : '—';
      return _PreviewItem(
        title: m.name,
        subtitle: '${m.unit} • Tồn: ${m.totalQuantity} • HSD: $hsd',
      );
    }).toList();
  }
}

/// ---------------------
/// UI thành phần
/// ---------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('Xem tất cả')),
        ],
      ),
    );
  }
}

class _HorizontalCards extends StatelessWidget {
  final List<_PreviewItem> items;
  const _HorizontalCards({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 148,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final it = items[i];
          return Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.medication_liquid)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(it.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(it.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PreviewItem {
  final String title;
  final String subtitle;
  _PreviewItem({required this.title, required this.subtitle});
}

class _ReportCard extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  const _ReportCard({required this.leading, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(leading, color: cs.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpandableReport extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _ExpandableReport({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        children: children,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.check_circle_outline_rounded),
      title: Text(text),
    );
  }
}
