-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetPetIcon
-- Date: 2023-08-02 16:06:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetPetIcon = class("UIWidgetPetIcon")

function UIWidgetPetIcon:OnEnter(dwPetIndex, tPetTryMap, bHave)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwPetIndex = dwPetIndex
    self.bHave = bHave
    self:UpdateAdventure(tPetTryMap)
end

function UIWidgetPetIcon:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPetIcon:BindUIEvent()

end

function UIWidgetPetIcon:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnGetAdventurePetTryBook, function (tPetTryMap)
        self:UpdateAdventure(tPetTryMap)
    end)
end

function UIWidgetPetIcon:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPetIcon:UpdateAdventure(tPetTryMap)
    local nTabType, nTabIndex = GetItemIndexByFellowPetIndex(self.dwPetIndex)
    local tSource = ItemData.GetItemSourceList(nTabType, nTabIndex)
    if tSource and #tSource.tAdventure ~= 0 and not self.bHave then
        UIHelper.SetVisible(self.WidgetQiYuPrograss, true)
        local tAdventureInfo = Table_GetAdventureByID(tSource.tAdventure[1])
        if tPetTryMap then
            local nCount = tPetTryMap[tonumber(tSource.tAdventure[1])]
            for k, v in ipairs(self.tbDone) do
                UIHelper.SetVisible(v, nCount >= k)
            end
        end
    end
end


return UIWidgetPetIcon