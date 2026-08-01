-- ---------------------------------------------------------------------------------
-- Author: hanyu
-- Name: UIConfirmView
-- Date: 2022-10-31 17:33:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIConfirmView
local UIConfirmView = class("UIConfirmView")

local Def = {
    ShowRewardListTime = 10,
    RewardListWidthUnitByItem = 10,
}

local HEIGHT_THRESHOLD_VALUE = 210

local function gsubMessage(key, arg0, arg1)
	if key == "countdown_s" then
		return tostring(math.max(tonumber(arg0) - (GetCurrentTime() - tonumber(arg1)), 0))
	elseif key == "countdown_ms" then
		local nCDTime = math.max(tonumber(arg0) - (GetCurrentTime() - tonumber(arg1)), 0)
		local nH, nM, nS = GetTimeToHourMinuteSecond(nCDTime, false)
		return string.format("%02d:%02d", nM, nS)
	end
end

local ImgButtonPath = {
    ["Yellow"] = "UIAtlas2_Public_PublicButton_PublicButton1_PublicBtn_tuijian",
    ["Blue"] = "UIAtlas2_Public_PublicButton_PublicButton1_PublicBtn_Normal"
}

function UIConfirmView:OnEnter(szContent, funcConfirm, funcCancel, bRichText, szContent2, tbMoney, bDisableEnter)
    UIHelper.SetVisible(self.WidgetContent, false)
    UIHelper.SetVisible(self.WidgetReward, false)
    UIHelper.SetVisible(self.WidgetChooseNum, false)
    self.bTouchMaskClose = false --默认点空白处不关闭
    self.bDisableEnter = bDisableEnter or false --是否禁用Enter键响应
    self.bRewardMode = false

    if szContent then
        UIHelper.SetVisible(self.WidgetContent, true)
        self.szContent = szContent
        self.szContent2 = szContent2
        self.funcConfirm = funcConfirm
        self.funcCancel = funcCancel
        self.bRichText = bRichText
        self.tbMoney = tbMoney
        self:UpdateInfo()
    else
        UIHelper.SetVisible(self.WidgetReward, true)
        self.bRewardMode = true
        self:InitForRewardList()
    end

    self:RegEvent()
    self:BindUIEvent()

    TipsHelper.CallRewardListEvent()
end

function UIConfirmView:OnExit()
    -- self:UnRegEvent()
    TipsHelper.DeleteAllHoverTips()
    
    if self.nCallId then
        Timer.DelTimer(self, self.nCallId)
        self.nCallId = nil
    end

    self:UnInitForRewardList()

end

function UIConfirmView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCalloff,EventType.OnClick,function()

        UIMgr.Close(self._nViewID)

        if self.funcCancel then
            local bOptionChecked = UIHelper.GetVisible(self.TogOption) and UIHelper.GetSelected(self.TogOption)
            self.funcCancel(bOptionChecked)
        end

    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()

        UIMgr.Close(self._nViewID)

        if self.funcConfirm then
            local bOptionChecked = UIHelper.GetVisible(self.TogOption) and UIHelper.GetSelected(self.TogOption)
            self.funcConfirm(bOptionChecked)
        end

    end)

    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function(btn)
        UIMgr.Close(self._nViewID)

        if self.funcOther then
            local bOptionChecked = UIHelper.GetVisible(self.TogOption) and UIHelper.GetSelected(self.TogOption)
            self.funcOther(bOptionChecked)
        end

    end)


    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        if GetCurrentTime() > self.nCanCloseTime then
            UIMgr.Close(self._nViewID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function()
        if self.funcAdd then
            self.funcAdd()
        end
    end)

    UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function()
        if self.funcMinus then
            self.funcMinus()
        end
    end)

    UIHelper.BindUIEvent(self.ToggleTip, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnNoMorePrompts then
            self.fnNoMorePrompts(bSelected)
        end
    end)

    UIHelper.BindUIEvent(self.BtnChooseNumConfirm, EventType.OnClick, function()
        UIMgr.Close(self._nViewID)

        if self.funcConfirm then
            local bOptionChecked = UIHelper.GetVisible(self.TogOption) and UIHelper.GetSelected(self.TogOption)
            self.funcConfirm(bOptionChecked)
        end
    end)

    UIHelper.BindUIEvent(self.BtnChooseNumCancel, EventType.OnClick, function()
        UIMgr.Close(self._nViewID)

        if self.funcCancel then
            local bOptionChecked = UIHelper.GetVisible(self.TogOption) and UIHelper.GetSelected(self.TogOption)
            self.funcCancel(bOptionChecked)
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
        if self.fnEditAction then
            self.fnEditAction()
        end
    end)
