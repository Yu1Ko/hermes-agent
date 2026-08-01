-- ---------------------------------------------------------------------------------
-- Author: KSG
-- Name: UILiveRaidTeamMember
-- Date: 2026-03-23
-- Desc: 副本观战 - 左侧团队成员血条列表（挂载在 WidgetLeft 节点）
-- ---------------------------------------------------------------------------------

local UILiveRaidTeamMember = class("UILiveRaidTeamMember")

local MAX_TEAM_MEMBER = 25

-- 血条颜色（与 UITeamMainCityRaidCell 一致）
local BLOOD_COLOR = {
    [KUNGFU_POSITION.DPS]  = "UIAtlas2_MainCity_MainCity1_Teambg_frame_dps.png",
    [KUNGFU_POSITION.T]    = "UIAtlas2_MainCity_MainCity1_Teambg_frame_tank.png",
    [KUNGFU_POSITION.Heal] = "UIAtlas2_MainCity_MainCity1_Teambg_frame_cure.png",
}

function UILiveRaidTeamMember:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end

    self.tPlayerMap = {}        -- dwPlayerID → {完整数据}
    self.tSlotToPlayer = {}     -- nMemberIndex → dwPlayerID
    self.nPlayerNum = 0
    self.tCellScripts = {}      -- index → Cell script
    self.dwSelectPlayerID = nil
    self.tbWidgetPosX = {}      -- 缓存 Widget 原始 X 坐标（Tab 切换用）
    self.bPackUp = false        -- 团队列表折叠状态
    self.nCurTab = 1            -- 当前选中的 Tab（1=1-15，2=16+，3=全部）

    for k, v in ipairs(self.tWidgetTeamMore) do
        table.insert(self.tbWidgetPosX, UIHelper.GetPositionX(v))
    end

    self:InitCells()
    self:RefreshPlayerList()

    -- 默认选中第一个成员
    if self.nPlayerNum > 0 then
        for nSlot = 1, MAX_TEAM_MEMBER do
            if self.tSlotToPlayer[nSlot] then
                self:OnCellClick(nSlot)
                break
            end
        end
    end

    UIHelper.SetSelected(self.TogTeamTab1, true)
end

function UILiveRaidTeamMember:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
    self.tCellScripts = nil
    self.tPlayerMap = nil
    self.tSlotToPlayer = nil
end

function UILiveRaidTeamMember:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTeamTab1, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.nCurTab = 1
            for index, widget in ipairs(self.tWidgetTeamMore) do
                local bVisible = index <= 15 and self.tSlotToPlayer[index] ~= nil
                UIHelper.SetVisible(widget, bVisible)
                if bVisible then
                    local nPosX = self.tbWidgetPosX[index]
                    if nPosX then
                        UIHelper.SetPositionX(widget, nPosX)
                    end
                end
            end
        end
    end)

    UIHelper.BindUIEvent(self.TogTeamTab2, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.nCurTab = 2
            for index, widget in ipairs(self.tWidgetTeamMore) do
                local bVisible = index > 15 and self.tSlotToPlayer[index] ~= nil
                UIHelper.SetVisible(widget, bVisible)
                if bVisible then
                    local nPosX = self.tbWidgetPosX[index - 15]
                    if nPosX then
                        UIHelper.SetPositionX(widget, nPosX)
                    end
                end
            end
        end
    end)

    UIHelper.BindUIEvent(self.TogTeamTab3, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.nCurTab = 3
            for index, widget in ipairs(self.tWidgetTeamMore) do
                UIHelper.SetVisible(widget, self.tSlotToPlayer[index] ~= nil)
                if index > 15 then
                    local nPosX = self.tbWidgetPosX[index]
                    if nPosX then
                        UIHelper.SetPositionX(widget, nPosX)
                    end
                end
            end
        end
    end)
end

