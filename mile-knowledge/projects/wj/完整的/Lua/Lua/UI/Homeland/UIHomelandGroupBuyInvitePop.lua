-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandGroupBuyInvitePop
-- Date: 2024-02-05 16:39:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandGroupBuyInvitePop = class("UIHomelandGroupBuyInvitePop")
local DefaultLandIndex = 10 -- 默认使用十号土地展示
function UIHomelandGroupBuyInvitePop:OnEnter(szLeaderName, dwMapID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szLeaderName = UIHelper.GBKToUTF8(szLeaderName)
    self.dwMapID = dwMapID
    self:UpdateInfo()
    self:UpdateTimerInfo()
    RemoteCallToServer("On_HomeLand_LandRequirement", self.dwMapID, 1, DefaultLandIndex)
end

function UIHomelandGroupBuyInvitePop:OnExit()
    if not self.bSure then
        GetHomelandMgr().BuyLandGrouponAddPlayerRespond(0, self.dwMapID)
    end
    Timer.DelAllTimer(self)
    self.nTimerID = nil
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandGroupBuyInvitePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "Land") then
            UIMgr.Close(self)
            return
        end
        GetHomelandMgr().BuyLandGrouponAddPlayerRespond(1, self.dwMapID)
        self.bSure = true
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIHomelandGroupBuyInvitePop:RegEvent()
    Event.Reg(self, "Home_OnGetBuyLandConditions", function(tbConditions, dwMapID, nCopyIndex, nLandIndex)
        if dwMapID ~= self.dwMapID then return end
        self.tbConditions = tbConditions
        self:UpdateTitle()
    end)
end

function UIHomelandGroupBuyInvitePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandGroupBuyInvitePop:UpdateInfo()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(self.dwMapID))
    local tLandInfo = Table_GetLandInfo(self.dwMapID)

    local szTip = string.format(g_tStrings.STR_GROUP_BUY_INVITE_TIPS, self.szLeaderName, szMapName)
    UIHelper.SetString(self.LabelPart1Content, szTip)

    local nPrice = tLandInfo[DefaultLandIndex].nPrice
    local tPrice = {math.floor(nPrice / 10000), nPrice % 10000} -- {zhuan, gold}
    for i = 1, #tPrice, 1 do
        UIHelper.SetString(self.tbMoneyLabel[i], tPrice[i])
    end
end

function UIHomelandGroupBuyInvitePop:UpdateTitle()
    local pPlayer = GetClientPlayer()
	local pHomelandMgr = GetHomelandMgr()
	if not pPlayer or not pHomelandMgr then
		return
	end
	local tLandHash = pHomelandMgr.GetAllMyLand()
    local bLevelOk = pPlayer.nLevel >= 120
    local bHaveBindLand = false
    local bConditionsOK = false

    local szTips1 = ""
    local szColorFormat = bLevelOk and "#95ff95" or "#86aeb6"
    local szLevelTip = string.format("<color=%s>条件1：满级</color>", szColorFormat)
    local szBindLandTip = "<color=#95ff95>条件2：无绑定土地</color>"
	for _, tHash in ipairs(tLandHash) do
		if not tHash.bPrivateLand and not tHash.bAllied then
			szBindLandTip = "<color=#86aeb6>条件2：无绑定土地</color>"
            bHaveBindLand = true
		end
	end
    szTips1 = szLevelTip.."\n"..szBindLandTip

    local szTips2 = ""
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
                    bConditionsOK = true
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

    local bCanBuy = bConditionsOK and bLevelOk and not bHaveBindLand
    UIHelper.SetVisible(self.LabelTip, not bCanBuy)
    UIHelper.SetRichText(self.RichTextLeft, szTips1)
    UIHelper.SetRichText(self.RichTextRight, szTips2)

    UIHelper.SetVisible(self.WidgteTitle2, self.dwMapID == 674)
    UIHelper.SetString(self.LabelLeftTitle, self.dwMapID == 674 and "1.满足以下所有条件并且梓行点16000" or "1.满足以下所有条件")
    UIHelper.SetString(self.LabelRightTitle, self.dwMapID == 674 and "2.满足任意条件（1280平）" or "2.满足任意条件")
    UIHelper.LayoutDoLayout(self.LayoutCondition2)
end

function UIHomelandGroupBuyInvitePop:UpdateTimerInfo()
    local nCount = 120  -- 2分钟倒计时
    local fn = function ()
        local szCount = string.format("同意（%s）", nCount)
        UIHelper.SetString(self.LabelAccept, szCount)
        nCount = nCount - 1
        if nCount < 0 then
            GetHomelandMgr().BuyLandGrouponAddPlayerRespond(1, self.dwMapID)
            self.bSure = true
            UIMgr.Close(self)
        end
    end
    self.nTimerID = self.nTimerID or Timer.AddCycle(self, 1, function ()
        fn()
    end)
    fn()
end

return UIHomelandGroupBuyInvitePop