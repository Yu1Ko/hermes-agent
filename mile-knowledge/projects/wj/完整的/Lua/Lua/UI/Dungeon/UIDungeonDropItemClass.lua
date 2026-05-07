local UIDungeonDropItemClass = class("UIDungeonDropItemClass")

function UIDungeonDropItemClass:OnEnter(fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(fCallBack)
end

function UIDungeonDropItemClass:OnExit()
    self.bInit = false
end

function UIDungeonDropItemClass:BindUIEvent()
end

function UIDungeonDropItemClass:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonDropItemClass:UpdateInfo(fCallBack)
    self.fCallBack = fCallBack
end

function UIDungeonDropItemClass:UpdateDropInfo()
    UIHelper.RemoveAllChildren(self.WidgetDropItemClass)
    for _,tDropItem in ipairs(self.tDropItemList) do
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetAward, self.WidgetDropItemClass)
        if scriptItem then
            scriptItem:SetShowEquipSubName(true)
            scriptItem:OnEnter(tDropItem.szName, tDropItem.nCount, tDropItem.nItemTabType, tDropItem.nItemIndex)            
            Timer.AddFrame(self, 1, function ()                
                local scriptItemIcon = scriptItem:GetScriptItemIcon()
                scriptItemIcon:SetToggleGroupIndex(ToggleGroupIndex.DungeonDropItem)
                scriptItemIcon:SetSelectMode(false)
                scriptItemIcon:SetClickCallback(function(nTabType, nTabID) self.fCallBack(nTabType, nTabID, tDropItem.nItemParam) end)
            end)
        end
    end
    UIHelper.LayoutDoLayout(self.WidgetDropItemClass)
end

function UIDungeonDropItemClass:AppendDropItem(szName, nCount, nItemTabType, nItemIndex, nItemParam)
    if not self.tDropItemList then
        self.tDropItemList = {}
    end
    local tDropItem = {}
    tDropItem.szName = szName
    tDropItem.nCount = nCount
    tDropItem.nItemTabType = nItemTabType
    tDropItem.nItemIndex = nItemIndex
    tDropItem.nItemParam = nItemParam
    table.insert(self.tDropItemList, tDropItem)
end

return UIDungeonDropItemClass