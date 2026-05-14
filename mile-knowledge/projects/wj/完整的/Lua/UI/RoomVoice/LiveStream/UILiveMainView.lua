-- ---------------------------------------------------------------------------------
-- Author: KSG
-- Name: UILiveMainView
-- Date: 2026-03-23
-- Desc: 副本观战 - 主面板（挂载在 PanelFBShow 根节点）
-- ---------------------------------------------------------------------------------

local UILiveMainView = class("UILiveMainView")

local MAX_CAST_SKILL = 10       -- 施法历史最大显示条数
local MAX_OB_COUNT = 100        -- 最大观战人数
local MAX_SKILL_CD_NUM = 10     -- 最多显示的技能CD数
local DOUBLE_CLICK_INTERVAL = 1000 -- 双击触发间隔（毫秒）

--local m_tCastSkill = {}       -- 旧白名单（已废弃）
local m_tCastSkillBlackList = {
	[10] = true,    -- (10)    横扫千军           横扫千军
	[11] = true,    -- (11)    普通攻击-棍攻击     六合棍
	[12] = true,    -- (12)    普通攻击-枪攻击     梅花枪法
	[13] = true,    -- (13)    普通攻击-剑攻击     三柴剑法
	[14] = true,    -- (14)    普通攻击-拳套攻击   长拳
	[15] = true,    -- (15)    普通攻击-双兵攻击   连环双刀
	[16] = true,    -- (16)    普通攻击-笔攻击     判官笔法
	[1795] = true,  -- (1795)  普通攻击-重剑攻击   四季剑法
	[2183] = true,  -- (2183)  普通攻击-虫笛攻击   大荒笛法
	[3121] = true,  -- (3121)  普通攻击-弓攻击     罡风镖法
	[4326] = true,  -- (4326)  普通攻击-双刀攻击   大漠刀法
	[13039] = true, -- (13039) 普通攻击_盾刀攻击   卷雪刀
	[14063] = true, -- (14063) 普通攻击_琴攻击     五音六律
	[16010] = true, -- (16010) 普通攻击_傲霜刀攻击  霜风刀法
	[19712] = true, -- (19712) 普通攻击_蓬莱伞攻击  飘遥伞击
	[22126] = true, -- (22126) 普通攻击-碎风刃     碎风刃
	[31636] = true, -- (31636) 普通攻击-云刀       云刀
	[38034] = true, -- (38034) 普通攻击-云合扇法   云合扇法
	[17] = true,    -- (17)    江湖-防身武艺-打坐  打坐
	[18] = true,    -- (18)    踏云               踏云
	[21017] = true, -- (21017) 双人同骑           双人同骑 
	[21018] = true, -- (21018) 双人同骑           双人同骑 
	-- [21023] = true, -- (21023) 双人同骑           双人同骑 
	-- [21024] = true, -- (21024) 双人同骑           双人同骑
}

local function CanRecordCastSkill(dwSkillID, dwLevel)
    if m_tCastSkillBlackList[dwSkillID] then
        return false
    end

    local dwIconID = Table_GetSkillIconID(dwSkillID, dwLevel)
    local szSkillName = Table_GetSkillName(dwSkillID, dwLevel)
    if dwSkillID == 4097 then -- 跳跃
        dwIconID = 1899
    end
    if not szSkillName or szSkillName == "" then
        return
    end
    -- 过滤图标类技能（轻功、冲刺等）
    if dwIconID == 1817 --[[轻功]] or dwIconID == 533 --[[冲刺]] or dwIconID == 0 --[[加速]] or dwIconID == 13 --[[加速]] then
        return
    end
    -- 过滤阵眼技能和阵法技能
    if Table_IsSkillFormation(dwSkillID, dwLevel) or Table_IsSkillFormationCaster(dwSkillID, dwLevel) then
        return
    end
    return true
end

function UILiveMainView:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end

    self.dwSelectPlayerID = nil
    self.tPlayerCastSkill = {}           -- dwPlayerID → { {dwSkillID, dwLevel}, ... }
    self.tSkillData = {}                 -- dwPlayerID → { [dwSkillID] = {dwSkillID, dwTrueSkillID, dwSkillLevel, nIndex} }
    self.tCDScripts = {}                 -- 当前 CD 列表 WidgetNormalSkill 脚本缓存
    self.tbDalayShowTips = {}            -- 打赏通知队列
    self.bIsShowingTip = false
    self.nLastClickTime = nil            -- 上次场景点击时间（用于双击判定）
    self.nLastClickTargetID = nil        -- 上次场景点击的玩家ID

    self:InitView()

    -- 子节点 bFirstOnEnter=false，需手动获取脚本并调用 OnEnter
    -- 顺序要求：PlayerInfo 先注册事件，TeamMember 后初始化（会自动选中首成员并 Dispatch 事件）
    local scriptPlayerInfo = UIHelper.GetBindScript(self.WidgetCurrentPlayerInfo)
    if scriptPlayerInfo then
        scriptPlayerInfo:OnEnter()
    end

    local scriptTeam = UIHelper.GetBindScript(self.WidgetLeft)
    if scriptTeam then
        scriptTeam:OnEnter()
    end

    self.scriptJoyStick = self.scriptJoyStick or UIHelper.AddPrefab(PREFAB_ID.WidgetPerfabJoystick, self.WidgetJoystick)
    self:UpdateJoystickVisible()

    self.scriptChat = self.scriptChat or UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityMiniChat1, self.WidgetChatMainCityMini)
    if self.scriptChat then
        UIHelper.SetSwallowTouches(self.scriptChat.BtnContent, true)
    end

    Timer.AddCycle(self, 3, function()
        UpdatePartyMark(false)
    end)

    SetForbidSelectPlayer(true)
    UIHelper.HideInteract()
    -- InputHelper.LockKeyBoard(true) -- 会影响镜头缩放

    -- OB 模式下隐藏召唤物头顶名字
    ShowEmployeeCaption("name", false)
    -- OB 模式下隐藏自身头顶全部标识
    local ctrl = RLEnv.GetLowerVisibleCtrl()
    for _, nType in pairs(HEAD_FLAG_TYPE) do
        ctrl:ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, nType, false)
    end
    -- OB 模式下关闭目标连线
    rlcmd("set target sfx connection 1 0 0 0")

    -- OB 模式下禁止轻功
    Hotkey_EnableSprint(false)
