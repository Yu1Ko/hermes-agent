-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHLIdentityFishingMainView
-- Date: 2024-02-29 10:48:10
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nFishWarningBuffID = 27613    -- 咬钩提醒BuffID
local tbSpecialBuff = {
    [1] = 27779, -- 渔获满满
    [2] = 27837, -- 银霜口钓鱼事件BUFF
    [3] = 27707, -- 鱼王饵BUFF
}
local UIHLIdentityFishingMainView = class("UIHLIdentityFishingMainView")

function UIHLIdentityFishingMainView:OnEnter()
    if not self.bInit then
        HomelandFishingData.Init()
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIMgr.HideLayer(UILayer.Main)
    self:SetAutoFishing(Storage.HLIdentity.bIsAutoGetFish)
end

function UIHLIdentityFishingMainView:OnExit()
    UIMgr.ShowLayer(UILayer.Main)
    HomelandFishingData.UnInit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHLIdentityFishingMainView:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.BtnSetting, false)
    UIHelper.SetSelected(self.TogAuto, Storage.HLIdentity.bIsAutoGetFish)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        local player = g_pClientPlayer
        if player then
            player.SetDynamicSkillGroup(0)
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSetting, EventType.OnClick, function()
        if not UIHelper.GetVisible(self.WidgetRight) then
            UIHelper.SetVisible(self.WidgetRight, true)
            UIHelper.PlayAni(self,self.AniAll, "AniRightShow")
        end
    end)

    UIHelper.SetClickInterval(self.TogAuto, 0)
    UIHelper.BindUIEvent(self.TogAuto, EventType.OnClick, function()
        self:SetAutoFishing(UIHelper.GetSelected(self.TogAuto))
    end)

    UIHelper.BindUIEvent(self.BtnBuff, EventType.OnClick, function()
        local player = PlayerData.GetClientPlayer()
        local nX = UIHelper.GetWorldPositionX(self.BtnBuff)
        local nY = UIHelper.GetWorldPositionY(self.BtnBuff)
        local tBuff = BuffMgr.GetSortedBuff(player, true)
        if #tBuff > 0 then
            local _, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetMainCityBuffContentTip, nX, nY)
            script:UpdatePlayerInfo(player.dwID, tBuff, true)
        end
    end)

    UIHelper.BindUIEvent(self.BtnShop, EventType.OnClick, function()
        ShopData.OpenSystemShopGroup(1, 1463)
    end)

    UIHelper.BindUIEvent(self.BtnFish, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHomeFishDeal)
    end)

    UIHelper.BindUIEvent(self.WidgetPlayerHead, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHomeIdentity, HLIDENTITY_TYPE.FISH)
    end)

    UIHelper.BindUIEvent(self.BtnTeach, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelTutorialLite, 35)
    end)

    UIHelper.BindUIEvent(self.BtnBag, EventType.OnClick, function()
        UIMgr.OpenSingle(false, VIEW_ID.PanelHalfBag)
    end)

    UIHelper.BindUIEvent(self.BtnMenu, EventType.OnClick, function()
        UIMgr.OpenSingle(false, VIEW_ID.PanelSystemMenu)
    end)

    UIHelper.BindUIEvent(self.BtnSkillExpend, EventType.OnClick, function()
        OnUseSkill(35962, 1)
    end)
end

function UIHLIdentityFishingMainView:RegEvent()
    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelHomeFishGet then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnGetFishTips, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.PlayAnimMainCityShow, function()
        self:PlayShow()
    end)

    Event.Reg(self, EventType.PlayAnimMainCityHide, function()
        self:PlayHide()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetVisible(self.WidgetRight) then
            UIHelper.PlayAni(self,self.AniAll, "AniRightHide", function ()
                UIHelper.SetVisible(self.WidgetRight, false)
            end)
        end
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function()
        if UIHelper.GetVisible(self.WidgetRight) then
            UIHelper.PlayAni(self,self.AniAll, "AniRightHide", function ()
                UIHelper.SetVisible(self.WidgetRight, false)
            end)
        end
    end)

    Event.Reg(self, "BUFF_UPDATE", function()
        local owner, bdelete, index, cancancel, id, stacknum, endframe, binit, level, srcid, isvalid, leftframe = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
        if id == nFishWarningBuffID then
            Event.Dispatch(EventType.OnFishHooked, bdelete)
        elseif id == tbSpecialBuff[3] then
            self:UpdateFishBait()
        end
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        self:UpdateFishBait()
    end)

    Event.Reg(self, "UPDATE_VIGOR", function()
        self:UpdateVigor()
    end)
