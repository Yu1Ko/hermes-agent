-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPanelReviveView
-- Date: 2022-11-28 09:42:51
-- Desc: 复活界面
-- Prefab: PanelRevive
-- ---------------------------------------------------------------------------------

--- 配在这里的界面打开时，若复活界面开着，则复活界面会隐藏根节点，等待他们关闭后，将根节点恢复显示
local NotPermittedViewID = {
    VIEW_ID.PanelCharacter,
    VIEW_ID.PanelEndSettlement,
    VIEW_ID.PanelLKXRevive,
    VIEW_ID.PanelPvPSettlement,
    VIEW_ID.PanelPVPSettleData,
    VIEW_ID.PanelBahuangResult,
    VIEW_ID.PanelLieXingSettle,
    VIEW_ID.PanelLieXingData,
    VIEW_ID.PanelBattlePersonalCardSettle,
    VIEW_ID.PanelChampionshipSettleData,
    VIEW_ID.PanelBattleFieldXunBaoSettlement,
}

---@class UIPanelReviveView
local UIPanelReviveView  = class("UIPanelReviveView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPanelReviveView:_LuaBindList()
    self.RichTextRevive   = self.RichTextRevive --- 复活提示语（富文本）
    self.LabelRevive1     = self.LabelRevive1 --- 选项一的文字（如 原地疗伤）
    self.BtnRevive1       = self.BtnRevive1 --- 选项一的按钮
    self.LabelRevive2     = self.LabelRevive2 --- 选项二的文字（如 回营地）
    self.BtnRevive2       = self.BtnRevive2 --- 选项二的按钮
    self.ImgBgRed         = self.ImgBgRed --- 自己复活 - 背景
    self.ImgVideoRed      = self.ImgVideoRed --- 自己复活 - 右下角图标
    self.ImgBgGreen       = self.ImgBgGreen --- 被玩家复活 - 背景
    self.ImgVideoGreen    = self.ImgVideoGreen --- 被玩家复活 - 右下角图标

    self.LabelRevive3     = self.LabelRevive3 --- 选项三的文字（如 露营点疗伤）
    self.BtnRevive3       = self.BtnRevive3 --- 选项三的按钮
    self.LayoutButton     = self.LayoutButton --- 按钮的上层layout

    self.ImgReviveMask1   = self.ImgReviveMask1 --- 选项一的倒计时遮罩
    self.LabelReviveTime1 = self.LabelReviveTime1 --- 选项一的倒计时
    self.ImgReviveMask2   = self.ImgReviveMask2 --- 选项二的倒计时遮罩
    self.LabelReviveTime2 = self.LabelReviveTime2 --- 选项二的倒计时
    self.ImgReviveMask3   = self.ImgReviveMask3 --- 选项三的倒计时遮罩
    self.LabelReviveTime3 = self.LabelReviveTime3 --- 选项三的倒计时

    self.ImgRevive2       = self.ImgRevive2 --- 选项二的图标（如回营地、取消）
end

function UIPanelReviveView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:Init()
    Timer.DelAllTimer(self)
    Timer.AddCycle(self, 0.5, function()
        self:OnFrameBreathe()
    end)
end

function UIPanelReviveView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

local function CloseRevivePanel()
    UIMgr.Close(VIEW_ID.PanelRevive)
end

function UIPanelReviveView:Init()
    local tbAllOpenViewID = UIMgr.GetAllOpenViewID()
    for nIndex, nViewID in ipairs(tbAllOpenViewID) do
        if table.contain_value(NotPermittedViewID, nViewID) then
            self:AddOpenViewID(nViewID)
        end
    end
    self:UpdateVisible()
end

function UIPanelReviveView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRevive1, EventType.OnClick, function()
        if self.bReviveByPlayer then
            -- 被玩家复活
            GetClientPlayer().DoDeathRespond(REVIVE_TYPE.BY_PLAYER)
        else
            -- 自己原地复活
            GetClientPlayer().DoDeathRespond(REVIVE_TYPE.IN_SITU)
        end

        CloseRevivePanel()
        ReviveMgr.LogReviveAction(self.bReviveByPlayer and "被他人救助" or "原地疗伤")
    end)

    UIHelper.BindUIEvent(self.BtnRevive2, EventType.OnClick, function()
        if self.bReviveByPlayer then
            -- 拒绝被玩家复活
            GetClientPlayer().DoDeathRespond(REVIVE_TYPE.CANCEL_BY_PLAYER)
            self.bReviveByPlayer = false
            self:UpdateReviveState()
        else
            -- 复活点复活
            GetClientPlayer().DoDeathRespond(REVIVE_TYPE.IN_ALTAR)
            CloseRevivePanel()
            ReviveMgr.LogReviveAction("回营地")
        end
    end)

    UIHelper.BindUIEvent(self.BtnRevive3, EventType.OnClick, function()
        --- 自定义复活方式（如万灵的露营点复活）
        GetClientPlayer().DoDeathRespond(REVIVE_TYPE.BY_CUSTOM)
        CloseRevivePanel()
        ReviveMgr.LogReviveAction("露营点复活")
    end)
