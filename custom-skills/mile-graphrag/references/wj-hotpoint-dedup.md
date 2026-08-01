# HotPointMap 热力图分支1去重

## 背景

热力图插件在每个地图格子上采集 4 个方向的性能数据（东/西/南/北），每个方向一条记录。原始方案（分支2）保留全部 4 条上传到平台。分支1在写 Data.json 前自行去重，每个格子只保留 Ms（帧耗时）最大的一条。

## 数据格式

```json
{
  "performanceData": {
    "(x,1000000,y)": [
      "(0.00, 0.00, 0.00),SetPassCall,DrawCall,DrawBatch,Vertices,Triangles,Memory,Fps,Ms,CMD",
      "..."
    ]
  }
}
```

列索引（逗号分隔）：0=camera, 1=SetPassCall, 2=DrawCall, 3=DrawBatch, 4=Vertices, 5=Triangles, 6=Memory, 7=Fps, 8=Ms, 9=CMD。Ms 越大 = 性能越差。

## 四层改动

### Lua（HotPointRunMapOneDepth.lua）
- 新增 `nDedupType` 字段（默认0）+ `SetDedupType(n)` 函数
- 跑图结束时，若 `nDedupType==1`：遍历每个格子，保留 Ms 最大的条目，testGM 占位数据跳过

### Python（CaseHotPointMap.py）
- 新增 `self.strDedupType="0"` 默认
- `check_dic_args` 读 `DedupType` 参数
- `processSearchPanelTab` 中 `changeStrInFile(tmp, '_DedupType_', ...)`

### RunMap.tab 模板
需加：`/cmd HotPointRunMapOneDepth.SetDedupType(_DedupType_)`

### 验证脚本
`scripts/test-hotpoint-dedup.py` — 本地验证去重逻辑，不依赖设备。
```bash
python3 test-hotpoint-dedup.py Data.json
```
输出每个格子条目数变化，生成 `Data_dedup.json`。

## 架构纠正：HotPointRunMapOneDepth vs MapFarming

**HotPointRunMapOneDepth**（类型1）每个格子固定采集 4 个方向各 1 条，共 4 条。分支去重从 4→1 意义不大。

**MapFarming / CustomRunMap**（类型2）沿着自定义路径边走边每秒采一条，同一个格子会被反复踩到 10+ 次，去重才有实际价值。而且 **MapFarming 已有实时去重**：`MapFarming.Process()`（`Interface/MapFarming/MapFarming.lua`）在每次采样时做逐格比较，只保留性能最差的那条。

**2026-05-07 修复**：原 `Process()` 有两个 bug：
1. 比较字段错误——注释说比"面数"（Triangles），代码实际比 index 8 即 Memory，都不是帧耗时。修改为比较 index 10（Ms 帧耗时），越大越差。
2. 旧逻辑只在当前值比已存值更差时才替换，更优值被静默丢弃——这恰好就是分支1行为（保留最差），逻辑本身正确，只需修正比较字段。

修改后的 `Process()` 逻辑：当前入格 → 解析 Ms → 若有旧数据：Ms 更大才替换坐标 key → 若无旧数据：直接存。

**两分支应基于 MapFarming 而非 HotPointRunMapOneDepth**。分支1=保留 MapFarming 现有实时去重，分支2=关掉去重逻辑让 Process() 全保留。

**用户偏好**：做这种功能开关时，优先改 .lua 的默认值或 .tab 硬编码，不要为分支1另建目录（如 HotPointRunMapOneDepthB1 被拒），不要改 .py 加 changeStrInFile 管道。最简方案：MapFarming 默认分支1，要切分支2就换回旧 lua。

详见 `Interface/MapFarming/MapFarming.lua` 和 `Interface/CustomRunMap/CustomRunMap.lua`。
