import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';

class AnalysisPage extends StatefulWidget {
  final int year;
  final int month;

  const AnalysisPage({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _monthlyTrend = [];
  List<Map<String, dynamic>> _expenseCategoryData = [];
  List<Map<String, dynamic>> _incomeCategoryData = [];
  double _monthIncome = 0;
  double _monthExpense = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final startOfMonth = DateTime(widget.year, widget.month, 1);
    final endOfMonth =
        DateTime(widget.year, widget.month + 1, 0, 23, 59, 59);
    final startMs = startOfMonth.millisecondsSinceEpoch;
    final endMs = endOfMonth.millisecondsSinceEpoch;

    final monthlyTrend = await _db.getMonthlySummary(6);
    final expenseCats =
        await _db.getCategorySummary('expense', startMs, endMs);
    final incomeCats = await _db.getCategorySummary('income', startMs, endMs);
    final summary = await _db.getSummary(startMs, endMs);

    setState(() {
      _monthlyTrend = monthlyTrend;
      _expenseCategoryData = expenseCats;
      _incomeCategoryData = incomeCats;
      _monthIncome = summary['income'] ?? 0.0;
      _monthExpense = summary['expense'] ?? 0.0;
      _isLoading = false;
    });
  }

  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}万';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatFullAmount(double amount) {
    return '¥${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.year}年${widget.month}月收支分析'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '趋势', icon: Icon(Icons.trending_up)),
            Tab(text: '支出', icon: Icon(Icons.pie_chart)),
            Tab(text: '收入', icon: Icon(Icons.pie_chart_outline)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrendTab(),
                _buildExpensePieTab(),
                _buildIncomePieTab(),
              ],
            ),
    );
  }

  // ==================== 趋势Tab ====================
  Widget _buildTrendTab() {
    if (_monthlyTrend.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final hasData = _monthlyTrend.any((m) =>
        ((m['income'] as num).toDouble()) > 0 || ((m['expense'] as num).toDouble()) > 0);

    if (!hasData) {
      return const Center(child: Text('近6个月暂无收支记录'));
    }

    final maxAmount = _monthlyTrend.fold<double>(0, (max, m) {
      final inc = (m['income'] as num).toDouble();
      final exp = (m['expense'] as num).toDouble();
      return max > inc
          ? (max > exp ? max : exp)
          : (inc > exp ? inc : exp);
    });

    final interval = maxAmount > 0 ? maxAmount / 4 : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当月汇总卡片
          _buildMonthSummaryCard(),
          const SizedBox(height: 24),
          Text(
            '近6个月收支趋势',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = _monthlyTrend[groupIndex];
                      final type = rodIndex == 0 ? '收入' : '支出';
                      final amount = rodIndex == 0
                          ? data['income'] as double
                          : data['expense'] as double;
                      return BarTooltipItem(
                        '${data['month']}月\n$type: ${amount.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
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
                        if (index < 0 || index >= _monthlyTrend.length) {
                          return const SizedBox.shrink();
                        }
                        final data = _monthlyTrend[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${data['month']}月',
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          _formatAmount(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_monthlyTrend.length, (index) {
                  final data = _monthlyTrend[index];
                  final income = data['income'] as double;
                  final expense = data['expense'] as double;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: Colors.red.shade400,
                        width: 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: expense,
                        color: Colors.green.shade400,
                        width: 10,
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
          const SizedBox(height: 16),
          // 图例
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('收入', Colors.red.shade400),
              const SizedBox(width: 24),
              _buildLegendItem('支出', Colors.green.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMonthSummaryCard() {
    final balance = _monthIncome - _monthExpense;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${widget.month}月汇总',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '收入',
                    _formatFullAmount(_monthIncome),
                    Colors.red,
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: _buildSummaryItem(
                    '支出',
                    _formatFullAmount(_monthExpense),
                    Colors.green,
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: _buildSummaryItem(
                    '结余',
                    _formatFullAmount(balance),
                    balance >= 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ==================== 支出饼图Tab ====================
  Widget _buildExpensePieTab() {
    return _buildPieTab(
      title: '${widget.month}月支出分类',
      data: _expenseCategoryData,
      color: Colors.green,
      emptyMessage: '本月暂无支出记录',
    );
  }

  // ==================== 收入饼图Tab ====================
  Widget _buildIncomePieTab() {
    return _buildPieTab(
      title: '${widget.month}月收入分类',
      data: _incomeCategoryData,
      color: Colors.red,
      emptyMessage: '本月暂无收入记录',
    );
  }

  void _showCategoryTransactions({
    required String categoryName,
    required List<int> categoryIds,
    required String type,
    required MaterialColor color,
  }) async {
    final startOfMonth = DateTime(widget.year, widget.month, 1);
    final endOfMonth =
        DateTime(widget.year, widget.month + 1, 0, 23, 59, 59);

    final transactions = await _db.getTransactionsByCategoryIds(
      type: type,
      startDate: startOfMonth.millisecondsSinceEpoch,
      endDate: endOfMonth.millisecondsSinceEpoch,
      categoryIds: categoryIds,
    );

    if (!mounted) return;

    final totalAmount = transactions.fold<double>(
        0, (sum, t) => sum + t.amount);

    final typeLabel = type == 'expense' ? '支出' : '收入';
    final amountColor = type == 'expense' ? Colors.green : Colors.red;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$categoryName · $typeLabel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '合计 ¥${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (transactions.isEmpty)
                  const Expanded(
                    child: Center(child: Text('该分类本月暂无记录')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final t = transactions[index];
                        final date =
                            DateTime.fromMillisecondsSinceEpoch(t.date);
                        final dateStr =
                            '${date.month}/${date.day}';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          title: Text(
                            t.note != null && t.note!.isNotEmpty
                                ? t.note!
                                : '无备注',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Text(
                            '¥${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: amountColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPieTab({
    required String title,
    required List<Map<String, dynamic>> data,
    required MaterialColor color,
    required String emptyMessage,
  }) {
    if (data.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    final total = data.fold<double>(
        0, (sum, item) => sum + (item['total'] as num).toDouble());

    // 取前6个，其余合并为"其他"
    final displayData = _preparePieData(data);
    final type = color == Colors.green ? 'expense' : 'income';

    final colors = [
      color.shade300,
      color.shade400,
      color.shade500,
      color.shade600,
      color.shade700,
      Colors.grey.shade400,
    ];

    void onCategoryTap(Map<String, dynamic> item) {
      _showCategoryTransactions(
        categoryName: item['category_name'] as String,
        categoryIds: (item['category_ids'] as List<int>).cast<int>(),
        type: type,
        color: color,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                sections: List.generate(displayData.length, (index) {
                  final item = displayData[index];
                  final amount = item['total'] as double;
                  final percentage = total > 0 ? (amount / total * 100) : 0;
                  final isOther = item['category_name'] == '其他';
                  final sectionColor = isOther
                      ? Colors.grey.shade400
                      : colors[index % (colors.length - 1)];

                  return PieChartSectionData(
                    color: sectionColor,
                    value: amount,
                    title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (event, pieTouchResponse) {
                    if (event is FlTapUpEvent &&
                        pieTouchResponse?.touchedSection != null) {
                      final index =
                          pieTouchResponse!.touchedSection!.touchedSectionIndex;
                      if (index >= 0 && index < displayData.length) {
                        onCategoryTap(displayData[index]);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '点击分类查看明细',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          // 分类列表
          ...List.generate(displayData.length, (index) {
            final item = displayData[index];
            final amount = (item['total'] as num).toDouble();
            final percentage = total > 0 ? (amount / total * 100).toDouble() : 0.0;
            final isOther = item['category_name'] == '其他';
            final itemColor = isOther
                ? Colors.grey.shade400
                : colors[index % (colors.length - 1)];

            return _buildCategoryListItem(
              name: item['category_name'] as String,
              amount: amount,
              percentage: percentage,
              color: itemColor,
              iconName: item['icon_name'] as String?,
              onTap: () => onCategoryTap(item),
            );
          }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _preparePieData(
      List<Map<String, dynamic>> data) {
    // 1. 先合并同名分类（不同 ID 但同名的分类合并统计）
    final merged = <String, Map<String, dynamic>>{};
    final mergedIds = <String, List<int>>{}; // 记录每个名称对应的所有 category_id
    for (final item in data) {
      final name = item['category_name'] as String;
      final id = item['category_id'] as int;
      if (merged.containsKey(name)) {
        merged[name]!['total'] =
            (merged[name]!['total'] as double) + (item['total'] as double);
        mergedIds[name]!.add(id);
      } else {
        merged[name] = Map<String, dynamic>.from(item);
        mergedIds[name] = [id];
      }
    }
    // 按 total 降序重新排序
    data = merged.values.toList()
      ..sort((a, b) => ((b['total'] as num) - (a['total'] as num)).sign.toInt());
    // 把 category_ids 存进去，供点击"其他"时查询用
    for (final item in data) {
      final name = item['category_name'] as String;
      item['category_ids'] = mergedIds[name] ?? [];
    }

    // 2. ≤6 个分类直接返回
    if (data.length <= 6) return data;

    // 3. 取前 5 + 其余合并为"其他"
    final top5 = data.sublist(0, 5);
    final others = data.sublist(5);
    final otherTotal = others.fold<double>(
        0, (sum, item) => sum + (item['total'] as double));
    final otherIds = others
        .expand((item) => (item['category_ids'] as List<int>))
        .toList();

    // 4. 检查前 5 里是否已有名为"其他"的分类
    final existingOtherIdx =
        top5.indexWhere((item) => item['category_name'] == '其他');

    if (existingOtherIdx >= 0) {
      // 已有"其他"分类，把溢出量合并进去
      final existing = top5[existingOtherIdx];
      final combined = Map<String, dynamic>.from(existing);
      combined['total'] = (existing['total'] as double) + otherTotal;
      combined['category_ids'] = [
        ...(existing['category_ids'] as List<int>),
        ...otherIds,
      ];
      final result = List<Map<String, dynamic>>.from(top5);
      result[existingOtherIdx] = combined;
      return result;
    }

    return [
      ...top5,
      {
        'category_name': '其他',
        'total': otherTotal,
        'icon_name': 'more_horiz',
        'category_ids': otherIds,
      },
    ];
  }

  Widget _buildCategoryListItem({
    required String name,
    required double amount,
    required double percentage,
    required Color color,
    String? iconName,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '¥${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