end

function UIHLIdentityFishingMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHLIdentityFishingMainView:Init()
    self.scriptPlayerCard = self.scriptPlayerCard or UIHelper.GetBindScript(self.WidgetAniLeftTop)
    self.scriptSkills = self.scriptSkills or UIHelper.GetBindScript(self.WidgetAniRightBottom)
    self.scriptSetting = self.scriptSetting or UIHelper.GetBindScript(self.WidgetRight)
    self.scriptChat = self.scriptChat or UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityMiniChat1, self.WidgetChatMainCityMini)
    self.scriptCurrency = self.scriptCurrency or UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
    self.buffScript = self.buffScript or UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityBuffList, self.WidgetMainCityBuffList)
    self.scriptPlayerCard:OnEnter()
    self.scriptSkills:OnEnter()
    self.scriptSetting:OnEnter()
    self:UpdateFishingState()
    self:UpdateVigor()
    self:UpdateFishBait()
    self:UpdateBuffList()

    UIHelper.SetContentSize(self.buffScript._rootNode, 40, 40)
    UIHelper.SetAnchorPoint(self.scriptChat._rootNode, 0.5, 0)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetRightTopAnchor, true, true)
end

function UIHLIdentityFishingMainView:UpdateFishingState()
    local szTitle = ""

    local tbFishPondInfo = HomelandFishingData.GetCurFishPondInfo()
    if tbFishPondInfo then
        szTitle = self:GetFishPondInfo(tbFishPondInfo)
    end

    UIHelper.SetVisible(self.ImgFishNumBg, szTitle ~= "")
    UIHelper.SetString(self.LabelFishNum, szTitle)
end

function UIHLIdentityFishingMainView:UpdateInfo()
    UIHelper.SetSelected(self.TogAuto, Storage.HLIdentity.bIsAutoGetFish)

    self.scriptPlayerCard:UpdateInfo()
    self:UpdateFishBait()
    self:UpdateVigor()
    self:UpdateFishingState()

    UIHelper.SetVisible(self.LabelTip, GDAPI_IfFishManLevelLimit())
end

function UIHLIdentityFishingMainView:SetAutoFishing(bAuto, bOnlySetTog)
    if bAuto and (not HomelandFishingData.tExpData or HomelandFishingData.tExpData.nLevel < 2) then
        bAuto = false
        TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_GetFish_Level)
    end
    Storage.HLIdentity.bIsAutoGetFish = bAuto
    UIHelper.SetSelected(self.TogAuto, Storage.HLIdentity.bIsAutoGetFish)
    if Storage.HLIdentity.bIsAutoGetFish then
        TipsHelper.ShowNormalTip("开启自动钓鱼，本次钓鱼不再弹出提示")
        if not bOnlySetTog then
            RemoteCallToServer("On_HomeLand_GetFish", {}, Storage.HLIdentity.bIsAutoGetFish)
        end
    end
end

function UIHLIdentityFishingMainView:UpdateFishBait()
    if self:IsFreeFishing() then
        UIHelper.SetVisible(self.ImgRenovate, false)
        return
    end
    local nImageSize = 58
    local szItemIconPath = "Resource/icon/quest/Tong/banghui_07"
    local tFishItem = {66341}
    UIHelper.SetString(self.LabelExpend, "普通鱼饵")
    if self:IsFishingBoss() then
        tFishItem = {84055}
        szItemIconPath = UIHelper.GetIconPathByIconID(2679, true)
        UIHelper.SetString(self.LabelExpend, "鱼王饵")
    end

	local nFishBiteCount = 0
	for i = 1, #tFishItem do
        local nCount = ItemData.GetItemAmountInPackage(5, tFishItem[i])
		if nCount then
			nFishBiteCount = nFishBiteCount + nCount
		end
    end
    local szFrame = string.format("<img src='%s' width='%d' height='%d' type='0'/>", szItemIconPath, nImageSize, nImageSize)
    local szTip = "<color=#AED9E0>"..string.format(g_tStrings.STR_HOMELAND_FISH_BAIT_REMAIN, nFishBiteCount).."</c>"
    UIHelper.SetVisible(self.ImgRenovate, true)
    UIHelper.SetRichText(self.LabelRenovate, szFrame..szTip)
    UIHelper.LayoutDoLayout(self.ImgRenovate)
