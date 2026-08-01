SceneMgr = SceneMgr or {className = "SceneMgr"}
local this = SceneMgr
local kMaxModelCacheNum = 2     -- 模型最大缓存个数

function SceneMgr.Init()
    this.tbTouchesList = {}
    this.tbPersistentNode = {}
    -- 当前表现场景
    this.pGameScene = nil
    this.bInFaceState = false   -- 是否开启镜头光（怼脸）
    this.bReuseScene = false    -- 是否复用场景
    -- 动态创建的3D模型列表
    this.t3DModels = {
        tActive = {},           -- 活跃的模型
        tCache = {}             -- 缓存的模型
    }

    Event.Reg(SceneMgr, "PLAYER_ENTER_SCENE", function(nPlayerID, nSceneID)
        LOG.INFO("------PLAYER_ENTER_SCENE nPlayerID: %s, nSceneID: %s", tostring(nPlayerID), tostring(nSceneID))
        if not PlayerData.IsSelf(nPlayerID) then
            return
        end

        SceneMgr.SetScene(nSceneID)
        SceneMgr.pGameScene = KG3DEngine.IDToScene(nSceneID)

        --TODO_xt: 2024.6.11 处理特殊场景远景距离
        if g_pClientPlayer and g_pClientPlayer.GetMapID() == 655 then
            SceneMgr.pGameScene:SetCameraPerspective(nil, nil, nil, 400000)
        else
            SceneMgr.pGameScene:SetCameraPerspective(nil, nil, nil, Config.X3DENGINEOPTION.fCameraFarClip)   -- 游戏摄像机远视距
        end

        --TODO_xt: 2024.6.21 处理逻辑的表现场景没有名字的问题（0档镜头光依赖这个）
        if g_pClientPlayer then
            local nMapID = g_pClientPlayer.GetMapID()
            local szFilePath = GetMapParams(nMapID)
            SceneMgr.pGameScene:SetName(string.format("%s\\", szFilePath))
        end

        ConfirmClientReady()
        if g_pClientPlayer and not g_pClientPlayer.bUseFullAngle then
            UseFullAngle(true)
        end

        if not UIMgr.IsViewOpened(VIEW_ID.PanelMainCity) then
            UIMgr.Open(VIEW_ID.PanelMainCity)
            UIMgr.Open(VIEW_ID.PanelMainCityInteractive)
        end
    end)

    Event.Reg(SceneMgr, "SCENE_BEGIN_LOAD", function(nMapID, szPath, nFromMapID)
        local hHomelandMgr = GetHomelandMgr()
        if hHomelandMgr then
            if hHomelandMgr.IsPrivateHomeMap(nMapID) then
                local dwMapID, dwSkinID = hHomelandMgr.GetClientCurSkin()
                if dwSkinID > 0  then
                    local uMapSkinID = hHomelandMgr.GetMapSkinID(dwMapID, dwSkinID)
                    local tSkinConfig = hHomelandMgr.GetPrivateHomeSkinConfig(uMapSkinID)
                    if tSkinConfig then
                        szPath = tSkinConfig.szResourceDir
                    end
                end
            end
        end

        LOG.INFO("------SCENE_BEGIN_LOAD ".."nMapID:"..tostring(nMapID).."  szPath:"..tostring(UIHelper.GBKToUTF8(szPath)))

        XGSDK_TrackEvent("game.scene.begin.load", "login", {})

        UIHelper.ExitPowerSaveMode()
        SceneMgr.ShowLoading(nMapID, szPath, nFromMapID)
        UIMgr.ShowLayer(UILayer.Scene, nil, true)
    end)

    Event.Reg(SceneMgr, "SCENE_END_LOAD", function(nSceneID, bReuse)
        LOG.INFO("------SCENE_END_LOAD ".."nSceneID:"..tostring(nSceneID) )
        this.bReuseScene = bReuse
        XGSDK_TrackEvent("game.scene.end.load", "login", {})

        LoadingComplete()
        NotifyEndLoading()
    end)

    Event.Reg(SceneMgr, EventType.OnClientPlayerLeave, function()
        UIHelper.ExitPowerSaveMode()

        this.bInFaceState = false
        SceneMgr.SetScene(nil)
    end)

    Event.Reg(SceneMgr, "SET_3DSCENE", function(nSceneID)
        SceneMgr.SetScene(nSceneID)
    end)

    Event.Reg(SceneMgr, "FOCUS_FACE_STATUS_CHANGE", function(bInFaceState)
        SceneMgr.bInFaceState = bInFaceState
    end)

    Event.Reg(SceneMgr, EventType.UILoadingStart, function(nMapID)
        PlotMgr.ClosePanel(PLOT_TYPE.OLD)
        PlotMgr.ClosePanel(PLOT_TYPE.NEW)

        UIHelper.ExitHideAllUIMode()
        UIMgr.CloseAllInLayer(UILayer.Popup)
        UIMgr.CloseAllInLayer(UILayer.Page, {VIEW_ID.PanelRevive})

        TipsHelper.DeleteAllHoverTips()
    end)

    Event.Reg(SceneMgr, EventType.UILoadingFinish, function(nMapID)
        if  g_pClientPlayer and this.pGameScene then
            -- 预加载、缓存常用特效模型
            --this.cacheModels()

            -- 副本场景关闭引擎的角色模型裁减逻辑
            local _, nMapType = GetMapParams(nMapID)
            if nMapType and nMapType == MAP_TYPE.DUNGEON then
                local bDisable = true
                for _, nCullMapID in ipairs(MODEL_CULL_DUNGEON_MAP_IDS) do
                    if nMapID == nCullMapID then
                        bDisable = false
                        break
                    end
                end
                this.pGameScene:DisableModelSTCull(bDisable)
            end
        end
    end)

    --if Platform.IsWindows() then
        Event.Reg(SceneMgr, EventType.OnWindowsSizeChanged, function ()
            if not SceneMgr.nCurSceneID or SceneMgr.nCurSceneID == 0 then
                return
            end

            local layer = UIMgr.GetLayer(UILayer.Scene)
            if not layer then
                return
            end

            -- 场景名称需要和UIMgr中New3DScene的保持一致
            local scene = layer:getChildByName(string.format("3DScene_%s", SceneMgr.nCurSceneID))
            if scene then
                scene:setContentSize(arg0, arg1)
            end
        end)
    --end

    -- 注册场景点击
    SceneMgr.RegisterTouch()