end

function UILiveMainView:OnExit()
    self.bInit = false
    SetForbidSelectPlayer(false)
    UIHelper.ShowInteract()
    CameraMgr.CamaraReset()
    -- InputHelper.LockKeyBoard(false)

    -- 恢复召唤物头顶名字显示（按用户设置还原）
    local bShowSummonName = GameSettingData.GetNewValue(UISettingKey.ShowSummonName)
    if bShowSummonName == nil then bShowSummonName = true end
    ShowEmployeeCaption("name", bShowSummonName)

    -- 恢复自身头顶全部标识（按用户设置还原）
    local ctrl = RLEnv.GetLowerVisibleCtrl()
    local bShowSelfName = GameSettingData.GetNewValue(UISettingKey.ShowSelfName)
    if bShowSelfName == nil then bShowSelfName = true end
    ctrl:ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.NAME, bShowSelfName)
    local bShowSelfLife = GameSettingData.GetNewValue(UISettingKey.ShowSelfHealthBar)
    if bShowSelfLife == nil then bShowSelfLife = false end
    ctrl:ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.LIFE, bShowSelfLife)
    local bShowSelfTitle = GameSettingData.GetNewValue(UISettingKey.ShowSelfTitle)
    if bShowSelfTitle == nil then bShowSelfTitle = true end
    ctrl:ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.TITLE, bShowSelfTitle)
    local bShowSelfGuild = GameSettingData.GetNewValue(UISettingKey.ShowSelfGuildName)
    if bShowSelfGuild == nil then bShowSelfGuild = false end
    ctrl:ShowHeadFlag(HEAD_FLAG_OBJ.CLIENTPLAYER, HEAD_FLAG_TYPE.GUILD, bShowSelfGuild)

    -- 恢复轻功
    Hotkey_EnableSprint(true)

    self.tCDScripts = nil

    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function UILiveMainView:BindUIEvent()
    -- 关闭按钮（二次确认）
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIHelper.ShowConfirm(g_tStrings.STR_LEAVE_OBDUNGEON_ESC_MESSAGE, function()
            self:DoClose()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnSet, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelGameSettings)
    end)

    UIHelper.BindUIEvent(self.BtnTopView, EventType.OnClick, function(btn)
        if CameraMgr.bFreeView then
            TipsHelper.ShowNormalTip("当前已在全局视角中")
            return
        end

        -- 切换到自由视角，清空当前选中玩家
        TargetMgr.ManualSelect(nil, nil)
        RemoteCallToServer("On_Dungeon_WatchAll")
    end)

    -- 打赏选中玩家
    if self.BtnReward then
        UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function()
            self:OnClickReward()
        end)
    end

    -- 打赏全团
    if self.BtnTeamReward then
        UIHelper.BindUIEvent(self.BtnTeamReward, EventType.OnClick, function()
            self:OnClickTeamReward()
        end)
    end
end

