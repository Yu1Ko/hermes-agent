-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: TargetMgr
-- Date: 2022-11-09 19:59:20
-- Desc: 目标点选逻辑
-- ---------------------------------------------------------------------------------

-- 自动索敌配置
local tAutoSearchTab = require("Lua/Tab/TargetAutoSearchTab.lua")

TargetMgr = TargetMgr or { className = "TargetMgr" }
local this = TargetMgr
local Const = Const
local kDirectionCount = GLOBAL.DIRECTION_COUNT
local kHalfDirection = kDirectionCount / 2
local kSearchSfxID = 104    -- 锁定特效ID, global_effect.txt
local kTimeInterval = 0.2   -- 自动搜索间隔（秒）
local kFovScoreFactor = 70  -- 视角系数
local kDisScoreFactor = 30  -- 距离系数
local getDistance = kmath.metre_len
local getAutoSearchConfig, getQteSearchConfig
local kSponserMain = "main"
local kSponserQte = "qte"
local kQteForceID = 10001
local bEnableAutoSerach = false
local _nSearchX, _nSearchY = 0, 0

-- 当这些界面打开时，不可选中目标
local _tBlackListViewIDForSelectTarget = {
    [VIEW_ID.PanelCharacter] = true,
    [VIEW_ID.PanelAccessory] = true,
    [VIEW_ID.PanelHomeOverview] = true,
    [VIEW_ID.PanelCamera] = true,
    [VIEW_ID.PanelCameraVertical] = true,
}

function TargetMgr.Init()
    this.setupVars()
    this.registerEvents()
end

function TargetMgr.UnInit()
    TargetMgr.ResumeSearchTargetLock()
end

function TargetMgr.OnLogin()
end

function TargetMgr.OnFirstLoadEnd()
end

function TargetMgr.OnReload()
    Event.UnReg(this)
    this.registerEvents()
end

function TargetMgr.GetTargetName(dwType, dwID)
    local szName = ""
    if dwType == TARGET.NPC then
        local npc = NpcData.GetNpc(dwID)
        if npc then
            szName = npc.szName
        end
    elseif dwType == TARGET.DOODAD then
        local doodad = GetDoodad(dwID)
        if doodad then
            szName = Table_GetDoodadName(doodad.dwTemplateID, doodad.dwNpcTemplateID)
        end
    elseif dwType == TARGET.ITEM then
        local item = ItemData.GetItem(dwID)
        if item then
            szName = ItemData.GetItemNameByItem(item)
        end
    elseif dwType == TARGET.PLAYER then
        local player = GetPlayer(dwID)
        if player then
            szName = player.szName
        end
    end
    return szName
end

---comment 获取当前选择的目标
---@return integer 角色ID
---@return integer 角色类型
function TargetMgr.GetSelect()
    return this.tSelect.nTargetID, this.tSelect.nTargetType
end

---comment 角色当前的心法是否允许自动索敌
---@return boolean
function TargetMgr.IsKungfuEnableSearch()
    return this.tSearchConfig and not this.tSearchConfig.bDisableSearch
end

---comment 是否注视目标
---@return boolean
function TargetMgr.IsAttention()
    return this.bAttention
end

---comment 注视当前选中的目标
---@param bAttention boolean
function TargetMgr.Attention(bAttention)
    if this.bAttention == bAttention then
        return
    end

    if bAttention and this.tSelect.nTargetID ~= 0 then
        this.bAttention = true
        CameraMgr.LockTarget(this.tSelect.nTargetID)
    else
        this.bAttention = false
        CameraMgr.LockTarget(false)
    end
end

---comment 设置是否自动选择目标（角色当前没有目标时，被其它角色攻击、释放技能打中其他角色时，自动选择该角色为目标）
---@param bAuto boolean
function TargetMgr.SetAutoTarget(bAuto)
    this.bAutoTarget = bAuto
end

---comment 是否开启自动Tab逻辑
---@return boolean
function TargetMgr.IsAutoTab()
    return true
end