end

function UIConfirmView:RegEvent()
    Event.Reg(self, "ShowRewardListTip", function (tRewardList,nCanCloseTime)
        self:OnShowRewardListTip(tRewardList,nCanCloseTime)
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function(scriptView)
        if self.bTouchMaskClose and self == scriptView then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.OnKeyboardDownForGameSetting, function(nKeyCode, szKeyName) --设置界面里的弹窗也要能按
        self:OnKeyboardDown(nKeyCode, szKeyName)
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        self:OnKeyboardDown(nKeyCode, szKeyName)
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if not self.bRewardMode then return end
        local tbConf = TabHelper.GetUIViewTab(nViewID)
        if tbConf and UILayer[tbConf.szLayerName] == UILayer.Page then
            UIMgr.Close(self._nViewID)
        end
    end)
end

function UIConfirmView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIConfirmView:UpdateInfo()
    if not self.szContent2 then
        UIHelper.SetVisible(self.LabelHintNormal, not self.bRichText)
    else
        UIHelper.SetVisible(self.LayoutPayMoney, not self.bRichText)
    end
    local nHeight = 0
    if self.bRichText then
        UIHelper.SetRichText(self.LabelHint, self.szContent)
        UIHelper.SetRichText(self.LabelHint01, self.szContent)
        nHeight = UIHelper.GetHeight(self.LabelHint)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        self:SetContentCountDown()
    else
        if not self.szContent2 then
            UIHelper.SetVisible(self.LayoutHintNormal, true)
            UIHelper.SetVisible(self.TogHintNormal, false)
            UIHelper.SetString(self.LabelHintNormal, self.szContent)
            self:SetContentCountDown()
        else
            UIHelper.SetString(self.LabelTip, self.szContent)
            UIHelper.SetString(self.LabelOthers, self.szContent2)
            if self.tbMoney.nGoldB and self.tbMoney.nGoldB ~= 0 then
                UIHelper.SetVisible(self.LabelMoney1, true)
                UIHelper.SetVisible(self.ImgCoin1, true)
                UIHelper.SetString(self.LabelMoney1, tostring(self.tbMoney.nGoldB))
            end
            if self.tbMoney.nGold and self.tbMoney.nGold ~= 0 then
                UIHelper.SetVisible(self.LabelMoney2, true)
                UIHelper.SetVisible(self.ImgCoin2, true)
                UIHelper.SetString(self.LabelMoney2, tostring(self.tbMoney.nGold))
            end
            if self.tbMoney.nSilver and self.tbMoney.nSilver ~= 0 then
                UIHelper.SetVisible(self.LabelMoney3, true)
                UIHelper.SetVisible(self.ImgCoin3, true)
                UIHelper.SetString(self.LabelMoney3, tostring(self.tbMoney.nSilver))
            end
            if self.tbMoney.nCopper and self.tbMoney.nCopper ~= 0 then
                UIHelper.SetVisible(self.LabelMoney4, true)
                UIHelper.SetVisible(self.ImgCoin4, true)
                UIHelper.SetString(self.LabelMoney4, tostring(self.tbMoney.nCopper))
            end
        end
    end
    UIHelper.SetVisible(self.LayoutHint, self.bRichText and nHeight <= HEIGHT_THRESHOLD_VALUE)
    UIHelper.SetVisible(self.ScrollViewContent, self.bRichText and nHeight > HEIGHT_THRESHOLD_VALUE)