function UILiveMainView:RegEvent()
    -- 回车键打开聊天（OB模式下切换到弹幕频道）
    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode)
        if nKeyCode == cc.KeyCode.KEY_ENTER then
            if not UIMgr.IsViewOpened(VIEW_ID.PanelChatSocial) then
                ChatData.SetSendChannelID(nil, PLAYER_TALK_CHANNEL.DUNGEON_BULLET_SCREEN)
                ChatHelper.Chat()
            end
        end
    end)

    -- 选中玩家变化（来自 UILiveRaidTeamMember）
    Event.Reg(self, EventType.ON_OB_SELECT_PLAYER_CHANGED, function(dwPlayerID)
        if dwPlayerID == self.dwSelectPlayerID then return end
        self:OnSelectPlayerChanged(dwPlayerID)
    end)

    Event.Reg(self, EventType.OnTargetChanged, function(...)
        self:OnTargetChanged(...)
    end)

    -- OB模式下双击场景中的参战玩家，切换到该玩家的跟随视角
    Event.Reg(self, EventType.OnSceneTouchTarget, function(nTargetID)
        if not nTargetID then return end
        if not OBDungeonData.GetDungeonCompetitor(nTargetID) then return end

        local nCurTime = GetTickCount()
        local bDoubleClick = self.nLastClickTargetID == nTargetID
            and self.nLastClickTime
            and (nCurTime - self.nLastClickTime) < DOUBLE_CLICK_INTERVAL
        self.nLastClickTime = nCurTime
        self.nLastClickTargetID = nTargetID
        if bDoubleClick and nTargetID ~= self.dwSelectPlayerID then
            -- 切换视角CD：3秒
            if self.nLastSwitchViewTime and nCurTime - self.nLastSwitchViewTime < 3000 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_OBDUNGEON_KICKOUT_OB_TIP)
                return
            end
            self.nLastSwitchViewTime = nCurTime
            RemoteCallToServer("On_Dungeon_WatchPlayer", nTargetID)
        end
    end)

    -- 团队信息变化 → 刷新选中玩家血量 + 观众人数
    Event.Reg(self, EventType.ON_DUNGEON_OB_COMPETITOR_VARIABLE_INFO_UPDATE_UI, function()
        self:UpdateSelectPlayerInfo()
        self:UpdateViewerCount()
    end)

    -- Event.Reg(self, "PLAYER_LEAVE_SCENE", function(dwPlayerID)
    --     if self.dwSelectPlayerID ~= dwPlayerID then
    --         return
    --     end

    --     OBDungeonData.OnSetView(nil)
    --     Timer.Add(self, 1, function()
    --         if not self.bInit then return end
    --         print("触发了一次")
    --         -- 验证：只有当前仍选中该玩家时才尝试恢复，避免用户已切换目标后被覆盖
    --         if self.dwSelectPlayerID ~= dwPlayerID then return end
    --         if not OBDungeonData.GetDungeonCompetitor(dwPlayerID) then return end
    --         OBDungeonData.OnSetView(dwPlayerID)
    --     end)
    -- end)

    -- 地图加载完成 → 检查是否仍在 OB 状态
    Event.Reg(self, "LOADING_END", function()
        if not self.bInit then return end
        local player = GetClientPlayer()
        if player and not player.bOBFlag then
            self:DoClose()
        end
    end)

    Event.Reg(self, "DO_SKILL_CAST", function(dwCaster, dwSkillID, dwLevel)
        if dwCaster and dwSkillID then
            self:OnSkillCast(dwCaster, dwSkillID, dwLevel, false)
        end
    end)

    Event.Reg(self, "DO_SKILL_HOARD_PROGRESS", function(nTotalFrame, dwSkillID, dwLevel, dwCasterID)
        if dwCasterID and dwSkillID then
            self:OnSkillCast(dwCasterID, dwSkillID, dwLevel, false)
        end
    end)

    Event.Reg(self, "DO_SKILL_CHANNEL_PROGRESS", function(nTotalFrame, dwSkillID, dwLevel, dwCasterID)
        if dwCasterID and dwSkillID then
            self:OnSkillCast(dwCasterID, dwSkillID, dwLevel, false)
        end
    end)

    -- 技能CD通知 → 刷新CD列表
    Event.Reg(self, "ON_SKILL_CD_NOTIFY", function(dwPlayerID, tSkillOrID, dwTrueSkillID)
        if not dwPlayerID then return end
        if type(tSkillOrID) == "table" then
            self:OnSkillListCDNotify(dwPlayerID, tSkillOrID)
        else
            self:OnSkillCDNotify(dwPlayerID, tSkillOrID, dwTrueSkillID)
        end
    end)

    -- 打赏成功回调（自己打赏成功后播放特效）
    Event.Reg(self, EventType.OnTipsGiftSuccess, function(nType, nGold, nNum, szTargetName)
        if nType == TIP_TYPE.ObserveInstance or nType == TIP_TYPE.ObserveInstance_Team then
            self:OnTipNotify(nGold, nNum, nType, szTargetName)
        end
    end)
end

-- ----------------------------------------------------------
-- 界面初始化与数据更新
-- ----------------------------------------------------------

function UILiveMainView:InitView()
    -- 副本名称（通过 Table_GetMapName 查配置表，GetMapName() 在 MUI 不可用）
    if self.LabelTitle then
        local pScene = GetClientPlayer() and GetClientPlayer().GetScene()
        local szMapName = (pScene and Table_GetMapName(pScene.dwMapID)) or ""
        UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(szMapName))
    end

    -- 观众人数
    self:UpdateViewerCount()

    -- 隐藏选中玩家信息（未选中时）
    if self.WidgetCurrentPlayerInfo then
        UIHelper.SetVisible(self.WidgetCurrentPlayerInfo, false)
    end

    -- 隐藏打赏通知
    if self.WidgeGiftHint then
        UIHelper.SetVisible(self.WidgeGiftHint, false)
    end
    if self.GiftSFX then
        UIHelper.SetVisible(self.GiftSFX, false)
    end
end

-- 更新观众人数
function UILiveMainView:UpdateViewerCount()
    local nOBCount = 0
    local pScene = GetClientScene()
    if pScene then
        nOBCount = pScene.nDungeonOBMemberCount or 0
    end
    local szText = string.format("观战人数：%d/%d", nOBCount, MAX_OB_COUNT)
    if self.LabelAudienceNum then
        UIHelper.SetString(self.LabelAudienceNum, szText)
    end
end

-- 选中玩家变更
function UILiveMainView:OnSelectPlayerChanged(dwPlayerID)
    if dwPlayerID == self.dwSelectPlayerID then return end
    self.dwSelectPlayerID = dwPlayerID
    -- 停掉旧的CD刷新定时器，切换玩家后由 UpdateCDList 按需重启
    self:StopCDUpdateTimer()
    self:UpdateSelectPlayerInfo()
    self:UpdateSpellSkillList()
    self:UpdateCDList()
    self:UpdateJoystickVisible()
end

