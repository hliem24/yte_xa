import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state.dart';
import '../../models.dart';
import '../../widgets/app_header.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});
  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();

  static List<CatalogPreviewItem> pickPreview(WidgetRef ref,{int from=0,int take=6}) {
    final inv = ref.read(inventoryProvider);
    final slice = inv.medicines.skip(from).take(take).toList();
    return slice.map((m)=>CatalogPreviewItem(
      title: m.name,
      subtitle: '${m.unit} • Tồn: ${m.totalQuantity}'
        '${m.nearestExpiry!=null?' • HSD: ${m.nearestExpiry!.day}/${m.nearestExpiry!.month}':''}',
    )).toList();
  }
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final inv = ref.watch(inventoryProvider);
    final meds = inv.medicines.where((m) =>
      m.name.toLowerCase().contains(_q.toLowerCase()) ||
      m.id.toLowerCase().contains(_q.toLowerCase())).toList();

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(icon: Icons.home_rounded, title: 'Tổng quan'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm thuốc & vật tư',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: meds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = meds[i];
                final ne = m.nearestExpiry;
                return _Tile(
                  title: m.name,
                  subtitle: 'Mã: ${m.id} • ĐV: ${m.unit} • Tồn: ${m.totalQuantity}'
                            '${ne!=null?' • HSD: ${ne.day}/${ne.month}/${ne.year}':''}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title, subtitle;
  const _Tile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            height: 48, width: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha:.12), borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medical_services_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
        ],
      ),
    );
  }
}

class CatalogPreviewItem {
  final String title; final String subtitle;
  CatalogPreviewItem({required this.title, required this.subtitle});
}