end

function UIPanelReviveView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if table.contain_value(NotPermittedViewID, nViewID) then
            self:AddOpenViewID(nViewID)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if table.contain_value(NotPermittedViewID, nViewID) then
            self:RemoveViewID(nViewID)
        end
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        CloseRevivePanel()
    end)
end

function UIPanelReviveView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelReviveView:UpdateParameters(bReviveInSite, bReviveInAlter, bReviveByPlayer, bReviveByCustom, nLeftReviveFrame, dwReviver, nMessageID, nReviveUIType, nCustomData)
    --- 是否启用原地疗伤
    self.bReviveInSitu   = bReviveInSite
    --- 是否启用回营地休息
    self.bReviveInAltar  = bReviveInAlter
    --- 是否是他人救助
    self.bReviveByPlayer = bReviveByPlayer
    --- 端游新增的自定义复活点，如万灵的露营点复活
    self.bReviveByCustom = bReviveByCustom

    local nFrame         = tonumber(nLeftReviveFrame) or 0
    --- 原地疗伤cd的结束时间点
    self.nEndTime        = (nFrame / GLOBAL.GAME_FPS) * 1000 + GetTickCount()

    --- 救助自己的角色ID
    self.dwPlayerID      = dwReviver
    --- 提示语ID
    self.nMessageID      = nMessageID

    --- 复活UI类型
    self.nReviveUIType   = nReviveUIType
    --- 自定义数据
    self.nCustomData     = nCustomData or 0
    --- 其他复活类型的倒计时
    self.nNestEndTime    = (self.nCustomData / GLOBAL.GAME_FPS) * 1000 + GetTickCount()
end