---comment 是否开启自动索敌
---@return boolean bEnable
function TargetMgr.IsEnableSearch()
    return this.bEnableSearch
end

---comment 是否锁定索敌
function TargetMgr.IsSearchTargetLocked()
    return this.bSearchTargetLocked
end

---comment 设置索敌锁定
function TargetMgr.SearchTargetLock(bLock, tType)
    this.bSearchTargetLocked = bLock

    if bLock then
        if tType then
            this.tLastSearchTargetType = GameSettingData.GetNewValue(UISettingKey.EnemySelectionPriority)
            GameSettingData.ApplyNewValue(UISettingKey.EnemySelectionPriority, tType)
            Event.Dispatch(EventType.OnGameSettingViewUpdate)
        end
    else
        TargetMgr.ResumeSearchTargetLock()
    end
end

---comment 恢复索敌锁定
function TargetMgr.ResumeSearchTargetLock()
    if this.tLastSearchTargetType then
        GameSettingData.ApplyNewValue(UISettingKey.EnemySelectionPriority, this.tLastSearchTargetType)
        this.tLastSearchTargetType = nil

        Event.Dispatch(EventType.OnGameSettingViewUpdate)
    end
end

---comment 开/关主角的自动索敌，根据主角自身的门派、功夫配置
---@param bEnable boolean
function TargetMgr.EnableMainSearch(bEnable)
    if bEnable then
        this.doEnableSearch(kSponserMain, getAutoSearchConfig())
    else
        this.doDisableSearch(kSponserMain)
    end
end

---comment 开/关动态技能栏的自动索敌配置
---@param bEnable boolean
---@param nGroupID integer|nil 动态技能组ID
function TargetMgr.EnableQteSearch(bEnable, nGroupID)
    if bEnable then
        local tSkill = g_tTable.DynamicSkill:Search(nGroupID)
        this.doEnableSearch(kSponserQte, tSkill and getQteSearchConfig(tSkill.nTargetAutoSearchID) or getAutoSearchConfig())
    else
        this.doDisableSearch(kSponserQte)
    end
end

---comment 获取搜索半径（米）
---@return integer radius 半径（米）
function TargetMgr.GetSearchRadius()
    return this.tSearchConfig and this.tSearchConfig.nDistance or 20
end

---comment 当前没有目标，则尝试自动选择一个
---@param nSkillID integer 目标技能ID
---@return boolean bSelected 是否成功选择了目标
function TargetMgr.TrySelectOneTarget(nSkillID)
    local hPlayer = g_pClientPlayer
    if not this.IsAutoTab() or not nSkillID then
        return false        -- 禁止自动索敌
    end

    if this.tSearchConfig.bIsHD then
        local nLevel = hPlayer.GetSkillLevel(nSkillID)
        nLevel = math.max(1, nLevel)
        local skill = GetSkill(nSkillID,nLevel)
        return Skill_AutoSearchEnemyInJoystick(hPlayer, this.tSelect.nTargetID, skill, nSkillID, nLevel)
    end

    local nCurTarget = this.tSelect.nTargetID
    if not nSkillID then
        if nCurTarget ~= 0 then
            return false    -- 已有目标
        end

        this.SearchNextTarget()
        return this.tSelect.nTargetID ~= 0
    end

    local tSkillConfig = TabHelper.GetUISkillMap(nSkillID) or
            SkillData.GetUIDynamicSkillMap(nSkillID, math.max(1, hPlayer.GetSkillLevel(nSkillID)))
    if tSkillConfig and tSkillConfig.bForbidSelectTarget then
        return false        -- 禁止自动索敌
    end
    if not tSkillConfig.bDynamicSkill and not this.tSearchConfig.bEnemy then
        return false        -- 治疗心法不主动选择目标
    end

    if nCurTarget ~= 0 then
        if tSkillConfig.bDynamicSkill or not this.tSearchConfig or not this.tSearchConfig.nLockedDistance then
            return false    -- 动态技能栏不重新选目标
        end

        if this.tSelect.nTargetType ~= TARGET.PLAYER and this.tSelect.nTargetType ~= TARGET.NPC then
            return false    -- 非角色类型目标
        end

        local pCharacter = Global.GetCharacter(nCurTarget)
        if not pCharacter then
            return false    -- 获取目标对象失败
        end

        local nX1, nY1, nZ1 = pCharacter.GetAbsoluteCoordinate()
        local nX2, nY2, nZ2 = hPlayer.GetAbsoluteCoordinate()
        local nDis = kmath.metre_len(nX2 - nX1, nY2 - nY1, nZ2 - nZ1)
        if nDis < this.tSearchConfig.nLockedDistance then
            return false    -- 目标距离不够远
        end
    end

    local nMaxDistance = hPlayer.GetSkillMaxRadius(nSkillID, 1) - 0.2 / Const.kMetreLength  -- 减少一定距离避免可能释放失败
    if tSkillConfig and tSkillConfig.nUIRadius and tSkillConfig.nUIRadius > 0 then                  -- 使用UI指定的滑选半径
        nMaxDistance = math.min(nMaxDistance, tSkillConfig.nUIRadius / Const.kMetreLength)
    end

    local nBackup = GetSearchMaxRadius()
    if nMaxDistance > 0 then
        SetSearchMaxRadius(nMaxDistance)
    end
    this.SearchNextTarget()
    SetSearchMaxRadius(nBackup)
    return this.tSelect.nTargetID ~= 0 and this.tSelect.nTargetID ~= nCurTarget
