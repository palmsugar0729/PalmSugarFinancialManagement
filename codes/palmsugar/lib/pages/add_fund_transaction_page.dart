import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart';
import '../database/models.dart';

class AddFundTransactionPage extends StatefulWidget {
  final FundHolding? preselectedHolding;
  final String? initialType; // 'buy', 'sell', 'dividend'

  const AddFundTransactionPage({
    super.key,
    this.preselectedHolding,
    this.initialType,
  });

  @override
  State<AddFundTransactionPage> createState() =>
      _AddFundTransactionPageState();
}

class _AddFundTransactionPageState extends State<AddFundTransactionPage> {
  final DatabaseHelper _db = DatabaseHelper();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _navController = TextEditingController();
  final _sharesController = TextEditingController();
  final _noteController = TextEditingController();
  final _fundCodeController = TextEditingController();
  final _fundNameController = TextEditingController();

  String _selectedType = 'buy';
  DateTime _selectedDate = DateTime.now();
  FundHolding? _selectedHolding;
  List<FundHolding> _holdings = [];
  bool _isLoading = true;
  bool _isLookingUp = false;
  bool _isNewFund = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) _selectedType = widget.initialType!;
    _loadHoldings();
  }

  Future<void> _loadHoldings() async {
    final holdings = await _db.getFundHoldings();
    setState(() {
      _holdings = holdings;
      _isLoading = false;
      if (widget.preselectedHolding != null) {
        _selectedHolding = widget.preselectedHolding;
        _isNewFund = false;
      } else if (_selectedType == 'sell' && holdings.isNotEmpty) {
        _selectedHolding = holdings.first;
      }
    });
  }

  Future<void> _lookupFundCode() async {
    final code = _fundCodeController.text.trim();
    if (code.length < 6) {
      _showError('请输入6位基金代码');
      return;
    }

    setState(() => _isLookingUp = true);

    try {
      // 天天基金实时估值接口
      final url = 'http://fundgz.1234567.com.cn/js/$code.js';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.contains('jsonpgz(')) {
          final jsonStr =
              body.substring(body.indexOf('{'), body.lastIndexOf('}') + 1);
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final name = data['name'] as String?;
          if (name != null && name.isNotEmpty) {
            _fundNameController.text = name;
            setState(() => _isLookingUp = false);
            return;
          }
        }
      }
      _showError('未找到该基金，请检查代码或手动输入名称');
    } catch (e) {
      _showError('联网查询失败，请手动输入基金名称');
    }

    setState(() => _isLookingUp = false);
  }

  void _calculateAmount() {
    if (_selectedType == 'dividend') return;
    final nav = double.tryParse(_navController.text) ?? 0;
    final shares = double.tryParse(_sharesController.text) ?? 0;
    if (nav > 0 && shares > 0) {
      // 金额 = 份额 × 净值（净额，不含手续费）
      final amount = shares * nav;
      _amountController.text = amount.toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    // 验证基金
    if (_isNewFund) {
      final name = _fundNameController.text.trim();
      if (name.isEmpty) {
        _showError('请输入基金名称');
        return;
      }
      final holding = FundHolding(
        fundName: name,
        fundCode: _fundCodeController.text.trim().isNotEmpty
            ? _fundCodeController.text.trim()
            : null,
        currentNav: double.tryParse(_navController.text) ?? 0,
      );
      final id = await _db.insertFundHolding(holding);
      _selectedHolding = await _db.getFundHoldingById(id);
    } else if (_selectedHolding == null) {
      _showError('请选择基金');
      return;
    }

    if (_selectedHolding == null) {
      _showError('请选择基金');
      return;
    }

    final fee = double.tryParse(_feeController.text) ?? 0;
    final nav = double.tryParse(_navController.text);
    final shares = double.tryParse(_sharesController.text);

    double? amount;
    if (_selectedType != 'dividend') {
      if (shares == null || shares <= 0) {
        _showError('请输入有效份额');
        return;
      }
      if (nav == null || nav <= 0) {
        _showError('请输入有效净值');
        return;
      }
      // 金额 = 份额 × 净值（净额，手续费单独记录为支出）
      amount = shares * nav;
      _amountController.text = amount.toStringAsFixed(2);
    } else {
      amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        _showError('请输入分红金额');
        return;
      }
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

    final ft = FundTransaction(
      fundId: _selectedHolding!.id!,
      type: _selectedType,
      date: dateMs,
      amount: amount,
      fee: fee,
      nav: nav,
      shares: shares,
      dividendAmount: _selectedType == 'dividend' ? amount : null,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    // 卖出时检查份额是否足够
    if (_selectedType == 'sell' && shares != null) {
      if (shares > _selectedHolding!.holdingShares) {
        _showError('卖出份额不能超过持有份额（当前持有 ${_selectedHolding!.holdingShares.toStringAsFixed(2)} 份）');
        return;
      }
    }

    try {
      await _db.insertFundTransaction(ft);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('保存失败：$e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _navController.dispose();
    _sharesController.dispose();
    _noteController.dispose();
    _fundCodeController.dispose();
    _fundNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewFund ? '新建基金并记录' : '记录交易'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _save,
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
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    _buildFundSelector(),
                    const SizedBox(height: 24),
                    _buildDateSelector(),
                    const SizedBox(height: 24),
                    if (_selectedType != 'dividend') ...[
                      _buildFeeInput(),
                      const SizedBox(height: 16),
                      _buildNavInput(),
                      const SizedBox(height: 16),
                      _buildSharesDisplay(),
                      const SizedBox(height: 16),
                      _buildAmountInput(),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildDividendAmountInput(),
                      const SizedBox(height: 24),
                    ],
                    _buildNoteInput(),
                  ],
                ),
              ),
            ),
    );
  }

  // ==================== 类型选择 ====================
  Widget _buildTypeSelector() {
    final types = [
      {'value': 'buy', 'label': '买入', 'color': Colors.red},
      {'value': 'sell', 'label': '卖出', 'color': Colors.green},
      {'value': 'dividend', 'label': '分红', 'color': Colors.orange},
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
              onSelected: (_) {
                setState(() {
                  _selectedType = type['value'] as String;
                  _amountController.clear();
                  _feeController.clear();
                  _navController.clear();
                  _sharesController.clear();
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================== 基金选择 ====================
  Widget _buildFundSelector() {
    if (_isNewFund) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '新建基金',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isNewFund = false;
                    if (_holdings.isNotEmpty) _selectedHolding = _holdings.first;
                  });
                },
                child: const Text('选择已有基金'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _fundCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '基金代码',
                    border: OutlineInputBorder(),
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isLookingUp ? null : _lookupFundCode,
                icon: _isLookingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 18),
                label: const Text('查询'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fundNameController,
            decoration: const InputDecoration(
              labelText: '基金名称',
              border: OutlineInputBorder(),
              hintText: '输入代码查询或手动填写',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '选择基金',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isNewFund = true;
                  _selectedHolding = null;
                  _fundCodeController.clear();
                  _fundNameController.clear();
                });
              },
              child: const Text('新建基金'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_holdings.isEmpty)
          const Text('暂无基金，请先新建')
        else
          DropdownButtonFormField<int>(
            initialValue: _selectedHolding?.id,
            items: _holdings
                .map((h) => DropdownMenuItem(
                      value: h.id,
                      child: Text(
                        h.fundCode != null && h.fundCode!.isNotEmpty
                            ? '${h.fundCode} ${h.fundName}'
                            : h.fundName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (id) {
              setState(() {
                _selectedHolding = _holdings.firstWhere((h) => h.id == id);
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        // 卖出时显示持仓信息
        if (_selectedType == 'sell' && _selectedHolding != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '当前持有 ${_selectedHolding!.holdingShares.toStringAsFixed(2)} 份 · '
                  '成本 ¥${(_selectedHolding!.costPerShare ?? 0).toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==================== 日期 ====================
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
                Text('日期',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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

  // ==================== 金额 ====================
  Widget _buildAmountInput() {
    final label = _selectedType == 'sell' ? '到账金额（自动计算）' : '买入金额（自动计算）';
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      readOnly: true,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.attach_money, size: 28),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== 手续费 ====================
  Widget _buildFeeInput() {
    return TextField(
      controller: _feeController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '手续费（选填）',
        hintText: '0.00',
        prefixIcon: Icon(Icons.receipt, color: Colors.grey.shade500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (_) => _calculateAmount(),
    );
  }

  // ==================== 净值 ====================
  Widget _buildNavInput() {
    return TextField(
      controller: _navController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '净值',
        hintText: '0.0000',
        prefixIcon: Icon(Icons.trending_up, color: Colors.grey.shade500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (_) => _calculateAmount(),
    );
  }

  // ==================== 份额 ====================
  Widget _buildSharesDisplay() {
    final label = _selectedType == 'sell' ? '卖出份额' : '买入份额';
    return TextField(
      controller: _sharesController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.pie_chart, color: Colors.grey.shade500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (_) => _calculateAmount(),
    );
  }

  // ==================== 分红金额 ====================
  Widget _buildDividendAmountInput() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: '分红金额',
        prefixIcon: const Icon(Icons.card_giftcard, size: 28),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== 备注 ====================
  Widget _buildNoteInput() {
    return TextField(
      controller: _noteController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: '备注（选填）',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
