import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';
import '../database/models.dart' as models;

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isExporting = false;
  bool _isImporting = false;

  // ==================== 导出 ====================

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);

    try {
      final transactions = await _db.getAllTransactions();
      final categories = await _db.getAllCategoriesWithDeleted();

      final excel = Excel.createExcel();

      // 将默认 Sheet1 重命名为「收支记录」，避免产生空白 Sheet
      excel.rename('Sheet1', '收支记录');

      // ---- Sheet 1: 收支记录 ----
      final sheetTx = excel['收支记录'];
      sheetTx.appendRow([
        TextCellValue('日期'),
        TextCellValue('类型'),
        TextCellValue('分类'),
        TextCellValue('金额'),
        TextCellValue('备注'),
      ]);

      for (final t in transactions) {
        final category = await _db.getCategoryById(t.categoryId);
        final dateStr = DateFormat('yyyy-MM-dd')
            .format(DateTime.fromMillisecondsSinceEpoch(t.date));

        sheetTx.appendRow([
          TextCellValue(dateStr),
          TextCellValue(_typeLabel(t.type)),
          TextCellValue(category?.name ?? ''),
          DoubleCellValue(t.amount),
          TextCellValue(t.note ?? ''),
        ]);
      }

      // ---- Sheet 2: 分类表（仅未删除，按 ID 排序） ----
      final sheetCat = excel['分类表'];
      sheetCat.appendRow([
        TextCellValue('名称'),
        TextCellValue('类型'),
      ]);

      final activeCategories = categories
          .where((c) => c.isDeleted == 0)
          .toList()
        ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

      for (final c in activeCategories) {
        sheetCat.appendRow([
          TextCellValue(c.name),
          TextCellValue(_typeLabel(c.type)),
        ]);
      }

      // 生成文件内容
      final fileName = '棕榈糖账本_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('生成 Excel 失败');
      }

      // 保存到公共 Downloads 目录（优先）
      String? savedPath;
      try {
        final downloadDir = Directory('/sdcard/Download');
        if (await downloadDir.exists()) {
          savedPath = '${downloadDir.path}/$fileName';
          await File(savedPath).writeAsBytes(fileBytes);
        }
      } catch (_) {
        // 公共目录写入失败，回退到临时目录
      }

      // 回退到临时目录
      if (savedPath == null) {
        final tempDir = await getTemporaryDirectory();
        savedPath = '${tempDir.path}/$fileName';
        await File(savedPath).writeAsBytes(fileBytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出成功，文件已保存到：下载/$fileName'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '分享',
              onPressed: () => _shareFile(savedPath!, fileName),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _shareFile(String path, String fileName) {
    try {
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: '棕榈糖账本导出',
          text: '棕榈糖账本数据导出文件：$fileName',
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败：$e')),
      );
    }
  }

  // ==================== 导入 ====================

  Future<void> _importFromExcel() async {
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
        setState(() => _isImporting = false);
        return;
      }

      final bytes = result.files.first.bytes!;
      final excel = Excel.decodeBytes(bytes);

      // 先导入分类表（如果存在）
      if (excel.sheets.keys.contains('分类表')) {
        await _importCategoriesFromSheet(excel['分类表']);
      }

      // 导入收支记录
      if (!excel.sheets.keys.contains('收支记录')) {
        throw Exception('未找到「收支记录」Sheet，请检查文件格式');
      }
      final sheetTx = excel['收支记录'];

      final importedTransactions = <models.Transaction>[];
      var rowIndex = 0;

      for (final row in sheetTx.rows) {
        rowIndex++;
        if (rowIndex == 1) continue; // 跳过表头
        if (row.isEmpty || row[0] == null) continue;

        try {
          final dateStr = _cellToString(row[0]);
          final typeLabel = _cellToString(row[1]);
          final categoryName = _cellToString(row[2]);
          final amountStr = _cellToString(row[3]);
          final note = row.length > 4 ? _cellToString(row[4]) : null;

          if (dateStr.isEmpty || amountStr.isEmpty) continue;

          final date = _parseDate(dateStr);
          if (date == null) continue;

          final amount = double.tryParse(amountStr);
          if (amount == null) continue;

          final type = _parseType(typeLabel);
          if (type == null) continue;

          // 查找或匹配分类
          final categoryId = await _findOrCreateCategory(categoryName, type);

          importedTransactions.add(models.Transaction(
            type: type,
            amount: amount,
            categoryId: categoryId,
            date: date.millisecondsSinceEpoch,
            note: note?.isNotEmpty == true ? note : null,
          ));
        } catch (_) {
          // 单行解析失败，跳过
          continue;
        }
      }

      if (importedTransactions.isEmpty) {
        throw Exception('未解析到有效记录，请检查文件格式');
      }

      // 确认导入
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入'),
          content: Text('共解析到 ${importedTransactions.length} 条记录，是否导入？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('导入'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final count = await _db.batchInsertTransactions(importedTransactions);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 $count 条记录')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _importCategoriesFromSheet(Sheet sheet) async {
    final allCategories = await _db.getAllCategoriesWithDeleted();
    var rowIndex = 0;

    for (final row in sheet.rows) {
      rowIndex++;
      if (rowIndex == 1) continue;
      if (row.isEmpty || row[0] == null) continue;

      try {
        final name = _cellToString(row[0]);
        final typeLabel = _cellToString(row[1]);

        if (name.isEmpty) continue;

        final type = _parseType(typeLabel);
        if (type == null) continue;

        // 查找是否已存在同名同类型分类
        final existing = allCategories.firstWhere(
          (c) => c.name == name && c.type == type,
          orElse: () => models.Category(id: -1, name: '', type: ''),
        );

        if (existing.id == null || existing.id! <= 0) {
          // 创建新分类，排序自动分配
          await _db.insertCategory(models.Category(
            name: name,
            type: type,
            sortOrder: rowIndex,
          ));
        }
      } catch (_) {
        continue;
      }
    }
  }

  // ==================== 辅助方法 ====================

  String _typeLabel(String type) {
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

  String? _parseType(String label) {
    switch (label.trim()) {
      case '支出':
        return 'expense';
      case '收入':
        return 'income';
      case '转账':
        return 'transfer';
      default:
        return null;
    }
  }

  DateTime? _parseDate(String str) {
    str = str.trim();
    // 先尝试 yyyy-MM-dd
    try {
      return DateFormat('yyyy-MM-dd').parseLoose(str);
    } catch (_) {}
    // 再尝试 ISO 8601
    try {
      return DateTime.parse(str);
    } catch (_) {}
    return null;
  }

  String _cellToString(Data? cell) {
    if (cell == null) return '';
    final value = cell.value;
    if (value == null) return '';
    return value.toString();
  }

  Future<int> _findOrCreateCategory(String name, String type) async {
    if (name.isEmpty) {
      name = '未分类';
    }
    // 先按名称精确查找
    final allCategories = await _db.getAllCategoriesWithDeleted();
    for (final c in allCategories) {
      if (c.name == name && c.type == type) {
        return c.id!;
      }
    }
    // 未找到则创建新分类
    final newId = await _db.insertCategory(models.Category(
      name: name,
      type: type,
    ));
    return newId;
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 导出卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        '导出 Excel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '将收支记录和分类表导出为 Excel 文件，自动保存到「下载」文件夹。',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isExporting ? null : _exportToExcel,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(_isExporting ? '导出中...' : '导出数据'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 导入卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.file_download_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        '导入 Excel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择 Excel 文件导入收支记录。支持从本 App 导出的格式，日期格式支持 yyyy-MM-dd 或 ISO 8601。',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isImporting ? null : _importFromExcel,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.file_download_outlined),
                      label: Text(_isImporting ? '导入中...' : '导入数据'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 格式说明
          Text(
            '文件格式说明',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '• 导出文件包含「收支记录」和「分类表」两个 Sheet\n'
            '• 收支记录列：日期、类型、分类、金额、备注\n'
            '• 分类表列：名称、类型\n'
            '• 支持 .xlsx 格式文件',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
