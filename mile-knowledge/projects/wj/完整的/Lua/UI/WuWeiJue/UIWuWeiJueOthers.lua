local UIWuWeiJueOthers = class("UIWuWeiJueOthers")

local PERSONAL = 1
local PUBLIC = 2

local ITEM_MAX_NUM = 24

local PUBLIC_GROUP = 6

local OPTIONS = {
    {nKey = 1, szText = "配置一"},
    {nKey = 2, szText = "配置二"},
    {nKey = 3, szText = "配置三"},
    {nKey = 4, szText = "配置四"},
}

local function SlotToWidgetIndex(nSlot)
    if nSlot > 100 then
        return nSlot - 100 + 10
    end
    return nSlot
end

local function WidgetIndexToSlotIndex(nDataIndex)
    if nDataIndex > 10 then
        return nDataIndex - 10 + 100
    end
    return nDataIndex
end

function UIWuWeiJueOthers:OnEnter(tLinkArg)
    self:BindUIEvent()
    self:UpdateInfo(tLinkArg)
end

function UIWuWeiJueOthers:OnExit()
    
end

function UIWuWeiJueOthers:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        local script = UIMgr.Open(VIEW_ID.PanelUseWuWeiJuePop, nil, nil, OPTIONS, nil, function(nConfigIndex)
            Storage.FastEnchanting.tbConfig[self.nType] = Storage.FastEnchanting.tbConfig[self.nType] or {}
            Storage.FastEnchanting.tbConfig[self.nType][nConfigIndex] = clone(self.tbData)

            Storage.FastEnchanting.Dirty()
        end)
        script.nSelectKey = 1
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        UIHelper.ShowConfirm("是否一键使用已配置的物品？\n</c><color=#FFE26E>(效果大于30分钟时不可叠加)</c><color=#e5e5e5>", function()
            local playerKungfu = g_pClientPlayer.GetActualKungfuMount()
            ItemData.FastEnchanting(self.tbData, playerKungfu.dwSkillID)
        end, nil, true)
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function()
        self:UpdateSlotsCount()
    end)
end

function UIWuWeiJueOthers:GetContent()
    local szType = self.nType == PERSONAL and "私人消耗品" or "宴席"
    return "玩家 " .. self.szPlayer .. " 的" .. szType .. "配置"
end

function UIWuWeiJueOthers:UpdateSlotsCount()
    for nSlot, tInfo in pairs(self.tbData) do
        if type(tInfo) == "table" then
            local script = self.tbItemWidgetScripts[nSlot]
            local nStackNum = ItemData.GetItemAmountInPackage(tInfo.dwTabType, tInfo.dwIndex)
            script:SetLabelCount(nStackNum)
            script:SetIconGray(nStackNum <= 0)
            script:SetIconOpacity(nStackNum == 0 and 120 or 255)
        end
    end
end

function UIWuWeiJueOthers:UpdateSlots()
    self.tbItemWidgetScripts = {}
    for nWidgetIndex, widget in ipairs(self.tbItemWidgets) do
        local nSlot = WidgetIndexToSlotIndex(nWidgetIndex)
        local tInfo = self.tbData[nSlot]
        if tInfo then
            local nStackNum = ItemData.GetItemAmountInPackage(tInfo.dwTabType, tInfo.dwIndex)
            local widgetScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, widget)
            widgetScript:OnInitWithTabID(tInfo.dwTabType, tInfo.dwIndex)
            widgetScript:SetClickNotSelected(true)
            widgetScript:SetClickCallback(function()
                local nStackNum = ItemData.GetItemAmountInPackage(tInfo.dwTabType, tInfo.dwIndex)
                local _, itemTipScript = TipsHelper.ShowItemTips(widgetScript._rootNode, tInfo.dwTabType, tInfo.dwIndex, false)
                local tbBtnState = {}
                if nStackNum > 0 then
                    table.insert(tbBtnState, {
                        szName = "使用",
                        OnClick = function()
                            ItemData.FastEnchanting({
                                [nSlot] = {dwTabType = tInfo.dwTabType, dwIndex = tInfo.dwIndex}
                            })
                            Event.Dispatch(EventType.HideAllHoverTips)
                        end
                    })
                end
        
                itemTipScript:SetBtnState(tbBtnState)
            end)
            self.tbItemWidgetScripts[nSlot] = widgetScript
        end
    end

    self:UpdateSlotsCount()
end

function UIWuWeiJueOthers:UpdateInfo(tLinkArg)
    local bPublic = false
    local tItem = {}

    self.tbData = {}
    self.nType = PERSONAL
    self.szPlayer = GBKToUTF8(tLinkArg[1] or "")

    self.tbData.dwKungfuID = tonumber(tLinkArg[2] or "") or 0
    self.tbData.bMelee = tLinkArg[3] and tLinkArg[3] == "1" or false 
    self.tbData.bHeavy = tLinkArg[4] and tLinkArg[4] == "1" or false

    local szIcon = PlayerKungfuImg[self.tbData.dwKungfuID] or ""
    local szKungfu = GBKToUTF8(Table_GetSkillName(self.tbData.dwKungfuID, 1))
    UIHelper.SetLabel(self.LabelKungfu, szKungfu)
    UIHelper.SetSpriteFrame(self.ImgKungfu, szIcon)

    for i = 5, ITEM_MAX_NUM, 2 do
        if tLinkArg[i] then 
            local nSlot = tonumber(tLinkArg[i])
            local dwID = tonumber(tLinkArg[i + 1])
            tItem[nSlot] = dwID
        end
    end
    for nSlot, dwID in pairs(tItem) do
        if dwID ~= 0 then
            local tInfo = Table_GetEatingQuickItemByID(dwID)
            self.tbData[nSlot] = {dwTabType = tInfo.dwTabType, dwIndex = tInfo.dwIndex, dwID = tInfo.dwID}
            if tInfo.nGroup == PUBLIC_GROUP then
                self.nType = PUBLIC
            end
        end
    end

    self:UpdateSlots()

    UIHelper.SetLabel(self.LabelContent, self:GetContent())
    
    self:UpdateType()
end

function UIWuWeiJueOthers:UpdateType()
    for i, widget in ipairs(self.tbTypeLayouts) do
        UIHelper.SetVisible(widget, i == self.nType)
    end
end

return UIWuWeiJueOthers