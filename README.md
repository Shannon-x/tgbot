# Policr Mini - 智能 Telegram 群组验证机器人

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Language](https://img.shields.io/badge/language-Elixir-purple)
![Platform](https://img.shields.io/badge/platform-Telegram-blue)

## 🚀 项目简介

Policr Mini 是一个高性能的 Telegram 群组管理机器人，专注于新成员验证和反垃圾功能。通过智能验证系统和行为分析，有效防止垃圾账号和恶意用户的骚扰。

### 🌟 核心功能

#### 智能验证系统
- **多样化验证方式**：图片选择、算术题、自定义问答
- **灵活接入模式**：支持直接加群和加群请求两种方式
- **智能容错机制**：自动重试和权限修复
- **多语言支持**：根据用户语言自动适配

#### 反垃圾防护
- **行为模式识别**：实时监测刷屏和重复消息
- **智能处理策略**：可配置禁言、踢出或封禁
- **时间窗口分析**：基于消息频率的动态检测
- **自动清理机制**：定期清理历史记录

#### 群组管理工具
- **快捷管理命令**：`/ban`、`/mute`、`/unmute`、`/kick`
- **灵活时长设置**：支持分钟(m)、小时(h)、天(d)为单位
- **批量操作支持**：可通过回复或指定用户ID/用户名
- **权限安全控制**：仅管理员可执行管理操作

#### 个性化配置
- **欢迎消息定制**：支持富文本、内联按钮、图片附件
- **变量动态替换**：用户名、ID、提及等信息自动填充
- **自动删除设置**：可配置欢迎消息的显示时长
- **Web 管理后台**：直观的图形化配置界面

## 💡 应用场景

- **社区群组**：防止广告和垃圾信息骚扰
- **技术交流群**：确保成员质量，维护讨论氛围
- **商业群组**：保护客户隐私，防止竞争对手潜入
- **教育群组**：验证学生身份，维护学习环境

## 🛠️ 技术架构

- **编程语言**：Elixir (基于 Erlang/OTP)
- **Web 框架**：Phoenix Framework
- **数据库**：PostgreSQL
- **缓存**：Redis (可选)
- **容器化**：Docker & Docker Compose
- **API 库**：Telegex (Telegram Bot API)

## 📦 快速部署

### 使用 Docker（推荐）

1. **克隆项目**
```bash
git clone https://github.com/your-username/policr-mini.git
cd policr-mini
```

2. **配置环境变量**
```bash
cp prod.env.example prod.env
# 编辑 prod.env 文件，填入必要的配置
```

3. **启动服务**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

4. **访问管理后台**
```
http://your-server:4000
```

### 手动部署

详细的手动部署步骤请参考 [DEPLOYMENT.md](DEPLOYMENT.md)

## ⚙️ 配置说明

### 必需配置

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `TG_BOT_TOKEN` | Bot Token | 从 @BotFather 获取 |
| `TG_OWNER_ID` | 管理员 ID | 您的 Telegram 用户 ID |
| `DB_HOST` | 数据库地址 | `localhost` 或 `postgres` |
| `DB_PASS` | 数据库密码 | 安全的密码 |

### 可选配置

- **性能优化**：连接池大小、消息速率限制
- **功能开关**：反垃圾、欢迎消息等模块
- **第三方服务**：错误追踪、云存储等

## 📊 API 接口

### 认证方式

所有 API 请求需要包含认证令牌：

```http
Authorization: Bearer YOUR_TOKEN
```

### 核心接口

| 方法 | 端点 | 描述 |
|------|------|------|
| GET | `/admin/api/chats` | 获取群组列表 |
| GET/PUT | `/admin/api/chats/:id/scheme` | 群组方案配置 |
| GET/PUT | `/admin/api/chats/:id/anti_spam_config` | 反垃圾配置 |
| GET/PUT | `/admin/api/chats/:id/welcome_message` | 欢迎消息配置 |

## 🔧 开发指南

### 环境准备

```bash
# 安装 Elixir 和 Erlang
asdf install

# 安装项目依赖
mix deps.get

# 创建并迁移数据库
mix ecto.setup

# 安装前端依赖
cd assets && npm install
```

### 启动开发服务器

```bash
mix phx.server
```

访问 `http://localhost:4000` 查看应用

### 运行测试

```bash
mix test
```

## 🚀 功能路线图

- [ ] 多语言界面支持
- [ ] 高级统计分析功能
- [ ] 自定义插件系统
- [ ] 集群部署支持
- [ ] AI 驱动的智能识别

## 📄 开源协议

本项目基于 [MIT License](LICENSE) 开源

## 🤝 参与贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建您的特性分支
3. 提交您的更改
4. 推送到分支
5. 创建 Pull Request

## 🎉 致谢

- 基于 [Telegex](https://github.com/telegex/telegex) 构建
- 使用 [Phoenix Framework](https://www.phoenixframework.org/)
- 感谢所有贡献者的支持

---

<p align="center">Made with ❤️ by the Policr Mini Team</p>