-- 刷新选中玩家信息
function UILiveMainView:UpdateSelectPlayerInfo()
    if not self.dwSelectPlayerID then
        if self.WidgetCurrentPlayerInfo then
            UIHelper.SetVisible(self.WidgetCurrentPlayerInfo, false)
        end
        return
    end

    local dwPlayerID, szName, llCurrentLife, llMaxLife, nTotalEquipScore, dwKungfuID, nMemberIndex
        = OBDungeonData.GetDungeonCompetitor(self.dwSelectPlayerID)
    if not dwPlayerID then
        if self.WidgetCurrentPlayerInfo then
            UIHelper.SetVisible(self.WidgetCurrentPlayerInfo, false)
        end
        return
    end

    if self.WidgetCurrentPlayerInfo then
        UIHelper.SetVisible(self.WidgetCurrentPlayerInfo, true)
    end
end

-- ----------------------------------------------------------
-- 施法历史记录
-- ----------------------------------------------------------

function UILiveMainView:OnSkillCast(dwCaster, dwSkillID, dwLevel, bFromCastLog)
    if not CanRecordCastSkill(dwSkillID, dwLevel) then
        return
    end

    self.tPlayerCastSkill[dwCaster] = self.tPlayerCastSkill[dwCaster] or {}
    table.insert(self.tPlayerCastSkill[dwCaster], {dwSkillID = dwSkillID, dwLevel = dwLevel or 1})

    if #self.tPlayerCastSkill[dwCaster] > MAX_CAST_SKILL then
        table.remove(self.tPlayerCastSkill[dwCaster], 1)
    end

    if dwCaster then
        self:UpdateSpellSkillList(dwCaster)
    end
end

function UILiveMainView:UpdateSpellSkillList(dwCaster)
    if not self.LayoutSpellSkill then return end

    local pRecentSkill = UIHelper.GetParent(self.LayoutSpellSkill)
    if not self.dwSelectPlayerID then
        UIHelper.SetVisible(pRecentSkill, false)
        return
    end

    UIHelper.SetVisible(pRecentSkill, true)
    local tSkillList = self.tPlayerCastSkill[self.dwSelectPlayerID]
    if not tSkillList or #tSkillList == 0 then
        UIHelper.SetVisible(self.LayoutSpellSkill, false)
        return
    end

    UIHelper.SetVisible(self.LayoutSpellSkill, true)
    UIHelper.RemoveAllChildren(self.LayoutSpellSkill)

    for i = #tSkillList, 1, -1 do
        local tSkill = tSkillList[i]
        local scriptDisplay = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillDisplay, self.LayoutSpellSkill)
        if scriptDisplay and scriptDisplay.WidgetContent then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, scriptDisplay.WidgetContent, tSkill.dwSkillID, tSkill.dwLevel)
            UIHelper.SetAnchorPoint(script._rootNode, 0.5, 0.5)
            UIHelper.UpdateMask(scriptDisplay.WidgetContent)
            -- 点击技能图标显示技能Tip
            local dwSkillID = tSkill.dwSkillID
            UIHelper.BindUIEvent(script.TogSkill, EventType.OnClick, function()
                if not self.dwSelectPlayerID then return end
                local dwPlayerID, szName, llCurrentLife, llMaxLife, nTotalEquipScore, dwKungfuID, nMemberIndex
                    = OBDungeonData.GetDungeonCompetitor(self.dwSelectPlayerID)

                local dwTrueSkillID = dwSkillID
                if not dwTrueSkillID then return end
                local player = GetPlayer(self.dwSelectPlayerID)
                local nSkillLevel = 1
                local tRecipe = SkillData.GetFinalRecipeList(dwTrueSkillID, player)
                local nFakeMijiIndex = nil
                if tRecipe then
                    for i = 1, #tRecipe do
                        if tRecipe[i].active then
                            nFakeMijiIndex = i
                        end
                    end
                end
                local tCursor = GetCursorPoint()
                local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(
                        PREFAB_ID.WidgetSkillInfoTips, tCursor.x, tCursor.y)
                if tipsScriptView then
                    if not nFakeMijiIndex then
                        tipsScriptView:SetForbidShowMiji(true)
                    end
                    local nCurrentSetID = player.GetTalentCurrentSet(player.dwForceID, dwKungfuID)
                    tipsScriptView.player = player
                    tipsScriptView:SetBtnVisible(false)
                    tipsScriptView:OnEnter(dwTrueSkillID, dwKungfuID, nCurrentSetID, nSkillLevel, nFakeMijiIndex, player)
                    UIHelper.SetVisible(tipsScriptView.WidgetSkillLock, false)
                end
            end)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutSpellSkill)
end

-- ----------------------------------------------------------
-- 技能CD列表
-- ----------------------------------------------------------

function UILiveMainView:OnSkillListCDNotify(dwPlayerID, tSkillList)
    -- 构建新的技能列表数据
    local tNewSkillData = {}
    local nCount = 0
    for _, dwSkillID in ipairs(tSkillList) do
        if nCount >= MAX_SKILL_CD_NUM then
            break
        end
        nCount = nCount + 1
        tNewSkillData[dwSkillID] = {
            dwSkillID = dwSkillID,
            dwTrueSkillID = dwSkillID,
            nIndex = nCount,
        }
    end

    -- 比较新旧技能列表，技能ID集合相同则跳过重建
    local tOldSkillData = self.tSkillData[dwPlayerID]
    if tOldSkillData and dwPlayerID == self.dwSelectPlayerID then
        local bSame = true
        for dwSkillID in pairs(tNewSkillData) do
            if not tOldSkillData[dwSkillID] then
                bSame = false
                break
            end
        end
        if bSame then
            for dwSkillID in pairs(tOldSkillData) do
                if not tNewSkillData[dwSkillID] then
                    bSame = false
                    break
                end
            end
        end
        if bSame then
            return
        end
    end

    self.tSkillData[dwPlayerID] = tNewSkillData
    -- 当前选中玩家的技能列表被全量替换，需要重建CD列表
    if dwPlayerID == self.dwSelectPlayerID then
        self:UpdateCDList()
    end
