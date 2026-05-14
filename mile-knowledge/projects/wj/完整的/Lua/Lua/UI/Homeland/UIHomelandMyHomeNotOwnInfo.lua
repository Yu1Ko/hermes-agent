-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeNotOwnInfo
-- Date: 2023-03-29 10:26:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeNotOwnInfo = class("UIHomelandMyHomeNotOwnInfo")

local NPC_TRACE_LINKID = 2364	--个人家园npc指引
local NPC_TRACK_MAPID = 108
local tSpecialMapBuyLandRequirementTitle =
{
	[462] = g_tStrings.STR_DATANGJIAYUAN_BUY_LAND_REQUIREMENT_TITLE_SPECIAL_1,-- 九寨沟
	[674] = g_tStrings.STR_DATANGJIAYUAN_BUY_LAND_REQUIREMENT_TITLE_SPECIAL_2,
}

local tSpecialMapBuyLandState =
{
	[674] = g_tStrings.STR_SPECIAL_MAP_LAND_STATE_TEXT,
}

function UIHomelandMyHomeNotOwnInfo:OnEnter(nMapID, nCopyIndex, dwSkinID, nLandIndex)
    self.nMapID = nMapID
    self.nCopyIndex = nCopyIndex
    self.dwSkinID = dwSkinID
    self.nLandIndex = nLandIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbConditions = nil
    if HomelandData.IsPrivateHome(self.nMapID) then
        RemoteCallToServer("On_HomeLand_PLandRequirement", self.nMapID)
    else
        RemoteCallToServer("On_HomeLand_LandRequirement", self.nMapID, self.nCopyIndex, self.nLandIndex)
    end
    self:UpdateInfo()
end

function UIHomelandMyHomeNotOwnInfo:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeNotOwnInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnVisit, EventType.OnClick, function()
        local nMapID = self.nMapID
        local nCopyIndex = self.nCopyIndex
        local dwSkinID = self.dwSkinID
        local nLandIndex = self.nLandIndex

        local function _goPrivateLand()
            if HomelandData.IsPrivateHome(nMapID) then
                HomelandData.GoPrivateLand(nMapID, nil, dwSkinID, 2)
            else
                HomelandData.BackToLand(nMapID, nCopyIndex, nLandIndex)
            end
            UIMgr.Close(VIEW_ID.PanelHome)
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
            Event.Dispatch(EventType.HideAllHoverTips)
        end
        if PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, dwSkinID, _goPrivateLand) then
            _goPrivateLand()
        end
    end)

    UIHelper.BindUIEvent(self.BtnLive, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "Land") then
			return
		end
		GetHomelandMgr().SendCustomEvent(1, self.nMapID, 0)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "Land") then
			return
		end

        if HomelandData.IsPrivateHome(self.nMapID) then
            self:OnBuyPrivateHome()
        else
            local tbLandInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex)
            local tUILandInfo = Table_GetMapLandInfo(self.nMapID, self.nLandIndex)
            local szMapName = Table_GetMapName(self.nMapID)

            UIHelper.ShowConfirm(string.format("确定要以%s购买%s%s号园宅地吗？", UIHelper.GetMoneyText(tUILandInfo.nPrice * 10000), UIHelper.GBKToUTF8(szMapName), tostring(self.nLandIndex)), function ()
                RemoteCallToServer("On_HomeLand_BuyLand", self.nMapID, self.nCopyIndex, self.nLandIndex)
            end, nil, true)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSkip, EventType.OnClick, function()
        local tLinkInfo = Table_GetCareerLinkNpcInfo(NPC_TRACE_LINKID, NPC_TRACK_MAPID)
        local szText = UIHelper.GBKToUTF8(tLinkInfo.szNpcName)

		MapMgr.SetTracePoint(szText, tLinkInfo.dwMapID, {tLinkInfo.fX, tLinkInfo.fY, tLinkInfo.fZ})
        UIMgr.Open(VIEW_ID.PanelMiddleMap, tLinkInfo.dwMapID, 0)
    end)

    UIHelper.SetTouchDownHideTips(self.BtnVisit, false)
    UIHelper.SetTouchDownHideTips(self.BtnBuy, false)
    UIHelper.SetTouchDownHideTips(self.BtnLive, false)
    UIHelper.SetTouchDownHideTips(self.ScrollViewHome, false)
end

function UIHomelandMyHomeNotOwnInfo:RegEvent()
    Event.Reg(self, "Home_OnGetBuyLandConditions", function(tbConditions, dwMapID, nCopyIndex, nLandIndex)
        if dwMapID ~= self.nMapID then return end
        self.tbConditions = tbConditions
        self:UpdateInfo()
    end)

    Event.Reg(self, "Home_OnGetPrivateHomeCons", function(tbConditions, dwMapID)
        if dwMapID ~= self.nMapID then return end
        self.tbConditions = tbConditions
        self:UpdateInfo()
    end)

end

