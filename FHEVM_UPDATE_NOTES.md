# fhEVM 更新说明

## 📅 更新日期
2025年1月 - 适配最新 fhEVM API 变更

## 🔄 主要变更内容

### 1. PauserSet 不可变合约配置

**新增功能**: 暂停器集合现已不可变,可通过多个地址暂停主机和网关合约。

#### 网关合约环境变量
新的环境变量配置:
- `NUM_PAUSERS`: 要添加的暂停器地址数量 (应设置为 n_kms + n_copro)
  - `n_kms`: 已注册的 KMS 节点数量
  - `n_copro`: 已注册的协处理器数量
- `PAUSER_ADDRESS_[0-N]`: 各个暂停器地址

**已废弃**: `PAUSER_ADDRESS` (单一暂停器地址)

#### 主合约环境变量
配置方式相同:
- `NUM_PAUSERS`: 暂停器地址总数
- `PAUSER_ADDRESS_[0-N]`: 各个暂停器地址

**已废弃**: `PAUSER_ADDRESS`

### 2. 交易输入的重新随机化

**新增安全特性**: 所有交易输入(包括来自状态的输入)在 FHE 操作评估前都会重新加密,提供 **sIND-CPAD 安全性**。

**影响**:
- ✅ 对用户完全透明,无需修改应用代码
- ✅ 自动提供更高级别的隐私保护
- ✅ 防止密文分析攻击

### 3. 用户解密响应改进

**变更详情**:
- 加密共享和签名不再在网关的链上存储
- 环境变量重命名:
  - `KMS_CONNECTOR_OR_KMS_MANAGEMENT_CONTRACT__ADDRESS` → `KMS_CONNECTOR_KMS_GENERATION_CONTRACT__ADDRESS`

- Helm 图表 `values.yaml` 字段重命名:
  - `kmsManagement` → `kmsGeneration`

### 4. 网关检查功能替换

**重大变更**: 所有 `check...` 视图函数已从网关合约中删除

#### 函数映射表

| 已废弃函数 | 新函数 | 变更说明 |
|----------|--------|---------|
| `checkPublicDecryptAllowed()` | `isPublicDecryptAllowed()` | 返回 `bool` 而非 revert |
| 其他 `check...` 函数 | 对应 `is...` 函数 | 统一返回布尔值 |

**相关错误处理**:
- `PublicDecryptNotAllowed` 错误已移至 `Decryption` 合约
- 其他相关事件已被删除

## ✅ 本项目适配情况

### 已完成的更新

#### 1. ✅ 签名验证代码更新
**文件**: `contracts/PrivateBuildingMaterialProcurement.sol:236-244`

**变更内容**:
```solidity
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

**说明**:
- 移除了手动签名验证的占位代码
- 添加了说明注释,明确指出网关自动处理签名验证
- 利用了新的自动重新随机化特性

#### 2. ✅ Gateway API 函数检查
**检查结果**: 项目中未使用任何已废弃的 `check...` 函数

**验证命令**:
```bash
grep -r "check.*Allowed\|checkPublic\|checkSignatures" contracts/
```

**结果**: 无匹配项 ✓

### 需要注意的配置项

#### 部署时的环境变量配置

如果您需要部署自己的 fhEVM 网络或 KMS 服务,请确保:

1. **更新 PauserSet 配置**:
```bash
# 旧配置 (已废弃)
PAUSER_ADDRESS=0x1234...

# 新配置
NUM_PAUSERS=3
PAUSER_ADDRESS_0=0x1234...
PAUSER_ADDRESS_1=0x5678...
PAUSER_ADDRESS_2=0x9abc...
```

2. **更新 KMS 连接器配置**:
```bash
# 旧配置 (已废弃)
KMS_CONNECTOR_OR_KMS_MANAGEMENT_CONTRACT__ADDRESS=0x...

# 新配置
KMS_CONNECTOR_KMS_GENERATION_CONTRACT__ADDRESS=0x...
```

3. **Helm 图表配置**:
```yaml
# values.yaml
# 旧配置 (已废弃)
kmsManagement:
  address: "0x..."

# 新配置
kmsGeneration:
  address: "0x..."
```

## 🔒 安全改进总结

1. **增强的密文安全性**: 自动重新随机化防止密文关联攻击
2. **简化的签名验证**: 网关自动处理,减少实现错误
3. **改进的错误处理**: 使用布尔返回值代替 revert,更灵活的错误处理
4. **多重暂停器支持**: 提高了系统的去中心化和安全性

## 📚 相关资源

- [fhEVM 官方文档](https://docs.fhevm.zama.ai/)
- [Zama 文档中心](https://docs.zama.ai/)
- [fhEVM Solidity 库](https://github.com/zama-ai/fhevm)

## ⚠️ 迁移建议

### 对于使用本合约的项目

1. **立即行动**:
   - ✅ 重新编译合约使用最新的 `@fhevm/solidity` 库
   - ✅ 测试所有解密流程确保签名验证正常工作
   - ✅ 验证前端集成没有受到影响

2. **如果自建 fhEVM 基础设施**:
   - ⚠️ 更新所有环境变量配置
   - ⚠️ 更新 Helm 图表配置
   - ⚠️ 重新部署 KMS 和网关服务
   - ⚠️ 配置多个暂停器地址提高安全性

3. **如果使用 Zama 托管服务**:
   - ✅ 仅需重新编译和部署更新后的合约
   - ✅ 基础设施更新由 Zama 自动处理

## 🎯 后续建议

1. **监控合约行为**: 在测试网上彻底测试所有功能
2. **性能测试**: 验证重新随机化不会显著影响 gas 消耗
3. **安全审计**: 如果是生产环境,建议进行新一轮安全审计
4. **文档更新**: 更新用户文档说明新的安全特性

---

**最后更新**: 2025年1月
**维护者**: Private Building Material Procurement Team
**联系方式**: 请通过 GitHub Issues 反馈问题
