-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBodyCodeMainView
-- Date: 2024-03-15 09:51:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBodyCodeMainView = class("UIBodyCodeMainView")

local MAX_DATA_COUNT = 30
local FilterIndex2RoleType =
{
    [1] = -1,
    [2] = ROLE_TYPE.STANDARD_MALE,
    [3] = ROLE_TYPE.STANDARD_FEMALE,
    [4] = ROLE_TYPE.LITTLE_BOY,
    [5] = ROLE_TYPE.LITTLE_GIRL,
}

function UIBodyCodeMainView:OnEnter(bIsLogin)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bIsLogin = bIsLogin

    self:InitView()
    self:UpdateInfo()
end

function UIBodyCodeMainView:OnExit()
    self.bInit = false
    BodyCodeData.UnInit()

    if self.funcCloseCallback then
        self.funcCloseCallback()
    end
end

function UIBodyCodeMainView:BindUIEvent()
    self.scriptScrollViewTab = UIHelper.GetBindScript(self.WidgetList)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnManage, EventType.OnClick, function(btn)
        self.bEnterDelMode = true

        self.nJustShowRoleType = -1
        local tbFilterDefSelected = FilterDef.BodyCodeType.tbRuntime
        if tbFilterDefSelected then
            tbFilterDefSelected[1][1] = 1
        end
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.BOTTOM_CENTER, FilterDef.BodyCodeType)
    end)

    UIHelper.BindUIEvent(self.BtnUse, EventType.OnClick, function(btn)
        if self.bUseBusy then
            TipsHelper.ShowNormalTip("正在导入体型，请稍候")
            return
        end

        BodyCodeData.ReqGetBody(self.szCurSelectBodyCode)
        self.bUseBusy = true
        TipsHelper.ShowNormalTip("正在导入体型，请稍候")
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Disable, "正在导入体型，请稍候")
    end)

    UIHelper.BindUIEvent(self.BtnDeleteExit, EventType.OnClick, function(btn)
        self.bEnterDelMode = false

        self.nJustShowRoleType = -1
        local tbFilterDefSelected = FilterDef.BodyCodeType.tbRuntime
        if tbFilterDefSelected then
            tbFilterDefSelected[1][1] = 1
        end
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function(btn)
        if self.bUseBusy then
            TipsHelper.ShowNormalTip("正在导入体型，请稍候")
            return
        end

        local tbDelBodyCodes = {}
        for szCode, _ in pairs(self.tbSelectDelBodyCode) do
            table.insert(tbDelBodyCodes, szCode)
        end
        BodyCodeData.ReqDelBatchBody(tbDelBodyCodes)
        self.tbSelectDelBodyCode = {}
    end)

    UIHelper.BindUIEvent(self.TogCanUseOnly, EventType.OnClick, function(btn)
        self.bJustShowCanUse = UIHelper.GetSelected(self.TogCanUseOnly)
        self:UpdateInfo()
    end)
end

function UIBodyCodeMainView:RegEvent()
    Event.Reg(self, EventType.OnBodyCodeRsp, function (szKey, tInfo)
        if szKey == "LOGIN_ACCOUNT" then
            if BodyCodeData.szSessionID then
                self.bLoginWeb = true
                BodyCodeData.ReqGetBodyList()
            else
                TipsHelper.ShowNormalTip("连接云端服务器失败，请稍候重试")
                UIMgr.Close(self)
            end
        elseif szKey == "GET_BODY_LIST" then
        elseif szKey == "GET_BODY" then
            if tInfo and tInfo.code and tInfo.code ~= 1 then
                self.bUseBusy = false
                self:UpdateBtnState()
            end
        elseif szKey == "DEL_BODY" or szKey == "DEL_BATCH_BODY" then
            self:UpdateBtnState()
            self:DelayReqGetBodyList()
        end
    end)

    Event.Reg(self, EventType.OnDownloadBodyCodeData, function (bSuccess, szBodyCode)
        if szBodyCode == self.szCurSelectBodyCode then
            self.bUseBusy = false
            self:UpdateBtnState()
        end
    end)

    Event.Reg(self, EventType.OnUpdateBodyCodeList, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnUpdateBodyCodeListCell, function ()
        self:DelayUpdateList()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.BodyCodeType.Key then
            self.nJustShowRoleType = FilterIndex2RoleType[tbSelected[1][1]]
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnSelectBodyCodeListCell, function (bSelected, szBodyCode)
        if bSelected then
            self.szCurSelectBodyCode = szBodyCode
        elseif self.szCurSelectBodyCode == szBodyCode then
            self.szCurSelectBodyCode = nil
        end

        self:UpdateBtnState()
    end)

    Event.Reg(self, EventType.OnSelectDelBodyCodeListCell, function (bSelected, szBodyCode)
        if bSelected then
            self.tbSelectDelBodyCode[szBodyCode] = bSelected
        else
            self.tbSelectDelBodyCode[szBodyCode] = nil
        end
        self:UpdateBtnState()
    end)

    Event.Reg(self, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			Timer.Add(self, 0.3, function ()
                UIMgr.Close(self)
            end)
		end
    end)
end

