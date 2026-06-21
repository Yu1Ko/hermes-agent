GameQualityHook = {
    ["fLoadCullRadius"] = function()
        -- 登录场景40000 其他走配置
        local nSceneID = SceneMgr.GetCurSceneID()
        if nSceneID == LOGIN_SCENE_ID then
            return 40000
        end

        local tbSetting = QualityMgr.GetQualitySettingByType(QualityMgr.GetCurQualityType())
        return tbSetting.fLoadCullRadius
    end,

    ["bEnableSSPR"] = function()
        -- 登录场景强制打开，其他走配置
        local nSceneID = SceneMgr.GetCurSceneID()
        if nSceneID == LOGIN_SCENE_ID then
            return true
        end

        local tbSetting = QualityMgr.GetQualitySettingByType(QualityMgr.GetCurQualityType())
        return tbSetting.bEnableSSPR
    end,

    ["bSimpleSSR"] = function()
        -- 登录场景强制打开，其他走配置
        local nSceneID = SceneMgr.GetCurSceneID()
        if nSceneID == LOGIN_SCENE_ID then
            return false
        end

        local tbSetting = QualityMgr.GetQualitySettingByType(QualityMgr.GetCurQualityType())
        return tbSetting.bSimpleSSR
    end,

    ["nClientSceneSFXLimit"] = function()
        -- 登录场景强制设置为30，其他走配置
        local nSceneID = SceneMgr.GetCurSceneID()
        if nSceneID == LOGIN_SCENE_ID then
            return 30
        end

        local tbSetting = QualityMgr.GetQualitySettingByType(QualityMgr.GetCurQualityType())
        return tbSetting.nClientSceneSFXLimit
    end,

    ["bEnableGI"] = function()
        -- 新稻香村地宫强制开启，其他走配置

        local nCurQualityType = QualityMgr.GetCurQualityType()
        local nRecommendQualityType = QualityMgr.GetRecommendQualityType()
        local tbSetting = QualityMgr.GetQualitySettingByType(nCurQualityType)
        --[[
        -- 如果是登录场景，走默认配置
        local nSceneID = SceneMgr.GetCurSceneID()
        if nSceneID == LOGIN_SCENE_ID then
            return tbSetting.bEnableGI
        end

        -- 推荐画质是电影和极致才开
        if nRecommendQualityType == GameQualityType.HIGH or nRecommendQualityType == GameQualityType.EXTREME_HIGH then
            -- 异常走默认配置
            local scene = GetClientScene()
            if not scene then
                return tbSetting.bEnableGI
            end

            -- 新稻香村地宫强制开启
            if scene.dwMapID == 653 and MapMgr.nAreaID == 50 then
                return true
            end
        end
        ]]

        -- 走默认配置
        return tbSetting.bEnableGI
    end,

    ["eShadowLevel"] = function()
        -- 多人场景 eShadowLevel 在原有基础上 减1，最小为0

        -- local nCurQualityType = QualityMgr.GetCurQualityType()
        -- local tbSetting = QualityMgr.GetQualitySettingByType(nCurQualityType)
        local nShadowLevel = QualityMgr.GetOptionShadowLevel()
        local bDungeon = DungeonData.IsInDungeon()

        if Device.IsHuaWei() or Device.IsHonor() then
            return math.min(2, nShadowLevel)
        end

        -- 如果是登录场景，走默认配置
        local nSceneID = SceneMgr.GetCurSceneID()
        if nSceneID == LOGIN_SCENE_ID then
            return nShadowLevel
        end

        -- 如果是非副本的多人场景 eShadowLevel 就降一档
        if APIHelper.IsMultiPlayerScene() and not bDungeon then
            local nLevel = nShadowLevel - 1
            if nLevel < 1 then
                nLevel = 1
            end
            return nLevel
        end

        -- 副本场景的特殊处理
        if bDungeon then
            --if (Platform.IsAndroid() or Platform.IsWindows()) then
                if nShadowLevel == 4 then
                    return 3
                end
            --end
        end

        -- 走默认配置
        return nShadowLevel
    end,

    ["bEnableTAA"] = function()
        -- 0档镜头默认开启
        if SceneMgr.bInFaceState then
            return true
        end

        -- 多人场景 关闭 bEnableTAA
        local nCurQualityType = QualityMgr.GetCurQualityType()
        local tbSetting = QualityMgr.GetQualitySettingByType(nCurQualityType)
        local bDungeon = DungeonData.IsInDungeon()

        -- 如果是登录场景，走默认配置
        local nSceneID = SceneMgr.GetCurSceneID()
        if nSceneID == LOGIN_SCENE_ID then
            return tbSetting.bEnableTAA
        end

        -- 多人场景或者副本 关闭 bEnableTAA
        if APIHelper.IsMultiPlayerScene() or bDungeon then
            return false
        end

        -- 走默认配置
        return tbSetting.bEnableTAA
    end,
    ["nLimitFrame"] = function()
        QualityMgr.UpdateFramePerSecond() -- 多人场景 帧率限制
    end,
    ["bEnableSSAO"] = function()
        local bDungeon = DungeonData.IsInDungeon()
        -- 多人场景或者副本 关闭 bEnableSSAO
        if APIHelper.IsMultiPlayerScene() or bDungeon then
            return false
        end

        if not Platform.IsIos() then
           local nCurQualityType = QualityMgr.GetCurQualityType()
           local tbSetting = QualityMgr.GetQualitySettingByType(nCurQualityType)
           return tbSetting.bEnableSSAO -- 非IOS类型设备直接走已存储的设置
        else
            local nCurQualityType = QualityMgr.GetBasicQualityType() -- 查真实画质
            local tbDefaultSetting = QualityMgr.GetQualitySettingByType(nCurQualityType)
            return tbDefaultSetting.bEnableSSAO
        end
    end,
}
