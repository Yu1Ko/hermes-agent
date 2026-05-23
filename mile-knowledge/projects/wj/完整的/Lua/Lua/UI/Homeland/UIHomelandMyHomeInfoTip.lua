-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeInfoTip
-- Date: 2023-03-29 11:09:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeInfoTip = class("UIHomelandMyHomeInfoTip")

function UIHomelandMyHomeInfoTip:OnEnter(nMapID, nCopyIndex, dwSkinID, nLandIndex, nIndex)
    self.nMapID = nMapID
    self.nCopyIndex = nCopyIndex
    self.dwSkinID = dwSkinID
    self.nLandIndex = nLandIndex
    self.nIndex = nIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomeInfoTip:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeInfoTip:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function ()
        if HomelandData.IsPrivateHome(self.nMapID) then
            ChatHelper.SendPrivateLandToChat(self.dwSkinID, self.nMapID, self.nCopyIndex)
        else
            ChatHelper.SendLandToChat(self.nIndex, self.nMapID, self.nCopyIndex, self.nLandIndex)
        end
    end)

    UIHelper.BindUIEvent(self.BtnHomeIocnBg, EventType.OnClick, function(btn)
        local tInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex)
        if HomelandData.IsPrivateHome(self.nMapID) then
            Homeland_GetDigitalBlueprintNameAndAuthorUI(tInfo.szOwnerID, 2)
        else
            Homeland_GetDigitalBlueprintNameAndAuthorUI(tInfo.szOwnerID, 1)
        end
    end)

    UIHelper.SetTouchDownHideTips(self.BtnShare, false)
    UIHelper.SetTouchDownHideTips(self.BtnHomeIocnBg, false)
end

function UIHomelandMyHomeInfoTip:RegEvent()
    Event.Reg(self, EventType.OnUpdateHomelandLandInfo, function (nMapID, nCopyIndex, nLandIndex)
        if nMapID == self.nMapID and nCopyIndex == self.nCopyIndex and nLandIndex == self.nLandIndex then
            self:UpdateInfo()
        end
    end)
end

function UIHomelandMyHomeInfoTip:UpdateInfo()
    self:UpdatePrivateHomeTopInfo()
    self:UpdateLandTopInfo()

    self:UpdateConditionInfo()
    self:UpdateAttributeInfo()
end

