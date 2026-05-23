-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHarnessBagContent
-- Date: 2022-12-13 20:34:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHarnessBagContent = class("UIHarnessBagContent")

local dwHorseEquipType = ITEM_TABLE_TYPE.CUST_TRINKET

function UIHarnessBagContent:OnEnter(nSetID, szName, tList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nSetID = nSetID
    self.tList = tList
    self:UpdateInfo(szName, tList)
end

function UIHarnessBagContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHarnessBagContent:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCheck, EventType.OnClick, function ()
        if not self.bEmpty then
            self.bSelected = not self.bSelected

            local tList = {}
            for nindex, tItem in ipairs(self.tList) do
                if self.tHave[nindex] then
                    local bContain = table.contain_value(self.tCurHorseEquip, tItem.dwItemIndex)
                    if self.bSelected and not bContain then
                        table.insert(tList, tItem.dwItemIndex)
                    elseif not self.bSelected and bContain then
                        table.insert(tList, tItem.dwItemIndex)
                    end
                end
            end

            Event.Dispatch(EventType.EquipHorseEquipBySetID, tList, self.bSelected)
        end
    end)
end

function UIHarnessBagContent:RegEvent()
    Event.Reg(self, EventType.HorseEquipSelect,function (tHorseEquip)
        self:SetCurHorseEquipSelect(tHorseEquip)
    end)
end

function UIHarnessBagContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHarnessBagContent:UpdateInfo(szName, tlist)
    UIHelper.SetString(self.LabelWords, szName)

    self.tbHorseEquipBag = {}
    for nIndex = 1, 4 do
        UIHelper.SetVisible(self.tbWidgetItem[nIndex], tlist[nIndex] and true or false)
        if tlist[nIndex] then
            local ItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetHorseBagItem, self.tbEquipItem[nIndex], dwHorseEquipType, tlist[nIndex].dwItemIndex, true)
            if ItemIcon then
                ItemIcon:SetClickCallback(function ()
                    Event.Dispatch(EventType.ShowHorseEquipTips, dwHorseEquipType, self.tList[nIndex].dwItemIndex,  self.tHave[nIndex])
                end)
                UIHelper.SetNodeSwallowTouches(ItemIcon.ToggleSelect, false, true)
                table.insert(self.tbHorseEquipBag, ItemIcon)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutWordsContent)
end

function UIHarnessBagContent:SetHarnessBagContent(nCount, tHave, tCurEquip)
    local nStackNum = 0
    self.tHave = tHave

    for nIndex = 1, 4 do
        if self.tbHorseEquipBag[nIndex] then
            UIHelper.SetNodeGray(self.tbHorseEquipBag[nIndex].ImgIcon, not tHave[nIndex], true)
            UIHelper.SetOpacity(self.tbHorseEquipBag[nIndex].WidgetItem, (not tHave[nIndex]) and 120 or 255)
        end
        if tHave[nIndex] then
            nStackNum = nStackNum + 1
        end
    end

    UIHelper.SetVisible(self.TogCheck, not table.is_empty(tHave))
    UIHelper.SetString(self.LabelNum, nStackNum .. "/".. nCount)
    self.bEmpty = nStackNum == 0
end

function UIHarnessBagContent:SetCurHorseEquipSelect(tCurHorseEquip)
    for nIndex, item in ipairs(self.tList) do
        local dwItemIndex = item.dwItemIndex
        local bContain = table.contain_value(tCurHorseEquip,dwItemIndex)
        if bContain then
            self.bSelected = true
            UIHelper.SetSelected(self.TogCheck, self.bSelected)
        end

        local ItemIcon = self.tbHorseEquipBag[nIndex]
        ItemIcon:SetCurEquiped(bContain)

        self.tCurHorseEquip = tCurHorseEquip
    end
end

return UIHarnessBagContent