end

function UIHLIdentityFishingMainView:UpdateVigor()
    if self:IsFreeFishing() then
        UIHelper.SetVisible(self.scriptCurrency._rootNode, false)
        return
    end
    local player = GetClientPlayer()
    local nCurrentVigor = player.nVigor + player.nCurrentStamina
	local nMaxVigor = player.GetMaxVigor() + player.nMaxStamina
    self.scriptCurrency:SetCurrencyType(CurrencyType.Vigor)
    self.scriptCurrency:SetLableCount(nCurrentVigor..'/'..nMaxVigor)
    UIHelper.SetVisible(self.WidgetCurrency, true)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetRightTopAnchor, true, true)
end

function UIHLIdentityFishingMainView:UpdateBuffList()
    self.nBuffCycelID = self.nBuffCycelID or Timer.AddFrameCycle(self, 3, function ()
        local player = GetClientPlayer()
        if not player then
            return
        end

        self.buffScript:UpdateBuffCycle(player)
        local bShowSpecialBuff = false
        for index, nBuffID in ipairs(tbSpecialBuff) do
            local buff = Player_GetBuff(nBuffID)
            if buff and not table.is_empty(buff) then
                local tbInfo = Table_GetBuff(buff.dwID, buff.nLevel)
                UIHelper.SetString(self.LabelFishBuff, UIHelper.GBKToUTF8(tbInfo.szName))
                bShowSpecialBuff = true
                break
            end
        end
        UIHelper.SetVisible(self.ImgFishBg_Buff, bShowSpecialBuff)
    end)
end

function UIHLIdentityFishingMainView:GetFishPondInfo(tbFishPondInfo)
    local szTitle = ""
    local tbInteractInfo = LandObject_GetLandObjectInteractionInfo(tbFishPondInfo.nLandIndex, tbFishPondInfo.nInstID, tbFishPondInfo.nRepsesentID)
    if not tbInteractInfo then
        return szTitle
    end

    local szFishName = ""
    local nShareFishNum = tbInteractInfo.nShareFishNum or 0
    local nFishNum = tbInteractInfo.nFishNum or 0

    if tbInteractInfo.tModule1Item then
        local itemInfo = ItemData.GetItemInfo(tbInteractInfo.tModule1Item.dwTabType, tbInteractInfo.tModule1Item.dwIndex)
        szFishName  = ItemData.GetItemNameByItemInfo(itemInfo)
    end
    szTitle = string.format(g_tStrings.STR_HOMELAND_FISH_POND_REMAIN, UIHelper.GBKToUTF8(szFishName), nShareFishNum, nFishNum)
    return szTitle
end

function UIHLIdentityFishingMainView:IsFreeFishing()
    -- 特殊钓鱼场景不显示精力和鱼饵数量
    local player = PlayerData.GetClientPlayer()
    if not player then
        return false
    end

    local bIsPrivateHomeMap = HomelandData.IsNowPrivateHomeMap()
    local bIsYinShuangKou = player.GetScene().dwMapID == 647 and player.IsHaveBuff(tbSpecialBuff[2], 1)

    return bIsPrivateHomeMap or bIsYinShuangKou
end

function UIHLIdentityFishingMainView:IsFishingBoss()
    -- 鱼王饵状态
    local player = PlayerData.GetClientPlayer()
    if not player then
        return false
    end

    local bIsFishingBoss = player.IsHaveBuff(tbSpecialBuff[3], 1)
    return bIsFishingBoss
end

function UIHLIdentityFishingMainView:PlayShow()
    UIHelper.SetVisible(self._rootNode, true)
end

function UIHLIdentityFishingMainView:PlayHide()
    UIHelper.SetVisible(self._rootNode, false)
end

function UIHLIdentityFishingMainView:OnChangeSkillGroup(nGroupID)

end

return UIHLIdentityFishingMainView