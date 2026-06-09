import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../database/models.dart' as models;

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;

  List<models.Category> _expenseCategories = [];
  List<models.Category> _incomeCategories = [];
  List<models.Category> _transferCategories = [];
  bool _isLoading = true;
  bool _isBatchMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final expense = await _db.getCategories('expense');
    final income = await _db.getCategories('income');
    final transfer = await _db.getCategories('transfer');

    setState(() {
      _expenseCategories = expense;
      _incomeCategories = income;
      _transferCategories = transfer;
      _isLoading = false;
    });
  }

  void _toggleBatchMode() {
    setState(() {
      _isBatchMode = !_isBatchMode;
      if (!_isBatchMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 个分类吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in _selectedIds) {
        await _db.deleteCategory(id);
      }
      _selectedIds.clear();
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    }
  }

  Future<void> _addCategory(String type) async {
    final result = await _showCategoryDialog(type: type);
    if (result != null) {
      final category = models.Category(
        name: result.name,
        type: type,
        iconName: result.iconName,
        sortOrder: 100,
        isDefault: 0,
      );
      await _db.insertCategory(category);
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分类已添加')),
        );
      }
    }
  }

  Future<void> _editCategory(models.Category category) async {
    final result = await _showCategoryDialog(
      type: category.type,
      initialName: category.name,
      initialIcon: category.iconName,
    );
    if (result != null) {
      final updated = category.copyWith(
        name: result.name,
        iconName: result.iconName,
      );
      await _db.updateCategory(updated);
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(models.Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${category.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.deleteCategory(category.id!);
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    }
  }

  Future<_CategoryDialogResult?> _showCategoryDialog({
    required String type,
    String? initialName,
    String? initialIcon,
  }) async {
    String name = initialName ?? '';
    String? selectedIcon = initialIcon;

    return showDialog<_CategoryDialogResult?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(initialName == null ? '添加分类' : '编辑分类'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: TextEditingController(text: name)
                        ..selection = TextSelection.collapsed(offset: name.length),
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '分类名称',
                      ),
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '选择图标',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetIcons.map((entry) {
                        final iconName = entry.key;
                        final iconData = entry.value;
                        final isSelected = selectedIcon == iconName;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = iconName;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              iconData,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (name.trim().isNotEmpty) {
                      Navigator.pop(
                        context,
                        _CategoryDialogResult(
                          name: name.trim(),
                          iconName: selectedIcon,
                        ),
                      );
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          TextButton(
            onPressed: _toggleBatchMode,
            child: Text(
              _isBatchMode ? '完成' : '批量管理',
              style: TextStyle(
                color: _isBatchMode
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '支出', icon: Icon(Icons.arrow_downward)),
            Tab(text: '收入', icon: Icon(Icons.arrow_upward)),
            Tab(text: '转账', icon: Icon(Icons.swap_horiz)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryTab(_expenseCategories, 'expense'),
                _buildCategoryTab(_incomeCategories, 'income'),
                _buildCategoryTab(_transferCategories, 'transfer'),
              ],
            ),
      bottomNavigationBar: _isBatchMode && _selectedIds.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _batchDelete,
                  icon: const Icon(Icons.delete),
                  label: Text('删除 (${_selectedIds.length})'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryTab(List<models.Category> categories, String type) {
    return Column(
      children: [
        Expanded(
          child: categories.isEmpty
              ? const Center(
                  child: Text(
                    '暂无分类',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryItem(category, type);
                  },
                ),
        ),
        if (!_isBatchMode)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addCategory(type),
                icon: const Icon(Icons.add),
                label: const Text('添加分类'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryItem(models.Category category, String type) {
    final typeColor = _getTypeColor(type);
    final isSelected = _selectedIds.contains(category.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: _isBatchMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(category.id!),
              )
            : CircleAvatar(
                backgroundColor: typeColor.withAlpha(30),
                child: Icon(
                  _getCategoryIcon(category.iconName),
                  color: typeColor,
                  size: 20,
                ),
              ),
        title: Text(category.name),
        subtitle: category.isDefault == 1
            ? const Text(
                '预设分类',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              )
            : null,
        trailing: _isBatchMode
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCategory(category);
                  } else if (value == 'delete') {
                    _deleteCategory(category);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: _isBatchMode ? () => _toggleSelection(category.id!) : null,
      ),
    );
  }

  static const List<MapEntry<String, IconData>> _presetIcons = [
    MapEntry('restaurant', Icons.restaurant),
    MapEntry('directions_car', Icons.directions_car),
    MapEntry('shopping_bag', Icons.shopping_bag),
    MapEntry('home', Icons.home),
    MapEntry('movie', Icons.movie),
    MapEntry('local_hospital', Icons.local_hospital),
    MapEntry('school', Icons.school),
    MapEntry('phone_android', Icons.phone_android),
    MapEntry('card_giftcard', Icons.card_giftcard),
    MapEntry('account_balance_wallet', Icons.account_balance_wallet),
    MapEntry('emoji_events', Icons.emoji_events),
    MapEntry('trending_up', Icons.trending_up),
    MapEntry('work', Icons.work),
    MapEntry('redeem', Icons.redeem),
    MapEntry('undo', Icons.undo),
    MapEntry('swap_horiz', Icons.swap_horiz),
    MapEntry('more_horiz', Icons.more_horiz),
  ];

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
    _tabController.dispose();
    super.dispose();
  }
}

class _CategoryDialogResult {
  final String name;
  final String? iconName;

  _CategoryDialogResult({required this.name, this.iconName});
}
