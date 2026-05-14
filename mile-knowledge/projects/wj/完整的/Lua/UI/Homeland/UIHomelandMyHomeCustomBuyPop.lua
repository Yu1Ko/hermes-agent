-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeCustomBuyPop
-- Date: 2023-04-13 11:04:40
-- Desc: ?
-- ---------------------------------------------------------------------------------
local COLD_TIME = 30
local tSpecialMapBuyLandRequirementTitle =
{
	[462] = g_tStrings.STR_DATANGJIAYUAN_BUY_LAND_REQUIREMENT_TITLE_SPECIAL_1,-- 九寨沟
}

local UIHomelandMyHomeCustomBuyPop = class("UIHomelandMyHomeCustomBuyPop")
local DataModel = HomelandGroupBuyData

local function OutputErrorMessage(arg1)
    local szErrorText = g_tStrings.tHomelandBuildingFailureNotify[arg1] or
        g_tStrings.STR_GROUP_BUY_UNKNOWN_ERROR
	OutputMessage("MSG_SYS", szErrorText.."\n")
	OutputMessage("MSG_ANNOUNCE_NORMAL", szErrorText.."\n")
end

function UIHomelandMyHomeCustomBuyPop:OnEnter(nMapID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbConditions = nil
    self.nCountDown = 0
    self.nMapID = nMapID
    self:Init()
    self:ApplayBuyLandGroupon()
    if self.nMapID == 674 then
        RemoteCallToServer("On_HomeLand_LandRequirement", self.nMapID, 1, 10)
    else
        RemoteCallToServer("On_HomeLand_LandRequirement", self.nMapID, 1, 2)
    end
end

function UIHomelandMyHomeCustomBuyPop:OnExit()
    self.bInit = false
    -- DataModel.UnInit()--放到UIHomelandMainView.lua中清除
end

function UIHomelandMyHomeCustomBuyPop:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.ScrollViewCustomBuyPopTips, false)
    UIHelper.BindUIEvent(self.BtnPackUp, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCustomization, EventType.OnClick, function ()
        local nResultCode = GetHomelandMgr().CreateBuyLandGroupon(DataModel.nMapID)
        if nResultCode ~= HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
            OutputErrorMessage(nResultCode)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCustomization, EventType.OnClick, function ()
        local nResultCode = GetHomelandMgr().CreateBuyLandGroupon(DataModel.nMapID)
        if nResultCode ~= HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
            OutputErrorMessage(nResultCode)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        if not self.nSelectedPlayerID or self.nSelectedPlayerID == 0 then
            return
        end
        local szName = DataModel.GetPlayerName(self.nSelectedPlayerID)
        local szContent = string.format(g_tStrings.tHomelandGroupBuyDoubleCofirm.RemoveMemberWithName, szName)
        UIHelper.ShowConfirm(szContent,function ()
            GetHomelandMgr().BuyLandGrouponRemovePlayer(self.nSelectedPlayerID)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function ()
        local bIsGroupBuyOrganizer = DataModel.IsGroupBuyOrganizer()
        local szContent = bIsGroupBuyOrganizer and g_tStrings.tHomelandGroupBuyDoubleCofirm.DisbandGroup or g_tStrings.tHomelandGroupBuyDoubleCofirm.Exit
        local fnAction = function()
            if bIsGroupBuyOrganizer then
                GetHomelandMgr().DeleteBuyLandGroupon()
            else
                GetHomelandMgr().BuyLandGrouponRemovePlayer(DataModel.nMyGlobalRoleID)
            end
        end
        self:PopUpDoubleConfirmTips(szContent, fnAction)
    end)

    UIHelper.BindUIEvent(self.BtnSend, EventType.OnClick, function()
        if not self.nSelectedPlayerID or self.nSelectedPlayerID == 0 then
            return
        end

        for i, tbInfo in ipairs(DataModel.tMemberInfo) do
            if tbInfo.GlobalRoleID == self.nSelectedPlayerID then
                local szName = UIHelper.GBKToUTF8(tbInfo.Name)
                local szTips = g_tStrings.tHomelandGroupBuyPlayerState[tbInfo.State]
                local tbData = {szName = szName, dwTalkerID = tbInfo.PlayerID, szGlobalID = tbInfo.GlobalRoleID}
                ChatHelper.WhisperTo(szName, tbData)
                ChatHelper.Chat(UI_Chat_Channel.Whisper, szTips)
                break
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelInviteFriendPop)
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        ChatHelper.Chat()
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function ()
        local ResultCode = GetHomelandMgr().BuyLandGrouponReadyRequest()
        if ResultCode ~= HOMELAND_RESULT_CODE.GROUPON_SUCCEED  then
            OutputErrorMessage(ResultCode)
            self:Init()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function ()
        if self.nRefreshCD <= 0 then
            self:ApplayBuyLandGroupon()
        end
    end)
