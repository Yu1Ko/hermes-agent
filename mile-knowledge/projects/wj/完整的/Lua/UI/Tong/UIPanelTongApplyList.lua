-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIPanelTongApplyList
-- Date: 2023-01-04
-- Desc: 帮会申请列表
-- Prefab: PanelApplicationListPop
-- ---------------------------------------------------------------------------------

local function IsMsgEditAllowed()
    return UI_IsActivityOn(ACTIVITY_ID.ALLOW_EDIT) -- 此活动在时间上一直开启，通过策划调用指令来改变实际的开启状态
end

---@class UIPanelTongApplyList
local UIPanelTongApplyList = class("UIPanelTongApplyList")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPanelTongApplyList:_LuaBindList()
    self.TogApplyList              = self.TogApplyList --- 申请列表的toggle
    self.TogTopTenRecommendList    = self.TogTopTenRecommendList --- 十大推荐帮会的toggle

    self.WidgetApplyList           = self.WidgetApplyList --- 申请列表的顶层组件

    self.WidgetTopTenRecommend     = self.WidgetTopTenRecommend --- 十大推荐帮会的顶层组件
    self.ScrollViewTopTenTongList  = self.ScrollViewTopTenTongList --- 十大推荐帮会的scroll view
    self.LabelAuctionPrice         = self.LabelAuctionPrice --- 竞标费用的label
    self.BtnRecommendAuction       = self.BtnRecommendAuction --- 竞标按钮
    self.WidgetEmptyTopTenTongList = self.WidgetEmptyTopTenTongList --- 无推荐帮会时显示的组件
    self.LabelAuctionDescription   = self.LabelAuctionDescription --- 竞标费用背景信息的label
    self.LayoutAuctionInfo         = self.LayoutAuctionInfo --- 竞标信息上方的layout
    self.WidgetRecommendTitle      = self.WidgetRecommendTitle --- 推荐帮会标题栏

    self.ScrollViewLeftNavToggle   = self.ScrollViewLeftNavToggle --- 左侧导航栏的scroll view

    self.EditBoxInvitePlayer       = self.EditBoxInvitePlayer --- 邀请指定玩家加入帮会的输入框
end

function UIPanelTongApplyList:OnEnter()
    self.m          = {}

    -- 默认显示申请列表界面
    self.bApplyList = true

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPanelTongApplyList:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self.m = nil
end

function UIPanelTongApplyList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    UIHelper.BindUIEvent(self.TogReceiveApplication, EventType.OnClick, function()
        Storage.Tong.bReceiveJoinApplyMsg = not Storage.Tong.bReceiveJoinApplyMsg
        UIHelper.SetSelected(self.TogReceiveApplication, not Storage.Tong.bReceiveJoinApplyMsg)
    end)

    local nPlayerGroupID = TongData.GetCurMemberInfo().nGroupID
    local nGroupID       = GetTongClient().GetDefaultGroupID()
    local bPermission    = GetTongClient().CanAdvanceOperate(nPlayerGroupID, nGroupID, TONG_OPERATION_INDEX.ADD_TO_GROUP)

    UIHelper.SetButtonState(self.BtnAllAccept, bPermission and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnAllReject, bPermission and BTN_STATE.Normal or BTN_STATE.Disable)

    UIHelper.BindUIEvent(self.BtnAllReject, EventType.OnClick, function()
        self:RejectAllApply()
        UIHelper.SetButtonState(self.BtnAllAccept, BTN_STATE.Disable)
        UIHelper.SetButtonState(self.BtnAllReject, BTN_STATE.Disable)
    end)
    UIHelper.BindUIEvent(self.BtnAllAccept, EventType.OnClick, function()
        self:AcceptAllApply()
        UIHelper.SetButtonState(self.BtnAllAccept, BTN_STATE.Disable)
        UIHelper.SetButtonState(self.BtnAllReject, BTN_STATE.Disable)
    end)

    local tTogList = { self.TogApplyList, self.TogTopTenRecommendList }
    for _, tTog in ipairs(tTogList) do
        UIHelper.SetToggleGroupIndex(tTog, ToggleGroupIndex.TongList)

        UIHelper.BindUIEvent(tTog, EventType.OnClick, function()
            self:UpdateInfo()
        end)
    end
    UIHelper.SetSelected(self.TogApplyList, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftNavToggle)

    UIHelper.BindUIEvent(self.BtnRecommendAuction, EventType.OnClick, function()
        self:OpenPanelAddTopTen()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxInvitePlayer, function()
        local szPlayerName = UIHelper.GetString(self.EditBoxInvitePlayer)

        if szPlayerName and szPlayerName ~= "" then
            UIHelper.ShowConfirm(string.format("你确认要邀请<color=#FFE26E>%s</color>加入帮会么？", szPlayerName), function()
                TongData.InvitePlayerJoinTong(UIHelper.UTF8ToGBK(szPlayerName))
            end, nil, true)
        end
    end)
