
local UIMoZhuRightBag = class("UIMoZhuRightBag")

function UIMoZhuRightBag:OnEnter(szType, tList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szType = szType
    self.tList = tList or {}
    self:UpdateInfo()
end

function UIMoZhuRightBag:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    TipsHelper.DeleteAllHoverTips()
end

function UIMoZhuRightBag:BindUIEvent()

end

function UIMoZhuRightBag:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        Timer.AddFrame(self, 5, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBag)
        end)
    end)
end

function UIMoZhuRightBag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end
-- ----------------------------------------------------------
-- Please write your own code below  ↓↓
-- ----------------------------------------------------------

function UIMoZhuRightBag:UpdateInfo()
    local tEquip = {}
    for k, v in pairs(self.tList) do
        local item 
        if self.szType == "Target" then
            item = ItemData.GetItemInfo(v.dwTabType, v.dwIndex)
        else
            item = PlayerData.GetPlayerItem(g_pClientPlayer, v.dwBox, v.dwX)
        end
        local szEquip = ItemData.GetEquipTypeName(item)
        if not tEquip[szEquip] then
            tEquip[szEquip] = {}    
        end
        table.insert(tEquip[szEquip], v)
    end
    UIHelper.SetVisible(self.WidgetEmpty, #self.tList == 0)
    if #self.tList == 0 then
        local szEmpty = ""
        if self.szType == "Target" then
            szEmpty = g_tStrings.MOZHU_TARGET_EQUIP_EMPTY
        elseif self.szType == "Current" then
            szEmpty = g_tStrings.MOZHU_EQUIP_EMPTY
        elseif self.szType == "LevelUp" then
            szEmpty = g_tStrings.MOZHU_LEVEL_UP_EQUIP_EMPTY
        end
        UIHelper.SetString(self.LabelDescibe, szEmpty)
    end
    
    UIHelper.RemoveAllChildren(self.ScrollBag)
    for k, v in pairs(tEquip) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetMoZhuBagCellGroup, self.ScrollBag, self.szType, k, v)
    end
    UIHelper.LayoutDoLayout(self.ScrollBag)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBag)
end


return UIMoZhuRightBag