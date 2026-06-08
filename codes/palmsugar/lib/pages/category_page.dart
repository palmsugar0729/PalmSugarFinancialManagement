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

  Future<void> _addCategory(String type) async {
    final hintMap = {
      'expense': '例如：健身、旅游',
      'income': '例如：工资、奖金',
      'transfer': '例如：支付宝转微信、银行卡转账',
    };

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('添加分类'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '分类名称',
              hintText: hintMap[type] ?? '例如：健身、旅游',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('添加'),
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      final category = models.Category(
        name: result.trim(),
        type: type,
        sortOrder: 100, // 自定义分类排在后面
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
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: category.name);
        return AlertDialog(
          title: const Text('编辑分类'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '分类名称',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      final updated = category.copyWith(name: result.trim());
      await _db.updateCategory(updated);
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(models.Category category) async {
    if (category.isDefault == 1) {
      _showError('预设分类不能删除');
      return;
    }

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
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
                _buildCategoryList(_expenseCategories, 'expense'),
                _buildCategoryList(_incomeCategories, 'income'),
                _buildCategoryList(_transferCategories, 'transfer'),
              ],
            ),
    );
  }

  Widget _buildCategoryList(List<models.Category> categories, String type) {
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
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTypeColor(type).withAlpha(30),
                        child: Icon(
                          _getCategoryIcon(category.iconName),
                          color: _getTypeColor(type),
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
                      trailing: category.isDefault == 1
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
                                      Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('删除',
                                          style:
                                              TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
        ),
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