end

---comment 选择选中下一个目标
---@return integer
function TargetMgr.SearchNextTarget()
    if this.tSearchConfig.bEnemy then
        SearchEnemy()
    else
        SearchAllies()
    end
end

function TargetMgr.SelectSelf()
    if not g_pClientPlayer then
        return  -- 还没有进入场景
    end

    this.doSelectTarget(g_pClientPlayer.dwID, TARGET.PLAYER)
end

function TargetMgr.Scene_SetAutoSearch(bAutoSearch, nX, nY)
    bEnableAutoSerach = bAutoSearch
    if bEnableAutoSerach then
        if nX and nY then

            local tPos = cc.Director:getInstance():convertToGL({ x = nX, y = nY })
            local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
            _nSearchX = tPos.x * nScaleX
            _nSearchY = tPos.y * nScaleY

            -- Scene_StartSelectedObjsXY(_nSearchX, _nSearchY)--看起来手游好像用不了？
            this.StartAutoSearch()
        end
    else
        -- Scene_EndSelectedObjsXY()
        this.StopAutoSearch()
    end
end

function TargetMgr.doEnableSearch(szSponsor, tSearchConfig)
    local tConfig, nIndex = table.find_if(this.tSponsorList, function(t)
        return t[1] == szSponsor
    end)
    if tConfig then
        tConfig[2] = tSearchConfig
    else
        nIndex = 1
        tConfig = { szSponsor, tSearchConfig }
        table.insert(this.tSponsorList, nIndex, tConfig)
    end

    if nIndex == 1 then                                 -- 更新当前索敌配置
        this.bEnableSearch = not tSearchConfig.bDisableSearch
        this.tSearchConfig = tSearchConfig
    end
end

function TargetMgr.doDisableSearch(szSponsor)
    local _, nIndex = table.find_if(this.tSponsorList, function(t) return t[1] == szSponsor end)
    if not nIndex then
        return
    end

    table.remove(this.tSponsorList, nIndex)

    if #this.tSponsorList > 0 then
        this.tSearchConfig = this.tSponsorList[1][2]        -- 切换新的搜索配置
        this.bEnableSearch = not this.tSearchConfig.bDisableSearch
    else
        this.tSearchConfig = nil
        this.bEnableSearch = false
        this.doSelectTarget(0, TARGET.NO_TARGET)
    end
end

function TargetMgr.ManualSelect(nType, nID)
    if not g_pClientPlayer then
        return  -- 还没有进入场景
    end

    local nTargetType, nTargetID = TARGET.NO_TARGET, 0
    if CanSelectTarget(nType, nID) then
        nTargetType, nTargetID = nType, nID
    end

    this.doSelectTarget(nTargetID, nTargetType)
