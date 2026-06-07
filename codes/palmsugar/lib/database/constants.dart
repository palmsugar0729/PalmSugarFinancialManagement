// 预设数据：分类和答案之书题库

import 'models.dart';

/// 预设收支分类
final List<Category> defaultCategories = [
  // 支出分类
  Category(name: '餐饮', type: 'expense', iconName: 'restaurant', sortOrder: 1, isDefault: 1),
  Category(name: '交通', type: 'expense', iconName: 'directions_car', sortOrder: 2, isDefault: 1),
  Category(name: '购物', type: 'expense', iconName: 'shopping_bag', sortOrder: 3, isDefault: 1),
  Category(name: '居住', type: 'expense', iconName: 'home', sortOrder: 4, isDefault: 1),
  Category(name: '娱乐', type: 'expense', iconName: 'movie', sortOrder: 5, isDefault: 1),
  Category(name: '医疗', type: 'expense', iconName: 'local_hospital', sortOrder: 6, isDefault: 1),
  Category(name: '教育', type: 'expense', iconName: 'school', sortOrder: 7, isDefault: 1),
  Category(name: '通讯', type: 'expense', iconName: 'phone_android', sortOrder: 8, isDefault: 1),
  Category(name: '人情', type: 'expense', iconName: 'card_giftcard', sortOrder: 9, isDefault: 1),
  Category(name: '其他', type: 'expense', iconName: 'more_horiz', sortOrder: 10, isDefault: 1),

  // 收入分类
  Category(name: '工资', type: 'income', iconName: 'account_balance_wallet', sortOrder: 1, isDefault: 1),
  Category(name: '奖金', type: 'income', iconName: 'emoji_events', sortOrder: 2, isDefault: 1),
  Category(name: '投资收益', type: 'income', iconName: 'trending_up', sortOrder: 3, isDefault: 1),
  Category(name: '兼职', type: 'income', iconName: 'work', sortOrder: 4, isDefault: 1),
  Category(name: '红包', type: 'income', iconName: 'redeem', sortOrder: 5, isDefault: 1),
  Category(name: '退款', type: 'income', iconName: 'undo', sortOrder: 6, isDefault: 1),
  Category(name: '其他收入', type: 'income', iconName: 'more_horiz', sortOrder: 7, isDefault: 1),

  // 转账分类
  Category(name: '转账', type: 'transfer', iconName: 'swap_horiz', sortOrder: 1, isDefault: 1),
];

/// 答案之书预设题库
final List<Answer> defaultAnswers = [
  // 鼓励类
  Answer(content: '相信自己，你正在正确的道路上。', category: '鼓励'),
  Answer(content: '每一个小进步都值得庆祝。', category: '鼓励'),
  Answer(content: '坚持记账，你会发现自己的改变。', category: '鼓励'),
  Answer(content: '今天的努力是明天的自由。', category: '鼓励'),
  Answer(content: '你已经比昨天更了解自己了。', category: '鼓励'),

  // 建议类
  Answer(content: '现在可能是开始储蓄的好时机。', category: '建议'),
  Answer(content: '检查一下你的月度预算吧。', category: '建议'),
  Answer(content: '尝试减少不必要的开支，从小处开始。', category: '建议'),
  Answer(content: '给自己设定一个小目标，然后实现它。', category: '建议'),
  Answer(content: '记得定期回顾你的财务状况。', category: '建议'),

  // 提醒类
  Answer(content: '别忘了记录今天的开销。', category: '提醒'),
  Answer(content: '理性消费，快乐生活。', category: '提醒'),
  Answer(content: '量入为出，量力而行。', category: '提醒'),
  Answer(content: '财富积累需要耐心和纪律。', category: '提醒'),
  Answer(content: '记账不只是记录数字，更是记录生活。', category: '提醒'),

  // 趣味类
  Answer(content: '答案是：会。', category: '趣味'),
  Answer(content: '答案是：不会。', category: '趣味'),
  Answer(content: '也许吧，看你怎么选择。', category: '趣味'),
  Answer(content: '时机未到，再等等看。', category: '趣味'),
  Answer(content: '这个问题的答案在你心里。', category: '趣味'),
];