end

function UILiveMainView:OnSkillCDNotify(dwPlayerID, dwSkillID, dwTrueSkillID)
    -- 非当前选中玩家的单条CD更新不缓存（切换时会通过 GetSkillCDRequest 重新拉取）
    if dwPlayerID ~= self.dwSelectPlayerID then
        return
    end

    self.tSkillData[dwPlayerID] = self.tSkillData[dwPlayerID] or {}
    local t = self.tSkillData[dwPlayerID][dwSkillID]
    if not t then
        local nIndex = 0
        for _ in pairs(self.tSkillData[dwPlayerID]) do
            nIndex = nIndex + 1
        end
        t = { nIndex = nIndex + 1 }
        self.tSkillData[dwPlayerID][dwSkillID] = t
    end

    local dwOldTrueSkillID = t.dwTrueSkillID
    t.dwSkillID = dwSkillID
    t.dwTrueSkillID = dwTrueSkillID or dwSkillID

    -- 增量更新单个技能节点
    -- 如果 dwTrueSkillID 没变且节点已存在，跳过图标更新（纯CD变化由逐帧刷新处理）
    local script = self.tCDScripts and self.tCDScripts[dwSkillID]
    if script and dwOldTrueSkillID == t.dwTrueSkillID then
        return
    end
    self:AddOrUpdateCDSkillNode(dwSkillID, t)
end

-- 全量重建CD列表（仅在选中玩家变更或技能列表全量替换时调用）
function UILiveMainView:UpdateCDList()
    local scriptPlayerInfo = UIHelper.GetBindScript(self.WidgetCurrentPlayerInfo)
    if not scriptPlayerInfo or not scriptPlayerInfo.LayoutCDList then return end
    local layout = scriptPlayerInfo.LayoutCDList

    UIHelper.RemoveAllChildren(layout)
    self.tCDScripts = {}

    if not self.dwSelectPlayerID then
        return
    end

	local player = GetPlayer(self.dwSelectPlayerID)
    if not player then
        return
    end

    local tSkillList = self.tSkillData[self.dwSelectPlayerID]
    if not tSkillList then
        return
    end

    -- 按 nIndex 排序后加载，确保技能图标按固定顺序排列
    local tSorted = {}
    for dwSkillID, tSkill in pairs(tSkillList) do
        table.insert(tSorted, {dwSkillID = dwSkillID, tSkill = tSkill})
    end
    table.sort(tSorted, function(a, b) return a.tSkill.nIndex < b.tSkill.nIndex end)
    for _, v in ipairs(tSorted) do
        self:CreateCDSkillNode(layout, v.dwSkillID, v.tSkill)
    end
    UIHelper.LayoutDoLayout(layout)
    UIHelper.SetVisible(layout, true)

    -- 确保CD刷新定时器已启动
    self:EnsureCDUpdateTimer()
end