end

local function auto_searchxy(x, y)
    local _tSelectObject = Scene_SelectObjectsX3D(x, y)
    if not _tSelectObject then
        return
    end

    for nIndex = #_tSelectObject, 1, -1 do--排除掉不可选中的物体
        local dwObjType, dwObjID = _tSelectObject[nIndex]["Type"],  _tSelectObject[nIndex]["ID"]
        if not CanSelectTarget(dwObjType, dwObjID) then
            table.remove(_tSelectObject, nIndex)
        end
    end

    dwObjType, dwObjID = GetFitObject(_tSelectObject)
    dwObjType = dwObjType or TARGET.NO_TARGET
    dwObjID = dwObjID or 0

    return dwObjType, dwObjID
end

local function auto_search(x, y)
    --[[
    local tNextPos =
    {
        [1] = {-2, 0},
        [2] = {0, -2},
        [3] = {2, 0},
        [4] = {0, 2},
    }]]

    local dwObjType, dwObjID = auto_searchxy(x, y)
    if dwObjType ~= TARGET.NO_TARGET then
        FireUIEvent("HOVER_ON_MODEL", dwObjType, dwObjID)
    else
        FireUIEvent("HOVER_ON_MODEL", nil, nil)
    end
end

function TargetMgr.StartAutoSearch()
    this.StopAutoSearch()
    this.nASTimer = Timer.AddFrameCycle(this, 2, function()
        if bEnableAutoSerach then
            auto_search(_nSearchX, _nSearchY)
        end
    end)
end

function TargetMgr.StopAutoSearch()
    if this.nASTimer then
        Timer.DelTimer(this, this.nASTimer)
        this.nASTimer = nil
    end
end

function TargetMgr.onTouchMove(x, y)
    local nDeltaX = math.abs(this.tTouch.nX - x)
    local nDeltaY = math.abs(this.tTouch.nY - y)
    if nDeltaX > 0 or nDeltaY > 0 then
        this.tTouch.bHasMoved = true
    end

--    LOG("TargetMgr.onTouchMove (x:%s, y:%s)", tostring(x), tostring(y))
end

function TargetMgr.onTouchEnded(x, y)
    local bLastLDown = this.bLDown
    local bLastRDown = this.bRDown
    this.bLDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_LEFT)
    this.bRDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_RIGHT)

    if not g_pClientPlayer then
        return  -- 还没有进入场景
    end

