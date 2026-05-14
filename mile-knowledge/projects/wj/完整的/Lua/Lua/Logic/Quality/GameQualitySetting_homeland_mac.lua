return
{
    LOW = {
        eViewProbeType = 0,                           -- Shadow--远景投影类型(现在只有阴影)
        nOtherEffectQuality = 2,                      -- 其他玩家特效质量
        nHouseLoadCount = 2,                           -- 社区房子的加载数量
    },
    MID = {
        nRenderLimit = 8,                             -- 同屏玩家数(0-30)
        nRenderNpcLimit = 8,                          -- 同屏NPC数(0-30)
        nSelfEffectQuality = 2,                       -- 自身特效质量
        nOtherEffectQuality = 2,                      -- 其他玩家特效质量
        eViewProbeType = 0,                           -- Shadow--远景投影类型(现在只有阴影)
        nHouseLoadCount = 2,                           -- 社区房子的加载数量
    },
    HIGH = {
        nRenderLimit = 9,                             -- 同屏玩家数(0-30)
        nQualityLevel = 2,                            -- 绘制等级
        nResolutionLevel = 2,                         -- 渲染分辨率
        nSelfEffectQuality = 1,                       -- 自身特效质量
        nOtherEffectQuality = 2,                      -- 其他玩家特效质量
        bEnableBloom = false,                         -- 开启光晕效果
        bEnableFXAA = true,                           -- 开启FXAA抗锯齿
        bEnableTAA = false,                           -- 开启TAA抗锯齿,
        bCampUniform = true,                          -- 阵营同模
        bEnableFSR = false,                           -- 开启FSR超分
        bEnableLightShaft = false,                    -- 开启光束
        bEnableRayMarchFog = false,                   -- 开启笔刷雾
        afMeshLodDistance = { 7500, 15000, 20000 },   -- 场景物件模型LOD切换距离
        nSimIK = 0,                                   -- 主角贴地
        nHouseLoadCount = 3,                           -- 社区房子的加载数量
    },
    EXTREME_HIGH = {
        nRenderLimit = 9,                             -- 同屏玩家数(0-30)
        nQualityLevel = 2,                            -- 绘制等级
        nResolutionLevel = 2,                         -- 渲染分辨率
        nSelfEffectQuality = 1,                       -- 自身特效质量
        nOtherEffectQuality = 2,                      -- 其他玩家特效质量
        eShadowLevel = 3,                             -- 阴影质量
        bEnableBloom = false,                         -- 开启光晕效果
        bCampUniform = true,                          -- 阵营同模
        nSimIK = 0,                                   -- 主角贴地
        bEnableGI = false,                            -- 开启GI效果
        nHouseLoadCount = 4,                           -- 社区房子的加载数量
    },
}