-- 创建单个技能CD节点
function UILiveMainView:CreateCDSkillNode(layout, dwSkillID, tSkill)
    local scriptCD = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCD, layout)
    if not scriptCD or not scriptCD.Content then return end
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, scriptCD.Content)
    if not script then return end
    Event.UnRegAll(script)
    Timer.DelAllTimer(script)
    -- WidgetNormalSkill:UpdateVisibility() 会隐藏父节点（OB 无技能数据时 bValue=false），需恢复
    UIHelper.SetVisible(scriptCD.Content, true)

    -- 隐藏 OB 不需要的 UI 元素
    -- UIHelper.SetVisible(script.skillBtn, false)
    UIHelper.SetVisible(script.SliderCharge, false)
    UIHelper.SetVisible(script.ChargeLabel, false)
    UIHelper.SetVisible(script.LabelEnergy, false)
    UIHelper.SetVisible(script.ImgEnergyBg, false)
    UIHelper.SetVisible(script.ImgSkillBg, false)
    UIHelper.SetVisible(script.ImgCost, false)
    UIHelper.SetVisible(script.LabelCost, false)
    -- 隐藏所有特效和不需要的进度条
    UIHelper.SetVisible(script.Eff_UIskillRefresh_IndependentCD, false)
    UIHelper.SetVisible(script.Eff_UIskillRefresh_UIskillChuFa, false)
    UIHelper.SetVisible(script.Eff_UI_TiShiQuan, false)
    UIHelper.SetVisible(script.Eff_ChongNeng, false)
    UIHelper.SetVisible(script.Eff_BigChongNeng, false)
    UIHelper.SetVisible(script.SliderSkillSecond, false)
    UIHelper.SetVisible(script.SliderBigCharge, false)
    -- 初始隐藏CD遮罩和文本（由 UpdateSkillCDProgress 按需显示）
    UIHelper.SetVisible(script.imgSkillCd, false)
    UIHelper.SetVisible(script.cdLabel, false)
    -- 设置技能图标
    local szImgPath = TabHelper.GetSkillIconPath(tSkill.dwTrueSkillID)
        or TabHelper.GetSkillIconPathByIDAndLevel(tSkill.dwTrueSkillID, 1)

    if not string.find(szImgPath, "Resource/icon/") and not string.find(szImgPath, "Resource\\icon\\") then
        szImgPath = "Resource/icon/" .. szImgPath
    end

    if szImgPath then
        UIHelper.SetTexture(script.imgSkillIcon, szImgPath)
    end
    script.dwSkillID = tSkill.dwTrueSkillID
    script.dwPlayerID = self.dwSelectPlayerID
    -- 点击技能图标显示技能Tip
    UIHelper.BindUIEvent(script.skillBtn, EventType.OnClick, function()
        if not self.dwSelectPlayerID then return end
        local dwPlayerID, szName, llCurrentLife, llMaxLife, nTotalEquipScore, dwKungfuID, nMemberIndex
            = OBDungeonData.GetDungeonCompetitor(self.dwSelectPlayerID)

        local dwTrueSkillID = script.dwSkillID
        if not dwTrueSkillID then return end
        local player = GetPlayer(script.dwPlayerID)
        local nSkillLevel = 1
        local tRecipe = SkillData.GetFinalRecipeList(dwTrueSkillID, player)
        local nFakeMijiIndex = nil
        if tRecipe then
            for i = 1, #tRecipe do
                if tRecipe[i].active then
                    nFakeMijiIndex = i
                end
            end
        end
        local tCursor = GetCursorPoint()
        local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(
                PREFAB_ID.WidgetSkillInfoTips, tCursor.x, tCursor.y)
        if tipsScriptView then
            if not nFakeMijiIndex then
                tipsScriptView:SetForbidShowMiji(true)
            end
            local nCurrentSetID = player.GetTalentCurrentSet(player.dwForceID, dwKungfuID)
            tipsScriptView.player = player
            tipsScriptView:SetBtnVisible(false)
            tipsScriptView:OnEnter(dwTrueSkillID, dwKungfuID, nCurrentSetID, nSkillLevel, nFakeMijiIndex, player)
            UIHelper.SetVisible(tipsScriptView.WidgetSkillLock, false)
        end
    end)
    self.tCDScripts[dwSkillID] = script
    UIHelper.UpdateMask(scriptCD.Content)
end

-- 增量添加或更新单个技能CD节点
function UILiveMainView:AddOrUpdateCDSkillNode(dwSkillID, tSkill)
    local script = self.tCDScripts and self.tCDScripts[dwSkillID]
    if script then
        -- 已有节点，更新图标（dwTrueSkillID 可能变化）
        local szImgPath = TabHelper.GetSkillIconPath(tSkill.dwTrueSkillID)
            or TabHelper.GetSkillIconPathByIDAndLevel(tSkill.dwTrueSkillID, 1)

        if not string.find(szImgPath, "Resource/icon/") and not string.find(szImgPath, "Resource\\icon\\") then
            szImgPath = "Resource/icon/" .. szImgPath
        end

        if szImgPath then
            UIHelper.SetTexture(script.imgSkillIcon, szImgPath)
        end
        script.dwSkillID = tSkill.dwTrueSkillID
        return
    end

    -- 数量限制检查
    local nCount = 0
    if self.tCDScripts then
        for _ in pairs(self.tCDScripts) do nCount = nCount + 1 end
    end
    if nCount >= MAX_SKILL_CD_NUM then return end

    -- 获取 LayoutCDList 并新增节点
    local scriptPlayerInfo = UIHelper.GetBindScript(self.WidgetCurrentPlayerInfo)
    if not scriptPlayerInfo or not scriptPlayerInfo.LayoutCDList then return end
    local layout = scriptPlayerInfo.LayoutCDList

    self:CreateCDSkillNode(layout, dwSkillID, tSkill)
    UIHelper.LayoutDoLayout(layout)
    UIHelper.SetVisible(layout, true)

    -- 确保CD刷新定时器已启动
    self:EnsureCDUpdateTimer()
end

-- 确保CD刷新定时器已启动（只创建一次，避免反复重建）
function UILiveMainView:EnsureCDUpdateTimer()
    if self.nCDUpdateTimerID then return end
    self.nCDUpdateTimerID = Timer.AddFrameCycle(self, 1, function()
        if not self.bInit then return end
        self:UpdateSkillCDProgress()
    end)
end

-- 停止CD刷新定时器
function UILiveMainView:StopCDUpdateTimer()
    if self.nCDUpdateTimerID then
        Timer.DelTimer(self, self.nCDUpdateTimerID)
        self.nCDUpdateTimerID = nil
    end
end

-- 逐帧刷新选中玩家技能CD进度
function UILiveMainView:UpdateSkillCDProgress()
    if not self.dwSelectPlayerID or not self.tCDScripts then return end
    local player = GetPlayer(self.dwSelectPlayerID)
    if not player then return end

    for dwSkillID, script in pairs(self.tCDScripts) do
        local _, nLeft, nTotal = SkillData.GetSkillCDProcess(player, script.dwSkillID)
        if nLeft and nTotal and nTotal > 0 and nLeft > 0 then
            local fPercent = nLeft / nTotal * 100
            UIHelper.SetProgressBarPercent(script.imgSkillCd, fPercent)
            UIHelper.SetVisible(script.imgSkillCd, true)
            UIHelper.SetString(script.cdLabel, string.format("%.1f", nLeft / GLOBAL.GAME_FPS))
            UIHelper.SetVisible(script.cdLabel, true)
        else
            UIHelper.SetVisible(script.imgSkillCd, false)
            UIHelper.SetVisible(script.cdLabel, false)
        end
    end