end

function SceneMgr.UnInit()
    Event.UnRegAll(SceneMgr)
end

function SceneMgr.NewScene(szScenePath, bFixCamera, nSceneID, nX, nY, nZ)
    print("[Scene] NewScene", szScenePath, bFixCamera, nSceneID, nX, nY, nZ)
    SceneMgr.curScene = Scene_New(szScenePath, bFixCamera, nSceneID, nX, nY, nZ)
    return SceneMgr.curScene
end

function SceneMgr.DeleteCurScene()
    Scene_RemoveOutputWindow(SceneMgr.nCurSceneID)
    local ret = Scene_Delete(SceneMgr.curScene)
    SceneMgr.curScene = nil
    return ret
end

function SceneMgr.SetScene(nSceneID)
    if nSceneID then
        this.nCurSceneID = nSceneID
        UIMgr.RemoveAllScene()
        UIMgr.New3DScene(0, nSceneID)
        this.HideSwitcher()
    else
        SceneMgr.ShowLoading(nil, nil, nil)

        this.clearScene()
        this.ShowSwitcher()
        this.nCurSceneID = nil
        UIMgr.RemoveAllScene()
    end

    Event.Dispatch(EventType.OnSetUIScene, nSceneID)
end

function SceneMgr.GetCurSceneID()
    return this.nCurSceneID
end

-- 获取游戏表现场景
-- 由于可能存在多个游戏场景，这里特指游戏逻辑场景对应的那个表现场景
-- TODO: 命名需更准确
function SceneMgr.GetGameScene()
    return SceneMgr.pGameScene
end

---comment 当前是否开启镜头光（怼脸）
---@return boolean
function SceneMgr.IsInFaceState()
    return this.bInFaceState
end

---comment 当前是否复用表现场景
---@return boolean
function SceneMgr.IsReuseScene()
    return this.bReuseScene
end

