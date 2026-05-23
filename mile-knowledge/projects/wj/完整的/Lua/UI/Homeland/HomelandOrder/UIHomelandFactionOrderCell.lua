-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandFactionOrderCell
-- Date: 2024-01-16 17:35:57
-- Desc: ?
-- ---------------------------------------------------------------------------------
local TONGFIELD_LINK_ID = 2530
local TONGFIELD_MAPID = 74
local UIHomelandFactionOrderCell = class("UIHomelandFactionOrderCell")

function UIHomelandFactionOrderCell:OnEnter(bHaveTong, tData, tInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bInTongMap = GetClientPlayer().GetMapID() == TONGFIELD_MAPID
    self.bHaveTong = bHaveTong
    self.tData = tData
    self.tInfo = tInfo
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UIHomelandFactionOrderCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandFactionOrderCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSubmit, EventType.OnClick, function ()
        self:TrySubmitTongOrder()
    end)
end

function UIHomelandFactionOrderCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandFactionOrderCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandFactionOrderCell:UpdateInfo()
    UIHelper.SetTexture(self.ImgEmptyFg, HomelandOrderIcon[HLORDER_TYPE.TONG])
    UIHelper.SetTexture(self.ImgEmptyBg, "Resource/HomelandIdentify/Order/hui.png")
    if not self.bHaveTong then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.WidgetOrder, false)
        UIHelper.SetVisible(self.ImgWeekTab, false)
        UIHelper.SetString(self.LabelEmpty, g_tStrings.STR_HOMELAND_JOIN_TONG)
        return
    end
    local tInfo = self.tInfo
    local tData = self.tData
    if not tInfo or not tData or tData.dwID == 0 then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.WidgetOrder, false)
        UIHelper.SetVisible(self.ImgWeekTab, false)
        return
    end
    self:UpdataOrderItemInfo()
    self:UpdataRewardItemInfo()
end

function UIHomelandFactionOrderCell:UpdataOrderItemInfo()
    local tInfo = self.tInfo
    local tData = self.tData
    self.bCanSubmit = true
    UIHelper.RemoveAllChildren(self.WidgetItem80)
    if tInfo and tInfo.szImagePath ~= "" then
        local szBgPath = UIHelper.FixDXUIImagePath(tInfo.szImagePath)
        UIHelper.SetTexture(self.ImgRightBg, szBgPath)
    end
    for _, v in pairs(tInfo.tItemList) do
        local dwTabType         = v.dwTabType
        local dwIndex           = v.dwIndex
        local nCount            = v.nCount
        local nInBagCount       = ItemData.GetItemAmountInPackage(dwTabType, dwIndex)
        local nInLockerCount    = GDAPI_GetLockerItemCount(tInfo.nType, dwTabType, dwIndex)
        local tItemInfo         = ItemData.GetItemInfo(dwTabType, dwIndex)
        local nAllCount         = nInBagCount + nInLockerCount
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80)
        script:OnInitWithTabID(dwTabType, dwIndex, nCount)
        script:SetClearSeletedOnCloseAllHoverTips(true)
        script:SetClickCallback(function ()
            TipsHelper.ShowItemTips(script._rootNode, dwTabType, dwIndex)
        end)
        if tItemInfo then
            local szNum = string.format("<color=#245460>当前进度：%s/%s</color>", tData.nCount, nCount)
            if not self.bInTongMap then
                szNum = "<color=#245460>进度:前往帮会领地查看</color>"
            end
            UIHelper.SetRichText(self.LabelNum, szNum)
            UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(tItemInfo)))
        end
    end
    local szSubmitNum = "单次提交数量:"..tInfo.nSubmitLimit
    UIHelper.SetString(self.LabelSubmitNum, szSubmitNum)
    UIHelper.SetString(self.LabelSubmit, self.bInTongMap and "上交" or "前往上交")
    -- UIHelper.SetNodeGray(self.BtnSubmit, not self.bCanSubmit, true)
    UIHelper.SetVisible(self.ImgFinish, tData.bFinish)
    UIHelper.SetVisible(self.BtnSubmit, not tData.bFinish)
    UIHelper.SetTexture(self.ImgFg, HomelandOrderIcon[HLORDER_TYPE.TONG])
end

function UIHomelandFactionOrderCell:UpdataRewardItemInfo(tInfo)
    UIHelper.RemoveAllChildren(self.LayoutReward)
    if self.tInfo.nMoney and self.tInfo.nMoney > 0 then
        local scriptMoneyIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutReward)
        scriptMoneyIcon:OnInitCurrency(CurrencyType.Money, self.tInfo.nMoney)
        scriptMoneyIcon:SetLabelCount(self.tInfo.nMoney)
        scriptMoneyIcon:SetToggleGroupIndex(ToggleGroupIndex.HomelandOrderRewardItem)
        scriptMoneyIcon:SetClickCallback(function(nTabType, nTabID)
            TipsHelper.ShowCurrencyTips(scriptMoneyIcon._rootNode, CurrencyType.Money, self.tInfo.nMoney)
        end)
    end

    local scriptArchitectureIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutReward)
    scriptArchitectureIcon:OnInitCurrency(CurrencyType.Architecture, self.tInfo.nArchitecture)
    scriptArchitectureIcon:SetToggleGroupIndex(ToggleGroupIndex.HomelandOrderRewardItem)
    scriptArchitectureIcon:SetClickCallback(function(nTabType, nTabID)
        TipsHelper.ShowCurrencyTips(scriptArchitectureIcon._rootNode, CurrencyType.Architecture, self.tInfo.nArchitecture)
    end)
    UIHelper.LayoutDoLayout(self.LayoutReward)
end

function UIHomelandFactionOrderCell:TrySubmitTongOrder()
    local player = PlayerData.GetClientPlayer()
    if not player or not player.dwTongID or player.dwTongID == 0 or not self.bCanSubmit then
        return
    end
    if player.GetMapID() ~= TONGFIELD_MAPID then
        local tLink = Table_GetCareerLinkNpcInfo(TONGFIELD_LINK_ID, TONGFIELD_MAPID)
        if not tLink then
            return
        end
        local tTrack = {
            nID      = TONGFIELD_LINK_ID,
            dwMapID  = TONGFIELD_MAPID,
            szName   = UIHelper.GBKToUTF8(tLink.szNpcName),
            nX       = tLink.fX,
            nY       = tLink.fY,
            nZ       = tLink.fZ,
            szSource = "Custom",
        }
        MapMgr.TryTransfer(TONGFIELD_MAPID)
        MapMgr.SetTracePoint(tTrack.szName, tTrack.dwMapID, {tTrack.nX, tTrack.nY, tTrack.nZ})
    end
    Event.Dispatch(EventType.OnSubmitHomelandOrder, self.tInfo.dwID, self.nIndex, true)
end
return UIHomelandFactionOrderCell