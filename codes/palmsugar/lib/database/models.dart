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

// ==================== 理财模型 ====================

class FundHolding {
  final int? id;
  final String fundName;
  final String? fundCode;
  final String? fundType;
  final double totalBuyAmount;
  final double totalFee;
  final double totalShares;
  final double holdingShares;
  final double? costPerShare;
  final double? currentNav;
  final double? holdingAmount;
  final double? costAmount;
  final double? profit;
  final double? profitRate;
  final int isDeleted;
  final int? createdAt;
  final int? updatedAt;

  FundHolding({
    this.id,
    required this.fundName,
    this.fundCode,
    this.fundType,
    this.totalBuyAmount = 0,
    this.totalFee = 0,
    this.totalShares = 0,
    this.holdingShares = 0,
    this.costPerShare,
    this.currentNav,
    this.holdingAmount,
    this.costAmount,
    this.profit,
    this.profitRate,
    this.isDeleted = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': id,
      'fund_name': fundName,
      'fund_code': fundCode,
      'fund_type': fundType,
      'total_buy_amount': totalBuyAmount,
      'total_fee': totalFee,
      'total_shares': totalShares,
      'holding_shares': holdingShares,
      'cost_per_share': costPerShare,
      'current_nav': currentNav,
      'holding_amount': holdingAmount,
      'cost_amount': costAmount,
      'profit': profit,
      'profit_rate': profitRate,
      'is_deleted': isDeleted,
      'created_at': createdAt ?? now,
      'updated_at': updatedAt ?? now,
    };
  }

  factory FundHolding.fromMap(Map<String, dynamic> map) {
    return FundHolding(
      id: map['id'] as int?,
      fundName: map['fund_name'] as String,
      fundCode: map['fund_code'] as String?,
      fundType: map['fund_type'] as String?,
      totalBuyAmount: (map['total_buy_amount'] as num?)?.toDouble() ?? 0,
      totalFee: (map['total_fee'] as num?)?.toDouble() ?? 0,
      totalShares: (map['total_shares'] as num?)?.toDouble() ?? 0,
      holdingShares: (map['holding_shares'] as num?)?.toDouble() ?? 0,
      costPerShare: (map['cost_per_share'] as num?)?.toDouble(),
      currentNav: (map['current_nav'] as num?)?.toDouble(),
      holdingAmount: (map['holding_amount'] as num?)?.toDouble(),
      costAmount: (map['cost_amount'] as num?)?.toDouble(),
      profit: (map['profit'] as num?)?.toDouble(),
      profitRate: (map['profit_rate'] as num?)?.toDouble(),
      isDeleted: map['is_deleted'] as int? ?? 0,
      createdAt: map['created_at'] as int?,
      updatedAt: map['updated_at'] as int?,
    );
  }

  FundHolding copyWith({
    int? id,
    String? fundName,
    String? fundCode,
    String? fundType,
    double? totalBuyAmount,
    double? totalFee,
    double? totalShares,
    double? holdingShares,
    double? costPerShare,
    double? currentNav,
    double? holdingAmount,
    double? costAmount,
    double? profit,
    double? profitRate,
    int? isDeleted,
    int? createdAt,
    int? updatedAt,
  }) {
    return FundHolding(
      id: id ?? this.id,
      fundName: fundName ?? this.fundName,
      fundCode: fundCode ?? this.fundCode,
      fundType: fundType ?? this.fundType,
      totalBuyAmount: totalBuyAmount ?? this.totalBuyAmount,
      totalFee: totalFee ?? this.totalFee,
      totalShares: totalShares ?? this.totalShares,
      holdingShares: holdingShares ?? this.holdingShares,
      costPerShare: costPerShare ?? this.costPerShare,
      currentNav: currentNav ?? this.currentNav,
      holdingAmount: holdingAmount ?? this.holdingAmount,
      costAmount: costAmount ?? this.costAmount,
      profit: profit ?? this.profit,
      profitRate: profitRate ?? this.profitRate,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FundTransaction {
  final int? id;
  final int fundId;
  final String type; // 'buy', 'sell', 'dividend'
  final int date;
  final double? amount;
  final double fee;
  final double? nav;
  final double? shares;
  final double? dividendAmount;
  final int syncedTransactionId;
  final String? note;
  final int? createdAt;

  FundTransaction({
    this.id,
    required this.fundId,
    required this.type,
    required this.date,
    this.amount,
    this.fee = 0,
    this.nav,
    this.shares,
    this.dividendAmount,
    this.syncedTransactionId = 0,
    this.note,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fund_id': fundId,
      'type': type,
      'date': date,
      'amount': amount,
      'fee': fee,
      'nav': nav,
      'shares': shares,
      'dividend_amount': dividendAmount,
      'synced_transaction_id': syncedTransactionId,
      'note': note,
      'created_at': createdAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory FundTransaction.fromMap(Map<String, dynamic> map) {
    return FundTransaction(
      id: map['id'] as int?,
      fundId: map['fund_id'] as int,
      type: map['type'] as String,
      date: map['date'] as int,
      amount: (map['amount'] as num?)?.toDouble(),
      fee: (map['fee'] as num?)?.toDouble() ?? 0,
      nav: (map['nav'] as num?)?.toDouble(),
      shares: (map['shares'] as num?)?.toDouble(),
      dividendAmount: (map['dividend_amount'] as num?)?.toDouble(),
      syncedTransactionId: map['synced_transaction_id'] as int? ?? 0,
      note: map['note'] as String?,
      createdAt: map['created_at'] as int?,
    );
  }

  FundTransaction copyWith({
    int? id,
    int? fundId,
    String? type,
    int? date,
    double? amount,
    double? fee,
    double? nav,
    double? shares,
    double? dividendAmount,
    int? syncedTransactionId,
    String? note,
    int? createdAt,
  }) {
    return FundTransaction(
      id: id ?? this.id,
      fundId: fundId ?? this.fundId,
      type: type ?? this.type,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      nav: nav ?? this.nav,
      shares: shares ?? this.shares,
      dividendAmount: dividendAmount ?? this.dividendAmount,
      syncedTransactionId: syncedTransactionId ?? this.syncedTransactionId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
