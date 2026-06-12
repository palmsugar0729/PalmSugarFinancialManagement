import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'palmsugar.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建分类表
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_id INTEGER DEFAULT 0,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('expense', 'income', 'transfer')),
        icon_name TEXT,
        sort_order INTEGER DEFAULT 0,
        is_default INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    // 创建收支记录表
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('expense', 'income', 'transfer')),
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        sub_category_id INTEGER DEFAULT 0,
        account_id INTEGER DEFAULT 0,
        to_account_id INTEGER DEFAULT 0,
        date INTEGER NOT NULL,
        note TEXT,
        tag TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // 创建索引
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_type ON transactions(type)',
    );

    // 创建答案表
    await db.execute('''
      CREATE TABLE answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        category TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // 创建基金持仓表
    await db.execute('''
      CREATE TABLE fund_holdings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fund_name TEXT NOT NULL,
        fund_code TEXT,
        fund_type TEXT,
        total_buy_amount REAL DEFAULT 0,
        total_fee REAL DEFAULT 0,
        total_shares REAL DEFAULT 0,
        holding_shares REAL DEFAULT 0,
        cost_per_share REAL,
        current_nav REAL,
        holding_amount REAL,
        cost_amount REAL,
        profit REAL,
        profit_rate REAL,
        is_deleted INTEGER DEFAULT 0,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    // 创建基金交易记录表
    await db.execute('''
      CREATE TABLE fund_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fund_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('buy', 'sell', 'dividend')),
        date INTEGER NOT NULL,
        amount REAL,
        fee REAL DEFAULT 0,
        nav REAL,
        shares REAL,
        dividend_amount REAL,
        synced_transaction_id INTEGER DEFAULT 0,
        note TEXT,
        created_at INTEGER,
        FOREIGN KEY (fund_id) REFERENCES fund_holdings(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_fund_transactions_fund ON fund_transactions(fund_id)',
    );
    await db.execute(
      'CREATE INDEX idx_fund_transactions_date ON fund_transactions(date)',
    );

    // 插入预设数据
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: 新增基金持仓表和交易记录表
      await db.execute('''
        CREATE TABLE fund_holdings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fund_name TEXT NOT NULL,
          fund_code TEXT,
          fund_type TEXT,
          total_buy_amount REAL DEFAULT 0,
          total_fee REAL DEFAULT 0,
          total_shares REAL DEFAULT 0,
          holding_shares REAL DEFAULT 0,
          cost_per_share REAL,
          current_nav REAL,
          holding_amount REAL,
          cost_amount REAL,
          profit REAL,
          profit_rate REAL,
          is_deleted INTEGER DEFAULT 0,
          created_at INTEGER,
          updated_at INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE fund_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fund_id INTEGER NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('buy', 'sell', 'dividend')),
          date INTEGER NOT NULL,
          amount REAL,
          fee REAL DEFAULT 0,
          nav REAL,
          shares REAL,
          dividend_amount REAL,
          synced_transaction_id INTEGER DEFAULT 0,
          note TEXT,
          created_at INTEGER,
          FOREIGN KEY (fund_id) REFERENCES fund_holdings(id)
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_fund_transactions_fund ON fund_transactions(fund_id)',
      );
      await db.execute(
        'CREATE INDEX idx_fund_transactions_date ON fund_transactions(date)',
      );
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // 插入预设分类
    for (final category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }

    // 插入预设答案
    for (final answer in defaultAnswers) {
      await db.insert('answers', answer.toMap());
    }
  }

  // ==================== Category CRUD ====================

  Future<List<Category>> getCategories(String type) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'type = ? AND parent_id = 0 AND is_deleted = 0',
      whereArgs: [type],
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'parent_id = 0 AND is_deleted = 0',
      orderBy: 'type ASC, sort_order ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return Category.fromMap(maps.first);
    return null;
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    // 软删除
    return await db.update(
      'categories',
      {'is_deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== Transaction CRUD ====================

  Future<List<Transaction>> getTransactions({
    int? startDate,
    int? endDate,
    String? type,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    where.add('is_deleted = 0');

    if (startDate != null) {
      where.add('date >= ?');
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      where.add('date <= ?');
      whereArgs.add(endDate);
    }
    if (type != null) {
      where.add('type = ?');
      whereArgs.add(type);
    }

    final maps = await db.query(
      'transactions',
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'date DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<Transaction?> getTransactionById(int id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return Transaction.fromMap(maps.first);
    return null;
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.update(
      'transactions',
      {'is_deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== Statistics ====================

  /// 获取指定时间范围的收支汇总
  Future<Map<String, double>> getSummary(int startDate, int endDate) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        type,
        COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE date >= ? AND date <= ? AND is_deleted = 0
      GROUP BY type
    ''', [startDate, endDate]);

    final summary = <String, double>{
      'expense': 0.0,
      'income': 0.0,
      'transfer': 0.0,
    };

    for (final row in result) {
      final type = row['type'] as String;
      final total = (row['total'] as num).toDouble();
      summary[type] = total;
    }

    return summary;
  }

  /// 按分类统计
  Future<List<Map<String, dynamic>>> getCategorySummary(
    String type,
    int startDate,
    int endDate,
  ) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        c.id as category_id,
        c.name as category_name,
        c.icon_name,
        COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.type = ?
        AND t.date >= ?
        AND t.date <= ?
        AND t.is_deleted = 0
      GROUP BY c.id
      ORDER BY total DESC
    ''', [type, startDate, endDate]);
  }

  /// 获取近N个月每月的收支汇总
  Future<List<Map<String, dynamic>>> getMonthlySummary(int months) async {
    final db = await database;
    final now = DateTime.now();
    final results = <Map<String, dynamic>>[];

    for (var i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

      final summary = await getSummary(
        startOfMonth.millisecondsSinceEpoch,
        endOfMonth.millisecondsSinceEpoch,
      );

      results.add({
        'year': monthDate.year,
        'month': monthDate.month,
        'income': summary['income'] ?? 0.0,
        'expense': summary['expense'] ?? 0.0,
      });
    }

    return results;
  }

  /// 获取指定月份按日的收支汇总
  Future<List<Map<String, dynamic>>> getDailySummary(int year, int month) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    return await db.rawQuery('''
      SELECT
        CAST(date / 86400000 as INTEGER) as day_bucket,
        type,
        COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE date >= ? AND date <= ? AND is_deleted = 0
      GROUP BY day_bucket, type
      ORDER BY day_bucket ASC
    ''', [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch]);
  }

  // ==================== Answer Book ====================

  Future<Answer?> getRandomAnswer() async {
    final db = await database;
    final maps = await db.query(
      'answers',
      where: 'is_active = 1',
      orderBy: 'RANDOM()',
      limit: 1,
    );
    if (maps.isNotEmpty) return Answer.fromMap(maps.first);
    return null;
  }

  Future<List<Answer>> getAllAnswers() async {
    final db = await database;
    final maps = await db.query('answers', orderBy: 'id ASC');
    return maps.map((m) => Answer.fromMap(m)).toList();
  }

  // ==================== Fund Holdings CRUD ====================

  Future<List<FundHolding>> getFundHoldings() async {
    final db = await database;
    final maps = await db.query(
      'fund_holdings',
      where: 'is_deleted = 0',
      orderBy: 'id ASC',
    );
    return maps.map((m) => FundHolding.fromMap(m)).toList();
  }

  Future<FundHolding?> getFundHoldingById(int id) async {
    final db = await database;
    final maps = await db.query(
      'fund_holdings',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return FundHolding.fromMap(maps.first);
    return null;
  }

  Future<int> insertFundHolding(FundHolding holding) async {
    final db = await database;
    return await db.insert('fund_holdings', holding.toMap());
  }

  Future<int> updateFundHolding(FundHolding holding) async {
    final db = await database;
    return await db.update(
      'fund_holdings',
      holding.toMap(),
      where: 'id = ?',
      whereArgs: [holding.id],
    );
  }

  Future<int> deleteFundHolding(int id) async {
    final db = await database;
    return await db.update(
      'fund_holdings',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== Fund Transactions CRUD ====================

  Future<List<FundTransaction>> getFundTransactions({
    int? fundId,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (fundId != null) {
      where.add('fund_id = ?');
      whereArgs.add(fundId);
    }

    final whereClause = where.isNotEmpty ? where.join(' AND ') : null;

    final maps = await db.query(
      'fund_transactions',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => FundTransaction.fromMap(m)).toList();
  }

  /// 插入基金交易记录，自动更新持仓并同步到首页
  Future<int> insertFundTransaction(FundTransaction ft) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    int? syncedTxnId;

    await db.transaction((txn) async {
      // 1. 处理持仓更新
      final holding = await _getHoldingForUpdate(txn, ft.fundId);
      if (holding == null) throw Exception('基金不存在');

      double newCostPerShare = holding.costPerShare ?? 0;

      // 获取或创建指定名称、类型的分类
      Future<int> _categoryId(String name, String type, {String icon = 'category'}) async {
        final cats = await txn.query(
          'categories',
          where: "type = ? AND name = ? AND is_deleted = 0",
          whereArgs: [type, name],
          limit: 1,
        );
        if (cats.isNotEmpty) return cats.first['id'] as int;
        return await txn.insert('categories', {
          'parent_id': 0,
          'name': name,
          'type': type,
          'icon_name': icon,
          'sort_order': 90,
          'is_default': 0,
          'is_deleted': 0,
          'created_at': now,
          'updated_at': now,
        });
      }

      switch (ft.type) {
        case 'buy':
          final buyAmount = ft.amount ?? 0; // 净投资额 = 份额 × 净值
          final newTotalBuyAmount = holding.totalBuyAmount + buyAmount;
          final newTotalShares = holding.totalShares + (ft.shares ?? 0);
          final newHoldingShares =
              holding.holdingShares + (ft.shares ?? 0);
          newCostPerShare = newTotalShares > 0
              ? newTotalBuyAmount / newTotalShares
              : 0;
          // 用本次交易净值作为当前净值
          final newNav = ft.nav ?? holding.currentNav ?? 0;
          final newCostAmount = newHoldingShares * newCostPerShare;
          final newHoldingAmount = newHoldingShares * newNav;
          await txn.update(
            'fund_holdings',
            {
              'total_buy_amount': newTotalBuyAmount,
              'total_fee': holding.totalFee + ft.fee,
              'total_shares': newTotalShares,
              'holding_shares': newHoldingShares,
              'cost_per_share': newCostPerShare,
              'current_nav': newNav,
              'cost_amount': newCostAmount,
              'holding_amount': newHoldingAmount,
              'profit': newHoldingAmount - newCostAmount,
              'profit_rate':
                  newCostAmount > 0 ? (newHoldingAmount - newCostAmount) / newCostAmount : 0,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [ft.fundId],
          );
          // 同步到首页：transfer（投资金额）+ expense（手续费）
          syncedTxnId = await txn.insert('transactions', {
            'type': 'transfer',
            'amount': buyAmount,
            'category_id': await _categoryId('投资', 'transfer', icon: 'trending_up'),
            'date': ft.date,
            'note': '买入 ${holding.fundName}',
            'is_deleted': 0,
            'created_at': now,
            'updated_at': now,
          });
          if (ft.fee > 0) {
            await txn.insert('transactions', {
              'type': 'expense',
              'amount': ft.fee,
              'category_id': await _categoryId('手续费', 'expense', icon: 'receipt'),
              'date': ft.date,
              'note': '买入 ${holding.fundName} 手续费',
              'is_deleted': 0,
              'created_at': now,
              'updated_at': now,
            });
          }
          break;

        case 'sell':
          final sellShares = ft.shares ?? 0;
          final newHoldingShares = holding.holdingShares - sellShares;
          final grossAmount = sellShares * (ft.nav ?? 0); // 净值卖出总额
          final costBasis = sellShares * newCostPerShare;
          final newTotalBuyAmount =
              holding.totalBuyAmount - costBasis;
          final newTotalShares = holding.totalShares - sellShares;
          // 用本次交易净值作为当前净值
          final newNav = ft.nav ?? holding.currentNav ?? 0;
          final newCostAmount = newHoldingShares * newCostPerShare;
          final newHoldingAmount = newHoldingShares * newNav;
          await txn.update(
            'fund_holdings',
            {
              'total_buy_amount': newTotalBuyAmount,
              'total_shares': newTotalShares,
              'holding_shares': newHoldingShares,
              'current_nav': newNav,
              'cost_amount': newCostAmount,
              'holding_amount': newHoldingAmount,
              'profit': newHoldingAmount - newCostAmount,
              'profit_rate':
                  newCostAmount > 0 ? (newHoldingAmount - newCostAmount) / newCostAmount : 0,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [ft.fundId],
          );
          // 同步到首页：transfer（卖出所得）+ expense（手续费）
          syncedTxnId = await txn.insert('transactions', {
            'type': 'transfer',
            'amount': grossAmount,
            'category_id': await _categoryId('赎回', 'transfer', icon: 'swap_horiz'),
            'date': ft.date,
            'note': '卖出 ${holding.fundName}',
            'is_deleted': 0,
            'created_at': now,
            'updated_at': now,
          });
          if (ft.fee > 0) {
            await txn.insert('transactions', {
              'type': 'expense',
              'amount': ft.fee,
              'category_id': await _categoryId('手续费', 'expense', icon: 'receipt'),
              'date': ft.date,
              'note': '卖出 ${holding.fundName} 手续费',
              'is_deleted': 0,
              'created_at': now,
              'updated_at': now,
            });
          }
          break;

        case 'dividend':
          // 分红不改变持仓，只记录
          // 同步到首页：income，分类=投资收益
          final incomeCategory = await txn.query(
            'categories',
            where: "type = 'income' AND name = '投资收益' AND is_deleted = 0",
            limit: 1,
          );

          int categoryId;
          if (incomeCategory.isNotEmpty) {
            categoryId = incomeCategory.first['id'] as int;
          } else {
            // 新建"投资收益"分类
            categoryId = await txn.insert('categories', {
              'parent_id': 0,
              'name': '投资收益',
              'type': 'income',
              'icon_name': 'trending_up',
              'sort_order': 100,
              'is_default': 0,
              'is_deleted': 0,
              'created_at': now,
              'updated_at': now,
            });
          }

          syncedTxnId = await txn.insert('transactions', {
            'type': 'income',
            'amount': ft.dividendAmount ?? ft.amount,
            'category_id': categoryId,
            'date': ft.date,
            'note': '${holding.fundName} 分红${ft.note != null ? "（${ft.note}）" : ""}',
            'is_deleted': 0,
            'created_at': now,
            'updated_at': now,
          });
          break;
      }

      // 2. 插入基金交易记录（带上 synced_transaction_id）
      final ftMap = ft.toMap();
      ftMap['synced_transaction_id'] = syncedTxnId ?? 0;
      ftMap['created_at'] = now;
      await txn.insert('fund_transactions', ftMap);
    });

    return syncedTxnId ?? 0;
  }

  /// 删除基金交易记录，反向更新持仓并删除首页同步记录
  Future<void> deleteFundTransaction(int id) async {
    final db = await database;

    await db.transaction((txn) async {
      // 查找交易记录
      final maps = await txn.query(
        'fund_transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return;
      final ft = FundTransaction.fromMap(maps.first);

      // 反向更新持仓（先获取，后面还要用 fundName）
      final holding = await _getHoldingForUpdate(txn, ft.fundId);
      if (holding == null) return;
      final fundName = holding.fundName;

      // 删除首页同步记录（transfer）
      if (ft.syncedTransactionId > 0) {
        await txn.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [ft.syncedTransactionId],
        );
      }
      // 同时删除可能的手续费 expense 记录（按日期+备注匹配）
      if (ft.fee > 0 && ft.type != 'dividend') {
        final typeLabel = ft.type == 'buy' ? '买入' : '卖出';
        await txn.delete(
          'transactions',
          where: "type = 'expense' AND date = ? AND note = ?",
          whereArgs: [ft.date, '$typeLabel $fundName 手续费'],
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      double newCostPerShare = holding.costPerShare ?? 0;

      switch (ft.type) {
        case 'buy':
          final buyAmount = ft.amount ?? 0; // 净投资额（不含手续费）
          final newTotalBuyAmount = holding.totalBuyAmount - buyAmount;
          final newTotalShares = holding.totalShares - (ft.shares ?? 0);
          final newHoldingShares =
              holding.holdingShares - (ft.shares ?? 0);
          newCostPerShare = newTotalShares > 0
              ? newTotalBuyAmount / newTotalShares
              : 0;
          final newCostAmount = newHoldingShares * newCostPerShare;
          final newHoldingAmount =
              newHoldingShares * (holding.currentNav ?? 0);
          await txn.update(
            'fund_holdings',
            {
              'total_buy_amount': newTotalBuyAmount,
              'total_fee': holding.totalFee - ft.fee,
              'total_shares': newTotalShares,
              'holding_shares': newHoldingShares,
              'cost_per_share': newCostPerShare,
              'cost_amount': newCostAmount,
              'holding_amount': newHoldingAmount,
              'profit': newHoldingAmount - newCostAmount,
              'profit_rate':
                  newCostAmount > 0 ? (newHoldingAmount - newCostAmount) / newCostAmount : 0,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [ft.fundId],
          );
          break;

        case 'sell':
          final sellShares = ft.shares ?? 0;
          final newHoldingShares = holding.holdingShares + sellShares;
          final costBasis = sellShares * newCostPerShare;
          final newTotalBuyAmount =
              holding.totalBuyAmount + costBasis;
          final newTotalShares = holding.totalShares + sellShares;
          final newCostAmount = newHoldingShares * newCostPerShare;
          final newHoldingAmount =
              newHoldingShares * (holding.currentNav ?? 0);
          await txn.update(
            'fund_holdings',
            {
              'total_buy_amount': newTotalBuyAmount,
              'total_shares': newTotalShares,
              'holding_shares': newHoldingShares,
              'cost_amount': newCostAmount,
              'holding_amount': newHoldingAmount,
              'profit': newHoldingAmount - newCostAmount,
              'profit_rate':
                  newCostAmount > 0 ? (newHoldingAmount - newCostAmount) / newCostAmount : 0,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [ft.fundId],
          );
          break;

        case 'dividend':
          // 分红只删除同步记录（已在上面处理），不需反向更新持仓
          break;
      }

      // 删除基金交易记录
      await txn.delete(
        'fund_transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// 在事务中获取持仓（用于更新）
  Future<FundHolding?> _getHoldingForUpdate(dynamic txn, int fundId) async {
    final maps = await txn.query(
      'fund_holdings',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [fundId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FundHolding.fromMap(maps.first);
  }

  /// 获取投资总览
  Future<Map<String, double>> getInvestmentSummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(holding_amount), 0) as total_value,
        COALESCE(SUM(cost_amount), 0) as total_cost,
        COALESCE(SUM(profit), 0) as total_profit
      FROM fund_holdings
      WHERE is_deleted = 0 AND holding_shares > 0
    ''');
    final row = result.first;
    final totalCost = (row['total_cost'] as num).toDouble();
    final totalProfit = (row['total_profit'] as num).toDouble();
    return {
      'total_value': (row['total_value'] as num).toDouble(),
      'total_cost': totalCost,
      'total_profit': totalProfit,
      'profit_rate': totalCost > 0 ? totalProfit / totalCost : 0,
    };
  }

  /// 更新基金净值
  Future<void> updateFundNav(int fundId, double nav) async {
    final db = await database;
    final holding = await getFundHoldingById(fundId);
    if (holding == null) return;

    final holdingAmount = holding.holdingShares * nav;
    final costAmount = holding.holdingShares * (holding.costPerShare ?? 0);
    final profit = holdingAmount - costAmount;
    final profitRate = costAmount > 0 ? profit / costAmount : 0;

    await db.update(
      'fund_holdings',
      {
        'current_nav': nav,
        'holding_amount': holdingAmount,
        'profit': profit,
        'profit_rate': profitRate,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [fundId],
    );
  }

  // ==================== Category Detail Query ====================

  /// 按分类 ID 列表查询指定月份的交易记录
  Future<List<Transaction>> getTransactionsByCategoryIds({
    required String type,
    required int startDate,
    required int endDate,
    required List<int> categoryIds,
  }) async {
    if (categoryIds.isEmpty) return [];
    final db = await database;
    final placeholders = categoryIds.map((_) => '?').join(',');
    final maps = await db.query(
      'transactions',
      where:
          'type = ? AND date >= ? AND date <= ? AND is_deleted = 0 AND category_id IN ($placeholders)',
      whereArgs: [type, startDate, endDate, ...categoryIds],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  // ==================== Import / Export Helpers ====================

  /// 获取所有交易记录（不分页，用于导出）
  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'is_deleted = 0',
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// 批量插入交易记录（用于导入），返回成功条数
  Future<int> batchInsertTransactions(List<Transaction> transactions) async {
    final db = await database;
    var count = 0;
    await db.transaction((txn) async {
      for (final t in transactions) {
        await txn.insert('transactions', t.toMap());
        count++;
      }
    });
    return count;
  }

  /// 获取所有分类（含已删除，用于导出完整分类表）
  Future<List<Category>> getAllCategoriesWithDeleted() async {
    final db = await database;
    final maps = await db.query(
      'categories',
      orderBy: 'type ASC, sort_order ASC, id ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  // ==================== Sort Order ====================

  Future<void> updateCategorySortOrder(List<Category> categories) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var i = 0; i < categories.length; i++) {
        await txn.update(
          'categories',
          {'sort_order': i, 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [categories[i].id],
        );
      }
    });
  }

  // ==================== Close ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