function UIHomelandMyHomeNotOwnInfo:UpdateInfo()
    local bCanBuy = false
    local szText = tSpecialMapBuyLandRequirementTitle[self.nMapID] or g_tStrings.STR_DATANGJIAYUAN_BUY_LAND_REQUIREMENT_TITLE_DEFAULT
    szText = szText.."\n"

    if self.tbConditions and #self.tbConditions > 0 then
        if HomelandData.IsPrivateHome(self.nMapID) then
            for i, aOneCondition in ipairs(self.tbConditions) do
                local szTips = FormatString(g_tStrings.tActivation.COLOR_CONDITION, i) .. UIHelper.GBKToUTF8(aOneCondition.szString)
                if aOneCondition.bCan then
                    bCanBuy = true
                    szText = szText .. string.format("<color=#6dbf98>%s</c>", szTips)
                else
                    szText = szText .. string.format("<color=#ff9393>%s</c>", szTips)
                end
            end
        else
            for i, aOneCondition in ipairs(self.tbConditions) do
                for j, tSubCond in ipairs(aOneCondition) do
                    local szTips = ""
                    if j == 1 then
                        szTips = FormatString(g_tStrings.tActivation.COLOR_CONDITION, i) .. UIHelper.GBKToUTF8(tSubCond.szString)
                    else
                        szTips = UIHelper.GBKToUTF8(tSubCond.szString)
                    end
                    if tSubCond.bCan then
                        bCanBuy = true
                        szText = szText .. string.format("<color=#6dbf98>%s</c>", szTips)
                    else
                        szText = szText .. string.format("<color=#ff9393>%s</c>", szTips)
                    end
                end

                if i < #self.tbConditions then
                    szText = szText .. "\n"
                end
            end
        end
    else
        szText = ""
    end

    local bIsSelling, bPrepareToSale, bIsOpen,
        nLevel, nAllyCount, eMarketType1, eMarketType2 =
        GetHomelandMgr().GetLandState(self.nMapID, self.nCopyIndex, self.nLandIndex)
    local tbLandInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex)


    UIHelper.SetVisible(self.BtnVisit, true)
    -- UIHelper.SetVisible(self.BtnToured, not bCanBuy)
    UIHelper.SetVisible(self.BtnLive, bCanBuy and HomelandData.IsPrivateHome(self.nMapID))
    UIHelper.SetVisible(self.BtnBuy, bCanBuy and not HomelandData.IsPrivateHome(self.nMapID))
    UIHelper.SetString(self.LabelBuy, "购买")

    UIHelper.LayoutDoLayout(self.LayoutButton)

    UIHelper.SetRichText(self.RichTextCondition, szText)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHome)

    local szLandStateText = "待购买"

    if HomelandData.IsPrivateHome(self.nMapID) then
        UIHelper.SetRichText(self.RichTextLimit, "每人可<color=#f0dc82>额外</c>拥有一块<color=#f0dc82>私邸宅园</c>。")
        UIHelper.SetVisible(self.BtnToured, false)
        UIHelper.SetVisible(self.BtnVisit, not bCanBuy)
        UIHelper.SetVisible(self.BtnBuy, not bCanBuy)
        UIHelper.SetString(self.LabelBuy, "免费获取")
        UIHelper.LayoutDoLayout(self.LayoutButton)
    else
        UIHelper.SetRichText(self.RichTextLimit, "每人最多同时拥有一块地皮，<color=#f0dc82>搬家</c>或者<color=#f0dc82>退地</c>可以更换地皮。")
        UIHelper.SetVisible(self.BtnSkip, false)

        local bGroupBuy = HomelandData.IsGroupBuy(self.nMapID)
        if bGroupBuy then
            szLandStateText = g_tStrings.STR_LAND_STATE_TEXT.GROUPON_BUY
        elseif bPrepareToSale then
            szLandStateText = g_tStrings.STR_LAND_STATE_TEXT.PREPARE_TO_SALE
        elseif bIsSelling then
            szLandStateText = g_tStrings.STR_LAND_STATE_TEXT.SELLING
        else
            szLandStateText = g_tStrings.STR_LAND_STATE_TEXT.SOLD
        end
    end

    if bIsSelling then
        local szSpecial = tSpecialMapBuyLandState[self.nMapID]
        if szSpecial then
            szLandStateText = szSpecial
        end
	end

    UIHelper.LayoutDoLayout(self.WidgetCont)
    UIHelper.LayoutDoLayout(self.WidgetBottom)

    if not bPrepareToSale then
        UIHelper.SetRichText(self.LabelState, string.format("<color=#F0DC82>状态：</c><color=#FFFFFF>%s</c>", szLandStateText))
    else
        local tTime = TimeToDate(tbLandInfo.nStartSaleTime)
		szLandStateText = FormatString(g_tStrings.STR_TIME_9, tTime.month, tTime.day, tTime.hour, string.format("%02d", tTime.minute))
        UIHelper.SetRichText(self.LabelState, string.format("<color=#F0DC82>开售时间：</c><color=#FFFFFF>%s</c>", szLandStateText))
    end
end

function UIHomelandMyHomeNotOwnInfo:OnBuyPrivateHome()
    RemoteCallToServer("On_Home_BuyPrivateHome", self.nMapID)
end

return UIHomelandMyHomeNotOwnInfo