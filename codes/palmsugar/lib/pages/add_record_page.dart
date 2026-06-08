import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../database/models.dart' as models;

class AddRecordPage extends StatefulWidget {
  final models.Transaction? transaction;

  const AddRecordPage({super.key, this.transaction});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final DatabaseHelper _db = DatabaseHelper();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'expense';
  DateTime _selectedDate = DateTime.now();
  models.Category? _selectedCategory;
  List<models.Category> _categories = [];
  bool _isLoading = true;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditing) {
      _initEditData();
    }
  }

  void _initEditData() {
    final t = widget.transaction!;
    _selectedType = t.type;
    _amountController.text = t.amount.toStringAsFixed(2);
    _noteController.text = t.note ?? '';
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(t.date);
    // category will be set after categories are loaded
  }

  Future<void> _loadCategories() async {
    final categories = await _db.getCategories(_selectedType);
    setState(() {
      _categories = categories;
      _isLoading = false;
    });

    // 如果是编辑模式，设置当前分类
    if (_isEditing && widget.transaction != null) {
      final current = categories.firstWhere(
        (c) => c.id == widget.transaction!.categoryId,
        orElse: () => categories.first,
      );
      setState(() {
        _selectedCategory = current;
      });
    } else if (categories.isNotEmpty) {
      setState(() {
        _selectedCategory = categories.first;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      _showError('请输入金额');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('请输入有效的金额');
      return;
    }

    if (_selectedCategory == null) {
      _showError('请选择分类');
      return;
    }

    final now = DateTime.now();
    final dateMs = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    ).millisecondsSinceEpoch;

    final transaction = models.Transaction(
      id: _isEditing ? widget.transaction!.id : null,
      type: _selectedType,
      amount: amount,
      categoryId: _selectedCategory!.id!,
      date: dateMs,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (_isEditing) {
      await _db.updateTransaction(transaction);
    } else {
      await _db.insertTransaction(transaction);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
      _selectedCategory = null;
    });
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑记录' : '记一笔'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saveTransaction,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 类型选择
                    _buildTypeSelector(),
                    const SizedBox(height: 24),

                    // 金额输入
                    _buildAmountInput(),
                    const SizedBox(height: 24),

                    // 日期选择
                    _buildDateSelector(),
                    const SizedBox(height: 24),

                    // 分类选择
                    _buildCategorySelector(),
                    const SizedBox(height: 24),

                    // 备注输入
                    _buildNoteInput(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [
      {'value': 'expense', 'label': '支出', 'color': Colors.red},
      {'value': 'income', 'label': '收入', 'color': Colors.green},
      {'value': 'transfer', 'label': '转账', 'color': Colors.blue},
    ];

    return Row(
      children: types.map((type) {
        final isSelected = _selectedType == type['value'];
        final color = type['color'] as Color;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                type['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: color.withAlpha(30),
              checkmarkColor: Colors.white,
              onSelected: (_) => _onTypeChanged(type['value'] as String),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '金额',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^[\d+\-*/.]*$')),
          ],
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.attach_money, size: 32),
            hintText: '0.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onEditingComplete: () {
            final result = _evaluateExpression(_amountController.text);
            if (result != null) {
              _amountController.text = result.toStringAsFixed(2);
            }
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '日期',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分类',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        if (_categories.isEmpty)
          const Text('暂无分类，请先添加分类')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory?.id == category.id;
              final typeColor = _getTypeColor(_selectedType);

              return ChoiceChip(
                avatar: isSelected
                    ? null
                    : Icon(
                        _getCategoryIcon(category.iconName),
                        size: 18,
                        color: typeColor,
                      ),
                label: Text(category.name),
                selected: isSelected,
                selectedColor: typeColor,
                backgroundColor: typeColor.withAlpha(20),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                checkmarkColor: Colors.white,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: '备注（选填）',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  double? _evaluateExpression(String input) {
    final pattern = RegExp(r'^\s*(\d+\.?\d*)\s*([\+\-\*/])\s*(\d+\.?\d*)\s*$');
    final match = pattern.firstMatch(input);
    if (match == null) return null;

    final left = double.tryParse(match.group(1)!) ?? 0;
    final op = match.group(2)!;
    final right = double.tryParse(match.group(3)!) ?? 0;

    switch (op) {
      case '+':
        return left + right;
      case '-':
        return left - right;
      case '*':
        return left * right;
      case '/':
        if (right == 0) return null;
        return left / right;
      default:
        return null;
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
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
