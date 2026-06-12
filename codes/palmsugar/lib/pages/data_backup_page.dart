import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:csv/csv.dart';
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

  Future<void> _showExportDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return _ExportDialog(
          onConfirm: (content, range, start, end) {
            Navigator.pop(ctx, {
              'content': content,
              'range': range,
              'start': start,
              'end': end,
            });
          },
        );
      },
    );

    if (result == null) return;

    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择导出格式'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'csv'),
            child: const Text('CSV'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'xlsx'),
            child: const Text('Excel (.xlsx)'),
          ),
        ],
      ),
    );

    if (format == null) return;

    final content = result['content'] as String;
    final range = result['range'] as String;
    DateTime? startDate = result['start'] as DateTime?;
    DateTime? endDate = result['end'] as DateTime?;

    // 计算时间范围
    final now = DateTime.now();
    if (range == 'last1') {
      startDate = DateTime(now.year, now.month - 1, now.day);
      endDate = now;
    } else if (range == 'last3') {
      startDate = DateTime(now.year, now.month - 3, now.day);
      endDate = now;
    }
    // custom: already set by dialog

    if (format == 'xlsx') {
      await _exportToXlsx(content, startDate, endDate);
    } else {
      await _exportToCsv(content, startDate, endDate);
    }
  }

  /// 判断记录的日期是否在范围内
  bool _inRange(int dateMs, DateTime? start, DateTime? end) {
    if (start == null && end == null) return true;
    final d = DateTime.fromMillisecondsSinceEpoch(dateMs);
    if (start != null && d.isBefore(DateTime(start.year, start.month, start.day))) {
      return false;
    }
    if (end != null && d.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59))) {
      return false;
    }
    return true;
  }

  Future<void> _exportToXlsx(
      String content, DateTime? startDate, DateTime? endDate) async {
    setState(() => _isExporting = true);

    try {
      final excel = Excel.createExcel();
      final includeTx = content == 'all' || content == 'transactions';
      final includeInv = content == 'all' || content == 'investment';

      // ---- Sheet 1: 收支记录 ----
      if (includeTx) {
        excel.rename('Sheet1', '收支记录');
        final sheetTx = excel['收支记录'];
        sheetTx.appendRow([
          TextCellValue('日期'),
          TextCellValue('类型'),
          TextCellValue('分类'),
          TextCellValue('金额'),
          TextCellValue('备注'),
        ]);

        final transactions = await _db.getAllTransactions();
        for (final t in transactions) {
          if (!_inRange(t.date, startDate, endDate)) continue;
          final category = await _db.getCategoryById(t.categoryId);
          final dateStr =
              DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(t.date));
          sheetTx.appendRow([
            TextCellValue(dateStr),
            TextCellValue(_typeLabel(t.type)),
            TextCellValue(category?.name ?? ''),
            DoubleCellValue(t.amount),
            TextCellValue(t.note ?? ''),
          ]);
        }
      } else {
        excel.rename('Sheet1', '收支记录');
      }

      // ---- Sheet 2: 理财记录 ----
      if (includeInv) {
        final sheetInv = excel['理财记录'];
        sheetInv.appendRow([
          TextCellValue('日期'),
          TextCellValue('类型'),
          TextCellValue('基金名称'),
          TextCellValue('基金代码'),
          TextCellValue('金额'),
          TextCellValue('手续费'),
          TextCellValue('净值'),
          TextCellValue('份额'),
          TextCellValue('备注'),
        ]);

        final holdings = await _db.getFundHoldings();
        final fundInfo = <int, Map<String, String>>{};
        for (final h in holdings) {
          if (h.id != null) {
            fundInfo[h.id!] = {
              'name': h.fundName,
              'code': h.fundCode ?? '',
            };
          }
        }

        final transactions = await _db.getFundTransactions();
        for (final ft in transactions) {
          if (!_inRange(ft.date, startDate, endDate)) continue;
          final dateStr =
              DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(ft.date));
          final info = fundInfo[ft.fundId];
          sheetInv.appendRow([
            TextCellValue(dateStr),
            TextCellValue(_fundTypeLabel(ft.type)),
            TextCellValue(info?['name'] ?? '未知基金'),
            TextCellValue(info?['code'] ?? ''),
            DoubleCellValue(ft.amount ?? 0),
            DoubleCellValue(ft.fee),
            ft.nav != null ? DoubleCellValue(ft.nav!) : TextCellValue(''),
            ft.shares != null ? DoubleCellValue(ft.shares!) : TextCellValue(''),
            TextCellValue(ft.note ?? ''),
          ]);
        }
      }

      // ---- Sheet 3: 分类表 ----
      {
        final sheetName = excel.sheets.keys.contains('分类表') ? '分类表' : null;
        if (sheetName == null) {
          excel['分类表'];
        }
        final sheetCat = excel['分类表'];
        sheetCat.appendRow([
          TextCellValue('名称'),
          TextCellValue('类型'),
        ]);

        final categories = await _db.getAllCategoriesWithDeleted();
        final activeCategories =
            categories.where((c) => c.isDeleted == 0).toList()
              ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

        for (final c in activeCategories) {
          sheetCat.appendRow([
            TextCellValue(c.name),
            TextCellValue(_typeLabel(c.type)),
          ]);
        }
      }

      final fileName =
          '棕榈糖账本_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('生成 Excel 失败');

      final savedPath = await _saveBytes(fileBytes, fileName);
      if (mounted) _showExportSuccess(savedPath, fileName);
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

  Future<void> _exportToCsv(
      String content, DateTime? startDate, DateTime? endDate) async {
    setState(() => _isExporting = true);

    try {
      final includeTx = content == 'all' || content == 'transactions';
      final includeInv = content == 'all' || content == 'investment';
      final allRows = <List<String>>[];

      // 收支记录section
      if (includeTx) {
        allRows.add(['--- 收支记录 ---']);
        allRows.add(['日期', '类型', '分类', '金额', '备注']);

        final transactions = await _db.getAllTransactions();
        for (final t in transactions) {
          if (!_inRange(t.date, startDate, endDate)) continue;
          final category = await _db.getCategoryById(t.categoryId);
          final dateStr = DateFormat('yyyy-MM-dd')
              .format(DateTime.fromMillisecondsSinceEpoch(t.date));

          allRows.add([
            dateStr,
            _typeLabel(t.type),
            category?.name ?? '',
            t.amount.toStringAsFixed(2),
            t.note ?? '',
          ]);
        }
      }

      // 理财记录section
      if (includeInv) {
        if (allRows.isNotEmpty) allRows.add(['']); // blank separator
        allRows.add(['--- 理财记录 ---']);
        allRows.add(['日期', '类型', '基金名称', '基金代码', '金额', '手续费', '净值', '份额', '备注']);

        final holdings = await _db.getFundHoldings();
        final fundInfo = <int, Map<String, String>>{};
        for (final h in holdings) {
          if (h.id != null) {
            fundInfo[h.id!] = {'name': h.fundName, 'code': h.fundCode ?? ''};
          }
        }

        final transactions = await _db.getFundTransactions();
        for (final ft in transactions) {
          if (!_inRange(ft.date, startDate, endDate)) continue;
          final dateStr = DateFormat('yyyy-MM-dd')
              .format(DateTime.fromMillisecondsSinceEpoch(ft.date));
          final info = fundInfo[ft.fundId];

          allRows.add([
            dateStr,
            _fundTypeLabel(ft.type),
            info?['name'] ?? '未知基金',
            info?['code'] ?? '',
            (ft.amount ?? 0).toStringAsFixed(2),
            ft.fee.toStringAsFixed(2),
            ft.nav?.toStringAsFixed(4) ?? '',
            ft.shares?.toStringAsFixed(2) ?? '',
            ft.note ?? '',
          ]);
        }
      }

      // UTF-8 BOM + CSV
      final csv = const ListToCsvConverter().convert(allRows);
      final bom = utf8.encode('﻿'); // UTF-8 BOM
      final csvBytes = utf8.encode(csv);
      final fileBytes = [...bom, ...csvBytes];

      final fileName =
          '棕榈糖账本_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final savedPath = await _saveBytes(fileBytes, fileName);

      if (mounted) _showExportSuccess(savedPath, fileName);
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

  Future<String> _saveBytes(List<int> bytes, String fileName) async {
    String? savedPath;
    try {
      final downloadDir = Directory('/sdcard/Download');
      if (await downloadDir.exists()) {
        savedPath = '${downloadDir.path}/$fileName';
        await File(savedPath).writeAsBytes(bytes);
      }
    } catch (_) {}

    if (savedPath == null) {
      final tempDir = await getTemporaryDirectory();
      savedPath = '${tempDir.path}/$fileName';
      await File(savedPath).writeAsBytes(bytes);
    }
    return savedPath;
  }

  void _showExportSuccess(String savedPath, String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('导出成功，文件已保存到：下载/$fileName'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '分享',
          onPressed: () => _shareFile(savedPath, fileName),
        ),
      ),
    );
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

  Future<void> _importData() async {
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
        setState(() => _isImporting = false);
        return;
      }

      final bytes = result.files.first.bytes!;
      final fileName = result.files.first.name.toLowerCase();

      int txCount = 0;
      int fundTxCount = 0;

      if (fileName.endsWith('.csv')) {
        final csvStr = utf8.decode(bytes);
        final allRows = const CsvToListConverter().convert(csvStr);

        // Split into sections: 收支记录 and 理财记录
        int txEnd = allRows.length;
        int invStart = -1;
        for (var i = 0; i < allRows.length; i++) {
          final firstCell = allRows[i].isNotEmpty ? allRows[i][0]?.toString() ?? '' : '';
          if (firstCell == '--- 理财记录 ---') {
            txEnd = i;
            invStart = i + 1; // skip separator, keep header for format detection
            break;
          }
        }

        final txRows = allRows.sublist(0, txEnd).where((r) {
          final c = r.isNotEmpty ? r[0]?.toString() ?? '' : '';
          return !c.startsWith('---') && c.isNotEmpty;
        }).toList();

        if (txRows.isNotEmpty) {
          final importedTx = await _parseTransactionRows(txRows);
          txCount = importedTx.length;
          if (txCount > 0) {
            txCount = await _db.batchInsertTransactions(importedTx);
          }
        }

        if (invStart > 0 && invStart < allRows.length) {
          final invRows = allRows.sublist(invStart);
          fundTxCount = await _importFundTransactionRows(invRows);
        }
      } else {
        try {
          final excel = Excel.decodeBytes(bytes);

          if (excel.sheets.keys.contains('分类表')) {
            await _importCategoriesFromExcelSheet(excel['分类表']);
          }

          // 导入收支记录
          if (excel.sheets.keys.contains('收支记录')) {
            final rows = excel['收支记录']
                .rows
                .map((r) => r.map((c) => c?.value).toList())
                .toList();
            final importedTx = await _parseTransactionRows(rows);
            txCount = importedTx.length;
            if (txCount > 0) {
              txCount = await _db.batchInsertTransactions(importedTx);
            }
          }

          // 导入理财记录
          if (excel.sheets.keys.contains('理财记录')) {
            final invRows = excel['理财记录']
                .rows
                .map((r) => r.map((c) => c?.value).toList())
                .toList();
            fundTxCount = await _importFundTransactionRows(invRows);
          }

          if (txCount == 0 && fundTxCount == 0) {
            throw Exception('未解析到有效记录，请检查文件格式');
          }
        } catch (e) {
          final msg = e.toString();
          if (msg.contains('numFmtId')) {
            throw Exception(
              '该 Excel 文件格式不兼容，可能是由 WPS 或 Numbers 生成的。'
              '建议将文件另存为 CSV 格式后再导入，或直接使用本 App 导出的 .xlsx 文件。',
            );
          }
          rethrow;
        }
      }

      if (mounted) {
        final parts = <String>[];
        if (txCount > 0) parts.add('收支 $txCount 条');
        if (fundTxCount > 0) parts.add('理财 $fundTxCount 条');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入成功：${parts.join('，')}')),
        );
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

  Future<List<models.Transaction>> _parseTransactionRows(
      List<List<dynamic>> rows) async {
    final imported = <models.Transaction>[];
    var rowIndex = 0;

    for (final row in rows) {
      rowIndex++;
      if (rowIndex == 1) continue; // skip header
      if (row.isEmpty || row[0] == null) continue;

      try {
        final firstCell = row[0]?.toString().trim() ?? '';
        // Skip section separators
        if (firstCell.startsWith('---')) continue;
        if (firstCell.isEmpty) continue;

        final dateStr = firstCell;
        final typeLabel = row.length > 1 ? (row[1]?.toString().trim() ?? '') : '';
        final categoryName = row.length > 2 ? (row[2]?.toString().trim() ?? '') : '';
        final amountStr = row.length > 3 ? (row[3]?.toString().trim() ?? '') : '';
        final note = row.length > 4 ? (row[4]?.toString().trim()) : null;

        if (dateStr.isEmpty || amountStr.isEmpty) continue;

        final date = _parseDate(dateStr);
        if (date == null) continue;

        final amount = double.tryParse(amountStr);
        if (amount == null) continue;

        final type = _parseType(typeLabel);
        if (type == null) continue;

        final categoryId = await _findOrCreateCategory(categoryName, type);

        imported.add(models.Transaction(
          type: type,
          amount: amount,
          categoryId: categoryId,
          date: date.millisecondsSinceEpoch,
          note: note?.isNotEmpty == true ? note : null,
        ));
      } catch (_) {
        continue;
      }
    }
    return imported;
  }

  /// 导入理财交易记录行
  Future<int> _importFundTransactionRows(List<List<dynamic>> rows) async {
    // 先获取或创建基金的缓存
    final allHoldings = await _db.getFundHoldings();
    final fundMap = <String, int>{}; // fundName -> fundId
    for (final h in allHoldings) {
      if (h.id != null) fundMap[h.fundName] = h.id!;
    }

    // 从表头检测格式：有"基金代码"列→新格式
    bool isNewFormat = false;
    if (rows.isNotEmpty) {
      final headerCells = rows.first.map((c) => c?.toString().trim() ?? '').toList();
      isNewFormat = headerCells.any((c) => c == '基金代码');
    }

    var count = 0;
    var rowIndex = 0;
    for (final row in rows) {
      rowIndex++;
      if (rowIndex == 1) continue; // skip header
      if (row.isEmpty || row[0] == null) continue;

      try {
        final firstCell = row[0]?.toString().trim() ?? '';
        if (firstCell.startsWith('---') || firstCell.isEmpty) continue;

        final dateStr = firstCell;
        final typeLabel = row.length > 1 ? (row[1]?.toString().trim() ?? '') : '';
        final fundName = row.length > 2 ? (row[2]?.toString().trim() ?? '') : '';

        var fundCode = isNewFormat
            ? (row.length > 3 ? (row[3]?.toString().trim() ?? '') : '')
            : '';
        // Excel 可能把基金代码当数字存，补齐前导0
        if (fundCode.isNotEmpty && fundCode.length < 6) {
          fundCode = fundCode.padLeft(6, '0');
        }
        final amountStr = isNewFormat
            ? (row.length > 4 ? (row[4]?.toString().trim() ?? '') : '')
            : (row.length > 3 ? (row[3]?.toString().trim() ?? '') : '');
        final offset = isNewFormat ? 1 : 0;
        final feeStr = row.length > 4 + offset ? (row[4 + offset]?.toString().trim() ?? '') : '';
        final navStr = row.length > 5 + offset ? (row[5 + offset]?.toString().trim() ?? '') : '';
        final sharesStr = row.length > 6 + offset ? (row[6 + offset]?.toString().trim() ?? '') : '';
        final note = row.length > 7 + offset ? (row[7 + offset]?.toString().trim()) : null;

        if (dateStr.isEmpty || fundName.isEmpty) continue;

        final date = _parseDate(dateStr);
        if (date == null) continue;

        final type = _parseFundType(typeLabel);
        if (type == null) continue;

        // 查找或创建基金
        int fundId;
        if (fundMap.containsKey(fundName)) {
          fundId = fundMap[fundName]!;
        } else {
          fundId = await _db.insertFundHolding(models.FundHolding(
            fundName: fundName,
            fundCode: fundCode.isNotEmpty ? fundCode : null,
          ));
          fundMap[fundName] = fundId;
        }

        final fee = double.tryParse(feeStr) ?? 0;
        final nav = double.tryParse(navStr);
        final shares = double.tryParse(sharesStr);

        var amount = double.tryParse(amountStr);
        // amount 为空时自动计算：份额 × 净值
        if ((amount == null || amount == 0) && nav != null && shares != null && shares > 0) {
          amount = shares * nav;
        }
        // 分红且 amount 为空则跳过
        if (type != 'dividend' && (amount == null || amount <= 0)) continue;
        if (type == 'dividend' && (amount == null || amount <= 0)) continue;

        final ft = models.FundTransaction(
          fundId: fundId,
          type: type,
          date: date.millisecondsSinceEpoch,
          amount: amount,
          fee: fee,
          nav: nav,
          shares: shares,
          dividendAmount: type == 'dividend' ? amount : null,
          note: note?.isNotEmpty == true ? note : null,
        );

        await _db.insertFundTransaction(ft);
        count++;
      } catch (_) {
        continue;
      }
    }
    return count;
  }

  Future<void> _importCategoriesFromExcelSheet(Sheet sheet) async {
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

        final existing = allCategories.firstWhere(
          (c) => c.name == name && c.type == type,
          orElse: () => models.Category(id: -1, name: '', type: ''),
        );

        if (existing.id == null || existing.id! <= 0) {
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
      case 'expense': return '支出';
      case 'income': return '收入';
      case 'transfer': return '转账';
      default: return type;
    }
  }

  String _fundTypeLabel(String type) {
    switch (type) {
      case 'buy': return '买入';
      case 'sell': return '卖出';
      case 'dividend': return '分红';
      default: return type;
    }
  }

  String? _parseFundType(String label) {
    switch (label.trim()) {
      case '买入': return 'buy';
      case '卖出': return 'sell';
      case '分红': return 'dividend';
      default: return null;
    }
  }

  String? _parseType(String label) {
    switch (label.trim()) {
      case '支出': return 'expense';
      case '收入': return 'income';
      case '转账': return 'transfer';
      default: return null;
    }
  }

  DateTime? _parseDate(String str) {
    str = str.trim();
    try { return DateFormat('yyyy-MM-dd').parseLoose(str); } catch (_) {}
    try { return DateTime.parse(str); } catch (_) {}
    return null;
  }

  String _cellToString(Data? cell) {
    if (cell == null) return '';
    final value = cell.value;
    if (value == null) return '';
    return value.toString();
  }

  Future<int> _findOrCreateCategory(String name, String type) async {
    if (name.isEmpty) name = '未分类';
    final allCategories = await _db.getAllCategoriesWithDeleted();
    for (final c in allCategories) {
      if (c.name == name && c.type == type) return c.id!;
    }
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
      appBar: AppBar(title: const Text('数据备份')),
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
                      Icon(Icons.upload_file,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text('导出数据',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '导出收支记录、理财记录和分类表。支持选择内容、时间范围和文件格式。',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isExporting ? null : _showExportDialog,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
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
                      Icon(Icons.file_download_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text('导入数据',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择 Excel 或 CSV 文件导入。系统自动识别文件中有数据的部分进行导入。',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isImporting ? null : _importData,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
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
          Text('文件格式说明', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            '• Excel 导出包含「收支记录」「理财记录」「分类表」三个 Sheet\n'
            '• CSV 导出包含收支和理财记录（UTF-8 编码）\n'
            '• 支持选择导出内容（全部 / 收支 / 理财）\n'
            '• 支持选择时间范围（近1月 / 近3月 / 自定义）\n'
            '• 导入支持 .xlsx 和 .csv 格式',
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ==================== 导出选项对话框 ====================

class _ExportDialog extends StatefulWidget {
  final void Function(String content, String range, DateTime? start, DateTime? end)
      onConfirm;

  const _ExportDialog({required this.onConfirm});

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  String _content = 'all';
  String _range = 'last3';
  DateTime? _customStart;
  DateTime? _customEnd;

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStart = picked;
        } else {
          _customEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出选项'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 导出内容
            const Text('导出内容', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('全部')),
                ButtonSegment(value: 'transactions', label: Text('收支')),
                ButtonSegment(value: 'investment', label: Text('理财')),
              ],
              selected: {_content},
              onSelectionChanged: (v) => setState(() => _content = v.first),
            ),
            const SizedBox(height: 20),
            // 时间范围
            const Text('时间范围', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'last1', label: Text('近1月')),
                ButtonSegment(value: 'last3', label: Text('近3月')),
                ButtonSegment(value: 'custom', label: Text('自定义')),
              ],
              selected: {_range},
              onSelectionChanged: (v) => setState(() => _range = v.first),
            ),
            // 自定义日期
            if (_range == 'custom') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _customStart != null
                              ? DateFormat('MM-dd').format(_customStart!)
                              : '开始日期',
                          style: TextStyle(
                            color: _customStart != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('至'),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _customEnd != null
                              ? DateFormat('MM-dd').format(_customEnd!)
                              : '结束日期',
                          style: TextStyle(
                            color: _customEnd != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
            if (_range == 'custom' && (_customStart == null || _customEnd == null)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请选择自定义日期范围')),
              );
              return;
            }
            widget.onConfirm(_content, _range, _customStart, _customEnd);
          },
          child: const Text('下一步'),
        ),
      ],
    );
  }
}
