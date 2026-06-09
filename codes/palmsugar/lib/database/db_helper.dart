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
      version: 1,
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

    // 插入预设数据
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 后续版本升级逻辑
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