function UILiveRaidTeamMember:RegEvent()
    -- 团队信息变化 → 刷新血量
    Event.Reg(self, EventType.ON_DUNGEON_OB_COMPETITOR_VARIABLE_INFO_UPDATE_UI, function()
        self:RefreshPlayerList()
    end)

    -- 位置信息更新 → 刷新观众人数
    Event.Reg(self, EventType.ON_DUNGEON_OB_PLAYERS_POS_INFO_UPDATE_UI, function()
        self:RefreshPlayerList()
    end)

    -- 标记变化
    Event.Reg(self, EventType.ON_TEAM_DUNGEON_OB_SET_MARK_UI, function()
        self:RefreshPlayerList()
    end)

    -- 权限变化（刷新队长图标）
    Event.Reg(self, EventType.ON_TEAM_DUNGEON_OB_AUTHORITY_CHANGED_UI, function()
        self:RefreshPlayerList()
    end)

    -- 监听选中变化（来自其他脚本的同步，加保护避免自触发重复刷新）
    Event.Reg(self, EventType.ON_OB_SELECT_PLAYER_CHANGED, function(dwPlayerID)
        if dwPlayerID == self.dwSelectPlayerID then return end
        self.dwSelectPlayerID = dwPlayerID
        self:UpdateAllCells()
    end)
end

-- ----------------------------------------------------------
-- Cell 初始化与数据刷新
-- ----------------------------------------------------------

-- 为每个 WidgetTeamMore 加载 WidgetTeamMoreBlood Cell
function UILiveRaidTeamMember:InitCells()
    for i = 1, MAX_TEAM_MEMBER do
        local widget = self.tWidgetTeamMore[i]
        if widget then
            UIHelper.RemoveAllChildren(widget)
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamMoreBlood, widget)
            self.tCellScripts[i] = script

            if script then
                Event.UnRegAll(script)
                Timer.DelAllTimer(script)

                -- 隐藏 OB 不需要的 UI 元素
                UIHelper.SetVisible(script.ImgTeamIcon, false)
                UIHelper.SetVisible(script.ImgMic, false)
                UIHelper.SetVisible(script.ImgOffLine, false)
                UIHelper.SetVisible(script.ProgressBlueBar, false)
                UIHelper.SetVisible(script.ImgBlueBarBg, false)
                UIHelper.SetVisible(script.ImgOutRange, false)
                UIHelper.SetVisible(script.ImgLoginSite, false)
                UIHelper.SetVisible(script.ImgQuShan, false)
                UIHelper.SetVisible(script.WidgetDianMing, false)
                UIHelper.SetVisible(script.ImgTeamDead1, false)
                UIHelper.SetVisible(script.WidgetPreparation, false)
                UIHelper.SetVisible(script.ImgWait, false)
                UIHelper.SetVisible(script.ImgHorse, false)
                UIHelper.SetVisible(script.ImgHorseBloodFrame, false)

                script:SetOnClickCallBack(function()
                    self:OnCellClick(i)
                end)
            end
        end
    end
end

-- 刷新完整成员列表
-- GetDungeonCompetitorsList() 返回: { [i] = { [dwPlayerID] = {dwKungfuID, nMemberIndex, nEquipScore, nCurrentLife, szPlayerName, nMaxLife} } }
function UILiveRaidTeamMember:RefreshPlayerList()
    local tDungeonRaid = OBDungeonData.GetDungeonCompetitorsList()
    self.tPlayerMap = {}
    self.tSlotToPlayer = {}
    self.nPlayerNum = 0

    if tDungeonRaid then
        for dwPlayerID, tPlayerInfo in pairs(tDungeonRaid) do
            self.nPlayerNum = self.nPlayerNum + 1
            local tInfo = {
                dwPlayerID       = dwPlayerID,
                szPlayerName     = tPlayerInfo.szPlayerName,
                nCurrentLife     = tPlayerInfo.nCurrentLife,
                nMaxLife         = tPlayerInfo.nMaxLife,
                nEquipScore      = tPlayerInfo.nEquipScore,
                dwKungfuID       = tPlayerInfo.dwKungfuID,
                nMemberIndex     = tPlayerInfo.nMemberIndex,
            }
            self.tPlayerMap[dwPlayerID] = tInfo
            local nSlot = tPlayerInfo.nMemberIndex or self.nPlayerNum
            self.tSlotToPlayer[nSlot] = dwPlayerID
        end
    end

    self:UpdateAllCells()