---comment 创建一个3D模型(游戏场景)
---@param szPath string 模型路径
---@param nX number|nil
---@param nY number|nil
---@param nZ number|nil
---@return userdata pModel 模型对象
function SceneMgr.CreateModel(szPath, nX, nY, nZ)
    assert(this.pGameScene)
    local pModel
    local tModels = this.t3DModels.tCache[szPath]
    if tModels then
        local nCount = #tModels
        if nCount > 0 then
            pModel = tModels[nCount]
            table.remove(tModels, nCount)
        else
            pModel = KG3DEngine.GetModelMgr():NewModel(szPath)
        end
    else
        pModel = KG3DEngine.GetModelMgr():NewModel(szPath)
    end

    pModel:SetTranslation(nX or 0, nY or 0, nZ or 0)
    this.pGameScene:AddRenderEntity(pModel)
    this.t3DModels.tActive[pModel] = szPath
    return pModel
end

---comment 销毁一个3D模型(游戏场景)
---@param pModel userdata 模型对象
---@param bCache boolean|nil 是否缓存模型(NOTE: 主要用于技能选择框特效缓存)
function SceneMgr.DestoryModel(pModel, bCache)
    if not pModel then
        return
    end

    -- 从场景中移除
    if this.pGameScene then
        this.pGameScene:RemoveRenderEntity(pModel)
    end

    local szPath = this.t3DModels.tActive[pModel]
    if not szPath then
        pModel:Release()    -- 销毁
        return
    end

    this.t3DModels.tActive[pModel] = nil

    -- 缓存, TODO: 2024.4.16 去掉模型缓存已解决模型重新添加到场景闪一下的bug
    -- if bCache and not this.t3DModels.tCache[szPath] then
    --     this.t3DModels.tCache[szPath] = {}
    -- end

    local tModels = this.t3DModels.tCache[szPath]
    if tModels and #tModels < kMaxModelCacheNum then
        table.insert(tModels, pModel)
    else
        pModel:Release()    -- 销毁
    end
end

---comment 逻辑坐标到场景坐标
---@param x integer
---@param y integer
---@param z integer
---@return xyz number
function SceneMgr.LogicPosToScenePos(x, y, z)
    return Scene_GameWorldPositionToScenePosition(x, y, z)
end

-- 场景坐标到逻辑坐标
function SceneMgr.ScenePosToLogicPos(x, y, z)
    return Scene_ScenePositionToGameWorldPosition(x, y, z)
end