--    LOG("TargetMgr.onTouchEnded(x:%s, y:%s)", tostring(x), tostring(y))

    local nDeltaX = math.abs(this.tTouch.nX - x)
    local nDeltaY = math.abs(this.tTouch.nY - y)

    if Platform.IsWindows() or Platform.IsMac() then
        if this.tTouch.bHasMoved then
            return  -- 电脑端若曾经移动过则不认为是点击事件
        end
        if this.bBothDown then
            return  -- 电脑端左右键一起点击则不认为是点击事件
        end
    else
        if nDeltaX > 10 or nDeltaY > 10 then
            return  -- 移动平台点击有位移则不认为是点击事件
        end
    end

    local bLButtonUp = bLastLDown and not this.bLDown
    local bRButtonUp = bLastRDown and not this.bRDown
    if not this.tTouch.bHasMoved then
        Event.Dispatch(EventType.OnSceneTouchWithoutMove, bLButtonUp, bRButtonUp)
    end

    local tPos = cc.Director:getInstance():convertToGL({ x = x, y = y })
    local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
    local tSelectObject = Scene_SelectObjectsX3D(tPos.x * nScaleX, tPos.y * nScaleY)
    local nTargetType, nTargetID = TARGET.NO_TARGET, 0

    --选择可选择目标
    for _, obj in pairs(tSelectObject or {}) do
        if CanSelectTarget(obj.Type, obj.ID) then
            nTargetType, nTargetID = obj.Type, obj.ID
            break
        end
    end

    --若无可选择目标且点击右键，则选择第一个目标
    if nTargetType == TARGET.NO_TARGET and nTargetID == 0 and bRButtonUp then
        for _, obj in pairs(tSelectObject or {}) do
            nTargetType, nTargetID = obj.Type, obj.ID
            break
        end
    end

    if nTargetType == TARGET.PLAYER or nTargetType == TARGET.NPC then
        local pTarget = Global.GetCharacter(nTargetID)
        if pTarget then
            if nTargetType == TARGET.PLAYER then
                LOG.INFO("选择目标, playerID:%s, playerName:%s", pTarget.dwID, GBKToUTF8(pTarget.szName))
            elseif nTargetType == TARGET.NPC then
                LOG.INFO("选择目标, npcID:%s npcTemplateID:%s, npcName:%s", pTarget.dwID, pTarget.dwTemplateID, GBKToUTF8(pTarget.szName))
            end
        end
        Event.Dispatch(EventType.OnSceneTouchTarget, nTargetID)   -- 点击XXX
    elseif nTargetType == TARGET.FURNITURE then
        InteractLandObject(nTargetID)
    else
        Event.Dispatch(EventType.OnSceneTouchNothing)   -- 点击空白区域
    end

    local bCanSelectTarget = true
    for nViewID, _ in pairs(_tBlackListViewIDForSelectTarget) do
        if UIMgr.IsViewOpened(nViewID) then
            bCanSelectTarget = false
            break
        end
    end

    if nTargetType == TARGET.FURNITURE then
        bCanSelectTarget = false
    end

    if SelfieData.IsInStudioMap() then
        if nTargetType == TARGET.PLAYER then
            local pTarget = Global.GetCharacter(nTargetID)
            if pTarget then
                bCanSelectTarget = TeamData.IsPlayerInTeam(pTarget.dwID)
            end
        end
    end

    if OBDungeonData.IsPlayerInOBDungeon() then
        if nTargetType ~= TARGET.NPC then
            return -- 需要完全吞噬，禁止直接从屏幕改变选中状态
        end
    end

    if bCanSelectTarget then
        if bLButtonUp then
            --左键
            this.doSelectTarget(nTargetID, nTargetType)
        elseif bRButtonUp then
            --右键
            this.doInteractAction(nTargetID, nTargetType)
        end
    end
end

local function OnTargetSelectionShowSFX(player, dwTargetID, dwType, dwLevel)
    local nForceRelationType = 0
    local nBuffCount = 0
    if dwType == TARGET.PLAYER then
        if dwLevel then
            nBuffCount = dwLevel
        else
            local hPlayer = GetPlayer(dwTargetID)
            if hPlayer then
                local hBuff = hPlayer.GetBuff(DAOZONG_BUFF_ID, 0)
                if hBuff then
                    nBuffCount = hBuff.nLevel
                end
            end
        end
        nForceRelationType = GetRelation(player.dwID, dwTargetID)
    else
        if dwLevel then
            nBuffCount = dwLevel
        else
            local hNpc = GetNpc(dwTargetID)
            if hNpc then
                local hBuff = hNpc.GetBuff(DAOZONG_BUFF_ID, 0)
                if hBuff then
                    nBuffCount = hBuff.nLevel
                end
            end
        end
        nForceRelationType = GetRelation(dwTargetID, player.dwID)
    end
    TargetSelection_ShowSFX(nForceRelationType, nBuffCount) --根据势力修改光圈的颜色
end

-- 角色选择的目标更新
function TargetMgr.onUpdateSelectTarget()
    local player = g_pClientPlayer
    local dwTargetType, dwTargetID = player.GetTarget()

    if dwTargetID ~= this.tSelect.nTargetID or dwTargetType ~= this.tSelect.nTargetType then
        this.onSelectTarget(dwTargetID, dwTargetType)
    end

    -- 无目标默认选自己
    if dwTargetID == 0 and this.bEnableSearch and this.tSearchConfig.bDefaultSelectSelf then
        SetTarget(TARGET.PLAYER, g_pClientPlayer.dwID)
    end

    if dwTargetType == TARGET.NPC then --清明节活动自动射箭
        local bTarget, dwSkillID = GDAPI_CheckTargetAutoSkill(player, dwTargetType, dwTargetID)
        if bTarget then
            OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
        end
    end
