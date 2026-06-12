import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../database/db_helper.dart';
import '../database/models.dart';
import 'add_fund_transaction_page.dart';
import 'fund_detail_page.dart';
import 'fund_management_page.dart';
import 'investment_analysis_page.dart';

class InvestmentPage extends StatefulWidget {
  const InvestmentPage({super.key});

  @override
  State<InvestmentPage> createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;

  bool _isLoading = true;
  List<FundHolding> _holdings = [];
  List<FundTransaction> _allTransactions = [];
  Map<String, double> _summary = {};

  // 多选批量删除
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final holdings = await _db.getFundHoldings();
    final transactions = await _db.getFundTransactions();
    final summary = await _db.getInvestmentSummary();
    setState(() {
      _holdings = holdings;
      _allTransactions = transactions;
      _summary = summary;
      _isLoading = false;
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(int id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _batchDeleteFundTx() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 $count 条理财记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final id in _selectedIds.toList()) {
        await _db.deleteFundTransaction(id);
      }
      _exitSelectionMode();
      _loadData();
    }
  }

  void _selectAllFundTx() {
    setState(() {
      for (final ft in _allTransactions) {
        if (ft.id != null) _selectedIds.add(ft.id!);
      }
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode)
            : null,
        title: _selectionMode ? Text('已选 ${_selectedIds.length} 项') : const Text('理财'),
        actions: _selectionMode
            ? [
                IconButton(icon: const Icon(Icons.select_all), tooltip: '全选', onPressed: _selectAllFundTx),
                IconButton(icon: const Icon(Icons.delete), onPressed: _batchDeleteFundTx),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: '基金管理',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FundManagementPage(),
                ),
              );
              _loadData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '持仓', icon: Icon(Icons.account_balance_wallet)),
            Tab(text: '交易记录', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InvestmentAnalysisPage(),
                    ),
                  ),
                  child: _buildSummaryCard(),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHoldingsTab(),
                      _buildTransactionsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddFundTransactionPage(),
            ),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ==================== 投资总览卡片 ====================
  Widget _buildSummaryCard() {
    final totalValue = _summary['total_value'] ?? 0;
    final totalCost = _summary['total_cost'] ?? 0;
    final totalProfit = _summary['total_profit'] ?? 0;
    final profitRate = _summary['profit_rate'] ?? 0;
    final profitColor = totalProfit >= 0 ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '投资总览',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('总市值', _formatMoney(totalValue), Colors.black87),
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: _buildSummaryItem('总成本', _formatMoney(totalCost), Colors.grey.shade600),
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: _buildSummaryItem(
                    '总盈亏',
                    _formatMoney(totalProfit),
                    profitColor,
                  ),
                ),
              ],
            ),
            if (totalCost > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: math.min(
                          (totalProfit / totalCost).abs().clamp(0, 1), 1),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(profitColor),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${profitRate >= 0 ? "+" : ""}${(profitRate * 100).toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: profitColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ==================== 持仓 Tab ====================
  Widget _buildHoldingsTab() {
    if (_holdings.isEmpty) {
      return const Center(child: Text('暂无持仓，点击右下角 + 开始记录'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _holdings.length,
        itemBuilder: (context, index) {
          final h = _holdings[index];
          return _buildHoldingCard(h);
        },
      ),
    );
  }

  Widget _buildHoldingCard(FundHolding h) {
    final profitColor = (h.profit ?? 0) >= 0 ? Colors.red : Colors.green;
    final profitSign = (h.profit ?? 0) >= 0 ? '+' : '';

    // 基金代码补前导0
    String displayCode(String? code) {
      if (code == null || code.isEmpty) return '';
      final s = code.trim();
      if (int.tryParse(s) != null && s.length < 6) return s.padLeft(6, '0');
      return s;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FundDetailPage(holding: h),
            ),
          );
          _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 基金名称 + 代码
              Row(
                children: [
                  Expanded(
                    child: Text(
                      h.fundName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (displayCode(h.fundCode).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayCode(h.fundCode),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 持仓金额 — 居中大字
              Text(
                _formatMoney(h.holdingAmount),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '持仓金额',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 12),
              // 持仓成本 | 持有收益 | 收益率
              Row(
                children: [
                  Expanded(
                    child: _buildHoldingItem('持仓成本', _formatMoney(h.costAmount)),
                  ),
                  Expanded(
                    child: _buildHoldingItem(
                      '持有收益',
                      '$profitSign${_formatMoney(h.profit)}',
                      profitColor,
                    ),
                  ),
                  Expanded(
                    child: _buildHoldingItem(
                      '收益率',
                      '$profitSign${((h.profitRate ?? 0) * 100).toStringAsFixed(2)}%',
                      profitColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 份额 + 净值
              Row(
                children: [
                  Text(
                    '持有 ${h.holdingShares.toStringAsFixed(2)} 份 · 净值 ¥${(h.currentNav ?? 0).toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingItem(String label, String value, [Color? color]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ==================== 交易记录 Tab ====================
  Widget _buildTransactionsTab() {
    if (_allTransactions.isEmpty) {
      return const Center(child: Text('暂无交易记录'));
    }

    // 构建基金名称映射
    final fundNames = <int, String>{};
    for (final h in _holdings) {
      if (h.id != null) fundNames[h.id!] = h.fundName;
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _allTransactions.length,
      itemBuilder: (context, index) {
        final ft = _allTransactions[index];
        final fundName = fundNames[ft.fundId] ?? '未知基金';

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

        final isSelected = ft.id != null && _selectedIds.contains(ft.id);

        Widget tile = Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _selectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => ft.id != null ? _toggleSelection(ft.id!) : null,
                  )
                : CircleAvatar(
                    backgroundColor: iconColor.withAlpha(30),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
            title: Text(
              '$typeLabel · $fundName',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              dateStr,
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
            onTap: _selectionMode
                ? () => ft.id != null ? _toggleSelection(ft.id!) : null
                : null,
            onLongPress: _selectionMode
                ? null
                : () => ft.id != null ? _enterSelectionMode(ft.id!) : null,
          ),
        );

        if (_selectionMode) return tile;

        return Slidable(
          key: ValueKey('fund_tx_${ft.id}'),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              CustomSlidableAction(
                onPressed: (_) async {
                  if (ft.id != null) {
                    await _db.deleteFundTransaction(ft.id!);
                    _loadData();
                  }
                },
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
          child: tile,
        );
      },
    );
  }
}
