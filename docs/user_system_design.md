# 用户系统详细设计文档

## 1. 用户系统概述

### 1.1 系统目标
- 提供完整的用户生命周期管理
- 实现安全可靠的用户认证机制
- 管理用户元数据，支持个性化展示
- 确保用户数据的安全性和隐私性

### 1.2 核心功能
- 用户注册与登录
- 用户信息管理
- 用户认证与授权
- 用户元数据管理
- 用户安全策略

## 2. 用户数据模型

### 2.1 用户基础信息
```sql
-- 用户基础信息表
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 用户元数据表
CREATE TABLE user_metadata (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    avatar_url VARCHAR(255),
    signature TEXT,
    nickname VARCHAR(50),
    gender VARCHAR(10),
    birthday DATE,
    location VARCHAR(100),
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 用户登录历史表
CREATE TABLE login_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    device_info TEXT,
    login_status VARCHAR(20)
);
```

## 3. 用户认证系统

### 3.1 认证流程
1. 用户注册
   - 验证用户名唯一性
   - 验证邮箱格式
   - 密码加密存储
   - 生成初始元数据

2. 用户登录
   - 验证用户凭证
   - 生成JWT token
   - 记录登录历史
   - 更新用户状态

3. 会话管理
   - Token验证
   - 会话超时处理
   - 多设备登录控制

### 3.2 安全策略
- 密码策略
  - 最小长度要求
  - 复杂度要求
  - 定期更换提醒
  - 密码加密存储

- 登录安全
  - 登录失败限制
  - IP限制
  - 设备指纹
  - 异常登录检测

## 4. 用户元数据管理

### 4.1 头像管理
- 支持格式：JPG, PNG, GIF
- 大小限制：最大5MB
- 尺寸要求：建议200x200像素
- 存储策略：
  - 原始图片存储
  - 自动生成缩略图
  - CDN加速

### 4.2 签名管理
- 长度限制：最大200字符
- 内容过滤：敏感词检测
- 更新频率：无限制
- 历史记录：保留最近10次修改

### 4.3 其他元数据
- 昵称：最大50字符
- 性别：男/女/保密
- 生日：日期格式
- 位置：省市区
- 个人简介：最大500字符

## 5. API接口设计

### 5.1 用户管理接口
```elixir
# 用户注册
POST /api/v1/users/register
{
  "username": "string",
  "password": "string",
  "email": "string",
  "phone": "string"
}

# 用户登录
POST /api/v1/users/login
{
  "username": "string",
  "password": "string"
}

# 获取用户信息
GET /api/v1/users/:id

# 更新用户信息
PUT /api/v1/users/:id
{
  "nickname": "string",
  "signature": "string",
  "avatar_url": "string"
}
```

### 5.2 元数据管理接口
```elixir
# 上传头像
POST /api/v1/users/:id/avatar
Content-Type: multipart/form-data

# 更新签名
PUT /api/v1/users/:id/signature
{
  "signature": "string"
}

# 获取元数据
GET /api/v1/users/:id/metadata
```

## 6. 缓存策略

### 6.1 用户信息缓存
- 缓存键：`user:{id}`
- 缓存时间：1小时
- 更新策略：用户信息变更时更新

### 6.2 元数据缓存
- 缓存键：`user_metadata:{id}`
- 缓存时间：2小时
- 更新策略：元数据变更时更新

## 7. 安全与隐私

### 7.1 数据加密
- 密码：bcrypt加密
- 敏感信息：AES加密
- 传输层：SSL/TLS

### 7.2 隐私保护
- 数据脱敏
- 访问控制
- 数据导出
- 数据删除

## 8. 监控与日志

### 8.1 监控指标
- 用户注册成功率
- 登录成功率
- 认证延迟
- 缓存命中率

### 8.2 日志记录
- 用户操作日志
- 安全事件日志
- 系统错误日志
- 性能监控日志 