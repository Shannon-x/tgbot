# 密钥安全指南

## 重要警告 ⚠️

**绝对不要将真实的密钥、令牌或密码提交到 Git 仓库！**

## 已泄露密钥的处理

如果您已经泄露了密钥（如 Bot Token），请立即：

1. **撤销旧密钥**
   - Telegram Bot Token: 联系 @BotFather，使用 `/revoke` 命令
   - 数据库密码: 立即更改数据库密码
   - 应用密钥: 生成新的密钥并更新配置

2. **更新配置**
   - 创建新的密钥/令牌
   - 更新本地 `.env` 文件
   - 重启应用服务

3. **清理 Git 历史**（可选）
   ```bash
   # 使用 BFG Repo-Cleaner 清理敏感数据
   bfg --delete-files .env
   bfg --replace-text passwords.txt  # 包含要替换的文本
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```

## 安全最佳实践

### 1. 使用环境变量

不要在代码中硬编码任何密钥：

```elixir
# ❌ 错误
token = "7718935459:AAELIUVpPOD8FDYwVojV7wJMZ-R6kYsi2j8"

# ✅ 正确
token = System.get_env("POLICR_MINI_BOT_TOKEN")
```

### 2. 使用 .gitignore

确保以下文件在 `.gitignore` 中：

```
.env
.env.*
!.env.example
config/*.secret.exs
```

### 3. 使用密钥管理服务

生产环境建议使用：
- AWS Secrets Manager
- HashiCorp Vault
- Azure Key Vault
- 环境变量注入（Kubernetes Secrets）

### 4. 定期轮换密钥

- 每 3-6 个月更换一次密钥
- 使用强密码生成器
- 记录密钥更新日期

### 5. 最小权限原则

- 数据库用户只授予必要权限
- Bot 只申请必要的权限
- 使用只读账户进行备份

## 生成安全密钥

### Phoenix Secret Key Base
```bash
# 方法 1: Mix
mix phx.gen.secret

# 方法 2: OpenSSL
openssl rand -hex 64

# 方法 3: Ruby
ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'
```

### 数据库密码
```bash
# 生成强密码
openssl rand -base64 32

# 或使用密码管理器生成
```

### Redis 密码
```bash
# 生成 Redis 密码
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
```

## 配置示例

正确的 `.env` 文件应该像这样：

```bash
# 数据库配置
DB_PASS=xK9$mP2&qR5*vN8@wL3#

# 应用密钥
POLICR_MINI_SERVER_SECRET_KEY_BASE=a1b2c3d4e5f6...（64个字符）

# Bot Token（从 @BotFather 获取）
POLICR_MINI_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz

# Bot 管理员 ID
POLICR_MINI_BOT_OWNER_ID=123456789
```

## 检查清单

部署前请确认：

- [ ] 所有密钥都已更改为真实值
- [ ] `.env` 文件未被提交到 Git
- [ ] 生产环境使用了不同的密钥
- [ ] 数据库密码足够强
- [ ] Bot Token 是有效的
- [ ] 应用密钥是新生成的
- [ ] 已设置文件权限 (`chmod 600 .env`)

## 相关资源

- [Telegram Bot API - Token Security](https://core.telegram.org/bots#botfather)
- [Phoenix Security Guide](https://hexdocs.pm/phoenix/security.html)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/auth-methods.html)