end

function UIHomelandMyHomeCustomBuyPop:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function (nResultCode1, nResultCode2, ...)
        --创建团购
        if nResultCode1 == HOMELAND_RESULT_CODE.CREATE_BUY_LAND_GROUPON then
            if nResultCode2 == HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
                OutputMessage("MSG_SYS", g_tStrings.STR_GROUP_BUY_CREATE_SUCCEED.."\n")
            end
        --解散团购
        elseif nResultCode1 == HOMELAND_RESULT_CODE.DELETE_BUY_LAND_GROUPON then
            if nResultCode2 == HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
                DataModel.ReSetGroupBuyInfo()
                UIMgr.Close(self)
            end
        elseif nResultCode1 == HOMELAND_RESULT_CODE.BUY_LAND_GROUPON_DISBIND_PLAYER_LAND then
            if nResultCode2 == HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
                local nPlayerId = arg2
                local nGlobalId = nil
                for i, playerInfo in ipairs(DataModel.tMemberInfo) do
                    if playerInfo.PlayerID == nPlayerId then
                        nGlobalId = playerInfo.GlobalRoleID
                        break
                    end
                end
                if nGlobalId and DataModel.tBindPlayerWaitQueue[nGlobalId] then
                    GetHomelandMgr().BuyLandGrouponBindPlayerLand(DataModel.tBindPlayerWaitQueue[nGlobalId], nGlobalId)
                    DataModel.tBindPlayerWaitQueue[nGlobalId] = nil
                end
            end
        elseif nResultCode1 == HOMELAND_RESULT_CODE.BUY_LAND_GROUPON_READY_REQUEST then
            if nResultCode2 == HOMELAND_RESULT_CODE.GROUPON_SUCCEED then
                self.nCountDown = GetCurrentTime() + COLD_TIME
                DataModel.State.bInWaitResponse = true
                self:UpdateBuyButtom()
            end
        elseif nResultCode1 == HOMELAND_RESULT_CODE.APPLY_BUY_LAND_GROUPON then
            self:Init()
            if nResultCode2 ~= HOMELAND_RESULT_CODE.GROUPON_SUCCEED and nResultCode2 ~= HOMELAND_RESULT_CODE.NO_GROUPON_FAILED then
                OutputErrorMessage(nResultCode2)
            end
        end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE", function(nResultCode)
        --数据全更新
        if nResultCode == HOMELAND_RESULT_CODE.BUY_LAND_GROUPON_UPDATE_DATA then
            self:Init()
        end
    end)

    Event.Reg(self, "HS_BUY_LAND_GROUPON_UPDATE_SINGLE_DATA", function(nGlobalRoleID)
        local tPlayerInfo = GetHomelandMgr().GetBuyLandGrouponSingle(nGlobalRoleID)
        DataModel.SetSigleMemberData(tPlayerInfo, nGlobalRoleID)
        self:UpdateGroupMemberTable()
        if DataModel.nMyGlobalRoleID == DataModel.nLeaderId then
            self:UpdateBuyButtom()
        end
        if tPlayerInfo.PlayerID == DataModel.nMyPlayerID then
            DataModel.nMyLandIndex = tPlayerInfo.LandIndex
            DataModel.UpdatePrice()
        end
        self:UpdateMyInfo()
    end)

    Event.Reg(self, "HS_BUY_LAND_GROUPON_REMOVE_PLAYER", function(szName)
        DataModel.DeleteGroupBuyMember(szName)
        self:UpdateGroupMemberTable()
    end)

    Event.Reg(self, "Home_OnGetBuyLandConditions", function(tbConditions, dwMapID, nCopyIndex, nLandIndex)
        if dwMapID ~= self.nMapID then return end
        self.tbConditions = tbConditions
        self:UpdateTitle()
    end)

    Event.Reg(self, EventType.OnHomelandGroupBuySelectMember, function(nGlobalRoleID)
        self:OnSelectedMember(nGlobalRoleID)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:HideLandIndexSelectList()
    end)