end

function UIConfirmView:SetNromalContent(szContent)
    UIHelper.SetString(self.LabelHintNormal, szContent)
end

function UIConfirmView:ShowButton(szButtonName)
    if szButtonName=="Cancel" then
        UIHelper.SetVisible(self.BtnCalloff,true)
    elseif szButtonName=="Confirm" then
        UIHelper.SetVisible(self.BtnOk,true)
    elseif szButtonName=="Other" then
        UIHelper.SetVisible(self.BtnGo,true)
    end
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end


function UIConfirmView:HideButton(szButtonName)
    if szButtonName=="Cancel" then
        UIHelper.SetVisible(self.BtnCalloff,false)
    elseif szButtonName=="Confirm" then
        UIHelper.SetVisible(self.BtnOk,false)
    elseif szButtonName=="Other" then
        UIHelper.SetVisible(self.BtnGo,false)
    end
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIConfirmView:SetButtonContent(szButtonName, szContent)
    if szButtonName=="Cancel" then
        self:SetCancelButtonContent(szContent)
    elseif szButtonName=="Confirm" then
        self:SetConfirmButtonContent(szContent)
    elseif szButtonName=="Other" then
        self:SetOtherButtonContent(szContent)
    end
end

function UIConfirmView:SetButtonColor(szButtonName, szColorName)
    if szButtonName=="Cancel" then
        UIHelper.SetSpriteFrame(self.ImgCalloff, ImgButtonPath[szColorName])
    elseif szButtonName=="Confirm" then
        UIHelper.SetSpriteFrame(self.ImgOk, ImgButtonPath[szColorName])
    elseif szButtonName=="Other" then
        UIHelper.SetSpriteFrame(self.ImgGo, ImgButtonPath[szColorName])
    end
end

function UIConfirmView:ShowCancelButton()
    UIHelper.SetVisible(self.BtnCalloff,true)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIConfirmView:ShowConfirmButton()
    UIHelper.SetVisible(self.BtnOk,true)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIConfirmView:ShowOtherButton()
    UIHelper.SetVisible(self.BtnGo,true)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIConfirmView:HideCancelButton()
    UIHelper.SetVisible(self.BtnCalloff,false)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIConfirmView:HideConfirmButton()
    UIHelper.SetVisible(self.BtnOk,false)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIConfirmView:HideOtherButton()
    UIHelper.SetVisible(self.BtnGo,false)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIConfirmView:SetCancelButtonContent(szContent)
    UIHelper.SetString(self.LabelCalloff, szContent)
end

function UIConfirmView:SetConfirmButtonContent(szContent)
    UIHelper.SetString(self.LabelOk, szContent)
end

function UIConfirmView:SetOtherButtonContent(szContent)
    UIHelper.SetString(self.LabelGo,szContent)
end

function UIConfirmView:SetOtherButtonClickedCallback(funcCallback)
    self.funcOther = funcCallback
end

function UIConfirmView:ShowTogOption(szContent, bDefaultChecked)
    if self.bRichText then
        UIHelper.SetVisible(self.TogHint, true)
        UIHelper.SetSelected(self.TogHint, bDefaultChecked)
        UIHelper.SetString(self.LabelHintNormal01, szContent)
        local layout = UIHelper.GetParent(self.LabelHintNormal01)
        UIHelper.LayoutDoLayout(layout)
    else
        UIHelper.SetVisible(self.TogOption, true)
        UIHelper.SetSelected(self.TogOption, bDefaultChecked)
        UIHelper.SetString(self.LabelTogOption, szContent)
        local layout = UIHelper.GetParent(self.LabelTogOption)
        UIHelper.LayoutDoLayout(layout)
    end
end

function UIConfirmView:SetAutoClose(fnAutoClose)
    Timer.DelTimer(self, self.nAutoCloseTimerID)
    if fnAutoClose then
        self.nAutoCloseTimerID = Timer.AddFrameCycle(self, 1, function()
            if fnAutoClose()  then
                UIHelper.StopAni(self, self.AniAll, "AniContent")--防止打开界面动画没播完的时候关闭卡住
                UIMgr.Close(self)
            end
        end)
    end