function UIPanelReviveView:UpdateReviveState()
    local nBtnRevive1State = BTN_STATE.Disable
    local nBtnRevive2State = BTN_STATE.Disable

    -- 重置一些组件为默认状态
    self:UpdateRichTextRevive("")

    local bInTreasureBattle = BattleFieldData.IsInTreasureBattleFieldMap()
    local bInArena          = ArenaData.IsInArena()
    UIHelper.SetVisible(self.LabelRevive1, true)
    UIHelper.SetVisible(self.BtnRevive1, not bInTreasureBattle)
    nBtnRevive1State = BTN_STATE.Disable

    UIHelper.SetVisible(self.LabelRevive2, true)
    UIHelper.SetVisible(self.BtnRevive2, not bInTreasureBattle)
    nBtnRevive2State = BTN_STATE.Disable

    UIHelper.SetVisible(self.ImgBgRed, false)
    UIHelper.SetVisible(self.ImgVideoRed, false)
    UIHelper.SetVisible(self.ImgBgGreen, false)
    UIHelper.SetVisible(self.ImgVideoGreen, false)

    UIHelper.SetVisible(self.ImgReviveMask1, false)
    UIHelper.SetVisible(self.LabelReviveTime1, false)
    UIHelper.SetVisible(self.ImgReviveMask2, false)
    UIHelper.SetVisible(self.LabelReviveTime2, false)
    UIHelper.SetVisible(self.ImgReviveMask3, false)
    UIHelper.SetVisible(self.LabelReviveTime3, false)
    UIHelper.SetVisible(self.WidgetLunHui, false)

    UIHelper.RemoveAllChildren(self.WidgetSkillParent)
    
    if self.bReviveByPlayer then
        -- 他人使用技能复活自己
        local szName = g_tStrings.STR_REVIVE_SOME_BODY

        if self.dwPlayerID and IsPlayer(self.dwPlayerID) then
            local player = GetPlayer(self.dwPlayerID)
            if player then
                szName = UIHelper.GBKToUTF8(player.szName)
            end
        elseif self.dwPlayerID then
            local npc = GetNpc(self.dwPlayerID)
            if npc then
                szName = UIHelper.GBKToUTF8(npc.szName)
            end
        end

        if self.dwPlayerID and self.dwPlayerID == GetClientPlayer().dwID then
            self:UpdateRichTextRevive(g_tStrings.STR_REVIVE_SELF_REVIVE)
        else
            self:UpdateRichTextRevive(FormatString(ParseTextHelper.ParseNormalText(g_tStrings.STR_REVIVE_PLAYER_REVIVE_YOU), szName))
        end

        nBtnRevive1State = BTN_STATE.Normal
        UIHelper.SetString(self.LabelRevive1, g_tStrings.STR_HOTKEY_SURE)

        nBtnRevive2State = BTN_STATE.Normal
        UIHelper.SetString(self.LabelRevive2, g_tStrings.STR_HOTKEY_CANCEL)

        UIHelper.SetVisible(self.ImgBgGreen, true)
        UIHelper.SetVisible(self.ImgVideoGreen, true)

        UIHelper.SetSpriteFrame(self.ImgRevive2, "UIAtlas2_MainCity_MainCity1_img_resurgence_11.png")
    else
        -- 自己选择复活方式
        UIHelper.SetString(self.LabelRevive1, g_tStrings.STR_REVIVE_PLAYER_REVIVE_SITU)
        UIHelper.SetString(self.LabelRevive2, g_tStrings.STR_REVIVE_PLAYER_REVIVE_ALTAR)

        if self.bReviveInSitu then
            nBtnRevive1State = BTN_STATE.Normal
        end

        if self.bReviveInAltar then
            nBtnRevive2State = BTN_STATE.Normal
        end

        if g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.SHAO_LIN then
            local nReviveShaoLinID = 259
            local nSkillLevel = g_pClientPlayer.GetSkillLevel(nReviveShaoLinID)
            if nSkillLevel >= 1 then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, self.WidgetSkillParent)
                local szLunHuiName = Table_GetSkillName(nReviveShaoLinID, 1)
                script:InitSkill(nReviveShaoLinID)
                UIHelper.SetVisible(self.WidgetLunHui, true)
                UIHelper.SetLabel(self.LabelLunHui, UIHelper.GBKToUTF8(szLunHuiName))
            end
        end

        UIHelper.SetVisible(self.ImgBgRed, true)
        UIHelper.SetVisible(self.ImgVideoRed, true)

        UIHelper.SetSpriteFrame(self.ImgRevive2, "UIAtlas2_MainCity_MainCity1_img_resurgence_05.png")
    end
    
    UIHelper.SetButtonState(self.BtnRevive1, nBtnRevive1State)
    UIHelper.SetButtonState(self.BtnRevive2, nBtnRevive2State)

    local bBtnRevive3Visible = false
    local nBtnRevive3State   = BTN_STATE.Disable
    if self.nReviveUIType == PLAYER_REVIVE_UI_TYPE.HOMING then
        bBtnRevive3Visible = true
        nBtnRevive3State   = self.bReviveByCustom and BTN_STATE.Normal or BTN_STATE.Disable
    end
    UIHelper.SetVisible(self.BtnRevive3, bBtnRevive3Visible)
    UIHelper.SetButtonState(self.BtnRevive3, nBtnRevive3State)

    UIHelper.SetString(self.LabelRevive3, "露营点疗伤")

    UIHelper.LayoutDoLayout(self.LayoutButton)

    self:OnFrameBreathe()
end

