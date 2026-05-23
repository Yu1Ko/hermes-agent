return
{
    LOW = {
        eViewProbeType = 0,                           -- Shadow--远景投影类型(现在只有阴影)
        nHouseLoadCount = 1,                          -- 社区房子的加载数量
    },
    MID = {
        eViewProbeType = 0,                           -- Shadow--远景投影类型(现在只有阴影)
        nHouseLoadCount = 1,                          -- 社区房子的加载数量
        bEnableShadowMask = true,                     -- 开启ShadowMask
    },
    HIGH = {
        eViewProbeType = 1,                           -- Shadow--远景投影类型(现在只有阴影)
        eTerrainBakeLevel = 1,                        -- 渲染精度
        eShadowLevel = 2,                             -- 阴影质量
        bEnableFXAA = true,                           -- 开启FXAA抗锯齿
        bEnableTAA = false,                           -- 开启TAA抗锯齿,
        nHouseLoadCount = 1,                          -- 社区房子的加载数量
    },
    EXTREME_HIGH = {
        eViewProbeType = 1,                           -- Shadow--远景投影类型(现在只有阴影)
        bEnableFXAA = true,                           -- 开启FXAA抗锯齿
        bEnableTAA = false,                           -- 开启TAA抗锯齿,
        nHouseLoadCount = 1,                          -- 社区房子的加载数量
    },
}