end

function UIConfirmView:SetDynamicText(fnGetText)
    Timer.DelTimer(self, self.nDynamicTextTimerID)
    if fnGetText then
        UIHelper.SetVisible(self.LabelTime, true)
        self.nDynamicTextTimerID = Timer.AddFrameCycle(self, 1, function()
            local szText = fnGetText()
            UIHelper.SetString(self.LabelTime, szText)
        end)
    else
        UIHelper.SetVisible(self.LabelTime, false)
    end
end

function UIConfirmView:InitForRewardList()
    self.nEndTime = self.nEndTime or (GetCurrentTime() + Def.ShowRewardListTime)
    self.nCanCloseTime = self.nCanCloseTime or (GetCurrentTime() + Def.ShowRewardListTime)
    self.tMoney = FormatMoneyTab(0)

    self.nCallId = Timer.AddDelayCycle(self, 1, 1, function ()
        self:OnUpdateForRewardList()
    end)
end

function UIConfirmView:UnInitForRewardList()
    local list = self.ScrollViewItemShell assert(list)
    UIHelper.RemoveAllChildren(list)
end

function UIConfirmView:OnUpdateForRewardList()
    if GetCurrentTime() > self.nEndTime then
        UIMgr.Close(self._nViewID)
    end
end

function UIConfirmView:OnShowServiceTip()
    Event.Reg(self, EventType.OnRichTextOpenUrl, function (szUrl, node)
        if szUrl == "GoServiceHelp" then
            ServiceCenterData.OpenServiceWeb()
        end
    end)
end

function UIConfirmView:OnShowRewardListTip(tRewardList,nCanCloseTime)
    local player = GetClientPlayer()
    if not player then return end

    self.tRewardList = self.tRewardList or {}
    table.insert_tab(self.tRewardList, tRewardList)
    local bTooMuch = #self.tRewardList > 11

    local list = self.ScrollViewItemShell assert(list)
    if not bTooMuch then
        list = self.LayoutItemShellShort assert(list)
    end
    UIHelper.RemoveAllChildren(list)

    UIHelper.SetVisible(self.ScrollViewItemShell, bTooMuch)
    UIHelper.SetVisible(self.LayoutItemShellShort, not bTooMuch)

    local nMoneyCount = 0
    for i, tReward in ipairs(self.tRewardList) do
        if tReward.nItemId == 0 then
            nMoneyCount = nMoneyCount + 1
            self.tMoney = MoneyOptAdd(self.tMoney, tReward.nCount)
            local label = self.LayoutMoneyShell:getChildByName("RichTextMoney") assert(label)
            UIHelper.SetMoneyText(label, self.tMoney, 30)
            local icon = self.LayoutMoneyShell:getChildByName("ImgIcon") assert(icon)
            UIHelper.SetVisible(icon, false)
            -- UIHelper.SetMoneyIcon(icon, self.tMoney)
        elseif tReward.nTabType and tReward.nTabType ~= 0 then
            local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, list) assert(tItemScript)
            tItemScript:OnInitWithTabID(tReward.nTabType,tReward.nTabID)
            tItemScript:SetLabelCount(tReward.nCount)
            tItemScript:SetClickCallback(function(dwItemTabType, dwItemTabIndex)
                TipsHelper.DeleteAllHoverTips()
                local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(tItemScript._rootNode, dwItemTabType, dwItemTabIndex)
                uiItemTipScript:SetBtnState({})
            end)
            UIHelper.SetAnchorPoint(tItemScript._rootNode, 0, 0)
        elseif tReward.nTabID == "prestige" then
            local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, list) assert(tItemScript)
            tItemScript:OnInitWithCurrencyType(tReward.nTabID)
            tItemScript:SetLabelCount(tReward.nCount)
            tItemScript:SetClickCallback(function()
                TipsHelper.DeleteAllHoverTips()
                CurrencyData.ShowCurrencyHoverTipsInDir(tItemScript._rootNode, TipsLayoutDir.RIGHT_CENTER, CurrencyNameToType[tReward.nTabID])
            end)
            UIHelper.SetAnchorPoint(tItemScript._rootNode, 0, 0)
        else
            local item = GetItem(tReward.nItemId)
            if item then
                local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, list) assert(tItemScript)
                UIHelper.InitItemIcon(tItemScript, item, tReward.nCount , true)
                UIHelper.SetAnchorPoint(tItemScript._rootNode, 0, 0)
            end
        end
    end

    -- 当奖励只有货币时修改标题为获得货币
    if nMoneyCount == #tRewardList then
        UIHelper.SetString(self.LabelTitle, "获得货币")
    end
    -- 修正list大小
    local children = UIHelper.GetChildren(list)
    local nChildCount = #children
    local nCount = math.min(Def.RewardListWidthUnitByItem, nChildCount)
    UIHelper.SetWidth(list, nCount * 100 + (nCount - 1) * 20)

    -- 排版
    if bTooMuch then
        UIHelper.ScrollViewDoLayout(list)
        UIHelper.ScrollToTop(list, 0, false)
    else
        UIHelper.LayoutDoLayout(list)
    end

    --list:setDirection(nChildCount > Def.RewardListWidthUnitByItem and 2 or 0)
    UIHelper.SetVisible(self.LayoutMoneyShell, MoneyOptCmp(self.tMoney, 0) == 1)
    UIHelper.SetVisible(list, nCount > 0)
    UIHelper.LayoutDoLayout(list:getParent())

    self.nEndTime = GetCurrentTime() + Def.ShowRewardListTime
    self.nCanCloseTime = GetCurrentTime() + (nCanCloseTime or 0)
