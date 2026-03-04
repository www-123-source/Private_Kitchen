# 私厨 - 家庭厨房点餐服务

## 项目概述
这是一个家庭厨房点餐服务应用，支持家庭成员之间共享菜单、预订菜品、统计偏好等功能。

## 系统要求
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 功能特性
- 菜品管理：添加、编辑、删除家庭菜单
- 今日餐单：规划每日三餐的菜品安排
- 想吃菜品：记录家庭成员想尝试的菜品
- 统计分析：成员点餐统计、菜品排行等功能
- 云端同步：使用CloudKit实现跨设备数据同步

## 如何运行

1. 使用Xcode打开项目：
   - 打开Xcode
   - 选择 "Open a project or file"
   - 选择项目根目录下的 `PrivateKitchenApp.xcodeproj`

2. 配置开发环境：
   - 确保已登录Apple开发者账号
   - 配置正确的Bundle Identifier
   - 启用iCloud功能（用于CloudKit）

3. 选择目标设备：
   - 选择要运行的模拟器或连接真实设备

4. 运行应用：
   - 点击"Run"按钮（Cmd+R）
   - 或使用快捷键 Cmd+R

## 架构说明

### 主要模块
- `DataManager`: 统一管理所有数据模型的CRUD操作
- `CloudKitManager`: 处理云端数据同步
- `SyncManager`: 同步状态管理
- `AppSettingsManager`: 应用设置管理

### 数据模型
- `Dish`: 菜品模型
- `Family`: 家庭模型
- `FamilyMember`: 家庭成员模型
- `DailyMenu`: 今日餐单模型
- `WantedDish`: 想吃菜品模型
- `OrderStatistics`: 统计数据模型

### 视图结构
- `Onboarding`: 启动和身份选择界面
- `Admin`: 管理员功能界面
- `Customer`: 普通成员功能界面
- `Shared`: 共享组件界面

## CloudKit设置
本应用使用CloudKit进行数据同步，请确保：
1. 在Apple Developer Portal中启用iCloud
2. 配置正确的CloudKit容器
3. 在Xcode中启用iCloud entitlements

## 注意事项
- 开发过程中需要有效的Apple开发者账号
- 使用CloudKit功能需要连接到互联网
- 某些功能可能需要特定的权限设置