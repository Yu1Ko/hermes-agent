-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterIdleActionPage
-- Date: 2024-09-06 10:01:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@type UICharacterPendantPublicPage
---@class UICharacterIdleActionPage : UICharacterPendantPublicPage
local UICharacterIdleActionPage = class(UICharacterPendantPublicPage, "UICharacterIdleActionPage")

function UICharacterIdleActionPage:Init()
    self.nCurSelectedIndex = PLAYER_IDLE_ACTION_DISPLAY_TYPE.C_PANEL
    self:BindMainPageIndex(AccessoryMainPageIndex.IdleAction)
    self:BindDataModel(CharacterIdleActionData)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.DataModel.Init(self.nCurSelectedIndex)
    self:UpdateInfo()
end

function UICharacterIdleActionPage:BindUIEvent()
    for i, tog in ipairs(self.tbTogType) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupRightNav, tog)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            self:ClearSelect()
            self.nCurSelectedIndex = i - 1
            Event.Dispatch(EventType.OnCharacterPendantSelectedSubPage, self.nCurSelectedIndex)
        end)
    end
    UIHelper.SetToggleGroupSelected(self.ToggleGroupRightNav, self.nCurSelectedIndex)
end

function UICharacterIdleActionPage:RegEvent()
    Event.Reg(self, "ON_SYNC_DISPLAY_IDLE_ACTION_NOTIFY", function(nDisplayType, dwIdleActionID)
        self:UpdateInfo()
    end)

    Event.Reg(self, "REMOTE_PREFER_IDLEACTION_EVENT", function()
        self.DataModel.Init()

        if self:IsNowActivity() then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if not self.tbFilter or szKey ~= self.tbFilter.Key then
            return
        end

        local nFilterHave = tbInfo[1][1]
        local nFilterGainWay = tbInfo[2][1]
        self.DataModel.SetFilterHave(nFilterHave - 1)
        self.DataModel.SetFilterGainWay(nFilterGainWay - 1)
        self.DataModel.UpdateFilterList()
        self.DataModel.SetCurrentPage(1)
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)
end

function UICharacterIdleActionPage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICharacterIdleActionPage:UpdateInfo()
    self.tbScriptIdleActionCell = self.tbScriptIdleActionCell or {}
    self:SetImgTitle("UIAtlas2_Character_Accessory_Img_Pose_T")
    self:SetLabelEmpty(string.format("暂无符合条件的站姿"))
    self:ShowBtnDefault(self.DataModel.IsEquipedAction())

    for i, scriptCell in ipairs(self.tbScriptIdleActionCell) do
        UIHelper.SetVisible(scriptCell._rootNode, false)
    end

    local tbIdleActionList = self.DataModel.GetIdleActionList()
    for index, tbInfo in ipairs(tbIdleActionList) do
        local scriptCell = self.tbScriptIdleActionCell[index]
        if not scriptCell then
            scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAccessoryEffect, self.ScrollViewStandbyList)
            table.insert(self.tbScriptIdleActionCell, scriptCell)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupStandbyList, scriptCell.TogAccessoryEffect)
        end
        scriptCell:InitWithIdleAction(tbInfo)
        scriptCell:SetClickCallback(function ()
            self:ShowIdleActionTips(tbInfo.dwID)
            RedpointHelper.IdleAction_SetNew(tbInfo.dwID)
            scriptCell:InitWithIdleAction(tbInfo)
        end)
        UIHelper.SetVisible(scriptCell._rootNode, true)
    end
    self:ShowWidgetEmpty(#tbIdleActionList == 0)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStandbyList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewEffecScrollViewStandbyListtList, self.WidgetArrow)
end

function UICharacterIdleActionPage:ShowIdleActionTips(dwActionID)
    UIHelper.SetSelected(self.TogSift, false)
    local player = PlayerData.GetClientPlayer()

    local scriptItemTip = self:GetItemTips()
    if not scriptItemTip then
        return
    end

    scriptItemTip:OnInitIdleActionTip(dwActionID)
    local tbBtnState = {}
    if self.DataModel.bEnableCollect and dwActionID ~= 0 and not IsRemotePlayer(player.dwID) then
        local bCollected = self.DataModel.tCollection[dwActionID]
        if bCollected then
            table.insert(tbBtnState, {szName = "取消收藏", OnClick = function ()
                Event.Dispatch(EventType.HideAllHoverTips)
                RemoteCallToServer("On_IdleAction_DelPreferIdle", dwActionID)
            end})
        else
            table.insert(tbBtnState, {szName = "收藏", OnClick = function ()
                Event.Dispatch(EventType.HideAllHoverTips)
                RemoteCallToServer("On_IdleAction_AddPreferIdle", dwActionID)
            end})
        end
    end

    if dwActionID == 0 or player.IsHaveIdleAction(dwActionID) then
        local dwCurIdleActionID = player.GetDisplayIdleAction(self.DataModel.GetCurSelectedType())
        if dwCurIdleActionID == dwActionID then
            if dwActionID ~= 0 then
                table.insert(tbBtnState, {szName = "脱下", OnClick = function ()
                    Event.Dispatch(EventType.HideAllHoverTips)
                    local nCode = player.SetDisplayIdleAction(self.DataModel.GetCurSelectedType(), 0)
                    if nCode ~= PLAYER_IDLE_ACTION_ERROR_CODE.SUCCESS then
                        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_PLAYER_IDLE_ACTION_ERROR[nCode])
                    end
                end})
            end
        else
            table.insert(tbBtnState, {szName = "穿戴", OnClick = function ()
                Event.Dispatch(EventType.HideAllHoverTips)
                local nCode = player.SetDisplayIdleAction(self.DataModel.GetCurSelectedType(), dwActionID)
                if nCode ~= PLAYER_IDLE_ACTION_ERROR_CODE.SUCCESS then
                    OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_PLAYER_IDLE_ACTION_ERROR[nCode])
                end
            end})
        end
    end

    scriptItemTip:SetBtnState(tbBtnState)
end

function UICharacterIdleActionPage:OnClickBtnDefault()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local nCode = player.SetDisplayIdleAction(self.DataModel.GetCurSelectedType(), 0)
    if nCode ~= PLAYER_IDLE_ACTION_ERROR_CODE.SUCCESS then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_PLAYER_IDLE_ACTION_ERROR[nCode])
    end
end

function UICharacterIdleActionPage:ClearSelect()
    if self.tbScriptIdleActionCell then
        for i, scriptCell in ipairs(self.tbScriptIdleActionCell) do
            scriptCell:SetSelected(false)
        end
    end

    UIHelper.SetSelected(self.TogSift, false)
end

function UICharacterIdleActionPage:PlayIdleActionAni(dwID)
    local player = GetClientPlayer(dwID)    -- 本地播放动画
    if not player then
        return
    end
    local dwAdjustAniID = Player_GetAdjustAnimationByIdleActionID(dwID)
    rlcmd(string.format("character do action %d %d", player.dwID, dwID))
end
return UICharacterIdleActionPage