return
{
    LOW = {
        eViewProbeType = 0,                           -- Shadow--远景投影类型(现在只有阴影)
        nCullerFoliageImportSizeInRadius = 500,
    },
    MID = {
        eViewProbeType = 0,                           -- Shadow--远景投影类型(现在只有阴影)
        nCullerFoliageImportSizeInRadius = 1000,
    },
    HIGH = {
        nQualityLevel = 2,                            -- 绘制等级
        nResolutionLevel = 2,                         -- 渲染分辨率
        nSelfEffectQuality = 1,                       -- 自身特效质量
        nOtherEffectQuality = 2,                      -- 其他玩家特效质量
        eTerrainBakeLevel = 1,                        -- 渲染精度
        nCullerFoliageImportSizeInRadius = 1600,
        bEnableFXAA = true,                           -- 开启FXAA抗锯齿
        bEnableTAA = false,                           -- 开启TAA抗锯齿,
    },
    EXTREME_HIGH = {
        nSelfEffectQuality = 1,                       -- 自身特效质量
        nOtherEffectQuality = 2,                      -- 其他玩家特效质量
        eShadowLevel = 3,                             -- 阴影质量
        bEnableBloom = false,                         -- 开启光晕效果
        bEnableFXAA = true,                           -- 开启FXAA抗锯齿
        bEnableTAA = false,                           -- 开启TAA抗锯齿,
        nCullerFoliageImportSizeInRadius = 1600,
    },
    BLUE_RAY = {
        nSelfEffectQuality = 1,                       -- 自身特效质量
        nOtherEffectQuality = 2,                      -- 其他玩家特效质量
        eShadowLevel = 3,                             -- 阴影质量
        bEnableBloom = false,                         -- 开启光晕效果
        bEnableFXAA = true,                           -- 开启FXAA抗锯齿
        bEnableTAA = false,                           -- 开启TAA抗锯齿,
        nCullerFoliageImportSizeInRadius = 1600,
    },
}