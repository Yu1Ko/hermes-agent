-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieDataTitle
-- Date: 2025-10-23 09:52:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieDataTitle = class("UISelfieDataTitle")

local tDefault = {
    ["tAction"] = true,
    ["tFaceAction"] = true,
    ["tFace"] = true,
    ["tBody"] = true,
}

function UISelfieDataTitle:OnEnter(szTitle, tItemInfo, tItemList, tTitleData, tExterior)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self.szTitle = szTitle
    self.tItemInfo = tItemInfo
    self.tItemList = tItemList
    self.tTitleData = tTitleData
    self.tExterior = tExterior
    -- Output("UISelfieDataTitle", szTitle, tItemInfo, self.tItemList)
    self.tSelfieTitle = g_tStrings.tSelfieTitle
    self.tSelfieParam = g_tStrings.tSelfieParam
    self.tPlayerTitle = g_tStrings.tPlayerTitle
    self.tPlayerParam = g_tStrings.tPlayerParam
    self:UpdateInfo()
end

function UISelfieDataTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieDataTitle:BindUIEvent()
    
end

function UISelfieDataTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieDataTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieDataTitle:Hide()
    -- self.bIsOpen = false
    UIHelper.SetVisible(self._rootNode , false)
end

function UISelfieDataTitle:Show(bShow)
    if bShow then
        UIHelper.SetVisible(self._rootNode , true)
    else
        UIHelper.SetVisible(self._rootNode , false)
    end
end

-- ----------------------------------------------------------
-- Please write your own code below  ������
-- ----------------------------------------------------------

function UISelfieDataTitle:UpdateInfo()
    if self.tSelfieTitle[self.szTitle] then
        self:UpdateSelfieParam()
    elseif self.tPlayerTitle[self.szTitle] then 
        self:UpdatePlayerParam()
    end
end

function UISelfieDataTitle:UpdateSelfieParam()
    UIHelper.SetString(self.LabelDataLabel, self.tSelfieTitle[self.szTitle])

    local tParam = self.tSelfieParam[self.szTitle]
    for i = 1, 2 do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataInportCellLabel, self._rootNode)
        cell:OnEnter(tParam, i)
    end
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UISelfieDataTitle:UpdatePlayerParam()
    UIHelper.SetString(self.LabelDataLabel, self.tPlayerTitle[self.szTitle])
    if self.szTitle == "tAction" and self.tTitleData.dwAnimationID <= 0 then
        return
    end
    if self.szTitle == "tFaceAction" and self.tTitleData.dwFaceMotionID <= 0 then
        return
    end
    if tDefault[self.szTitle] then
        self.cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataInportCellItem, self._rootNode)
        -- local bDefault = true 
        -- if self.szTitle == "tAction" and self.tTitleData.dwAnimationID <= 0 then
        --     self.cell:Hide()
        -- else
            local tInfo = {
                szTitle = self.szTitle,
                bDefault = true,
                bImport = false,
            }
            self.cell:OnEnter(tInfo, self.tTitleData, self.tExterior)
        -- end
    else
        for nResSub, v in pairs(self.tItemList) do
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataInportCellItem, self._rootNode)
            local tInfo = {
                szTitle = self.szTitle,
                nResSub = nResSub,
                bDefault = false,
                bImport = false,
            }
            cell:OnEnter(tInfo, self.tItemInfo[nResSub], self.tTitleData)
            -- cell:OnEnter(self.szTitle, nResSub, self.tItemInfo[nResSub], false, false, self.tTitleData)
        end
    end
    UIHelper.LayoutDoLayout(self._rootNode)
end

return UISelfieDataTitle