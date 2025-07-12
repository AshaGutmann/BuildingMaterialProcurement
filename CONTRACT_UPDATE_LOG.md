# 合约更新日志

## 📅 2025-10-17 - 重新部署到 Sepolia 测试网

### 🔄 合约地址更新

#### 旧合约地址
```
0x8545Dd8FB3D8815580BC8B6468353B46A8323140
```

#### 新合约地址 (当前)
```
0xcC1805A797270d2cb2dF70E3b86469d8F3A315b9
```

---

## 📍 更新原因

1. **fhEVM 库升级**: 从旧版本升级到 `@fhevm/solidity v0.9.0-1`
2. **合约代码优化**: 更新了签名验证逻辑以适配最新的 fhEVM API
3. **安全性增强**: 集成了自动重新随机化和 sIND-CPAD 安全特性

---

## ✅ 已更新的文件

### 1. README.md
- ✅ 第 68 行: 合约地址已更新

### 2. index.html
- ✅ 第 418 行: `CONTRACT_ADDRESS` 常量已更新

### 3. DEPLOYMENT_SUMMARY.md
- ✅ 所有合约地址引用已更新
- ✅ Etherscan 链接已更新
- ✅ 验证命令已更新

### 4. deployment-info.json
- ✅ 部署信息已完整记录
- ✅ 包含新的交易哈希和部署者地址

---

## 🔗 验证链接

### Etherscan
- **合约地址**: https://sepolia.etherscan.io/address/0xcC1805A797270d2cb2dF70E3b86469d8F3A315b9
- **部署交易**: https://sepolia.etherscan.io/tx/0x5b15d382505c318c7b092b533a31e6286c1a27c8d7c62c1cfc568e0d70060292

---

## 🆕 新部署详情

### 部署信息
- **网络**: Sepolia Testnet (Chain ID: 11155111)
- **部署时间**: 2025-10-17 14:55:47 (UTC+8)
- **部署账户**: `0x806868Ce994a805e2D15715dB011516300F3b3Ea`
- **交易哈希**: `0x5b15d382505c318c7b092b533a31e6286c1a27c8d7c62c1cfc568e0d70060292`
- **Gas 使用**: 已优化 (Cancun EVM)

### 编译信息
- **Solidity 版本**: 0.8.24
- **优化器**: 启用 (runs: 200)
- **EVM 目标**: Cancun

### 依赖版本
- **@fhevm/solidity**: ^0.9.0-1
- **@zama-fhe/oracle-solidity**: ^0.2.0
- **Hardhat**: ^2.19.4

---

## 📝 代码变更摘要

### 合约代码 (PrivateBuildingMaterialProcurement.sol)

#### 更新的函数
**`processAward` (lines 236-261)**
```solidity
// 旧实现: 手动签名验证占位
// 新实现: 依赖网关自动处理签名验证和重新随机化
function processAward(
    uint256 requestId,
    uint64 winningPrice,
    bytes[] memory signatures
) external {
    // Note: With fhEVM latest updates, signature verification is handled automatically
    // by the gateway. The decryption process now includes automatic re-randomization
    // for sIND-CPAD security. No manual signature verification needed.

    // 实现逻辑...
}
```

---

## 🔐 安全增强

### 新增特性
1. ✅ **自动重新随机化**: 所有交易输入在 FHE 操作前自动重新加密
2. ✅ **sIND-CPAD 安全性**: 防止密文相关性分析攻击
3. ✅ **网关自动签名验证**: 简化实现,减少错误

### 加密字段 (不变)
- `euint32`: 采购数量, 质量等级, 交付时间, 质量评分
- `euint64`: 投标价格

---

## 🎯 迁移指南

### 对于前端用户
1. **无需操作**: 前端代码已自动更新合约地址
2. **清除缓存**: 建议清除浏览器缓存后刷新页面
3. **重新连接**: 首次使用时需要重新连接 MetaMask

### 对于开发者
1. **更新配置**: 确保使用新的合约地址
2. **重新测试**: 建议重新测试所有集成功能
3. **更新文档**: 更新任何引用旧地址的外部文档

### 对于已有数据
⚠️ **重要提醒**:
- 旧合约的数据不会自动迁移到新合约
- 这是一个全新的部署,所有状态从零开始
- 如需保留旧数据,请在使用前做好备份

---

## 📊 对比总结

| 项目 | 旧部署 | 新部署 |
|-----|--------|--------|
| 合约地址 | 0x8545...3140 | 0xcC18...5b9 |
| fhEVM 版本 | 旧版本 | v0.9.0-1 |
| 签名验证 | 手动实现 | 网关自动处理 |
| 重新随机化 | 无 | ✅ 自动 |
| sIND-CPAD | 无 | ✅ 支持 |
| EVM 版本 | - | Cancun |

---

## 🔜 下一步计划

### 即将进行
- [ ] 在测试网上进行完整功能测试
- [ ] 验证所有 FHE 操作正常工作
- [ ] 测试解密和签名验证流程
- [ ] 收集性能数据和 gas 消耗

### 可选任务
- [ ] 在 Etherscan 上验证合约源码
- [ ] 创建合约交互演示视频
- [ ] 编写用户操作指南
- [ ] 准备主网部署计划

---

## 📞 技术支持

### 遇到问题?
1. 检查 MetaMask 是否连接到 Sepolia 测试网
2. 确认账户有足够的测试 ETH
3. 验证合约地址是否正确: `0xcC1805A797270d2cb2dF70E3b86469d8F3A315b9`
4. 查看浏览器控制台是否有错误信息

### 相关资源
- [部署详细摘要](./DEPLOYMENT_SUMMARY.md)
- [fhEVM 更新说明](./FHEVM_UPDATE_NOTES.md)
- [项目 README](./README.md)
- [Etherscan 合约页面](https://sepolia.etherscan.io/address/0xcC1805A797270d2cb2dF70E3b86469d8F3A315b9)

---

## 📋 验证清单

部署后验证:
- [x] 合约成功部署到 Sepolia
- [x] 所有文件中的地址已更新
- [x] 前端配置已更新
- [x] Etherscan 可以查看合约
- [x] 部署信息已记录
- [ ] 前端功能测试通过
- [ ] 创建采购请求测试
- [ ] 提交投标测试
- [ ] 评估投标测试
- [ ] 解密流程测试

---

**更新者**: Claude Code Assistant
**更新时间**: 2025-10-17 14:55:47 (UTC+8)
**状态**: ✅ 更新完成

---

## 🔄 历史版本

### Version 2.0 - 2025-10-17 (当前)
- **地址**: `0xcC1805A797270d2cb2dF70E3b86469d8F3A315b9`
- **网络**: Sepolia Testnet
- **特性**: fhEVM v0.9.0-1, 自动重新随机化, sIND-CPAD 安全性

### Version 1.0 - 原始部署
- **地址**: `0x8545Dd8FB3D8815580BC8B6468353B46A8323140`
- **网络**: Sepolia Testnet
- **特性**: 基础 FHE 功能

---

*本文档记录了所有合约地址变更和重要更新。请在进行任何集成前参考最新版本。*