end

--是否点击空白处关闭
function UIConfirmView:SetTouchMaskCloseEnabled(bEnabled)
    self.bTouchMaskClose = bEnabled
end


function UIConfirmView:SetButtonCountDown(nCountDown)
    local szText = UIHelper.GetString(self.LabelOk)
    if not self.nTimer then
        UIHelper.SetButtonState(self.BtnOk, BTN_STATE.Disable)
        UIHelper.SetString(self.LabelOk, szText.."("..nCountDown..")")

        self.nTimer = Timer.AddCountDown(self, nCountDown, function(nRemain)
            UIHelper.SetString(self.LabelOk, szText.."("..nRemain..")")
        end, function()
            UIHelper.SetButtonState(self.BtnOk, BTN_STATE.Normal)
            UIHelper.SetString(self.LabelOk, szText)
            self.nTimer = nil
        end)
    end
end

function UIConfirmView:SetChooseNumContent(szContent, nCount, funcAdd, funcMinus, funcConfirm, fnEditAction)
    UIHelper.SetVisible(self.WidgetContent, false)
    UIHelper.SetVisible(self.WidgetReward, false)
    UIHelper.SetVisible(self.WidgetChooseNum, true)

    UIHelper.SetRichText(self.RichTextContent, szContent)
    UIHelper.SetVisible(self.EditPaginate, funcAdd and true or false)
    UIHelper.SetVisible(self.LabelNum, not (funcAdd and true or false))
    UIHelper.SetString(self.EditPaginate, nCount)
    UIHelper.SetString(self.LabelNum, nCount)

    self.funcAdd = funcAdd
    self.funcMinus = funcMinus
    UIHelper.SetButtonState(self.BtnAdd, funcAdd and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnMinus, funcMinus and BTN_STATE.Normal or BTN_STATE.Disable)

    self.funcConfirm = funcConfirm
    self.fnEditAction = fnEditAction
end

function UIConfirmView:SetChooseNum(szContent, nCount)
    UIHelper.SetRichText(self.RichTextContent, szContent)
    UIHelper.SetString(self.EditPaginate, nCount)
    UIHelper.SetString(self.LabelNum, nCount)
end

function UIConfirmView:GetChooseNum()
    local nCount = UIHelper.GetString(self.EditPaginate)
    return nCount