function UIPanelReviveView:OnFrameBreathe()
    local player = GetClientPlayer()
    if not player then
        CloseRevivePanel()
        return
    end

    if player.nMoveState ~= MOVE_STATE.ON_DEATH then
        Event.Dispatch(EventType.OnSetBottomRightAnchorVisible, true)
        CloseRevivePanel()
        return
    end

    self:UpdateVisible()
    if not self.bReviveByPlayer then
        self:UpdateMessage()

        if self.nReviveUIType == PLAYER_REVIVE_UI_TYPE.HOMING then
            self:UpdateNestState()
        end
    end
end

local function GetTimeToHourMinuteSecond(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local nHour   = math.floor(nTime / 3600)
    nTime         = nTime - nHour * 3600
    local nMinute = math.floor(nTime / 60)
    nTime         = nTime - nMinute * 60
    local nSecond = math.floor(nTime)
    return nHour, nMinute, nSecond
end

function UIPanelReviveView:UpdateMessage()
    local szTime = ""
    local nTime  = math.floor(((self.nEndTime or 0) - GetTickCount()) / 1000)
    if nTime < 0 then
        nTime = 0
    end

    local nH, nM, nS = GetTimeToHourMinuteSecond(nTime)
    if nH > 0 then
        szTime = nH .. g_tStrings.STR_BUFF_H_TIME_H
    end

    if nH > 0 or nM > 0 then
        szTime = szTime .. nM .. g_tStrings.STR_BUFF_H_TIME_M_SHORT
    end
    szTime       = szTime .. nS .. g_tStrings.STR_BUFF_H_TIME_S

    -- 更新提示语
    local szInfo = g_tStrings.tReviveInfo[self.nMessageID] or ""
    szInfo       = ParseTextHelper.ParseNormalText(szInfo)
    szInfo       = string.gsub(szInfo, "%$(%w+)", { time = szTime })

    self:UpdateRichTextRevive(szInfo)
end

function UIPanelReviveView:UpdateRichTextRevive(szText)
    UIHelper.SetRichText(self.RichTextRevive, string.format("<color=#D4BD7B>%s</color>", szText))
end

function UIPanelReviveView:UpdateNestState()
    local nTime = math.floor(((self.nEndTime or 0) - GetTickCount()) / 1000)
    if nTime < 0 then
        nTime = 0
    end

    local nNestTime = math.floor(((self.nNestEndTime or 0) - GetTickCount()) / 1000)
    if nNestTime < 0 then
        nNestTime = 0
    end

    -- note: 由于倒计时并不一定是原地疗伤的，比如在战场中死亡时，倒计时是回营地的，所以先屏蔽掉下面这个处理
    -- note: 不过目前暂时还是先继续显示吧
    local bShowInSiteCountDown = false
    if not self.bReviveInSitu and nTime > 0 then
        -- 当原地疗伤处于cd中时，更新原地疗伤的倒计时
        bShowInSiteCountDown = true
        UIHelper.SetString(self.LabelReviveTime1, nTime)
    end
    UIHelper.SetVisible(self.ImgReviveMask1, bShowInSiteCountDown)
    UIHelper.SetVisible(self.LabelReviveTime1, bShowInSiteCountDown)

    local bShowByCustomCountDown = false
    if not self.bReviveByCustom and nNestTime > 0 then
        -- 当露营点疗伤处于cd中时，更新倒计时
        bShowByCustomCountDown = true
        UIHelper.SetString(self.LabelReviveTime3, nNestTime)
    end
    UIHelper.SetVisible(self.ImgReviveMask3, bShowByCustomCountDown)
    UIHelper.SetVisible(self.LabelReviveTime3, bShowByCustomCountDown)
end

--某些界面打开时隐藏此界面
function UIPanelReviveView:UpdateVisible()
    local bVisible = self:IsViewIDEmpty()
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIPanelReviveView:AddOpenViewID(nViewID)
    if not self.tbOpenViewID then self.tbOpenViewID = {} end
    table.insert(self.tbOpenViewID, nViewID)
end

function UIPanelReviveView:RemoveViewID(nViewID)
    for nIndex, viewID in ipairs(self.tbOpenViewID) do
        if viewID == nViewID then
            table.remove(self.tbOpenViewID, nIndex)
            break
        end
    end
end

function UIPanelReviveView:IsViewIDEmpty()
    return table.get_len(self.tbOpenViewID) == 0
end

return UIPanelReviveView
