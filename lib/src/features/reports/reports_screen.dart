import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state.dart';
import '../../widgets/app_header.dart';
import '../../models.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  bool _near(Medicine m) {
    final d = m.nearestExpiry;
    if (d == null) return false;
    return d.difference(DateTime.now()).inDays <= 30;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(inventoryProvider);
    final meds = inv.medicines;
    final total = meds.fold<int>(0, (s, m) => s + m.totalQuantity);
    final low   = meds.where((m) => m.totalQuantity < 20).toList();
    final near  = meds.where(_near).toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const AppHeader(icon: Icons.insights_rounded, title: 'Báo cáo'),
          _CardStat(icon: Icons.inventory_2_rounded, title: 'Tổng tồn kho', value: '$total đơn vị'),
          _Expandable(title: 'Sắp hết hạn (≤ 30 ngày)', items: near),
          _Expandable(title: 'Tồn thấp (< 20)', items: low),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final IconData icon; final String title; final String value;
  const _CardStat({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
        Text(value, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Expandable extends StatefulWidget {
  final String title; final List<Medicine> items;
  const _Expandable({required this.title, required this.items});
  @override State<_Expandable> createState() => _ExpandableState();
}
class _ExpandableState extends State<_Expandable> {
  bool open = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.warning_amber_rounded),
          title: Text(widget.title),
          trailing: Icon(open ? Icons.expand_less : Icons.expand_more),
          onTap: () => setState(() => open = !open),
        ),
        if (open)
          ...widget.items.map((m) => ListTile(
            dense: true,
            title: Text(m.name), subtitle: Text('Tồn: ${m.totalQuantity} • HSD: ${m.nearestExpiry}'),
          )),
      ]),
    );
  }
}
