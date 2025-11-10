import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state.dart';
import '../../models.dart';
import '../../widgets/app_header.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String? _selectedMedId;
  final _qty = TextEditingController(text: '10');
  final _reason = TextEditingController(); // lý do xuất
  final _note = TextEditingController(); // ghi chú khi tạo yêu cầu nhập

  @override
  Widget build(BuildContext context) {
    final inv = ref.watch(inventoryProvider);
    final meds = inv.medicines;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    final isAdmin = (user?.role ?? 'staff') == 'admin';

    final currentStock = _selectedMedId != null
        ? ref.read(inventoryProvider.notifier).stockOf(_selectedMedId!, 'KHO_1')
        : null;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(icon: Icons.local_hospital_rounded, title: 'Kho Y tế xã'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedMedId,
                    items: meds
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text('${m.name} (${m.unit})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedMedId = v),
                    decoration: const InputDecoration(
                      labelText: 'Chọn thuốc/vật tư',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Lý do xuất (bắt buộc khi xuất)
                  TextField(
                    controller: _reason,
                    decoration: const InputDecoration(
                      labelText: 'Lý do xuất (bắt buộc khi xuất)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Ghi chú khi tạo yêu cầu nhập (staff)
                  if (!isAdmin)
                    TextField(
                      controller: _note,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú khi yêu cầu nhập (nhân viên)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // NHẬP (admin nhập trực tiếp, staff gửi yêu cầu)
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: (_selectedMedId == null)
                              ? null
                              : () async {
                                  final q = int.tryParse(_qty.text) ?? 0;
                                  if (q <= 0) return;
                                  if (isAdmin) {
                                    await ref
                                        .read(inventoryProvider.notifier)
                                        .addMovement(
                                            _selectedMedId!, 'KHO_1', 'in', q);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Đã nhập kho')),
                                    );
                                  } else {
                                    final id = await ref
                                        .read(inventoryProvider.notifier)
                                        .createStockInRequest(
                                          medicineId: _selectedMedId!,
                                          qty: q,
                                          note: _note.text,
                                          requester:
                                              user?.username ?? 'unknown',
                                        );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Đã gửi yêu cầu nhập (#$id)')),
                                    );
                                  }
                                  setState(() {});
                                },
                          icon: const Icon(Icons.arrow_downward),
                          label: Text(isAdmin ? 'Nhập kho' : 'Gửi yêu cầu nhập'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // XUẤT (không cần duyệt, nhưng bắt buộc lý do)
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: (_selectedMedId == null)
                              ? null
                              : () async {
                                  final q = int.tryParse(_qty.text) ?? 0;
                                  if (q <= 0) return;
                                  if (_reason.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Vui lòng nhập lý do xuất')),
                                    );
                                    return;
                                  }
                                  await ref
                                      .read(inventoryProvider.notifier)
                                      .addMovement(_selectedMedId!, 'KHO_1',
                                          'out', q,
                                          reason: _reason.text.trim());
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã xuất kho')),
                                  );
                                  setState(() {});
                                },
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text('Xuất kho'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (currentStock != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tồn hiện tại: $currentStock đơn vị',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(),

            // DANH SÁCH PHIẾU YÊU CẦU NHẬP (chỉ để admin duyệt nhanh)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  const Text(
                    'Phiếu yêu cầu nhập (chờ duyệt) ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (!isAdmin) const Text('(Xem)'),
                ],
              ),
            ),
            ...inv.requests.where((r) => r.status == 'pending').map((r) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  child: ListTile(
                    title:
                        Text('${r.medicineId} • Yêu cầu nhập ${r.qty}'),
                    subtitle: Text(
                        'Người tạo: ${r.requester} • ${r.createdAt} • Ghi chú: ${r.note}'),
                    trailing: isAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final ok = await ref
                                      .read(inventoryProvider.notifier)
                                      .reviewRequest(
                                        requestId: r.id,
                                        approve: false,
                                        reviewer:
                                            user?.username ?? 'admin',
                                        note: '', // ✅ bắt buộc
                                      );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Đã từ chối phiếu #${r.id}'
                                          : 'Phiếu không hợp lệ'),
                                    ),
                                  );
                                  setState(() {});
                                },
                                child: const Text('Từ chối'),
                              ),
                              const SizedBox(width: 6),
                              FilledButton(
                                onPressed: () async {
                                  final ok = await ref
                                      .read(inventoryProvider.notifier)
                                      .reviewRequest(
                                        requestId: r.id,
                                        approve: true,
                                        reviewer:
                                            user?.username ?? 'admin',
                                        note: '', // ✅ bắt buộc
                                      );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Đã duyệt & nhập kho (#${r.id})'
                                          : 'Phiếu không hợp lệ'),
                                    ),
                                  );
                                  setState(() {});
                                },
                                child: const Text('Duyệt'),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              );
            }),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Lịch sử nhập/xuất',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ...inv.movements.reversed.map((mv) {
              final list =
                  inv.medicines.where((m) => m.id == mv.medicineId).toList();
              final medName =
                  list.isNotEmpty ? list.first.name : mv.medicineId;
              final color = mv.type == 'in'
                  ? Colors.green.shade600
                  : Colors.red.shade600;
              final icon = mv.type == 'in'
                  ? Icons.arrow_downward
                  : Icons.arrow_upward;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  child: ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(
                      '$medName • ${mv.type == 'in' ? 'Nhập' : 'Xuất'} ${mv.quantity}'
                      '${mv.reason != null ? ' • Lý do: ${mv.reason}' : ''}',
                    ),
                    subtitle:
                        Text('Kho: ${mv.warehouseId} • ${mv.time}'),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
