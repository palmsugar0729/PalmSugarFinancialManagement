// 数据模型定义

enum TransactionType { expense, income, transfer }

class Category {
  final int? id;
  final int parentId;
  final String name;
  final String type; // 'expense', 'income', 'transfer'
  final String? iconName;
  final int sortOrder;
  final int isDefault;
  final int isDeleted;
  final int? createdAt;
  final int? updatedAt;

  Category({
    this.id,
    this.parentId = 0,
    required this.name,
    required this.type,
    this.iconName,
    this.sortOrder = 0,
    this.isDefault = 0,
    this.isDeleted = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'type': type,
      'icon_name': iconName,
      'sort_order': sortOrder,
      'is_default': isDefault,
      'is_deleted': isDeleted,
      'created_at': createdAt ?? DateTime.now().millisecondsSinceEpoch,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      parentId: map['parent_id'] as int? ?? 0,
      name: map['name'] as String,
      type: map['type'] as String,
      iconName: map['icon_name'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      isDefault: map['is_default'] as int? ?? 0,
      isDeleted: map['is_deleted'] as int? ?? 0,
      createdAt: map['created_at'] as int?,
      updatedAt: map['updated_at'] as int?,
    );
  }

  Category copyWith({
    int? id,
    int? parentId,
    String? name,
    String? type,
    String? iconName,
    int? sortOrder,
    int? isDefault,
    int? isDeleted,
    int? createdAt,
    int? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Transaction {
  final int? id;
  final String type; // 'expense', 'income', 'transfer'
  final double amount;
  final int categoryId;
  final int subCategoryId;
  final int accountId;
  final int toAccountId;
  final int date; // 毫秒时间戳
  final String? note;
  final String? tag;
  final int isDeleted;
  final int? createdAt;
  final int? updatedAt;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.subCategoryId = 0,
    this.accountId = 0,
    this.toAccountId = 0,
    required this.date,
    this.note,
    this.tag,
    this.isDeleted = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'date': date,
      'note': note,
      'tag': tag,
      'is_deleted': isDeleted,
      'created_at': createdAt ?? DateTime.now().millisecondsSinceEpoch,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      subCategoryId: map['sub_category_id'] as int? ?? 0,
      accountId: map['account_id'] as int? ?? 0,
      toAccountId: map['to_account_id'] as int? ?? 0,
      date: map['date'] as int,
      note: map['note'] as String?,
      tag: map['tag'] as String?,
      isDeleted: map['is_deleted'] as int? ?? 0,
      createdAt: map['created_at'] as int?,
      updatedAt: map['updated_at'] as int?,
    );
  }

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    int? categoryId,
    int? subCategoryId,
    int? accountId,
    int? toAccountId,
    int? date,
    String? note,
    String? tag,
    int? isDeleted,
    int? createdAt,
    int? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
      tag: tag ?? this.tag,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Answer {
  final int? id;
  final String content;
  final String? category;
  final int isActive;

  Answer({
    this.id,
    required this.content,
    this.category,
    this.isActive = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'category': category,
      'is_active': isActive,
    };
  }

  factory Answer.fromMap(Map<String, dynamic> map) {
    return Answer(
      id: map['id'] as int?,
      content: map['content'] as String,
      category: map['category'] as String?,
      isActive: map['is_active'] as int? ?? 1,
    );
  }
}