function SceneMgr.RegisterTouch()
    local layer = UIMgr.GetLayer(UILayer.Scene)
    if not layer then return end

    local tTouchEvent = {}
    this.nTouchingCount = 0
    this.tbTouchesList = {}
    local function _dispatchEvent(touches, szEventType1, szEventType2)
        local nIndex = tTouchEvent[1]
        if nIndex then
            local nX, nY = touches[nIndex], touches[nIndex + 1]
            if #tTouchEvent == 1 then
                Event.Dispatch(szEventType1, nX, nY)
            end
        end

        local tbPos1 = this.tbTouchesList[1] and this.tbTouchesList[1].tbPos or {}
        local tbPos2 = this.tbTouchesList[2] and this.tbTouchesList[2].tbPos or {}
        if EventType.OnSceneTouchsBegan == szEventType2 or EventType.OnSceneTouchsMoved == szEventType2 then
            if tbPos1.nX and tbPos1.nY and tbPos2.nX and tbPos2.nY then
                Event.Dispatch(szEventType2, tbPos1.nX, tbPos1.nY, tbPos2.nX, tbPos2.nY)
                this.szLastTouchsEvent = szEventType2
            end
        elseif EventType.OnSceneTouchsEnded == szEventType2 or EventType.OnSceneTouchsCancelled == szEventType2 then
            if #this.tbTouchesList <= 0 and (this.szLastTouchsEvent == EventType.OnSceneTouchsBegan or this.szLastTouchsEvent == EventType.OnSceneTouchsMoved) then
                Event.Dispatch(szEventType2, tbPos1.nX, tbPos1.nY, tbPos2.nX, tbPos2.nY)
                this.szLastTouchsEvent = szEventType2
            end
        end
        this.tbLastTouchPos = {tbPos1, tbPos2}
    end

    local function _containsTouch(nID)
        for k, v in pairs(this.tbTouchesList) do
            if v.nID == nID then
                return true, k
            end
        end
        return false
    end

    layer:setTouchEnabled(true)
    layer:registerScriptTouchHandler(function(szEventType, touches)
        if not touches then return end
        tTouchEvent = {}

        for i = 1, #touches, 4 do
            local nX, nY, nID, nMouseButton = touches[i], touches[i + 1], touches[i + 2], touches[i + 3]
            local bButtonValid = nMouseButton == cc.MouseButton.BUTTON_LEFT or nMouseButton == cc.MouseButton.BUTTON_RIGHT
            if szEventType == "began" then
                if not _containsTouch(nID) and #this.tbTouchesList < 2 and bButtonValid then
                    table.insert(this.tbTouchesList, {nID = nID, tbPos = {nX = nX, nY = nY}, nMouseButton = nMouseButton})
                    table.insert(tTouchEvent, i)
                end
            elseif szEventType == "moved" then
                local bContain, nIndex = _containsTouch( nID)
                if bContain then
                    table.insert(tTouchEvent, i)
                    this.tbTouchesList[nIndex].tbPos = {nX = nX, nY = nY}
                end
            elseif szEventType == "ended" or szEventType == "cancelled" then
                local bContain, nIndex = _containsTouch(nID)
                if bContain then
                    table.remove(this.tbTouchesList, nIndex)
                    table.insert(tTouchEvent, i)
                end
            end
        end
        this.nTouchingCount = #this.tbTouchesList
        if szEventType == "began" then
            _dispatchEvent(touches, EventType.OnSceneTouchBegan, EventType.OnSceneTouchsBegan)
        elseif szEventType == "moved" then
            _dispatchEvent(touches, EventType.OnSceneTouchMoved, EventType.OnSceneTouchsMoved)
        elseif szEventType == "ended" then
            _dispatchEvent(touches, EventType.OnSceneTouchEnded, EventType.OnSceneTouchsEnded)
        elseif szEventType == "cancelled" then
            _dispatchEvent(touches, EventType.OnSceneTouchCancelled, EventType.OnSceneTouchsCancelled)
        end
        return true
    end, true, 0, true)
end

function SceneMgr.GetTouchingCount()
    return this.nTouchingCount or 0
end

function SceneMgr.GetTouchPos()
    for i, v in ipairs(this.tbTouchesList) do
        return v.tbPos
    end
end

function SceneMgr.GetLastTouchPos()
    return this.tbLastTouchPos or {}
end

---@param nMouseButton number|nil cc.MouseButton
function SceneMgr.GetMouseButton(nMouseButton)
    for i, v in ipairs(this.tbTouchesList) do
        if not nMouseButton or v.nMouseButton == nMouseButton then
            return v
        end
    end
end

function SceneMgr.ClearTouches()
    if #this.tbTouchesList == 1 then
        local tbPos = this.tbTouchesList[1].tbPos or {}
        this.tbTouchesList = {}
        this.nTouchingCount = 0
        Event.Dispatch(EventType.OnSceneTouchCancelled, tbPos.nX, tbPos.nY)
    elseif #this.tbTouchesList == 2 then
        local tbPos1 = this.tbTouchesList[1] and this.tbTouchesList[1].tbPos or {}
        local tbPos2 = this.tbTouchesList[2] and this.tbTouchesList[2].tbPos or {}
        this.tbTouchesList = {}
        this.nTouchingCount = 0
        Event.Dispatch(EventType.OnSceneTouchsCancelled, tbPos1.nX, tbPos1.nY, tbPos2.nX, tbPos2.nY)
    else
        this.tbTouchesList = {}
        this.nTouchingCount = 0
    end
end

function SceneMgr.ShowSwitcher()
    do return end
    Timer.DelTimer(this, this.nHideSwitcherTimerID)

    -- if SceneMgr.nCurSceneID == nil then
    --     return
    -- end

    UIHelper.CaptureScreen(function(pTexture)
        if safe_check(pTexture) then
            local scriptSwitcher = UIMgr.GetViewScript(VIEW_ID.PanelSceneSwitcher)
            if not scriptSwitcher then
                scriptSwitcher = UIMgr.Open(VIEW_ID.PanelSceneSwitcher)
            end

            if not scriptSwitcher then
                return
            end

            UIHelper.SetTextureWithBlur(scriptSwitcher.ImgBg, pTexture, false, Const.UIBgBlur.nRadius, Const.UIBgBlur.nSampleNum)
        end
    end, 1)
