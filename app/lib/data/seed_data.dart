import '../models/category.dart';
import '../models/platform.dart';

/// 出厂预置数据：11 个分类 + 38 个平台（均可在 App 内自定义增删改）。
class SeedData {
  /// 分类 id 用稳定字符串，方便平台引用。
  static List<Category> categories() {
    final defs = <List<dynamic>>[
      ['cat_shop', '🛒 电商购物 & 生活', '🛒', 0xFFFF8A65],
      ['cat_music', '🎵 音乐音频', '🎵', 0xFF4DD0E1],
      ['cat_video', '🎬 视频影视', '🎬', 0xFFBA68C8],
      ['cat_ai', '🤖 AI 助手 & 大模型', '🤖', 0xFF7C9CFF],
      ['cat_create', '🎨 AI 创作工具', '🎨', 0xFFF06292],
      ['cat_cloud', '☁️ 云存储 & 网盘', '☁️', 0xFF4FC3F7],
      ['cat_learn', '📚 学习 & 知识', '📚', 0xFF81C784],
      ['cat_travel', '🚗 出行 & 汽车', '🚗', 0xFFFFD54F],
      ['cat_home', '🏠 智能家居 & 运营商', '🏠', 0xFFA1887F],
      ['cat_vpn', '🔒 VPN & 网络工具', '🔒', 0xFF90A4AE],
      ['cat_social', '💬 社交', '💬', 0xFF64B5F6],
    ];
    return [
      for (var i = 0; i < defs.length; i++)
        Category(
          id: defs[i][0] as String,
          name: defs[i][1] as String,
          emoji: defs[i][2] as String,
          colorValue: defs[i][3] as int,
          sortOrder: i,
        ),
    ];
  }

  static List<Platform> platforms() {
    final defs = <List<String>>[
      // 电商购物 & 生活
      ['cat_shop', '京东', '🛒'],
      ['cat_shop', '淘宝', '🛍️'],
      ['cat_shop', '美团', '🍔'],
      ['cat_shop', '盒马', '🦛'],
      // 音乐音频
      ['cat_music', '网易云音乐', '🎵'],
      ['cat_music', 'QQ 音乐', '🎶'],
      // 视频影视
      ['cat_video', '腾讯视频', '🎬'],
      ['cat_video', 'YouTube', '▶️'],
      // AI 助手 & 大模型
      ['cat_ai', 'ChatGPT', '🤖'],
      ['cat_ai', 'Claude', '🧠'],
      ['cat_ai', 'Gemini', '♊'],
      ['cat_ai', 'Grok', '🛰️'],
      ['cat_ai', 'Kimi', '🌙'],
      ['cat_ai', 'MiniMax', '🔺'],
      ['cat_ai', '智谱 GLM', '🧩'],
      ['cat_ai', '豆包', '🫛'],
      ['cat_ai', 'DeepSeek', '🐳'],
      ['cat_ai', 'OpenRouter', '🧭'],
      ['cat_ai', '小米 MiMo', '📱'],
      ['cat_ai', 'Typeless', '⌨️'],
      // AI 创作工具
      ['cat_create', 'Suno', '🎼'],
      ['cat_create', '剪映', '✂️'],
      ['cat_create', '即梦', '💭'],
      ['cat_create', 'Seedream', '🌱'],
      ['cat_create', 'Cursor', '🖱️'],
      // 云存储 & 网盘
      ['cat_cloud', '百度网盘', '☁️'],
      ['cat_cloud', '阿里云盘', '🅰️'],
      ['cat_cloud', '夸克', '⚛️'],
      // 学习 & 知识
      ['cat_learn', '得到 App', '📖'],
      ['cat_learn', 'CSDN', '💻'],
      // 出行 & 汽车
      ['cat_travel', '特斯拉', '🚗'],
      ['cat_travel', '特来电', '🔌'],
      ['cat_travel', '滴滴出行', '🚕'],
      // 智能家居 & 运营商
      ['cat_home', '移动爱家', '🏠'],
      // VPN & 网络工具
      ['cat_vpn', 'OKZVPN', '🔒'],
      ['cat_vpn', '闪电 VPN', '⚡'],
      ['cat_vpn', '星连 VPN', '✨'],
      // 社交
      ['cat_social', 'Twitter (X)', '🐦'],
    ];
    return [
      for (var i = 0; i < defs.length; i++)
        Platform(
          id: 'plat_${i.toString().padLeft(2, '0')}',
          categoryId: defs[i][0],
          name: defs[i][1],
          emoji: defs[i][2],
        ),
    ];
  }
}