end

---comment 获取自动索敌配置
---@return _TargetAutoSearchTab
function getAutoSearchConfig()
    local dwSchoolID = g_pClientPlayer.dwSchoolID
    local nKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    local bIsHDKungFu = nKungFuID and TabHelper.IsHDKungfuID(nKungFuID)
    local tSearchInfo = tAutoSearchTab[dwSchoolID] and tAutoSearchTab[dwSchoolID][nKungFuID]
    if not tSearchInfo and bIsHDKungFu then
        return {
            bIsHD = true,
            bEnemy = true,
            nFov = 360,
            nDistance = 20,
            nHeightDiff = 20,
            nLockedDistance = 30
        }
    end

    if tSearchInfo then
        tSearchInfo.bIsHD = bIsHDKungFu
    end
    return tSearchInfo or { bDisableSearch = true, nDistance = 20 }
end

---comment 获取QTE索敌配置
---@return _TargetAutoSearchTab
function getQteSearchConfig(nKungFuID)
    return nKungFuID and tAutoSearchTab[kQteForceID] and tAutoSearchTab[kQteForceID][nKungFuID] or
            getAutoSearchConfig()
end

function TargetMgr.onSelectTarget(nSelectID, nTargetType)
    local tSelect = this.tSelect
    local nPrevID, nPrevType = tSelect.nTargetID, tSelect.nTargetType
    tSelect.nTargetID, tSelect.nTargetType = nSelectID, nTargetType

    if this.bAttention then
        if nSelectID ~= 0 and nTargetType == TARGET.PLAYER or nTargetType == TARGET.NPC then
            CameraMgr.LockTarget(nSelectID)
        else
            local bAutoLock = GameSettingData.GetNewValue(UISettingKey.LockOnSwitchTargetWhenLocked)
            if not bAutoLock then
                this.bAttention = false -- 目标丢失解除注视
            end
            CameraMgr.LockTarget(0)
        end
    end

    Event.Dispatch("OnTargetChanged", nTargetType, nSelectID)
    Event.Dispatch(EventType.OnSearchTargetChanged, nSelectID)
    -- 教学 选择目标
    FireHelpEvent("OnSelectTarget", nTargetType, nSelectID)

    -- 更新目标特效
    if nPrevID ~= nSelectID or nPrevType ~= nTargetType then
        TargetSelection_DetachSceneObject(nPrevID, nPrevType)

        if nTargetType == TARGET.PLAYER or nTargetType == TARGET.NPC then
            --给选中的目标加脚底光圈
            TargetSelection_AttachSceneObject(nSelectID, nTargetType) --增加一个光圈特效
            SceneObject_SetBrightness(nTargetType, nSelectID, 1)      --修改光圈的亮度，也就是alpha
            OnTargetSelectionShowSFX(g_pClientPlayer, nSelectID, nTargetType)
        else
            --TargetSelection_AttachSceneObject(0, 0)
            TargetSelection_HideSFX()
        end
    end
end

---comment 选中目标
---@param nSelectID number 目标ID
---@param nType number 目标类型
function TargetMgr.doSelectTarget(dwObjID, dwObjType)
    if dwObjID == this.tSelect.nTargetID and dwObjType == this.tSelect.nTargetType then
        return
    end

    if dwObjType == TARGET.FURNITURE then
        return
    end

    local bCanSelectTarget = true
    if SelfieData.IsInStudioMap() then
        if dwObjType == TARGET.PLAYER then
            local pTarget = Global.GetCharacter(dwObjID)
            if pTarget then
                bCanSelectTarget = TeamData.IsPlayerInTeam(pTarget.dwID)
            end
        end
    end

    if not bCanSelectTarget then
        return
    end

    SetTarget(dwObjType, dwObjID)

    -- 调试信息
    if dwObjType == TARGET.PLAYER or dwObjType == TARGET.NPC then
        local pTarget = Global.GetCharacter(dwObjID)
        if pTarget then
            if dwObjType == TARGET.PLAYER then
                LOG.INFO("选择目标, playerID:%s, playerName:%s", pTarget.dwID, GBKToUTF8(pTarget.szName))
            elseif dwObjType == TARGET.NPC then
                LOG.INFO("选择目标, npcID:%s npcTemplateID:%s, npcName:%s", pTarget.dwID, pTarget.dwTemplateID, GBKToUTF8(pTarget.szName))
            end
        end
    end
