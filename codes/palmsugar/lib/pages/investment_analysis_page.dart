import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';
import '../database/models.dart';

class InvestmentAnalysisPage extends StatefulWidget {
  const InvestmentAnalysisPage({super.key});

  @override
  State<InvestmentAnalysisPage> createState() =>
      _InvestmentAnalysisPageState();
}

class _InvestmentAnalysisPageState extends State<InvestmentAnalysisPage> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  Map<String, double> _summary = {};
  List<FundHolding> _holdings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summary = await _db.getInvestmentSummary();
    final holdings = await _db.getFundHoldings();
    setState(() {
      _summary = summary;
      _holdings = holdings.where((h) => h.holdingShares > 0).toList();
      _isLoading = false;
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
      appBar: AppBar(title: const Text('投资分析')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _holdings.isEmpty
              ? const Center(child: Text('暂无持仓数据'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                      _buildAllocationPie(),
                      const SizedBox(height: 24),
                      _buildFundComparison(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final totalValue = _summary['total_value'] ?? 0;
    final totalCost = _summary['total_cost'] ?? 0;
    final totalProfit = _summary['total_profit'] ?? 0;
    final profitRate = _summary['profit_rate'] ?? 0;
    final profitColor = totalProfit >= 0 ? Colors.red : Colors.green;
    final profitSign = totalProfit >= 0 ? '+' : '';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('投资总览', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _infoItem('总市值', _formatMoney(totalValue), colorScheme.onSurface)),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Expanded(child: _infoItem('总成本', _formatMoney(totalCost), Colors.grey.shade600)),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Expanded(child: _infoItem('总盈亏', '$profitSign${_formatMoney(totalProfit)}', profitColor)),
              ],
            ),
            if (totalCost > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ((totalProfit / totalCost).abs() / 2).clamp(0, 1),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(profitColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$profitSign${(profitRate * 100).toStringAsFixed(2)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: profitColor),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  // ==================== 持仓占比饼图 ====================
  Widget _buildAllocationPie() {
    final totalValue = _summary['total_value'] ?? 0;
    if (totalValue <= 0) return const SizedBox.shrink();

    final colors = [
      Colors.blue.shade400,
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('持仓占比',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(_holdings.length, (index) {
                final h = _holdings[index];
                final value = h.holdingAmount ?? 0;
                final pct = totalValue > 0 ? (value / totalValue * 100) : 0;
                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: value,
                  title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_holdings.length, (index) {
          final h = _holdings[index];
          final pct = totalValue > 0
              ? ((h.holdingAmount ?? 0) / totalValue * 100)
              : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(h.fundName,
                      style: const TextStyle(fontSize: 13)),
                ),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==================== 基金对比柱状图 ====================
  Widget _buildFundComparison() {
    final maxAmount = _holdings.fold<double>(
        0, (max, h) => (h.holdingAmount ?? 0) > max ? (h.holdingAmount ?? 0) : max);
    if (maxAmount <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('基金市值对比',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAmount * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final h = _holdings[groupIndex];
                    final isMarketValue = rodIndex == 0;
                    final value =
                        isMarketValue ? h.holdingAmount : h.costAmount;
                    final label = isMarketValue ? '市值' : '成本';
                    return BarTooltipItem(
                      '${h.fundName}\n$label: ${_formatMoney(value ?? 0)}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _holdings.length) {
                        return const SizedBox.shrink();
                      }
                      final name = _holdings[index].fundName;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          name.length > 4
                              ? '${name.substring(0, 4)}...'
                              : name,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: _leftTitleWidget,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(_holdings.length, (index) {
                final h = _holdings[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (h.holdingAmount ?? 0).toDouble(),
                      color: Colors.blue.shade400,
                      width: 12,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: (h.costAmount ?? 0).toDouble(),
                      color: Colors.grey.shade400,
                      width: 12,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem('市值', Colors.blue.shade400),
            const SizedBox(width: 16),
            _legendItem('成本', Colors.grey.shade400),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

Widget _leftTitleWidget(double value, TitleMeta meta) {
  if (value == 0) return const SizedBox.shrink();
  String text;
  if (value >= 10000) {
    text = '${(value / 10000).toStringAsFixed(1)}万';
  } else {
    text = value.toStringAsFixed(0);
  }
  return Text(text, style: const TextStyle(fontSize: 10));
}