end

function UIPanelTongApplyList:RegEvent()
    Event.Reg(self, "ON_GET_APPLY_JOININ_TONGLIST", function(tApplyList)
        self.m.bRequesting = false
        self.m.tApplyList  = tApplyList
        self:UpdateList()
    end)
    Event.Reg(self, "On_Tong_DelApplyJoin", function(nRetCode)
        if nRetCode == TONG_APPLY_JOININ_RESULT_CODE.SUCCESS then
            self:RequestApplyList()
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tTongApplyJoininResult[nRetCode])
        end
    end)

    Event.Reg(self, "ON_GET_TOPTEN_TONGLIST", function(nCount, tTongArr)
        self:UpdateTopTenTongInfo(nCount, tTongArr)
    end)

    Event.Reg(self, "ON_GET_TOP_TEN_COST", function(nLastCost, nMyTongCost, nRanking)
        self:UpdateTopTenCost(nLastCost, nMyTongCost, nRanking)
    end)

    Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function(dwActivityID, bOpen)
        UIHelper.SetVisible(self.LabelIntroductionRecommend, IsMsgEditAllowed())

        for _, child in ipairs(UIHelper.GetChildren(self.ScrollViewTopTenTongList)) do
            ---@type UIFactionList
            local script           = UIHelper.GetBindScript(child)

            local tTong            = script.tTong
            local _, szDescription = TextFilterReplace(tTong.szDescription)

            UIHelper.SetString(script.LabelTopTenDescription, bOpen and UIHelper.GBKToUTF8(szDescription) or "")
        end
    end)
end

function UIPanelTongApplyList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTongApplyList:UpdateInfo()
    self.bApplyList = UIHelper.GetSelected(self.TogApplyList)

    UIHelper.SetVisible(self.WidgetApplyList, self.bApplyList)
    UIHelper.SetVisible(self.WidgetTopTenRecommend, not self.bApplyList)

    UIHelper.SetVisible(self.LabelIntroductionRecommend, IsMsgEditAllowed())

    if self.bApplyList then
        self:RequestApplyList()

        -- 是否推送
        UIHelper.SetSelected(self.TogReceiveApplication, not Storage.Tong.bReceiveJoinApplyMsg)
    else
        self:RequestTopTenTongList()
    end
end

function UIPanelTongApplyList:RequestApplyList()
    if self.m.bRequesting then return end
    RemoteCallToServer("On_Tong_GetApplyJoinInList")
    self.m.bRequesting = true
end

function UIPanelTongApplyList:UpdateList()
    local list = self.ScrollViewApplicationInformation
    assert(list)
    UIHelper.RemoveAllChildren(list)

    local arr    = self.m.tApplyList
    local bEmpty = not arr or #arr == 0
    UIHelper.SetVisible(self.WidgetDescibe, bEmpty)
    UIHelper.SetVisible(self.BtnAllReject, not bEmpty)
    UIHelper.SetVisible(self.BtnAllAccept, not bEmpty)
    if bEmpty then return end

    for i, tData in ipairs(arr) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetApplicationInformation, list)
        assert(cell)
        self:UpdateCell(cell, tData)
    end
    UIHelper.ScrollViewDoLayout(list)
    UIHelper.ScrollToTop(list, 0, false)

end