end

function TargetMgr.doInteractAction(dwObjID, dwObjType)
    local hPlayer = g_pClientPlayer
    TargetMgr.bInteracted = false
    if dwObjType ~= TARGET.NO_TARGET then
        --对doodad、家园物件或dummy物件进行操作时不切换目标。
        if dwObjType ~= TARGET.DOODAD and dwObjType ~= TARGET.FURNITURE and dwObjType ~= TARGET.DUMMY then
            SelectTarget(dwObjType, dwObjID)
        end

        Event.Dispatch(EventType.OnRightButtonInteract, dwObjID, dwObjType) --这里如果交互成功会将TargetMgr.bInteracted设为true

        if not TargetMgr.bInteracted then --右键攻击
            local bCanInteractive = true
            if dwObjType == TARGET.NPC and not PartnerData.CheckPartnerInteractive(dwObjID) then
                --- 若是NPC，且不符合侠客交互的条件，则不允许交互
                bCanInteractive = false
            end

            if bCanInteractive then
                if InteractTarget(dwObjType, dwObjID) then
                    TargetMgr.bInteracted = false
                end
            end
        end

        if not TargetMgr.bInteracted then --右键攻击
            if IsEnemy(hPlayer.dwID, dwObjID) then
                SprintData.SetViewState(false)
                if SkillData.IsUsingHDKungFu() then
                    local dwSkillID = hPlayer.GetCommonSkill(true)
                    if dwSkillID ~= 0 then
                        SkillData.CastSkill(hPlayer, dwSkillID)
                    end
                else
                    Event.Dispatch(EventType.OnShortcutUseSkillSelect, 1, 1)
                    Event.Dispatch(EventType.OnShortcutUseSkillSelect, 1, 3)
                end
            end
        end
    end
end

function TargetMgr.onKungfuChanged()
    --TODO: 如果有动态技能栏引用角色的本身的索敌配置，则这里是否需要一起更新？

    local tSponsor, nIndex = table.find_if(this.tSponsorList, function(t)
        return t[1] == kSponserMain
    end)
    if not tSponsor then
        return
    end

    local tSearchConfig = getAutoSearchConfig()
    tSponsor[2] = tSearchConfig
    if nIndex == 1 then
        this.tSearchConfig = tSearchConfig
        this.bEnableSearch = not tSearchConfig.bDisableSearch
    end
end

function TargetMgr.setupVars()
    this.bEnableSearch = false          -- 是否开启自动索敌
    this.bAutoTarget = true             -- 自动选择目标, 当前无目标时，玩家被击或是命中别人则自动选择对方为目标
    this.bAttention = false             -- 镜头是否注视目标

    this.tSelect = {                    -- 当前选中的目标（KPlayer.SelectTarget，服务器确认过的）
        nTargetType = 0,
        nTargetID = 0,
    }
    this.tManualSelect = {              -- 手动选择的目标
        nTargetType = 0,
        nTargetID = 0,
    }

    this.tTouch = { nX = 0, nY = 0, nTime = 0, bHasMoved = false }
    this.tSponsorList = {}          -- 发起开关方列表，支持多个模块开启自动索敌
    this.tSearchConfig = nil        ---@type _TargetAutoSearchTab

    this.bSearchTargetLocked = false  -- 是否被远程命令锁定目标
end

