import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class AnswerBookPage extends StatefulWidget {
  const AnswerBookPage({super.key});

  @override
  State<AnswerBookPage> createState() => _AnswerBookPageState();
}

class _AnswerBookPageState extends State<AnswerBookPage> {
  final DatabaseHelper _db = DatabaseHelper();

  String? _currentAnswer;
  String? _currentCategory;
  bool _isRevealing = false;
  bool _hasAnswer = false;

  Future<void> _askQuestion() async {
    setState(() {
      _isRevealing = true;
      _hasAnswer = false;
      _currentAnswer = null;
    });

    // 模拟一个"思考"过程
    await Future.delayed(const Duration(milliseconds: 800));

    final answer = await _db.getRandomAnswer();

    setState(() {
      _isRevealing = false;
      _hasAnswer = true;
      _currentAnswer = answer?.content ?? '暂无答案';
      _currentCategory = answer?.category;
    });
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case '鼓励':
        return Colors.orange;
      case '建议':
        return Colors.blue;
      case '提醒':
        return Colors.purple;
      case '趣味':
        return Colors.pink;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('答案之书'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 书本图标
            Icon(
              Icons.menu_book,
              size: 80,
              color: Theme.of(context).primaryColor.withAlpha(180),
            ),
            const SizedBox(height: 24),

            // 提示文字
            if (!_hasAnswer && !_isRevealing)
              const Text(
                '在心里默念你的问题，\n然后点击下方按钮获取答案',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.6,
                ),
              ),

            // 思考中动画
            if (_isRevealing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                '正在翻阅答案之书...',
                style: TextStyle(color: Colors.grey),
              ),
            ],

            // 答案卡片
            if (_hasAnswer && _currentAnswer != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCategoryColor(_currentCategory).withAlpha(40),
                      _getCategoryColor(_currentCategory).withAlpha(20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getCategoryColor(_currentCategory).withAlpha(60),
                  ),
                ),
                child: Column(
                  children: [
                    if (_currentCategory != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(_currentCategory)
                              .withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentCategory!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getCategoryColor(_currentCategory),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _currentAnswer!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // 按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRevealing ? null : _askQuestion,
                icon: _isRevealing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_hasAnswer ? '再问一个问题' : '获取答案'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
