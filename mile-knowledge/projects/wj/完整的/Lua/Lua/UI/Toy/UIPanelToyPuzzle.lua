-- ---------------------------------------------------------------------------------
-- Author: 贾宇然
-- Name: UIPanelToyPuzzle
-- Date: 2024.4.11
-- Desc: 玩具-拼图
-- Prefab: PanelToyPuzzle
-- ---------------------------------------------------------------------------------

local tBgDict = {
    ["ui/Image/ToyConflate/ToyPicture/YunCongJi.tga"] = "Texture/Toy/ToyPuzzle/Bg_YunCongJi.png",
    ["ui/Image/ToyConflate/ToyPicture/BaDuanJing.tga"] = "Texture/Toy/ToyPuzzle/Bg_BaDuanJing.png",
    ["ui/Image/ToyConflate/ToyPicture/HuFaZhiZi.tga"] = "Texture/Toy/ToyPuzzle/HuFaZhiZi.png"
}

---@class UIPanelToyPuzzle
local UIPanelToyPuzzle = class("UIPanelToyPuzzle")

function UIPanelToyPuzzle:OnEnter(dwID, dwItemID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        local tInfo = Table_GetConflatePanelInfo(dwID)
        if not tInfo then
            return
        end

        
        self.m_nSetID = dwID
        self.dwItemID = dwItemID
        self.nConflateCount = tInfo.nConflateCount

        self:ApplyItem()
    end
    
    self.tToggleScripts = {}
    local tToggleList = self.nConflateCount == 4 and self.tToggles_4 or self.tToggles
    UIHelper.SetVisible(self.WidgetPuzzle, self.nConflateCount == 8)
    UIHelper.SetVisible(self.WidgetPuzzle2, self.nConflateCount == 4)
    
    for nIndex, node in ipairs(tToggleList) do
        local script = UIHelper.GetBindScript(node)
        table.insert(self.tToggleScripts, script)
    end

    self:UpdateInfo()
end

function UIPanelToyPuzzle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelToyPuzzle:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

end

function UIPanelToyPuzzle:RegEvent()
    Event.Reg(self, "ON_SYNC_SET_COLLECTION", function()
        self:ApplyItem()
        self:UpdateInfo()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function()
        local pPlayer = g_pClientPlayer
        if not pPlayer then
            return
        end
        --pPlayer.ApplySetCollection()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SYNC_SET_COLLECTION_TO_AWARD_ACTIVE", function()
        local pPlayer = GetClientPlayer()
        if not pPlayer then
            return
        end
        local tInfo = pPlayer.GetSetCollection(self.m_nSetID)
        if tInfo.eType == SET_COLLECTION_STATE_TYPE.TO_AWARD then
            --    GetNew.Open(m_nSetID)
        end
    end)
end

function UIPanelToyPuzzle:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelToyPuzzle:ApplyItem()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local dwItemID = self.dwItemID
    local dwID = self.m_nSetID
    if dwItemID then
        self.tLastOpenState = self.tLastOpenState or {}
        local tConfigInfo = Table_GetConflatePanelInfo(dwID)
        for i = 1, tConfigInfo.nConflateCount do
            local t = SplitString(tConfigInfo["szConflate" .. i .. "Info"], "|")
            local szTips = t[1]
            local nItemType = tonumber(t[2])
            local nItemID = tonumber(t[3])
            local bLocked, bCanOp = GDAPI_GetConflateState(pPlayer, dwID, i, nItemType, nItemID)

            if dwItemID == nItemID then
                if bLocked == false and self.tLastOpenState[i] == true then
                    local itemInfo = ItemData.GetItemInfo(nItemType, nItemID)
                    TipsHelper.ShowImportantBlueTip(string.format("物品%s已收集", UIHelper.GBKToUTF8(itemInfo.szName)))
                    break
                end
                self.tLastOpenState[i] = bLocked
                local nBox, nIndex = ItemData.GetItemPos(nItemType, nItemID)
                local item = ItemData.GetItemByPos(nBox, nIndex)
                if not item then
                    return
                end
                if bCanOp then
                    RemoteCallToServer("On_Toy_OperateConflate", dwID, i, nItemType, nItemID)
                    break
                end
                if not bLocked then
                    TipsHelper.ShowImportantYellowTip("该道具已使用")
                else
                    TipsHelper.ShowImportantYellowTip("前置条件未满足")
                end
                break
            end
        end
    end
end

function UIPanelToyPuzzle:UpdateInfo()
    local nSetID = self.m_nSetID
    if not nSetID then
        return
    end

    local tConfigInfo = Table_GetConflatePanelInfo(nSetID)
    UIHelper.SetTexture(self.ImgBg, tBgDict[tConfigInfo.szBgPath], true)

    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    local bAllUnLock = true
    local nCount = 0
    for i = 1, tConfigInfo.nConflateCount do
        local script = self.tToggleScripts[i]

        local t = SplitString(tConfigInfo["szConflate" .. i .. "Info"], "|")
        local szTips = t[1]
        local nItemType = tonumber(t[2])
        local nItemID = tonumber(t[3])
        local bLocked, bCanOp = GDAPI_GetConflateState(hPlayer, nSetID, i, nItemType, nItemID)

        UIHelper.SetVisible(script.TogPuzzle, bLocked)

        if bLocked or bCanOp then
            bAllUnLock = false
        end

        nCount = nCount + (bLocked and 0 or 1)
    end

    local szTitle = UIHelper.GBKToUTF8(tConfigInfo.szTitle)
    szTitle = string.format("%s  (%d/%d)", szTitle, nCount, tConfigInfo.nConflateCount)
    UIHelper.SetString(self.LabelTitle, szTitle)

    UIHelper.SetVisible(self.WidgetEdge, not bAllUnLock)
    
    if bAllUnLock then
        hPlayer.ApplySetCollectionAward(nSetID)
    end
end

return UIPanelToyPuzzle