end

function UILiveRaidTeamMember:UpdateAllCells()
    if not self.bInit then return end

    for i = 1, MAX_TEAM_MEMBER do
        local widget = self.tWidgetTeamMore[i]
        local script = self.tCellScripts[i]
        if widget and script then
            local dwPlayerID = self.tSlotToPlayer[i]
            if dwPlayerID then
                -- 根据当前 Tab 判断该 cell 是否在可见范围
                local bInTab = (self.nCurTab == 1 and i <= 15)
                    or (self.nCurTab == 2 and i > 15)
                    or (self.nCurTab == 3)
                if bInTab then
                    local tInfo = self.tPlayerMap[dwPlayerID]
                    UIHelper.SetVisible(script._rootNode, true)
                    UIHelper.SetVisible(widget, true)
                    self:UpdateOneCell(i, dwPlayerID, tInfo)
                else
                    UIHelper.SetVisible(script._rootNode, false)
                    UIHelper.SetVisible(widget, false)
                end
            else
                UIHelper.SetVisible(script._rootNode, false)
                UIHelper.SetVisible(widget, false)
            end
        end
    end
end

function UILiveRaidTeamMember:UpdateOneCell(nIndex, dwPlayerID, tInfo)
    local script = self.tCellScripts[nIndex]
    if not script or not tInfo then return end

    -- 玩家名称
    local szUtf8Name = UIHelper.GetUtf8SubString(UIHelper.GBKToUTF8(tInfo.szPlayerName or ""), 1, 9)
    UIHelper.SetString(script.LabelTeamName, szUtf8Name)

    -- 心法图标 + 血条颜色
    local dwHDKungfuID
    if TabHelper.IsHDKungfuID(tInfo.dwKungfuID) then
        dwHDKungfuID = tInfo.dwKungfuID
    else
        dwHDKungfuID = TabHelper.GetHDKungfuID(tInfo.dwKungfuID)
    end
    local nPosition = PlayerKungfuPosition[dwHDKungfuID] or KUNGFU_POSITION.DPS
    UIHelper.PreloadSpriteFrame(BLOOD_COLOR[nPosition])
    script.ProgressBlood:loadTexture(BLOOD_COLOR[nPosition], 1)
    PlayerData.SetMountKungfuIcon(script.ImgTeamPlayerXinFa, tInfo.dwKungfuID)

    -- 血条
    if tInfo.nMaxLife and tInfo.nMaxLife > 0 then
        UIHelper.SetProgressBarPercent(script.ProgressBlood, 100 * tInfo.nCurrentLife / tInfo.nMaxLife)
    else
        UIHelper.SetProgressBarPercent(script.ProgressBlood, 100)
    end

    -- 死亡标记
    UIHelper.SetVisible(script.ImgDead, tInfo.nCurrentLife and tInfo.nCurrentLife <= 0 and tInfo.nMaxLife > 0)

    -- 选中高亮
    UIHelper.SetVisible(script.ImgSelect, dwPlayerID == self.dwSelectPlayerID)

    -- 队长图标（直接查询当前团队权限）
    local hTeam = GetClientTeam()
    local bIsLeader = hTeam and hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == dwPlayerID
    UIHelper.SetVisible(script.ImgTeamIcon, bIsLeader)
end

-- Cell 点击
function UILiveRaidTeamMember:OnCellClick(nIndex)
    local dwPlayerID = self.tSlotToPlayer[nIndex]
    if not dwPlayerID then return end

    -- 触发CD：3秒内重复点击提示
    local nNow = GetCurrentTime()
    if self.nLastClickTime and nNow - self.nLastClickTime < 3 then
        TipsHelper.ShowNormalTip(g_tStrings.STR_OBDUNGEON_KICKOUT_OB_TIP)
        return
    end
    self.nLastClickTime = nNow

    local player = GetClientPlayer()
    if player then
        player.CancelSyncDungeonCompetitorSkillCDState()
    end

    self.dwSelectPlayerID = dwPlayerID
    RemoteCallToServer("On_Dungeon_WatchPlayer", dwPlayerID)
end

return UILiveRaidTeamMember