local _tCellFieldNameArr = {
    "LabelRoleName",
    "ImgPlayerIcon",
    "AnimatePlayerIcon",
    "SFXPlayerIcon",
    "LabelLevel",
    "BtnReject",
    "BtnAccept",
}
function UIPanelTongApplyList:UpdateCell(cell, tData)
    assert(cell)
    local nPlayerID = tData.dwID
    local tCell     = {}
    UIHelper.FindNodeByNameArr(cell, tCell, _tCellFieldNameArr)

    UIHelper.SetString(tCell.LabelRoleName, UIHelper.GBKToUTF8(tData.szName))
    UIHelper.SetString(tCell.LabelLevel, tostring(tData.nLevel) .. "级")

    if tData.dwForceID then
        local dwMiniAvatarID = 0
        local nRoleType      = nil
        local dwForceID      = tData.dwForceID
        UIHelper.RoleChange_UpdateAvatar(tCell.ImgPlayerIcon, dwMiniAvatarID, tCell.SFXPlayerIcon, tCell.AnimatePlayerIcon, nRoleType, dwForceID, true)
    end

    -- 头像
    -- local tMiniAvatar = Table_GetMiniAvatarID(tData.dwForceID)
    -- if tMiniAvatar then
    -- 	UIHelper.RoleChange_UpdateAvatar(tCell.ImgPlayer, tMiniAvatar.dwMiniAvatarID, tCell.SFXPlayerIcon)
    -- end	

    local nPlayerGroupID = TongData.GetCurMemberInfo().nGroupID
    local nGroupID       = GetTongClient().GetDefaultGroupID()
    local bPermission    = GetTongClient().CanAdvanceOperate(nPlayerGroupID, nGroupID, TONG_OPERATION_INDEX.ADD_TO_GROUP)

    UIHelper.SetButtonState(tCell.BtnAccept, bPermission and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(tCell.BtnReject, bPermission and BTN_STATE.Normal or BTN_STATE.Disable)

    UIHelper.BindUIEvent(tCell.BtnReject, EventType.OnClick, function()
        self:RejectApply(nPlayerID)
    end)
    UIHelper.BindUIEvent(tCell.BtnAccept, EventType.OnClick, function()
        self:AcceptApply(nPlayerID)
    end)

end

function UIPanelTongApplyList:AcceptApply(nPlayerID)
    RemoteCallToServer("On_Tong_AddApplyJoinPlayer", nPlayerID)
    RemoteCallToServer("On_Tong_DelApplyJoin", nPlayerID)
end

function UIPanelTongApplyList:RejectApply(nPlayerID)
    RemoteCallToServer("On_Tong_DelApplyJoin", nPlayerID)
end

-- 远程调用单个函数一秒内最多允许16个（g_pSO3World->m_nPlayerRemoteCallMaxCount），这里限制每0.2秒发一个，避免被踢下线
local function DoOneByOne(self, tApplyList, bAccept)
    if #tApplyList == 0 then
        return
    end

    local tData          = table.remove(tApplyList, 1)
    local tRemainingList = tApplyList

    if bAccept then
        self:AcceptApply(tData.dwID)
    else
        self:RejectApply(tData.dwID)
    end

    Timer.Add(Global, 0.2, function()
        DoOneByOne(self, tRemainingList, bAccept)
    end)
end

function UIPanelTongApplyList:AcceptAllApply()
    local arr = self.m.tApplyList
    DoOneByOne(self, clone(arr), true)
end

function UIPanelTongApplyList:RejectAllApply()
    local arr = self.m.tApplyList

    DoOneByOne(self, clone(arr), false)
end

function UIPanelTongApplyList:Close()
    UIMgr.Close(self)
end

function UIPanelTongApplyList:UpdateRecommendWidgetsVisible(bHasAny)
    --UIHelper.SetVisible(self.WidgetRecommendTitle, bHasAny)
    UIHelper.SetVisible(self.ScrollViewTopTenTongList, bHasAny)
    UIHelper.SetVisible(self.WidgetEmptyTopTenTongList, not bHasAny)
end

function UIPanelTongApplyList:RequestTopTenTongList()
    local bHasAny = false
    self:UpdateRecommendWidgetsVisible(bHasAny)

    RemoteCallToServer("On_Tong_GetTopTenTongList")
    RemoteCallToServer("On_Tong_GetTopTenCost")
end

---@param tTongArr TopTenTongInfo[] 推荐帮会信息
function UIPanelTongApplyList:UpdateTopTenTongInfo(nCount, tTongArr)
    local bHasAny = #tTongArr > 0
    self:UpdateRecommendWidgetsVisible(bHasAny)

    UIHelper.RemoveAllChildren(self.ScrollViewTopTenTongList)

    for k, tTong in ipairs(tTongArr) do
        -- note: 由于帮会列表使用该组件时，没有通过绑定脚本的方式进行，因此将这个组件设置为不自动调用初始化函数，并在这里手动调用，从而不影响原来的用法
        ---@type UIFactionList
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFactionList, self.ScrollViewTopTenTongList)
        script:OnEnter(not self.bApplyList, tTong, true)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTopTenTongList)
end

function UIPanelTongApplyList:UpdateTopTenCost(nLastCost, nMyTongCost, nRanking)
    self.nLastCost = nLastCost

    local szMessage
    local nCost

    if nMyTongCost > 0 then
        -- 已竞标
        --szText = GetFormatText(g_tStrings.STR_GUILD_LIST_TOP_TEN_SUCCESS, GUILD_LIST_TOP_TEN_FONT_MY) .. GetGoldText(nCost, GUILD_LIST_TOP_TEN_FONT_MY)
        szMessage = g_tStrings.STR_GUILD_LIST_TOP_TEN_SUCCESS
        nCost     = nMyTongCost
    else
        szMessage = "下周推荐帮会最低竞标费用 "
        nCost     = nLastCost
    end

    UIHelper.SetString(self.LabelAuctionDescription, szMessage)
    UIHelper.SetString(self.LabelAuctionPrice, nCost)
    UIHelper.LayoutDoLayout(self.LayoutAuctionInfo)

    UIHelper.SetButtonState(self.BtnRecommendAuction, nMyTongCost > 0 and BTN_STATE.Disable or BTN_STATE.Normal)
end

function UIPanelTongApplyList:OpenPanelAddTopTen()
    UIMgr.Open(VIEW_ID.PanelFactionRecommendAuctionPop, self.nLastCost)
end

return UIPanelTongApplyList