function UIBodyCodeMainView:InitView()
    self.bEnterDelMode = false

    local tbFilterDefSelected = FilterDef.BodyCodeType.tbRuntime
    if tbFilterDefSelected then
        self.nJustShowRoleType = FilterIndex2RoleType[tbFilterDefSelected[1][1]]
    else
        self.nJustShowRoleType = -1
    end
    self.tbSelectDelBodyCode = {}
    BodyCodeData.Init()
    BodyCodeData.LoginAccount(self.bIsLogin)

    -- UIHelper.SetVisible(self.WidgetStepStart, self.bIsLogin)
    -- UIHelper.SetVisible(self.LayoutRightTop, not self.bIsLogin)

    -- if self.bIsLogin then
    --     self.bJustShowCanUse = true
    --     UIHelper.SetSelected(self.TogCanUseOnly, self.bJustShowCanUse)
    -- end
end

function UIBodyCodeMainView:UpdateInfo()
    self:UpdateListInfo()
    self:UpdateBtnState()
end

function UIBodyCodeMainView:UpdateBtnState()
    UIHelper.SetVisible(self.BtnDeleteExit, self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnDelete, self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnUse, not self.bEnterDelMode)
    UIHelper.SetVisible(self.BtnManage, not self.bEnterDelMode)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)

    for _, cell in pairs(self.tbBodyCell or {}) do
        cell:SetEnterDelMode(self.bEnterDelMode)
    end

    if self.szCurSelectBodyCode then
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnUse, BTN_STATE.Disable)
    end

    if table.get_len(self.tbSelectDelBodyCode) > 0 then
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnDelete, BTN_STATE.Disable)
    end

    if self.nJustShowRoleType ~= -1 then
        UIHelper.SetSpriteFrame(self.ImgFilter, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing.png")
    else
        UIHelper.SetSpriteFrame(self.ImgFilter, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen.png")
    end
end

local function SortBodyList(a, b)
    local nNumA = 100
    local nNumB = 100
    if not a then
        nNumA = 0
        return nNumA > nNumB
    end

    if not b then
        nNumB = 0
        return nNumA > nNumB
    end

    local tbDataA = BodyCodeData.GetBodyData(a.szBodyCode)
    local tbDataB = BodyCodeData.GetBodyData(b.szBodyCode)
    if tbDataA and tbDataB then
        local bValidA = tbDataA.nRoleType == BuildBodyData.nRoleType
        local bValidB = tbDataB.nRoleType == BuildBodyData.nRoleType

        if bValidA and bValidB then
            return nNumA > nNumB
        elseif bValidA and not bValidB then
            nNumB = 0
            return nNumA > nNumB
        elseif not bValidA and bValidB then
            nNumA = 0
            return nNumA > nNumB
        end
    elseif tbDataA and not tbDataB then
        nNumB = 0
        return nNumA > nNumB
    elseif not tbDataA and tbDataB then
        nNumA = 0
        return nNumA > nNumB
    end
    return nNumA > nNumB
end

function UIBodyCodeMainView:UpdateListInfo()
    UIHelper.SetString(self.LabelTitleSize, string.format("%d/%d", #(BodyCodeData.tbBodyList or {}), MAX_DATA_COUNT))

    local tbBodyList = {}
    for _, tbInfo in ipairs(BodyCodeData.tbBodyList or {}) do
        local bValidRoleType = false
        local tbBodyData = BodyCodeData.GetBodyData(tbInfo.szBodyCode)
        if tbBodyData then
            bValidRoleType = tbBodyData.nRoleType == self.nJustShowRoleType
        end

        if tbBodyData and (self.nJustShowRoleType == -1 or bValidRoleType) then
            table.insert(tbBodyList, tbInfo)
        end
    end

    table.sort(tbBodyList, SortBodyList)

    self.szCurSelectBodyCode = nil
    UIHelper.HideAllChildren(self.ScrollViewBodyList)
    self.tbBodyCell = self.tbBodyCell or {}
    for i, tbInfo in ipairs(tbBodyList) do
        if not self.tbBodyCell[i] then
            self.tbBodyCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetFaceCodeCell, self.ScrollViewBodyList, {tbInfo = tbInfo, bBody = true})
        end

        UIHelper.SetVisible(self.tbBodyCell[i]._rootNode, true)
        self.tbBodyCell[i]:OnEnter({tbInfo = tbInfo, bBody = true})
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBodyList)
end

function UIBodyCodeMainView:DelayUpdateList()
    if self.nDelayUpdateListTimerID then
        Timer.DelTimer(self, self.nDelayUpdateListTimerID)
        self.nDelayUpdateListTimerID = nil
    end
    self.nDelayUpdateListTimerID = Timer.Add(self, 1, function ()
        BodyCodeData.ReqGetBodyList()
    end)
end

function UIBodyCodeMainView:DelayReqGetBodyList()
    if self.nDelayReqGetBodyListTimerID then
        Timer.DelTimer(self, self.nDelayReqGetBodyListTimerID)
        self.nDelayReqGetBodyListTimerID = nil
    end
    self.nDelayReqGetBodyListTimerID = Timer.Add(self, 1, function ()
        BodyCodeData.ReqGetBodyList()
    end)
end

function UIBodyCodeMainView:SetCloseCallback(funcCloseCallback)
    self.funcCloseCallback = funcCloseCallback
end

return UIBodyCodeMainView