function TargetMgr.registerEvents()
    Event.Reg(this, "SET_MAIN_PLAYER", function(nPlayerID)
        if nPlayerID ~= 0 then
            -- 2022.12.06, 蕉说不要显示箭头
            -- 隐藏选中角色面向箭头
            -- 2023.06.27, 改为由系统设置界面控制
            --rlcmd("enable selection arrow 0 0")
            this.tSearchConfig = getAutoSearchConfig()
            this.EnableMainSearch(true)--索敌常驻
        else
            Timer.DelAllTimer(this)
            this.Attention(false)
            this.setupVars()
        end
    end)

    Event.Reg(this, "SKILL_MOUNT_KUNG_FU", this.onKungfuChanged)
    Event.Reg(this, "SKILL_UNMOUNT_KUNG_FU", this.onKungfuChanged)

    Event.Reg(this, EventType.OnSceneTouchBegan, function(x, y)
        this.tTouch.nX = x
        this.tTouch.nY = y
        this.tTouch.nTime = 0       -- 一定时间范围内的操作才会被当做点击
        this.tTouch.bHasMoved = false

        this.bLDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_LEFT)
        this.bRDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_RIGHT)

        --左右键一起按时，标记一下，不选目标
        this.bBothDown = this.bLDown and this.bRDown
    end)
    Event.Reg(this, EventType.OnSceneTouchEnded, this.onTouchEnded)
    Event.Reg(this, EventType.OnSceneTouchMoved, this.onTouchMove)
    Event.Reg(this, "UPDATE_SELECT_TARGET", this.onUpdateSelectTarget)
    Event.Reg(this, "ON_SWITCH_SELECT_TARGET", function ()
        LOG.INFO("ON_SWITCH_SELECT_TARGET %s %s", tostring(arg0), tostring(arg1))

        if this.bAutoTarget and this.IsAutoTab() then
            -- hack: 这里之前是启用自动索敌，或者当前没有选中目标的时候，尝试自动选中C++发过来的选择目标
            --      但是部分玩法里，会导致vk端未选择目标和已选中非敌对目标的情况下，都尝试自动选中敌对目标
            --      而dx端仅在未选择目标的情况下会触发这种情况
            --      为了确保两边一致，在vk的lua端再判断一次，仅在未选择目标的情况下自动选中敌对目标
            --if this.tSearchConfig.bEnemy or this.tSelect.nTargetID == 0 then
            if this.tSearchConfig.bEnemy and this.tSelect.nTargetID == 0 then
                SelectTarget(arg0, arg1)
            end
        end
    end)

    Event.Reg(this, "SCENE_BEGIN_LOAD", function ()
        Event.Dispatch(EventType.OnTargetChanged, TARGET.NO_TARGET, 0)
    end)
    Event.Reg(this, "SYS_MSG", function(szType, dwCharacterID)
        if g_pClientPlayer and g_pClientPlayer.bFightState and
            this.tSearchConfig and this.tSearchConfig.bEnemy and
            szType == "UI_OME_DEATH_NOTIFY" and this.tSelect.nTargetID == dwCharacterID then
            -- 战斗状态下当前目标死亡，则清除目标
            SelectTarget(TARGET.NO_TARGET, 0)
        end
    end)

    Event.Reg(this, "PLAYER_LEAVE_SCENE", function (nPlayerID)
        if this.tSelect and nPlayerID == this.tSelect.nTargetID then
            SelectTarget(TARGET.NO_TARGET, 0)
        end
    end)

    Event.Reg(this, EventType.On_PQ_RequestDataReturn, function ()
        if this.bAttention and PublicQuestData.IsInCampPQ() then
            this.Attention(false)
            Event.Dispatch(EventType.OnSearchTargetChanged, this.GetSelect())
        end
    end)

    Event.Reg(this, EventType.OnAccountLogout, function()
        TargetMgr.ResumeSearchTargetLock()
    end)

    Event.Reg(this, EventType.UILoadingStart, function()
        TargetMgr.ResumeSearchTargetLock()
    end)
end
