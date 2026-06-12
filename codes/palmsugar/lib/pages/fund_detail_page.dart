import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../database/db_helper.dart';
import '../database/models.dart';
import 'add_fund_transaction_page.dart';

class FundDetailPage extends StatefulWidget {
  final FundHolding holding;

  const FundDetailPage({super.key, required this.holding});

  @override
  State<FundDetailPage> createState() => _FundDetailPageState();
}

class _FundDetailPageState extends State<FundDetailPage> {
  final DatabaseHelper _db = DatabaseHelper();
  final _navController = TextEditingController();

  bool _isLoading = true;
  FundHolding? _holding;
  List<FundTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final holding = await _db.getFundHoldingById(widget.holding.id!);
    final transactions = await _db.getFundTransactions(fundId: widget.holding.id);
    if (holding != null) {
      _navController.text = (holding.currentNav ?? 0).toString();
    }
    setState(() {
      _holding = holding;
      _transactions = transactions;
      _isLoading = false;
    });
  }

  Future<void> _updateNav() async {
    final nav = double.tryParse(_navController.text);
    if (nav == null || nav <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效净值')),
      );
      return;
    }
    await _db.updateFundNav(widget.holding.id!, nav);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('净值已更新')),
      );
    }
  }

  Future<void> _deleteTransaction(FundTransaction ft) async {
    if (ft.id != null) {
      await _db.deleteFundTransaction(ft.id!);
      await _loadData();
    }
  }

  String _formatMoney(double? v) {
    if (v == null || v == 0) return '¥0.00';
    final abs = v.abs();
    final sign = v < 0 ? '-' : '';
    if (abs >= 10000) {
      return '$sign¥${(abs / 10000).toStringAsFixed(2)}万';
    }
    return '$sign¥${abs.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _holding == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.holding.fundName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final h = _holding!;
    final profitColor = (h.profit ?? 0) >= 0 ? Colors.red : Colors.green;
    final profitSign = (h.profit ?? 0) >= 0 ? '+' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(h.fundName),
        actions: [
          if (_transactions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除基金（需先清空交易记录）',
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请先删除所有交易记录，再联系开发者删除基金')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基金信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 名称 + 代码
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            h.fundName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (h.fundCode != null && h.fundCode!.isNotEmpty)
                          Text(h.fundCode!,
                              style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                    if (h.fundType != null && h.fundType!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(h.fundType!,
                            style: TextStyle(color: Colors.grey.shade600)),
                      ),
                    ],
                    const Divider(height: 24),
                    // 持仓金额 — 居中大字
                    Text(
                      _formatMoney(h.holdingAmount),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('持仓金额', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    // 持仓成本 | 持有收益 | 收益率
                    Row(
                      children: [
                        Expanded(child: _infoItem('持仓成本', _formatMoney(h.costAmount))),
                        Expanded(
                          child: _infoItem('持有收益', '$profitSign${_formatMoney(h.profit)}', profitColor),
                        ),
                        Expanded(
                          child: _infoItem(
                            '收益率',
                            '$profitSign${((h.profitRate ?? 0) * 100).toStringAsFixed(2)}%',
                            profitColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '持有 ${h.holdingShares.toStringAsFixed(2)} 份 · 净值 ¥${(h.currentNav ?? 0).toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 净值更新
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('当前净值', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _navController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          hintText: '0.0000',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _updateNav,
                      child: const Text('更新'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 交易记录
            Row(
              children: [
                Text(
                  '交易记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // 快捷操作按钮
                _quickActionButton('买入', Colors.red, () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddFundTransactionPage(
                        preselectedHolding: h,
                        initialType: 'buy',
                      ),
                    ),
                  );
                  _loadData();
                }),
                const SizedBox(width: 8),
                _quickActionButton('卖出', Colors.green, () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddFundTransactionPage(
                        preselectedHolding: h,
                        initialType: 'sell',
                      ),
                    ),
                  );
                  _loadData();
                }),
                const SizedBox(width: 8),
                _quickActionButton('分红', Colors.orange, () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddFundTransactionPage(
                        preselectedHolding: h,
                        initialType: 'dividend',
                      ),
                    ),
                  );
                  _loadData();
                }),
              ],
            ),

            const SizedBox(height: 8),

            if (_transactions.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('暂无交易记录'),
              ))
            else
              ..._transactions.map((ft) => _buildTransactionTile(ft)),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, [Color? color]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _quickActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(100)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTransactionTile(FundTransaction ft) {
    IconData icon;
    Color iconColor;
    String typeLabel;
    String? amountStr;

    switch (ft.type) {
      case 'buy':
        icon = Icons.add_circle_outline;
        iconColor = Colors.red;
        typeLabel = '买入';
        amountStr = '-¥${(ft.amount ?? 0).toStringAsFixed(2)}';
        break;
      case 'sell':
        icon = Icons.remove_circle_outline;
        iconColor = Colors.green;
        typeLabel = '卖出';
        final netAmount = (ft.amount ?? 0) - ft.fee;
        amountStr = '+¥${netAmount.toStringAsFixed(2)}';
        break;
      case 'dividend':
        icon = Icons.card_giftcard;
        iconColor = Colors.orange;
        typeLabel = '分红';
        amountStr = '+¥${(ft.dividendAmount ?? ft.amount ?? 0).toStringAsFixed(2)}';
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.grey;
        typeLabel = ft.type;
    }

    final date = DateTime.fromMillisecondsSinceEpoch(ft.date);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Slidable(
      key: ValueKey('fund_detail_tx_${ft.id}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.2,
        children: [
          CustomSlidableAction(
            onPressed: (_) => _deleteTransaction(ft),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            padding: EdgeInsets.zero,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, size: 20),
                SizedBox(height: 2),
                Text('删除', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withAlpha(30),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(typeLabel, style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            [
              dateStr,
              if (ft.shares != null) '${ft.shares!.toStringAsFixed(2)}份',
              if (ft.nav != null) '净值${ft.nav!.toStringAsFixed(4)}',
              if (ft.fee > 0) '手续费¥${ft.fee.toStringAsFixed(2)}',
              if (ft.note != null && ft.note!.isNotEmpty) ft.note,
            ].join(' · '),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          trailing: Text(
            amountStr ?? '',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ft.type == 'buy' ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}
