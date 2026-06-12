import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../database/models.dart';

class FundManagementPage extends StatefulWidget {
  const FundManagementPage({super.key});

  @override
  State<FundManagementPage> createState() => _FundManagementPageState();
}

class _FundManagementPageState extends State<FundManagementPage> {
  final DatabaseHelper _db = DatabaseHelper();
  List<FundHolding> _holdings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final holdings = await _db.getFundHoldings();
    setState(() {
      _holdings = holdings;
      _isLoading = false;
    });
  }

  Future<void> _addFund() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final typeCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增基金'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '基金名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: '基金代码（选填）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeCtrl,
              decoration: const InputDecoration(
                labelText: '基金类型（选填）',
                hintText: '如：混合型、股票型',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('添加')),
        ],
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      await _db.insertFundHolding(FundHolding(
        fundName: nameCtrl.text.trim(),
        fundCode: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : null,
        fundType: typeCtrl.text.trim().isNotEmpty ? typeCtrl.text.trim() : null,
      ));
      _load();
    }
  }

  Future<void> _editFund(FundHolding h) async {
    final nameCtrl = TextEditingController(text: h.fundName);
    final codeCtrl = TextEditingController(text: h.fundCode ?? '');
    final typeCtrl = TextEditingController(text: h.fundType ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑基金'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: '基金名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: '基金代码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: typeCtrl,
              decoration: const InputDecoration(
                labelText: '基金类型（选填）',
                hintText: '如：混合型、股票型',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true && h.id != null) {
      final updated = h.copyWith(
        fundName: nameCtrl.text.trim(),
        fundCode: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : null,
        fundType: typeCtrl.text.trim().isNotEmpty ? typeCtrl.text.trim() : null,
      );
      await _db.updateFundHolding(updated);
      _load();
    }
  }

  Future<void> _deleteFund(FundHolding h) async {
    if (h.holdingShares > 0.001) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('该基金还有 ${h.holdingShares.toStringAsFixed(4)} 份持仓，请先清空再删除')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除基金'),
        content: Text('确定删除「${h.fundName}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && h.id != null) {
      await _db.deleteFundHolding(h.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('基金管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFund(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _holdings.isEmpty
              ? const Center(child: Text('暂无基金'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _holdings.length,
                  itemBuilder: (context, index) {
                    final h = _holdings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.account_balance, color: Colors.blue),
                        ),
                        title: Text(h.fundName,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          [
                            if (h.fundCode != null && h.fundCode!.isNotEmpty)
                              h.fundCode,
                            if (h.fundType != null && h.fundType!.isNotEmpty)
                              h.fundType,
                            '持有 ${h.holdingShares.toStringAsFixed(2)} 份',
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editFund(h),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteFund(h),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
