-- ---------------------------------------------------------------------------------
-- Author: zengzipeng
-- Name: UIRedPacketGetListView
-- Date: 2023-11-28 14:51:18
-- Desc: 红包获取列表显示
-- ---------------------------------------------------------------------------------

local UIRedPacketGetListView = class("UIRedPacketGetListView")
local MAX_MONEY = 8 * 100000
function UIRedPacketGetListView:OnEnter(dwNpcID, tInfo)
    self.dwNpcID = dwNpcID
    self.tInfo = tInfo
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIRedPacketGetListView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRedPacketGetListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAddFriend , EventType.OnClick , function ()
        GetSocialManagerClient().AddFellowship(self.tInfo.szOwnerName)
    end)

    UIHelper.BindUIEvent(self.BtnAddFaction , EventType.OnClick , function ()
        local g_player = GetClientPlayer()
        if not g_player then
            return
        end
        if (g_player.nLevel < CAN_APPLY_JOIN_LEVEL) then
			OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.TONG_REQUEST_TOO_LOW)
			OutputMessage("MSG_SYS", g_tStrings.TONG_REQUEST_TOO_LOW .. "\n")
			return
		end
		RemoteCallToServer("On_Tong_ApplyJoinRequest", self.tInfo.szTongName)
    end)
end

function UIRedPacketGetListView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRedPacketGetListView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRedPacketGetListView:UpdateInfo()
    self:UpdateOwnerInfo()
    self:UpdateAllPlayer()

    Timer.AddCycle(self , 1,function ()
        local hPlayer = GetClientPlayer()
        if self.tInfo.dwNpcID then
            local hNpc = GetNpc(self.tInfo.dwNpcID)
            if not hNpc or not hNpc.CanDialog(hPlayer) then
                UIMgr.Close(self)
            end
        end
    end)
end

function UIRedPacketGetListView:UpdateOwnerInfo()
    local szCampTitle = ""
    if self.tInfo.nLimitType == 1 then
		szCampTitle = FormatString(g_tStrings.STR_REDGIFT_TOTEAM, "")
	elseif self.tInfo.nLimitType == 2 then
		szCampTitle = FormatString(g_tStrings.STR_REDGIFT_TOGUILD, "")
	else
		szCampTitle = FormatString(g_tStrings.STR_REDGIFT_TOALL, "")
	end
    UIHelper.SetString(self.LableCampTitle , szCampTitle)
    UIHelper.SetString(self.LableName , UIHelper.GBKToUTF8(self.tInfo.szOwnerName))

    if not self.WidgetHead then
        self.WidgetHead = UIHelper.GetParent(UIHelper.GetParent(self.ImgPlayerIcon))
    end

    UIHelper.RemoveAllChildren(self.WidgetHead)
    self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetHead)
    if self.scriptHead then
        self.scriptHead:SetHeadInfo(nil, self.tInfo.dwMiniAvatarID, self.tInfo.nRoleType,self.tInfo.dwForceID)
    end
    UIHelper.SetString(self.LableFaction , UIHelper.GBKToUTF8(self.tInfo.szTongName))
    UIHelper.SetString(self.LabelRedPacketNum , self.tInfo.nGiftCount)
    UIHelper.SetString(self.LabelMoneyNum , self.tInfo.nCurrency)
    if self.tInfo.nCurrencyType == 1 then
        UIHelper.SetString(self.LabelMoneytNumTitle , "剩余通宝")
	elseif self.tInfo.nCurrencyType == 2 then
		
        UIHelper.SetString(self.LabelMoneytNumTitle , "剩余金币")
	end

    if self.tInfo.bGetEnd then
        UIHelper.SetVisible(self.ImgEnd , true)
		UIHelper.SetVisible(self.ImgComplete , false)
	elseif self.tInfo.nGiftCount == 0 then
        UIHelper.SetVisible(self.ImgEnd , false)
		UIHelper.SetVisible(self.ImgComplete , true)
	else
        UIHelper.SetVisible(self.ImgEnd , false)
		UIHelper.SetVisible(self.ImgComplete , false)
	end

end

function UIRedPacketGetListView:UpdateAllPlayer()
    UIHelper.RemoveAllChildren(self.ScrollViewClaimList)
    local tPlayers = self.tInfo.GetInfo
    local nMostMoney = 0
	local tMostMoneyNum = {}
	local nLeastMoney = MAX_MONEY
	local tLeastMoneyNum = {}
    local tbScript = {}
    for k, v in ipairs(tPlayers) do
        local cellScript =  UIHelper.AddPrefab(PREFAB_ID.WidgetClaimList , self.ScrollViewClaimList , v , self.tInfo.nCurrencyType)
        if v.nCurrency == nMostMoney then
			table.insert(tMostMoneyNum, k)
		end
		if v.nCurrency > nMostMoney then
			nMostMoney = v.nCurrency
			tMostMoneyNum = {}
			table.insert(tMostMoneyNum, k)
		end

		if v.nCurrency == nLeastMoney then
			table.insert(tLeastMoneyNum, k)
		end
		if v.nCurrency < nLeastMoney then
			nLeastMoney = v.nCurrency
			tLeastMoneyNum = {}
			table.insert(tLeastMoneyNum, k)
		end
        table.insert(tbScript , cellScript)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewClaimList)
    if self.tInfo.nGiftCount == 0 or self.tInfo.bGetEnd then
		for k, v in ipairs(tLeastMoneyNum) do
			tbScript[k]:ShowRedHandInfo()
		end

		for k, v in ipairs(tMostMoneyNum) do
			tbScript[k]:ShowRedHandInfo()
		end
	end
    UIHelper.SetVisible(self.WidgetEmpty , table.get_len(tPlayers) <= 0)
end


return UIRedPacketGetListView