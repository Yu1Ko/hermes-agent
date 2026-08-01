return
{
    LOW = {
        eViewProbeType = 0,                           -- Shadow--远景投影类型(现在只有阴影)
        nResolutionLevel = 1,                         -- 渲染分辨率
    },
    MID = {
        eViewProbeType = 0,                           -- Shadow--远景投影类型(现在只有阴影)
        nResolutionLevel = 1,                         -- 渲染分辨率
    },
    HIGH = {
        nResolutionLevel = 1,                         -- 渲染分辨率
        eTerrainBakeLevel = 1,                        -- 渲染精度
        bEnableFXAA = true,                           -- 开启FXAA抗锯齿
        bEnableTAA = false,                           -- 开启TAA抗锯齿,
    },
    EXTREME_HIGH = {
        bEnableFXAA = true,                           -- 开启FXAA抗锯齿
        bEnableTAA = false,                           -- 开启TAA抗锯齿,
    },
}