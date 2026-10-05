# NOTE - 鸿蒙记账本应用

基于 HarmonyOS ArkTS 开发的个人收支记账应用，支持账单记录、月度统计、条件查询与收入隐私保护。

## 功能特性

- **记账首页**：按月份浏览账单，按日分组展示，汇总本月支出、收入与结余，支持月份切换
- **记一笔**：快速记录支出/收入，内置常用分类（餐饮、交通、购物、工资、奖金等），支持备注与日期选择
- **查询记录**：按关键字（备注/分类）、收支类型、时间范围（按月/全部）组合筛选账单
- **收支报表**：月度支出/收入分类占比、每日收支趋势、分类明细下钻
- **隐私保护**：收入金额默认隐藏，需通过锁屏密码（PIN）验证后方可查看

## 技术栈

| 类别 | 说明 |
| --- | --- |
| 语言/框架 | ArkTS、ArkUI（声明式 UI，状态管理 V2：`@ComponentV2`、`@Local`、`@ObservedV2`/`@Trace`） |
| 数据存储 | 关系型数据库 `@kit.ArkData`（relationalStore），单例 `BillService` 封装增删查 |
| 用户认证 | `@kit.UserAuthenticationKit`（userAuth PIN 验证） |
| 路由导航 | Navigation + 系统路由表（`router_map.json`） |
| 日志 | `@kit.PerformanceAnalysisKit`（hilog） |

## 项目结构

```
NOTE
├── AppScope                          # 应用级配置与资源
├── build-profile.json5               # 构建/签名/SDK 版本配置
├── hvigorfile.ts                     # 构建脚本
└── entry                             # 主模块
    └── src/main
        ├── ets
        │   ├── entryability          # Ability 入口
        │   ├── model/Bill.ets        # 账单模型、分类、日期工具
        │   ├── pages
        │   │   ├── Index.ets         # 首页（月账单列表）
        │   │   ├── AddBill.ets       # 记一笔
        │   │   ├── BillQuery.ets     # 查询记录
        │   │   └── Report.ets        # 收支报表
        │   └── service
        │       ├── BillService.ets   # 数据库服务（RDB）
        │       └── PrivacyService.ets# 收入隐私（PIN 验证）
        ├── resources                 # 资源文件（颜色、字符串、图片、路由表）
        └── module.json5              # 模块配置（权限：生物识别）
```

## 环境要求

- DevEco Studio（含 HarmonyOS SDK，`compileSdkVersion` 26.0.0）
- HarmonyOS 手机/模拟器（支持 PIN 锁屏密码的设备可体验隐私功能）

## 构建与运行

1. 使用 DevEco Studio 打开项目，或通过命令行：

   ```bash
   # 构建 HAP
   devecocli build

   # 部署到已连接的设备
   devecocli run
   ```

2. 真机调试需在 DevEco Studio 中配置签名（File → Project Structure → Signing Configs）。

## 数据说明

账单存储于应用沙箱内 RDB 数据库 `bills.db` 的 `bill` 表：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | INTEGER | 主键，自增 |
| type | INTEGER | 0-支出 / 1-收入 |
| amount | REAL | 金额 |
| category | TEXT | 分类 |
| note | TEXT | 备注 |
| date | TEXT | 账单日期（YYYY-MM-DD） |
| createTime | INTEGER | 创建时间戳 |