end

-- ----------------------------------------------------------
-- 打赏流程
-- ----------------------------------------------------------

-- 打赏选中玩家
function UILiveMainView:OnClickReward()
    if not self.dwSelectPlayerID then
        TipsHelper.ShowNormalTip("请先选择要赠礼的侠士")
        return
    end

    local tPlayerInfo = OBDungeonData.GetDungeonCompetitor(self.dwSelectPlayerID)
    local targetPlayer = GetPlayer(self.dwSelectPlayerID)
    if not targetPlayer or not tPlayerInfo then
        TipsHelper.ShowNormalTip("无法获取该侠士信息")
        return
    end

    local szGlobalID = targetPlayer.GetGlobalID()
    if not szGlobalID then
        TipsHelper.ShowNormalTip("无法获取该侠士信息")
        return
    end

    local dwPlayerID, szName, llCurrentLife, llMaxLife, nTotalEquipScore, dwKungfuID, nMemberIndex, dwCenterID
        = OBDungeonData.GetDungeonCompetitor(self.dwSelectPlayerID)
    local szMapName = self:GetDungeonMapInfo(dwCenterID)

    if BankLock and BankLock.CheckHaveLocked and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN) then
        return
    end

    UIMgr.Open(VIEW_ID.PanelSendGiftNewPop, TIP_TYPE.ObserveInstance, {szGlobalID = szGlobalID, nPlayerID = dwPlayerID},
        function(tTipItem)
            local nNum = tTipItem.nNum or 1
            local nGold = tTipItem.nGoldNum
            local nTipItemID = tTipItem.dwID
            if nGold * nNum >= GiftHelper.MESSAGE_TIP_NUM then
                local szContent = FormatString(g_tStrings.STR_VOICE_REWARD_NUM_BIG_MESSAGE, nGold * nNum)
                UIHelper.ShowConfirm(szContent, function()
                    GiftHelper.TipByGlobalID(dwCenterID, szGlobalID, nNum, nGold, nTipItemID, szMapName, "1", TIP_TYPE.ObserveInstance, szName)
                end)
            else
                GiftHelper.TipByGlobalID(dwCenterID, szGlobalID, nNum, nGold, nTipItemID, szMapName, "1", TIP_TYPE.ObserveInstance, szName)
            end
        end
    )
end

-- 获取副本地图信息字符串（格式：地图名|dwCenterID|nCopyIndex）
function UILiveMainView:GetDungeonMapInfo(dwCenterID)
    local pScene = GetClientPlayer() and GetClientPlayer().GetScene()
    if not pScene then return "" end
    local szMapName = Table_GetMapName(pScene.dwMapID) or ""
    local nCopyIndex = pScene.nCopyIndex or 0
    return szMapName .. "|" .. (dwCenterID or 0) .. "|" .. nCopyIndex
end

-- 打赏全团
function UILiveMainView:OnClickTeamReward()
    local tbCompetitors = OBDungeonData.GetDungeonCompetitorsList()
    if not tbCompetitors or table.is_empty(tbCompetitors) then
        TipsHelper.ShowNormalTip("当前无参战成员")
        return
    end

    if BankLock and BankLock.CheckHaveLocked and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN) then
        return
    end

    local nTeamCount = OBDungeonData.GetPlayerNum()

    UIMgr.Open(VIEW_ID.PanelSendGiftNewPop, TIP_TYPE.ObserveInstance_Team, {},
        function(tTipItem)
            local nNum = tTipItem.nNum or 1
            local nGold = tTipItem.nGoldNum
            local nTipItemID = tTipItem.dwID
            GiftHelper.TipDungeonAllTeam(nTeamCount, nNum, nGold, nTipItemID, TIP_TYPE.ObserveInstance_Team, UIHelper.UTF8ToGBK("全团"))
        end
    )
end

-- ----------------------------------------------------------
-- 打赏通知动画
-- ----------------------------------------------------------

function UILiveMainView:OnTipNotify(nGold, nNum, nType, szTargetName)
    if not nGold or not nNum then
        return
    end

    self.tbDalayShowTips = self.tbDalayShowTips or {}
    table.insert(self.tbDalayShowTips, {nGold = nGold, nNum = nNum, nType = nType, szTargetName = szTargetName})

    if not self.bIsShowingTip then
        self:ProcessNextTip()
    end
end