end

function UIHomelandMyHomeCustomBuyPop:Init()
    DataModel.Init(self.nMapID)
    self:UpdateInfo()
end

function UIHomelandMyHomeCustomBuyPop:UpdateInfo()
    self:UpdateCreateGroupBuyButtom()
    -- self:UpdateInviteFriendsButtom()
    self:UpdateGroupMemberTable()
    self:UpdateMyInfo()
    -- self:UpdateTitle()
end

function UIHomelandMyHomeCustomBuyPop:UpdateTitle()
    if DataModel.State.bInGroupBuyState then
        return
    end
    local pPlayer = GetClientPlayer()
	local pHomelandMgr = GetHomelandMgr()
	if not pPlayer or not pHomelandMgr then
		return
	end

    local szTips1 = "<color=#d7f6ff>1.满足以下所有条件</c>".."\n"
    if self.nMapID == 674 then
        szTips1 = "<color=#d7f6ff>1.满足以下所有条件并且梓行点16000</c>".."\n"
    end
    -- local szLevelTip = pPlayer.nLevel >= 120 and "<color=#95ff95>条件1：满级</color>" or "<color=#86aeb6>条件1：满级</color>"
    local szLevelTip = "<color=#d7f6ff>条件1：满级</color>"
    local szBindLandTip = "<color=#d7f6ff>条件2：无绑定土地</color>"
	-- local tLandHash = pHomelandMgr.GetAllMyLand()
	-- for _, tHash in ipairs(tLandHash) do
	-- 	if not tHash.bPrivateLand and not tHash.bAllied then
	-- 		szBindLandTip = "<color=#86aeb6>条件2：无绑定土地</color>"
	-- 	end
	-- end
    szTips1 = szTips1..szLevelTip.."\n"..szBindLandTip

    local szTips2 = "<color=#d7f6ff>2.满足任意条件</c>".."\n"
    if self.nMapID == 674 then
        szTips2 = ""
        UIHelper.SetVisible(self.LayoutCondition3, true)
        UIHelper.SetVisible(self.RichTextCondition02, false)
    else
        UIHelper.SetVisible(self.LayoutCondition3, false)
        UIHelper.SetVisible(self.RichTextCondition02, true)
    end
    if self.tbConditions and #self.tbConditions > 0 then
        for i, aOneCondition in ipairs(self.tbConditions) do
            for j, tSubCond in ipairs(aOneCondition) do
                local szTips = ""
                if j == 1 then
                    szTips = FormatString("条件<D0>：", i) .. UIHelper.GBKToUTF8(tSubCond.szString)
                else
                    szTips = UIHelper.GBKToUTF8(tSubCond.szString)
                end
                if tSubCond.bCan then
                    szTips2 = szTips2 .. string.format("<color=#95ff95>%s</c>", szTips)
                else
                    szTips2 = szTips2 .. string.format("<color=#86aeb6>%s</c>", szTips)
                end
            end

            if i < #self.tbConditions then
                szTips2 = szTips2 .. "\n"
            end
        end
    else
        szTips2 = ""
    end
    UIHelper.SetRichText(self.RichTextCondition01, szTips1)
    UIHelper.SetRichText(self.RichTextCondition02, szTips2)
    UIHelper.SetRichText(self.RichTextCondition03, szTips2)