end

function UIConfirmView:SetConfirmNormalCountDown(nCountDown)
    if not nCountDown or nCountDown <= 0 then
        return
    end
    local szContent = UIHelper.GetString(self.LabelOk)
    local nStartTime = GetTickCount()
    Timer.DelTimer(self, self.nConfirmNormalCDTimerID)
    self.nConfirmNormalCDTimerID = Timer.AddCycle(self, 0.1, function()
        local nSeconds = nCountDown - (GetTickCount() - nStartTime) / 1000
        nSeconds = math.floor(nSeconds + 0.5)
        if nSeconds < 0 then
            nSeconds = 0
        end
        UIHelper.SetString(self.LabelOk, szContent .. "("  .. nSeconds .. ")")
        if nSeconds == 0 then
            UIMgr.Close(self)
        end
    end)
end

function UIConfirmView:SetCancelNormalCountDown(nCountDown)
    if not nCountDown or nCountDown <= 0 then
        return
    end
    local szContent = UIHelper.GetString(self.LabelCalloff)
    local nStartTime = GetTickCount()
    Timer.DelTimer(self, self.nCancelNormalCDTimerID)
    self.nCancelNormalCDTimerID = Timer.AddCycle(self, 0.1, function()
        local nSeconds = nCountDown - (GetTickCount() - nStartTime) / 1000
        nSeconds = math.floor(nSeconds + 0.5)
        if nSeconds < 0 then
            nSeconds = 0
        end
        UIHelper.SetString(self.LabelCalloff, szContent .. "("  .. nSeconds .. ")")
        if nSeconds == 0 then
            UIMgr.Close(self)
        end
    end)
end

function UIConfirmView:SetOtherNormalCountDown(nCountDown)
    if not nCountDown or nCountDown <= 0 then
        return
    end
    local szContent = UIHelper.GetString(self.LabelGo)
    local nStartTime = GetTickCount()
    Timer.DelTimer(self, self.nOtherNormalCDTimerID)
    self.nOtherNormalCDTimerID = Timer.AddCycle(self, 0.1, function()
        local nSeconds = nCountDown - (GetTickCount() - nStartTime) / 1000
        nSeconds = math.floor(nSeconds + 0.5)
        if nSeconds < 0 then
            nSeconds = 0
        end
        UIHelper.SetString(self.LabelGo, szContent .. "("  .. nSeconds .. ")")
        if nSeconds == 0 then
            UIMgr.Close(self)
        end
    end)
end

function UIConfirmView:SetContentCountDown()
    local pattern = "{%$([^%s]+)%s*([^%s]*)%s*([^%s]*)}"
    local bCountDown = false
    local szContent = self.szContent:gsub(pattern, function(key, arg0, arg1)
        if key == "countdown_s" or key == "countdown_ms" then
            bCountDown = true
            if arg1 == "" then
                return "{$" .. key .. " " .. arg0 .. " " .. GetCurrentTime() .. "}"
            end
        end
    end)
    if not bCountDown then
        return
    end
    Timer.DelTimer(self, self.nContentCDTimerID)
    self.nContentCDTimerID = Timer.AddCycle(self, 0.1, function()
        local szNewContent = szContent:gsub(pattern, gsubMessage)
        if self.bRichText then
            UIHelper.SetRichText(self.LabelHint, szNewContent)
        else
            UIHelper.SetString(self.LabelHintNormal, szNewContent)
        end
    end)
end

function UIConfirmView:SetConfirmNormalCountDownWithCallback(nCountDown, fnCallBack)
    if not nCountDown or nCountDown <= 0 then
        return
    end
    local szContent = UIHelper.GetString(self.LabelOk)
    local nStartTime = GetTickCount()
    Timer.DelTimer(self, self.nConfirmNormalCDTimerID)
    self.nConfirmNormalCDTimerID = Timer.AddCycle(self, 0.1, function()
        local nSeconds = nCountDown - (GetTickCount() - nStartTime) / 1000
        nSeconds = math.floor(nSeconds + 0.5)
        if nSeconds < 0 then
            nSeconds = 0
        end
        UIHelper.SetString(self.LabelOk, szContent .. "("  .. nSeconds .. ")")
        if nSeconds == 0 then
            if fnCallBack then
                fnCallBack()
            end
            UIMgr.Close(self)
        end
    end)