function UILiveMainView:ProcessNextTip()
    if not self.tbDalayShowTips or #self.tbDalayShowTips == 0 then
        self.bIsShowingTip = false
        if self.WidgeGiftHint then
            UIHelper.SetVisible(self.WidgeGiftHint, false)
        end
        if self.GiftSFX then
            UIHelper.SetVisible(self.GiftSFX, false)
        end
        return
    end

    self.bIsShowingTip = true
    local tipData = table.remove(self.tbDalayShowTips, 1)
    local nGold = tipData.nGold
    local nNum = tipData.nNum
    local nType = tipData.nType
    local szTargetName = tipData.szTargetName

    local tTipItemList = Table_GetTipItemList()
    local tItem = nil
    for _, tTipItem in pairs(tTipItemList) do
        if tTipItem.nGoldNum == nGold then
            tItem = tTipItem
            break
        end
    end

    if not tItem then
        self.bIsShowingTip = false
        self:ProcessNextTip()
        return
    end

    -- 播放礼物特效
    if self.GiftSFX then
        local bUp = tItem.nUpNum and tItem.nUpNum <= nNum
        local szSFXPath = bUp and tItem.szUpSfxPath or tItem.szSfxPath
        UIHelper.SetVisible(self.GiftSFX, true)
        UIHelper.SetSFXPath(self.GiftSFX, szSFXPath, 0)
        UIHelper.PlaySFX(self.GiftSFX, 0)
    end

    -- 显示打赏提示
    if self.WidgeGiftHint then
        UIHelper.SetVisible(self.WidgeGiftHint, true)

        local bUp = tItem.nUpNum and tItem.nUpNum <= nNum
        local szIcon = bUp and tItem.szUpImagePath or tItem.szImagePath
        szIcon = UIHelper.FixDXUIImagePath(szIcon)

        local player = GetClientPlayer()

        -- 被打赏者名称：个人打赏显示玩家名，团队打赏显示"全团"
        if self.LabelPlayerName then
            local szName = szTargetName or ""
            UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(szName), 8)
        end

        -- 赠送者名称（自己）
        if self.LabelSend then
            local szMyName = player and player.szName or ""
            UIHelper.SetString(self.LabelSend, UIHelper.GBKToUTF8(szMyName), 8)
        end

        -- 送礼人头像
        if self.WidgetGiftGiver then
            UIHelper.RemoveAllChildren(self.WidgetGiftGiver)
            if player then
                UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetGiftGiver, player.dwID)
            end
        end

        -- 打赏数量：从个位开始动态加载
        if self.LayoutNumTotal then
            UIHelper.RemoveAllChildren(self.LayoutNumTotal)
            local szScoreStr = tostring(nNum)
            for i = #szScoreStr, 1, -1 do
                local szNumChar = string.sub(szScoreStr, i, i)
                local nDigit = tonumber(szNumChar)
                local szImg = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_" .. nDigit
                local imgScript = UIHelper.AddPrefab(PREFAB_ID.WidgetScoreNum, self.LayoutNumTotal)
                UIHelper.SetSpriteFrame(imgScript.ImgScore, szImg, false)
            end
        end

        -- 打赏物品图标
        if self.ImgZhuan then
            UIHelper.SetTexture(self.ImgZhuan, szIcon)
            UIHelper.SetVisible(self.ImgZhuan, true)
        end

        -- 播放显示动画
        if self.WidgeAniGiftHint then
            UIHelper.StopAni(self, self.WidgeAniGiftHint, "AniGiftHintShow")
            UIHelper.PlayAni(self, self.WidgeAniGiftHint, "AniGiftHintShow")
        end
        UIHelper.LayoutDoLayout(self.LayoutGiftTarget)
    end

    -- 定时关闭通知并处理下一条
    local nShowTime = tItem.nShowTime and (tItem.nShowTime / 1000) or 2
    Timer.Add(self, nShowTime, function()
        if not self.bInit then return end
        if self.WidgeGiftHint then
            UIHelper.SetVisible(self.WidgeGiftHint, false)
        end
        if self.GiftSFX then
            UIHelper.SetVisible(self.GiftSFX, false)
        end
        self.bIsShowingTip = false
        self:ProcessNextTip()
    end)
end

-- 摇杆可见性：移动端 + 自由视角（或调试模式强制显示）
function UILiveMainView:UpdateJoystickVisible()
    if not self.scriptJoyStick then return end

    local bShow = Platform.IsMobile() and not self.dwSelectPlayerID
    UIHelper.SetVisible(self.WidgetJoystick, bShow)
end

-- 统一退出入口：通知服务器离开 OB + 关闭面板
function UILiveMainView:DoClose()
    RemoteCallToServer("On_Dungeon_LeaveOB")
    UIMgr.Close(VIEW_ID.PanelFBShow)
end

function UILiveMainView:OnTargetChanged(nTargetType, nTargetId)
    -- 先清
    if self.scriptTargetInfo then
        self.scriptTargetInfo._rootNode:removeFromParent()
        self.scriptTargetInfo = nil
    end

    if TARGET.NO_TARGET == nTargetType then
        return
    end

    -- npc
    if nTargetType == TARGET.NPC then
        local npc = GetNpc(nTargetId)
        assert(npc)
        local nIntensity = npc.nIntensity
        assert(nIntensity)
        if 2 == nIntensity or 6 == nIntensity then
            -- boss
            self.scriptTargetInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetTargetBoss, self.WidgetTargetInfoAnchor, nTargetType, nTargetId, "boss")
        elseif nIntensity >= 4 and nIntensity <= 5 then
            -- Elite
            self.scriptTargetInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetTargetElite, self.WidgetTargetInfoAnchor, nTargetType, nTargetId, "elite")
        else
            self.scriptTargetInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetTargetNormal, self.WidgetTargetInfoAnchor, nTargetType, nTargetId, "normal")
        end

        -- 初始化并切到全局视角
        RemoteCallToServer("On_Dungeon_WatchAll")

        -- player
    elseif nTargetType == TARGET.PLAYER then
        self.scriptTargetInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityPlayer, self.WidgetTargetInfoAnchor, nTargetId, true)
        self.scriptTargetInfo:UpdateBuffAndVoicePosition(MAIN_CITY_CONTROL_MODE.CLASSIC, true)
    end

end

return UILiveMainView