end

function SceneMgr.HideSwitcher()
    do return end
    Timer.DelTimer(this, this.nHideSwitcherTimerID)

    if not UIMgr.GetView(VIEW_ID.PanelSceneSwitcher) then
        return
    end

    if SceneMgr.nCurSceneID == LOGIN_SCENE_ID then
        this.nHideSwitcherTimerID = Timer.Add(this, 0.5, function()
            UIMgr.Close(VIEW_ID.PanelSceneSwitcher)
        end)
    else
        UIMgr.Close(VIEW_ID.PanelSceneSwitcher)
    end
end

---comment 缓存频繁使用的模型
function SceneMgr.cacheModels()
    -- 技能选择框
    for _, tSelect in pairs(Const.kAreaSelectSfxs) do
        local pModel = this.CreateModel(tSelect.szDragSfx)
        if pModel then
            this.DestoryModel(pModel, true)
        end
    end

    -- 技能警告框
    for _, szSfx in pairs(Const.kWarningBox.tSfxs) do
        local pModel = this.CreateModel(szSfx)
        if pModel then
            this.DestoryModel(pModel, true)
        end
    end
end

function SceneMgr.clearScene()
    for pModel in pairs(this.t3DModels.tActive) do
        this.pGameScene:RemoveRenderEntity(pModel)
        pModel:Release()
    end

    for _, tModels in pairs(this.t3DModels.tCache) do
        for _, pModel in ipairs(tModels) do
            this.pGameScene:RemoveRenderEntity(pModel)
            pModel:Release()
        end
    end

    this.t3DModels.tActive = {}
    this.t3DModels.tCache = {}
    this.pGameScene = nil
end

function SceneMgr.IsLoading()
    return this.bIsLoading
end

function SceneMgr.SetIsLoading(bValue)
    this.bIsLoading = bValue
end

function SceneMgr.IsLoadingIsMainSubMap()
    return this.bIsLoadingIsMainSubMap
end

function SceneMgr.SetLoadingIsMainSubMap(bIsLoadingIsMainSubMap)
    this.bIsLoadingIsMainSubMap = bIsLoadingIsMainSubMap
end

function SceneMgr.ShowLoading(nMapID, szPath, nFromMapID)
    local loadingPanel = UIMgr.GetViewScript(VIEW_ID.PanelLoading)
    if loadingPanel then
        if loadingPanel.nMapID == nil then
            loadingPanel:OnEnter(nMapID, szPath, nFromMapID)
        else
            UIMgr.CloseWithCallBack(VIEW_ID.PanelLoading, function ()
                UIMgr.Open(VIEW_ID.PanelLoading, nMapID, szPath, nFromMapID)
            end)
        end
    else
        UIMgr.Open(VIEW_ID.PanelLoading, nMapID, szPath, nFromMapID)
    end
end

function SceneMgr.RegisterPersistentNode(szUUID, node)
    if not node or not IsUserData(node) then return end
    if string.is_nil(szUUID) then return end

    print("RegisterPersistentNode", node:getName(), szUUID)
    if not this.tbPersistentNode[szUUID] then
        this.tbPersistentNode[szUUID] = node
    elseif this.tbPersistentNode[szUUID] ~= node then
        LOG.ERROR("RegisterPersistentNode Error, UUID is already exist. name: %s, uuid: %s", node:getName(), tostring(szUUID))
    end
end

function SceneMgr.UnRegisterPersistentNode(szUUID)
    if string.is_nil(szUUID) then return end

    print("UnRegisterPersistentNode", szUUID)
    this.tbPersistentNode[szUUID] = nil
end

function SceneMgr.GetPersistentNode(szUUID)
    if string.is_nil(szUUID) then return end

    local node = this.tbPersistentNode[szUUID]
    if node and IsUserData(node) then
        return node
    else
        this.tbPersistentNode[szUUID] = nil
    end
end