end

function UIConfirmView:SetCancelNormalCountDownWithCallback(nCountDown, fnCallBack)
    if not nCountDown or nCountDown <= 0 then
        return
    end
    local szContent = UIHelper.GetString(self.LabelCalloff)
    local nStartTime = GetTickCount()
    Timer.DelTimer(self, self.nCancelNormalCDTimerID)
    self.nCancelNormalCDTimerID = Timer.AddCycle(self, 0.1, function()
        local nSeconds = nCountDown - (GetTickCount() - nStartTime) / 1000
        nSeconds = math.floor(nSeconds + 0.5)
        if nSeconds < 0 then
            nSeconds = 0
        end
        UIHelper.SetString(self.LabelCalloff, szContent .. "("  .. nSeconds .. ")")
        if nSeconds == 0 then
            if fnCallBack then
                fnCallBack()
            end
            UIMgr.Close(self)
        end
    end)
end

function UIConfirmView:SetDynamicTextCountDown(szContent, nCountDown)
    if not nCountDown or nCountDown <= 0 then
        return
    end
    local nStartTime = GetTickCount()
    Timer.DelTimer(self, self.nCancelNormalCDTimerID)
    self.nCancelNormalCDTimerID = Timer.AddCycle(self, 0.1, function()
        local nSeconds = nCountDown - (GetTickCount() - nStartTime) / 1000
        nSeconds = math.floor(nSeconds + 0.5)
        if nSeconds < 0 then
            nSeconds = 0
        end
        UIHelper.SetVisible(self.LabelTime, true)
        UIHelper.SetString(self.LabelTime, szContent .. nSeconds .. "秒")
        if nSeconds == 0 then
            UIMgr.Close(self)
        end
    end)
end

function UIConfirmView:OnKeyboardDown(nKeyCode, szKeyName)
    local bOkVis = UIHelper.GetHierarchyVisible(self.BtnOk)
    local bCanCelVis = UIHelper.GetHierarchyVisible(self.BtnCalloff)
    local bGoVis = UIHelper.GetHierarchyVisible(self.BtnGo)

    local nOkState = UIHelper.GetButtonState(self.BtnOk)
    if nKeyCode == cc.KeyCode.KEY_ENTER and not self.bDisableEnter then
        if bOkVis and nOkState == BTN_STATE.Normal then
            UIHelper.SimulateClick(self.BtnOk)
        elseif bCanCelVis and not bGoVis and not bOkVis then--确认以及Go按钮隐藏才执行取消
            UIHelper.SimulateClick(self.BtnCalloff)
        end
    elseif nKeyCode == cc.KeyCode.KEY_ESCAPE then
        if bCanCelVis then
            UIHelper.SimulateClick(self.BtnCalloff)
        elseif bOkVis and not bGoVis and nOkState == BTN_STATE.Normal then
            UIHelper.SimulateClick(self.BtnOk)
        end
    end
end


function UIConfirmView:SetTogSelectedFunc(func)
    if self.bRichText then
        UIHelper.BindUIEvent(self.TogHint, EventType.OnSelectChanged, function(_, bSelected)
            func(bSelected)
        end)
    else
        UIHelper.BindUIEvent(self.TogOption, EventType.OnSelectChanged, function(_, bSelected)
            func(bSelected)
        end)
    end
end

function UIConfirmView:SetNoMorePromptsFunc(func)
    if not func then
        return
    end
    self.fnNoMorePrompts = func
    UIHelper.SetVisible(self.WidgetNoMorePrompts, true)
    UIHelper.SetVisible(self.ToggleTips, true)
end

function UIConfirmView:SetName(szName)
    self.szName = szName
end

function UIConfirmView:GetName()
    return self.szName or ""
end

return UIConfirmView