end

function UIHomelandMyHomeCustomBuyPop:UpdateCreateGroupBuyButtom()
    local bIsGroupBuyOrganizer = DataModel.IsGroupBuyOrganizer()
    UIHelper.SetVisible(self.WidgetAnchorCustom, not DataModel.State.bInGroupBuyState)
    UIHelper.SetVisible(self.WidgetAnchorStartCustom, DataModel.State.bInGroupBuyState)
    UIHelper.SetVisible(self.BtnCustomization, not DataModel.State.bInGroupBuyState)
    if DataModel.State.bInGroupBuyState ~= nil then
        UIHelper.SetButtonState(self.BtnCustomization, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnCustomization, BTN_STATE.Disable)
    end

    if DataModel.State.bInGroupBuyState then
        UIHelper.SetVisible(self.ScrollViewCustomBuyPopList, not bIsGroupBuyOrganizer)
        UIHelper.SetVisible(self.WidgetAdd, bIsGroupBuyOrganizer)
    end
    UIHelper.SetVisible(self.BtnLeave, DataModel.State.bInGroupBuyState)
    UIHelper.SetVisible(self.BtnRefresh, DataModel.State.bInGroupBuyState)
    UIHelper.SetVisible(self.ImgBtnLine, DataModel.State.bInGroupBuyState)
end

function UIHomelandMyHomeCustomBuyPop:UpdateInviteFriendsButtom()
    UIHelper.SetVisible(self.BtnAdd, DataModel.IsGroupBuyOrganizer() and  DataModel.State.bInGroupBuyState)
end

function UIHomelandMyHomeCustomBuyPop:UpdateGroupMemberTable()
    local bLeader = DataModel.nLeaderId == DataModel.nMyGlobalRoleID
    local scrollview = bLeader and self.ScrollViewAdd or self.ScrollViewCustomBuyPopList
    local nMemberNum = #DataModel.tMemberInfo
    UIHelper.RemoveAllChildren(scrollview)
    for i, itemInfo in ipairs(DataModel.tMemberInfo) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomBuyPopListCell, scrollview)
        script:OnEnter(itemInfo, i)
        -- UIHelper.SetEnable(script.TogRanking, DataModel.IsGroupBuyOrganizer())
    end

    UIHelper.ScrollViewDoLayoutAndToTop(scrollview)
    self:UpdateGroupBuyMemberNum()
end

function UIHomelandMyHomeCustomBuyPop:UpdateMyInfo()
    self:UpdatePrice()
    self:UpdateBuyButtom()
end

function UIHomelandMyHomeCustomBuyPop:UpdateBuyButtom()
    local bInGroupBuyState = DataModel.State.bInGroupBuyState
    local bInWaitResponse = DataModel.State.bInWaitResponse
    local bIsGroupBuyOrganizer = DataModel.IsGroupBuyOrganizer()
    UIHelper.SetVisible(self.BtnBuy, bInGroupBuyState and bIsGroupBuyOrganizer)
    UIHelper.SetVisible(self.WidgetCD, not bIsGroupBuyOrganizer and (self.nCountDown > 0 or bInWaitResponse))
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    -- if not bInGroupBuyState or not bIsGroupBuyOrganizer then
    --     return
    -- end
    local nSeconds = 0
    if self.nCountDown > 0 then
        nSeconds = self.nCountDown - GetCurrentTime()
        if nSeconds <= 0 then
            self.nCountDown = 0
        end
    end

    UIHelper.SetNodeGray(self.BtnBuy, bInWaitResponse or self.nCountDown > 0 or DataModel.State.bAllReadyBuy, true)

    if DataModel.State.bAllReadyBuy then
        UIHelper.SetString(self.LabelBuy, g_tStrings.STR_BUY_BUTTOM_PROCESS)
    elseif nSeconds > 0 then
        self:BuyReadyCountDown()
    elseif bInWaitResponse then
        UIHelper.SetString(self.LabelBuy, g_tStrings.STR_BUY_BUTTOM_DISABLE)
        UIHelper.SetString(self.LabelCD, g_tStrings.STR_BUY_BUTTOM_DISABLE)
    else
        UIHelper.SetString(self.LabelBuy, g_tStrings.STR_BUY_BUTTOM_ENABLE)
    end
