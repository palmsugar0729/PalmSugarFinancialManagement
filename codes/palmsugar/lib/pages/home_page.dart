import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../database/models.dart' as models;
import 'add_record_page.dart';
import 'category_page.dart';
import 'answer_book_page.dart';
import 'data_backup_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _db = DatabaseHelper();

  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;
  double _monthIncome = 0.0;
  double _monthExpense = 0.0;
  List<models.Transaction> _monthTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final startOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final endOfMonth = DateTime(_currentYear, _currentMonth + 1, 0, 23, 59, 59);

    final startMs = startOfMonth.millisecondsSinceEpoch;
    final endMs = endOfMonth.millisecondsSinceEpoch;

    final summary = await _db.getSummary(startMs, endMs);
    final transactions = await _db.getTransactions(
      startDate: startMs,
      endDate: endMs,
      limit: 1000,
    );

    setState(() {
      _monthIncome = summary['income'] ?? 0.0;
      _monthExpense = summary['expense'] ?? 0.0;
      _monthTransactions = transactions;
      _isLoading = false;
    });
  }

  void _goToMonth(int year, int month) {
    setState(() {
      _currentYear = year;
      _currentMonth = month;
      _isLoading = true;
    });
    _loadData();
  }

  void _goToPreviousMonth() {
    // 检查是否有上个月的记录
    _checkHasRecords(_currentYear, _currentMonth - 1).then((hasRecords) {
      if (!hasRecords) return;
      var year = _currentYear;
      var month = _currentMonth - 1;
      if (month < 1) {
        month = 12;
        year--;
      }
      _goToMonth(year, month);
    });
  }

  void _goToNextMonth() {
    // 不能滑到未来月份
    final now = DateTime.now();
    final nextMonth = DateTime(_currentYear, _currentMonth + 1);
    if (nextMonth.isAfter(DateTime(now.year, now.month + 1, 1))) return;

    _checkHasRecords(_currentYear, _currentMonth + 1).then((hasRecords) {
      if (!hasRecords) return;
      var year = _currentYear;
      var month = _currentMonth + 1;
      if (month > 12) {
        month = 1;
        year++;
      }
      _goToMonth(year, month);
    });
  }

  Future<bool> _checkHasRecords(int year, int month) async {
    var targetYear = year;
    var targetMonth = month;
    if (targetMonth < 1) {
      targetMonth = 12;
      targetYear--;
    } else if (targetMonth > 12) {
      targetMonth = 1;
      targetYear++;
    }
    final start = DateTime(targetYear, targetMonth, 1).millisecondsSinceEpoch;
    final end = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
    final txs = await _db.getTransactions(startDate: start, endDate: end, limit: 1);
    return txs.isNotEmpty;
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final result = await showDialog<DateTime?>(
      context: context,
      builder: (context) {
        var selectedYear = _currentYear;
        return AlertDialog(
          title: const Text('选择月份'),
          content: SizedBox(
            width: 300,
            height: 280,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    // 年份选择
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setDialogState(() => selectedYear--),
                        ),
                        Text(
                          '$selectedYear年',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            if (selectedYear < now.year) {
                              setDialogState(() => selectedYear++);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    // 月份网格
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 4,
                        childAspectRatio: 1.5,
                        children: List.generate(12, (index) {
                          final month = index + 1;
                          final isSelected = selectedYear == _currentYear && month == _currentMonth;
                          final isFuture = selectedYear > now.year ||
                              (selectedYear == now.year && month > now.month);
                          return InkWell(
                            onTap: isFuture
                                ? null
                                : () {
                                    Navigator.pop(
                                      context,
                                      DateTime(selectedYear, month),
                                    );
                                  },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$month月',
                                  style: TextStyle(
                                    color: isFuture
                                        ? Colors.grey.shade400
                                        : (isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.black87),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      _goToMonth(result.year, result.month);
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  String _formatDate(int dateMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(dateMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return '今天 ${DateFormat('HH:mm').format(date)}';
    } else if (dateDay == yesterday) {
      return '昨天 ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(date);
    }
  }

  Future<void> _deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除')),
      );
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'expense':
        return Colors.green;
      case 'income':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'expense':
        return '支出';
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return type;
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    final map = <String, IconData>{
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'home': Icons.home,
      'movie': Icons.movie,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'phone_android': Icons.phone_android,
      'card_giftcard': Icons.card_giftcard,
      'more_horiz': Icons.more_horiz,
      'account_balance_wallet': Icons.account_balance_wallet,
      'emoji_events': Icons.emoji_events,
      'trending_up': Icons.trending_up,
      'work': Icons.work,
      'redeem': Icons.redeem,
      'undo': Icons.undo,
      'swap_horiz': Icons.swap_horiz,
    };
    return map[iconName] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('棕榈糖账本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnswerBookPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DataBackupPage()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! > 200) {
                    _goToNextMonth();
                  } else if (details.primaryVelocity! < -200) {
                    _goToPreviousMonth();
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(),
                      _buildMonthTransactions(),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRecordPage()),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final balance = _monthIncome - _monthExpense;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: _selectMonth,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_currentYear年$_currentMonth月收支',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.calendar_month, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '收入',
                    _formatAmount(_monthIncome),
                    Colors.red,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '支出',
                    _formatAmount(_monthExpense),
                    Colors.green,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '结余',
                    _formatAmount(balance),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_currentMonth月记录',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '共 ${_monthTransactions.length} 条',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (_monthTransactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                '本月暂无记录',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _monthTransactions.length,
            itemBuilder: (context, index) {
              final t = _monthTransactions[index];
              return _buildTransactionItem(t);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionItem(models.Transaction t) {
    return FutureBuilder<models.Category?>(
      future: _db.getCategoryById(t.categoryId),
      builder: (context, snapshot) {
        final category = snapshot.data;
        final typeColor = _getTypeColor(t.type);
        final prefix = t.type == 'expense' ? '-' : (t.type == 'income' ? '+' : '');

        return Slidable(
          key: ValueKey('transaction_${t.id}'),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              CustomSlidableAction(
                onPressed: (_) => _deleteTransaction(t.id!),
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
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: typeColor.withAlpha(30),
              child: Icon(
                _getCategoryIcon(category?.iconName),
                color: typeColor,
                size: 20,
              ),
            ),
            title: Text(
              category?.name ?? '未知分类',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${_getTypeLabel(t.type)} · ${_formatDate(t.date)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Text(
              '$prefix${_formatAmount(t.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddRecordPage(transaction: t),
                ),
              );
              _loadData();
            },
          ),
        );
      },
    );
  }
}
