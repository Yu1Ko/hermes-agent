-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetWants
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------
Wanted_Publish = 
{
	dwStartTime = 0,
    bPrivate = false, -- 是否私密
}
local UIWidgetWants = class("UIWidgetWants")
function UIWidgetWants:OnEnter(szName, bIsAppend, bPrivate)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bAnonymity = true
    self.bPrivate = bPrivate
    if bPrivate == nil then
        self.bPrivate = Wanted_Publish.bPrivate
    end
    if bIsAppend then
        UIHelper.SetString(self.LabelTitle, "追加决斗金额")
    end
    self:UpdateInfo(szName)
end

function UIWidgetWants:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetWants:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelReleaseRewardPop)
    end)

    UIHelper.BindUIEvent(self.BtnWants, EventType.OnClick, function ()
        self:OnWantsPublish()
        UIMgr.Close(VIEW_ID.PanelReleaseRewardPop)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxName, function ()
        local szName = UIHelper.GetText(self.EditBoxName)
        RemoteCallToServer("OnGetWantedMinMoneyLimitRequest", UIHelper.UTF8ToGBK(szName), self.bPrivate)
        -- UIHelper.SetPlaceHolder(self.EditBoxMoney, g_tStrings.STR_SYNC_INFO)
        UIHelper.SetEnable(self.EditBoxMoney, false)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxMoney, function ()
        local szText = UIHelper.GetText(self.EditBoxMoney)
        local nMoney = tonumber(szText) or 0
        UIHelper.SetText(self.EditBoxMoney, tostring(nMoney))
    end)

    UIHelper.BindUIEvent(self.ToggleGroup, EventType.OnToggleGroupSelectedChanged, function(toggle, index, eventType)
        self.bAnonymity = index == 0
    end)

    UIHelper.BindUIEvent(self.ToggleGroupPublic, EventType.OnToggleGroupSelectedChanged, function(toggle, index, eventType)
        self.bPrivate = index ~= 0
        Wanted_Publish.bPrivate = self.bPrivate
        UIHelper.SetVisible(self.WidgetAnonymous, self.bPrivate)
        UIHelper.SetString(self.LabelTimePrompt, string.format("发布后，决斗挑战时间持续%s天", self.bPrivate and "三" or "七"))
        UIHelper.LayoutDoLayout(self.LayoutContent)
        local szName = UIHelper.GetText(self.EditBoxName)
        if szName and szName ~= "" then
            RemoteCallToServer("OnGetWantedMinMoneyLimitRequest", UIHelper.UTF8ToGBK(szName), self.bPrivate)
        end
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function ()
        UIHelper.SetVisible(self.WidgetRichTextTips, not UIHelper.GetVisible(self.WidgetRichTextTips))
    end)
end

function UIWidgetWants:RegEvent()
    Event.Reg(self, "ON_GET_WANTED_MIN_MONEY_LIMIT", function (szName, nMinLimit, nMaxLimit)
        self:OnGetWantedMinMoney(szName, nMinLimit, nMaxLimit)
    end)
    Event.Reg(self, EventType.HideAllHoverTips,function()
        UIHelper.SetVisible(self.WidgetRichTextTips, false)
    end)
end

function UIWidgetWants:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetWants:UpdateInfo(szName)

    UIHelper.SetVisible(self.LabelMoneyRange, false)
    if szName then
        UIHelper.SetText(self.EditBoxName, szName)
        UIHelper.SetVisible(self.LabelMoneyRange, false)
        RemoteCallToServer("OnGetWantedMinMoneyLimitRequest", UIHelper.UTF8ToGBK(szName))
        -- UIHelper.SetPlaceHolder(self.EditBoxMoney, g_tStrings.STR_SYNC_INFO)
        UIHelper.SetEnable(self.EditBoxMoney, false)
    end
    --ToDo:匿名tog状态
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogTypeTrue)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogTypeFalse)
    UIHelper.SetToggleGroupSelected(self.ToggleGroup, 0)

    UIHelper.ToggleGroupAddToggle(self.ToggleGroupPublic, self.TogTypePublic)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupPublic, self.TogTypeUnpublic)
    local nIndex = 0
    if self.bPrivate then nIndex = 1 end
    UIHelper.SetToggleGroupSelected(self.ToggleGroupPublic, nIndex)

    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextTips, self.WidgetRichTextTips, ParseTextHelper.ParseNormalText(g_tStrings.STR_WANTEDTIP1, false))
    script:SetRichTextWidth(700)
    UIHelper.SetVisible(self.WidgetRichTextTips, false)
end