end

function UIHomelandMyHomeCustomBuyPop:BuyReadyCountDown()
    local fn = function ()
        local nSeconds
        if self.nCountDown > 0 then
            nSeconds = self.nCountDown - GetCurrentTime()
            if nSeconds <= 0 or self.nCountDown == 0 then
                if not DataModel.State.bAllReadyBuy then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_MEMBER_NOT_READY)
                end
                self.nBuyReadyTimerID = nil
                Timer.DelAllTimer(self)
                self.nCountDown = 0
            end
        end
        UIHelper.SetString(self.LabelCD, string.format(g_tStrings.STR_BUY_BUTTOM_DISABLE1, nSeconds))
        UIHelper.SetString(self.LabelBuy, string.format(g_tStrings.STR_BUY_BUTTOM_DISABLE, nSeconds))
    end

    self.nBuyReadyTimerID = self.nBuyReadyTimerID or Timer.AddCycle(self, 0.1, function ()
        fn()
    end)
    fn()
end

function UIHomelandMyHomeCustomBuyPop:UpdatePrice()
    local bInGroupBuyState = DataModel.State.bInGroupBuyState
    local nPriceGoldBrick = DataModel.nPriceGoldBrick
    local nPriceGoldIngot = DataModel.nPriceGoldIngot
    UIHelper.SetVisible(self.WidgetMoney, bInGroupBuyState)
    if not bInGroupBuyState then
        return
    end

    UIHelper.SetString(self.LabelMoney1, nPriceGoldBrick)
    UIHelper.SetString(self.LabelMoney2, nPriceGoldIngot)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetMoney, true, true)
end

function UIHomelandMyHomeCustomBuyPop:UpdateGroupBuyMemberNum()
    if not DataModel.State.bInGroupBuyState then
        return
    end
    local szNum
    local szGroupBuyNum = tostring(#DataModel.tMemberInfo).."/"..tostring(DataModel.nMaxLandIndex)
    if #DataModel.tMemberInfo < DataModel.nMaxLandIndex then
        szGroupBuyNum = string.format("<color=#FF0000>%s</color>", szGroupBuyNum)
    end

    szNum = string.format("团成员（%s）", szGroupBuyNum)
    UIHelper.SetRichText(self.LabelTeam, szNum)
end

function UIHomelandMyHomeCustomBuyPop:PopUpDoubleConfirmTips(message, fn)
    UIHelper.ShowConfirm(message, fn)
end

function UIHomelandMyHomeCustomBuyPop:OnSelectedMember(nGlobalRoleID)
    self.nSelectedPlayerID = nGlobalRoleID
    local bLeader = DataModel.nLeaderId == DataModel.nMyGlobalRoleID
    if bLeader then
        self:ShowLandIndexSelectList()
    else
        for i, tbInfo in ipairs(DataModel.tMemberInfo) do
            if tbInfo.GlobalRoleID == self.nSelectedPlayerID then
                local szTips = g_tStrings.tHomelandGroupBuyPlayerState[tbInfo.State]
                if szTips then
                    local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetAnchorTips, TipsLayoutDir.MIDDLE, szTips)
                    local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
                    tips:SetSize(nTipsWidth, nTipsHeight)
                    tips:Update()
                end
                return
            end
        end
    end
end

