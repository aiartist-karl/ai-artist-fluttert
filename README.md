# AI Artist - Flutter Cross-Platform

AI Artist 是一款跨平台 AI 助手应用，支持多模型对话、AI 生图、ComfyUI 集成、智能体管理等功能。

## 技术栈
- **框架**: Flutter 3.27+
- **状态管理**: Provider
- **网络**: Dio + HTTP
- **本地存储**: sqflite + shared_preferences
- **AI 服务**: 多提供商 (Ollama, OpenAI Compatible, Anthropic)

## 构建

### Android APK
```bash
flutter build apk --debug    # 调试版
flutter build apk --release  # 发布版
```

### iOS (需要 macOS + Xcode)
```bash
cd ios && pod install && cd ..
flutter build ios --release
```

### GitHub Actions 自动构建
推送到 main 分支自动构建：
- Android debug APK → Artifacts
- 打 tag (v*) 自动创建 Release

## 项目结构
```
lib/
├── main.dart              # 入口
├── models/                # 数据模型
├── providers/             # 状态管理
├── screens/               # 页面
├── services/              # 业务服务
├── utils/                 # 工具类
└── widgets/               # 自定义组件
```

## 功能
- 多 AI 模型对话 (Ollama/OpenAI/Anthropic)
- AI 生图 (ComfyUI/Pollinations)
- 智能体 (Agent) 管理与切换
- 知识库管理
- 记忆系统
- Function Calling
- 积分系统
- 语音输入/输出
- 图片分享
- 历史记录