function UIHomelandMyHomeInfoTip:UpdatePrivateHomeTopInfo()
    if not HomelandData.IsPrivateHome(self.nMapID) then return end

    self.tbSkinInfo = Table_GetPrivateHomeSkin(self.nMapID, self.dwSkinID)
    self.tbLandInfo = Table_GetMapLandInfo(self.nMapID, self.nLandIndex)

    UIHelper.SetString(self.LabelMyHome, UIHelper.GBKToUTF8(self.tbSkinInfo.szLandName))
    UIHelper.SetRichText(self.LabelInfo01, string.format("<color=#AED9E0>地址：</c><color=#ffffff>%s</color>", UIHelper.GBKToUTF8(self.tbSkinInfo.szLandAddress)))
    UIHelper.SetRichText(self.LabelInfo02, string.format("<color=#AED9E0>品质：</c><color=#ffffff>%s</color>", UIHelper.GBKToUTF8(self.tbLandInfo.szQuality)))
    UIHelper.SetRichText(self.LabelInfo03, string.format("<color=#AED9E0>面积：</c><color=#ffffff>%d平米</color>", self.tbLandInfo.nArea))
    local nGoldBrick, nGold = math.floor(self.tbLandInfo.nPrice / 10000), math.mod(self.tbLandInfo.nPrice, 10000)
    if nGoldBrick > 0 then
        UIHelper.SetVisible(self.WidgetMoney1, true)
        UIHelper.SetString(self.LabelMoney01, nGoldBrick)
    else
        UIHelper.SetVisible(self.WidgetMoney1, false)
    end

    UIHelper.SetString(self.LabelMoney02, nGold)
    UIHelper.LayoutDoLayout(self.WidgetMoney1)
    UIHelper.LayoutDoLayout(self.WidgetMoney2)
    UIHelper.LayoutDoLayout(self.LayoutMoney)

    local bDigital = false
    local tPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(self.nMapID, self.nCopyIndex)
	local tInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex)
    if tPrivateInfo then
        UIHelper.SetVisible(self.WidgetMoney, false)
        UIHelper.SetVisible(self.LabelInfo04, true)
        UIHelper.SetVisible(self.LabelInfoOwner, true)
        UIHelper.SetVisible(self.ImgOwnBg, false)
        UIHelper.SetVisible(self.ImgRewardBg, true)
        UIHelper.SetVisible(self.BtnShare, true)

        local szName = GetClientPlayer().szName
        UIHelper.SetRichText(self.LabelInfoOwner, string.format("<color=#AED9E0>户主：</c><color=#ffffff>%s</color>", UIHelper.GBKToUTF8(szName)))
        UIHelper.SetRichText(self.LabelInfo04, string.format("<color=#AED9E0>结庐评分：</c><color=#ffffff>%d</color>", PrivateHomeData.GetLandSeasonScore(self.nMapID, self.nCopyIndex, self.nLandIndex)))

        if tInfo then
            UIHelper.SetString(self.LabelReward, tInfo.nLevel .. "级")
            bDigital = Homeland_IsDigitalBlueprint(tInfo["uMarketType"] or 0)
        end
    else
        UIHelper.SetVisible(self.WidgetMoney, true)
        UIHelper.SetVisible(self.LabelInfo04, false)
        UIHelper.SetVisible(self.LabelInfoOwner, false)
        UIHelper.SetVisible(self.ImgOwnBg, false)
        UIHelper.SetVisible(self.ImgRewardBg, false)
        UIHelper.SetVisible(self.BtnShare, false)
    end

    UIHelper.SetVisible(self.ImgCangPin, bDigital)
    UIHelper.LayoutDoLayout(self.LayoutHome)
    UIHelper.LayoutDoLayout(self.LayoutHomeInfo)
end

function UIHomelandMyHomeInfoTip:UpdateLandTopInfo()
    if HomelandData.IsPrivateHome(self.nMapID) then return end

    self.tbLandInfo = Table_GetMapLandInfo(self.nMapID, self.nLandIndex)

    UIHelper.SetString(self.LabelMyHome, HomelandData.Homeland_GetHomeName(self.nMapID, self.nLandIndex))
    UIHelper.SetRichText(self.LabelInfo01, string.format("<color=#AED9E0>地址：</c><color=#ffffff>%s</color>", UIHelper.GBKToUTF8(self.tbLandInfo.szLandName)))
    UIHelper.SetRichText(self.LabelInfo02, string.format("<color=#AED9E0>品质：</c><color=#ffffff>%s</color>", UIHelper.GBKToUTF8(self.tbLandInfo.szQuality)))
    UIHelper.SetRichText(self.LabelInfo03, string.format("<color=#AED9E0>面积：</c><color=#ffffff>%d平米</color>", self.tbLandInfo.nArea))
    local nGoldBrick, nGold = math.floor(self.tbLandInfo.nPrice / 10000), math.mod(self.tbLandInfo.nPrice, 10000)
    if nGoldBrick > 0 then
        UIHelper.SetVisible(self.WidgetMoney1, true)
        UIHelper.SetString(self.LabelMoney01, nGoldBrick)
    else
        UIHelper.SetVisible(self.WidgetMoney1, false)
    end

    UIHelper.SetString(self.LabelMoney02, nGold)
    UIHelper.LayoutDoLayout(self.WidgetMoney1)
    UIHelper.LayoutDoLayout(self.WidgetMoney2)
    UIHelper.LayoutDoLayout(self.LayoutMoney)

    local tbLandInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex)
    if tbLandInfo and tbLandInfo.szName ~= "" then
        UIHelper.SetVisible(self.WidgetMoney, false)
        UIHelper.SetVisible(self.LabelInfo04, true)
        UIHelper.SetVisible(self.LabelInfoOwner, true)
        UIHelper.SetVisible(self.ImgOwnBg, tbLandInfo.szName == PlayerData.GetPlayerName())
        UIHelper.SetVisible(self.ImgRewardBg, true)

        local szName = tbLandInfo.szName
        UIHelper.SetRichText(self.LabelInfoOwner, string.format("<color=#AED9E0>户主：</c><color=#ffffff>%s</color>", UIHelper.GBKToUTF8(szName)))
        UIHelper.SetString(self.LabelReward, tbLandInfo.nLevel .. "级")
        UIHelper.SetRichText(self.LabelInfo04, string.format("<color=#AED9E0>结庐评分：</c><color=#ffffff>%d</color>", PrivateHomeData.GetLandSeasonScore(self.nMapID, self.nCopyIndex, self.nLandIndex)))
    else
        UIHelper.SetVisible(self.WidgetMoney, true)
        UIHelper.SetVisible(self.LabelInfo04, false)
        UIHelper.SetVisible(self.LabelInfoOwner, false)
        UIHelper.SetVisible(self.ImgOwnBg, false)
        UIHelper.SetVisible(self.ImgRewardBg, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutHome)
    UIHelper.LayoutDoLayout(self.LayoutHomeInfo)