local function GetUnAvailableLandQueue()
    local tbQueue = {}
    local tUnAvailableLandIndex = {}
    for i, player in ipairs(DataModel.tMemberInfo) do
        if player.LandIndex > 0 then
            tUnAvailableLandIndex[player.LandIndex] = true
        end
    end
    for i = 0, DataModel.nMaxLandIndex do
        if not tUnAvailableLandIndex[i] then
            table.insert(tbQueue, {nIndex = i})
        end
    end
    return tbQueue
end

function UIHomelandMyHomeCustomBuyPop:ShowLandIndexSelectList()
    UIHelper.RemoveAllChildren(self.ScrollViewCustomBuyPopTips)
    local nGlobalRoleID = self.nSelectedPlayerID
    local tPlayerInfo   = GetHomelandMgr().GetBuyLandGrouponSingle(nGlobalRoleID)
    if not tPlayerInfo then
        return
    end
    local tUnAvailableLandQueue = GetUnAvailableLandQueue()
    local szName = UIHelper.GBKToUTF8(tPlayerInfo.Name)
    UIHelper.SetVisible(self.WidgetAnchorTips, true)
    UIHelper.SetString(self.LabelFieldAllot, szName)

    for i, v in ipairs(tUnAvailableLandQueue) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomBuyPopTipsCell, self.ScrollViewCustomBuyPopTips)
        script:OnEnter(v)
        script:SetClickCallback(function (nIndex)
            self:BuyLandBindPlayerLand(nIndex)
            self:HideLandIndexSelectList()
        end)
    end

    local w, h = UIHelper.GetContentSize(self.WidgetAnchorTips)
    local w1, h1 = UIHelper.GetContentSize(self.ScrollViewCustomBuyPopTips)
    UIHelper.SetContentSize(self.WidgetAnchorTips, w, 720)
    UIHelper.SetContentSize(self.ScrollViewCustomBuyPopTips, w1, 534)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCustomBuyPopTips)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.ScrollViewCustomBuyPopTips)
end

function UIHomelandMyHomeCustomBuyPop:BuyLandBindPlayerLand(nIndex)
    local nGlobalRoleID = self.nSelectedPlayerID
    local tPlayerInfo   = GetHomelandMgr().GetBuyLandGrouponSingle(nGlobalRoleID)
    if tPlayerInfo then
        --第一个选项是无
        if nIndex == 0 then
            GetHomelandMgr().BuyLandGrouponDisbindPlayerLand(tPlayerInfo.LandIndex)
        elseif nIndex > 0 then
            if tPlayerInfo.LandIndex == 0 then
                GetHomelandMgr().BuyLandGrouponBindPlayerLand(nIndex, nGlobalRoleID)
            else
                DataModel.tBindPlayerWaitQueue[nGlobalRoleID] = nIndex
                GetHomelandMgr().BuyLandGrouponDisbindPlayerLand(tPlayerInfo.LandIndex)
            end
        end
    end
end

function UIHomelandMyHomeCustomBuyPop:ApplayBuyLandGroupon()
    GetHomelandMgr().ApplyBuyLandGroupon()

    self.nRefreshCD = 30
    local function fn(nRemain)
        local szRefresh = "刷新"
        if nRemain > 0 then
            szRefresh = szRefresh.."("..nRemain..")"
        end
        UIHelper.SetString(self.LabelRefreshTime, szRefresh)
    end

    local function endFunc()
        local szRefresh = "刷新"
        UIHelper.SetString(self.LabelRefreshTime, szRefresh)
        self.nRefreshCD = 0
    end
    Timer.AddCountDown(self, self.nRefreshCD, fn, endFunc)
end

function UIHomelandMyHomeCustomBuyPop:HideLandIndexSelectList()
    UIHelper.RemoveAllChildren(self.ScrollViewCustomBuyPopTips)
    UIHelper.SetVisible(self.WidgetAnchorTips, false)
end

return UIHomelandMyHomeCustomBuyPop