function UIWidgetWants:OnWantsPublish()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local szName = UIHelper.GetText(self.EditBoxName)
    local szMoney = UIHelper.GetText(self.EditBoxMoney)
    local nGold = tonumber(szMoney)
    if not szName or not nGold then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_MONEY_NAME_EMPTY)
        return
    elseif Wanted_Publish.nMaxGoldLimit == 0 then
        TipsHelper.ShowNormalTip(g_tStrings.STR_WANTED_EXCEED)
        return
    elseif not Wanted_Publish.nMinMoney then
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_WAIT)
        return
    elseif nGold < Wanted_Publish.nMinMoney then
        local szTip = FormatString(g_tStrings.WANT_PUBLISH_MONEY_MIN_LIMIT, Wanted_Publish.nMinMoney)
        TipsHelper.ShowNormalTip(szTip)
        return
    elseif nGold > Wanted_Publish.nMaxGoldLimit then
        local szTip = FormatString(g_tStrings.WANT_PUBLISH_MONEY_MAX_LIMIT, Wanted_Publish.nMaxGoldLimit)
        TipsHelper.ShowNormalTip(szTip)
        return
    elseif szName == UIHelper.GBKToUTF8(player.szName) then -- 检查输入的名字
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_CANNOT_WANT_SELF)
        return
    end
    if not player.IsMoneyEnough(nGold, 0, 0) then
        TipsHelper.ShowNormalTip(g_tStrings.GUILD_GIVE_NOT_ENOUGH_MONEY)
        return
    end
    --如果有锁,要先解锁~
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.WANTED) then
        return
    end
    
    RemoteCallToServer("OnWantedPlayer", UIHelper.UTF8ToGBK(szName), nGold, self.bPrivate, self.bAnonymity)
end

function UIWidgetWants:OnGetWantedMinMoney(szName, nGold, nMaxLimit)
    if nGold and nMaxLimit then
        local szMoreTip = ""
		local szTip = FormatString(g_tStrings.WANT_PUBLISH_MONEY_TIP, nGold, nMaxLimit)
        if nMaxLimit == 0 then
            szTip = g_tStrings.STR_WANTED_EXCEED
        end
        UIHelper.SetVisible(self.LabelMoreTips, false)
		if nGold > GetWantedPlayerMinGoldLimit() then
			szMoreTip = g_tStrings.WANT_PUBLISH_MONYE_DOUBLE
            UIHelper.SetString(self.LabelMoreTips, g_tStrings.WANT_PUBLISH_MONYE_DOUBLE)
            UIHelper.SetVisible(self.LabelMoreTips, true)
		end
		
		Wanted_Publish.nMinMoney = nGold
        Wanted_Publish.nMaxGoldLimit = nMaxLimit
        -- UIHelper.SetPlaceHolder(self.EditBoxMoney, szTip)
        UIHelper.SetString(self.LabelMoneyRange, szTip)
        UIHelper.SetVisible(self.LabelMoneyRange, true)
        UIHelper.SetText(self.EditBoxMoney, tostring(nGold))
	else
        Wanted_Publish.nMinMoney = nil
        Wanted_Publish.nMaxGoldLimit = nil
        TipsHelper.ShowNormalTip(g_tStrings.WANT_PUBLISH_PLAYER_NOT_EXIST)
        UIHelper.SetPlaceHolder(self.EditBoxMoney, "请输入决斗金额")
	end
    UIHelper.SetEnable(self.EditBoxMoney, true)
end

local function OnWantedRespoond(nErrCode)
    if nErrCode == WANTED_MAN_RESULT_CODE.SUCCESS then
        TipsHelper.ShowNormalTip(g_tStrings.tWanted[nErrCode])
        if not UIMgr.IsViewOpened(VIEW_ID.PanelWuDou) then
            UIMgr.Open(VIEW_ID.PanelWuDou, Wanted_Publish.bPrivate)
        end
	elseif nErrCode == WANTED_MAN_RESULT_CODE.MONEY_TOO_MUCH then
		local szTip = FormatString(g_tStrings.tWanted[nErrCode], Wanted_Publish.nMaxMoney)
        TipsHelper.ShowNormalTip(szTip)
	elseif arg0 == WANTED_MAN_RESULT_CODE.MONEY_TOO_LITTLE then
		local szTip = FormatString(g_tStrings.tWanted[nErrCode], Wanted_Publish.nMinMoney)
		TipsHelper.ShowNormalTip(szTip)
	else
        TipsHelper.ShowNormalTip(g_tStrings.tWanted[nErrCode])
	end
end

Event.Reg(Wanted_Publish, "ON_WANTED_MAN_RESPOND", function (nErrCode)
    OnWantedRespoond(nErrCode)
end)

return UIWidgetWants