end

function UIHomelandMyHomeInfoTip:UpdateConditionInfo()
    if not self.scriptHomeCondition then
        self.scriptHomeCondition = UIHelper.GetBindScript(self.WidgetRightHomeCondition)
    end

    if HomelandData.IsPrivateHome(self.nMapID) then
        local tPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(self.nMapID, self.nCopyIndex)
        if tPrivateInfo then
            UIHelper.SetVisible(self.scriptHomeCondition._rootNode, false)
        else
            UIHelper.SetVisible(self.scriptHomeCondition._rootNode, true)
            self.scriptHomeCondition:OnEnter(self.nMapID, self.nCopyIndex, self.dwSkinID, self.nLandIndex)
        end
    else
        local tbLandInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex)
        if tbLandInfo and tbLandInfo.szName == "" then
            UIHelper.SetVisible(self.scriptHomeCondition._rootNode, true)
            self.scriptHomeCondition:OnEnter(self.nMapID, self.nCopyIndex, self.dwSkinID, self.nLandIndex)
        else
            UIHelper.SetVisible(self.scriptHomeCondition._rootNode, false)
        end
    end

end

function UIHomelandMyHomeInfoTip:UpdateAttributeInfo()
    if not self.scriptHomeAttribute then
        self.scriptHomeAttribute = UIHelper.GetBindScript(self.WidgetRightHomeAttribute)
    end

    if HomelandData.IsPrivateHome(self.nMapID) then
        local tPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(self.nMapID, self.nCopyIndex)
        if tPrivateInfo then
            UIHelper.SetVisible(self.scriptHomeAttribute._rootNode, true)
            self.scriptHomeAttribute:OnEnter(self.nMapID, self.nCopyIndex, self.dwSkinID, self.nLandIndex)
        else
            UIHelper.SetVisible(self.scriptHomeAttribute._rootNode, false)
        end
    else
        local tbLandInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex)
        if tbLandInfo and tbLandInfo.szName ~= "" then
            UIHelper.SetVisible(self.scriptHomeAttribute._rootNode, true)
            self.scriptHomeAttribute:OnEnter(self.nMapID, self.nCopyIndex, self.dwSkinID, self.nLandIndex)
        else
            UIHelper.SetVisible(self.scriptHomeAttribute._rootNode, false)
        end
    end

end


return UIHomelandMyHomeInfoTip