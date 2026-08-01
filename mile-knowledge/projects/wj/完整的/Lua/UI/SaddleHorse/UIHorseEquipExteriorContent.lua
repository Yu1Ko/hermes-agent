-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHorseEquipExteriorContent
-- Date: 2022-12-13 20:34:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHorseEquipExteriorContent = class("UIHorseEquipExteriorContent")

function UIHorseEquipExteriorContent:OnEnter(tList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nSetID = tList.nSetID
    self.tList = tList
    self.szName = tList.szName
    self:UpdateInfo(tList.szName, tList)
end

function UIHorseEquipExteriorContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHorseEquipExteriorContent:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCheck, EventType.OnClick, function ()
        if not self.bEmpty then
            self.bSelected = not self.bSelected
            if self.bSelected then
                for nIndex, tExteriorInfo in ipairs(self.tList) do
                    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSaddleHorse)
					if scriptView then
						scriptView:SetExteriorPreview(tExteriorInfo.dwExteriorID, true, tExteriorInfo.nExteriorSlot)
					end
                end
            else
                for nIndex, tExteriorInfo in ipairs(self.tList) do
                    local bWear = RideExteriorData.IsInPreview(tExteriorInfo.dwExteriorID, true)
                    if bWear then
                        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSaddleHorse)    
                        if scriptView then          
                            scriptView:SetExteriorPreview(0, true, tExteriorInfo.nExteriorSlot)   
                        end
                    end
                end
            end

        end
    end)
end

function UIHorseEquipExteriorContent:RegEvent()
    
end

function UIHorseEquipExteriorContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHorseEquipExteriorContent:UpdateInfo(szName, tList)
    UIHelper.SetString(self.LabelWords, szName)

    self.tbHorseEquipExteriorBag = {}
    local nCount = #tList
    local nHave = 0
    local bInPreview = false
    for nIndex = 1, 4 do
        UIHelper.SetVisible(self.tbWidgetItem[nIndex], tList[nIndex] and true or false)
        if tList[nIndex] then
            local tExteriorInfo = tList[nIndex]
            if tExteriorInfo.bHave then
                nHave = nHave + 1
            end
            if RideExteriorData.IsInPreview(tExteriorInfo.dwExteriorID, true) then
                bInPreview = true
            end
            local ItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tbEquipItem[nIndex])
            if ItemIcon then
                ItemIcon:OnInitWithRideExterior(tExteriorInfo.dwExteriorID, true)
                ItemIcon:SetClickCallback(function(dwExteriorID, bEquip)
                    local tips, scriptTips = TipsHelper.ShowItemTips(ItemIcon._rootNode)
                    scriptTips:OnInitRideExterior(dwExteriorID, bEquip)
                    scriptTips:SetBtnState(RideExteriorData.GetExteriorTipsBtnState(dwExteriorID, bEquip))
                    if UIHelper.GetSelected(ItemIcon.ToggleSelect) then
                        UIHelper.SetSelected(ItemIcon.ToggleSelect, false)
                    end
                end)
                table.insert(self.tbHorseEquipExteriorBag, ItemIcon)
            end
        end
    end

    UIHelper.SetSelected(self.TogCheck, bInPreview)
    self.bSelected = bInPreview
    self:SetHorseEquipExteriorBagContent(nHave, nCount)
    self:SetHorseEquipExteriorInPreview()

    UIHelper.LayoutDoLayout(self.LayoutWordsContent)
end

function UIHorseEquipExteriorContent:SetHorseEquipExteriorBagContent(nHave, nCount)
    UIHelper.SetString(self.LabelNum, nHave .. "/".. nCount)
end

function UIHorseEquipExteriorContent:SetHorseEquipExteriorInPreview()
    for nIndex, tExteriorInfo in ipairs(self.tList) do
        local bWear = RideExteriorData.IsInPreview(tExteriorInfo.dwExteriorID, true)
        local ItemIcon = self.tbHorseEquipExteriorBag[nIndex]
        ItemIcon:SetItemWear(bWear)
    end
end

return UIHorseEquipExteriorContent