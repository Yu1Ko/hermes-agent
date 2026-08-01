
local UIMoZhuBagCellGroup = class("UIMoZhuBagCellGroup")

function UIMoZhuBagCellGroup:OnEnter(szType, szKey, tList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szType = szType
    self.szKey = szKey  
    self.tList = tList
    self:UpdateInfo()
end

function UIMoZhuBagCellGroup:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    TipsHelper.DeleteAllHoverTips()
end

function UIMoZhuBagCellGroup:BindUIEvent()
    
end

function UIMoZhuBagCellGroup:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        Timer.AddFrame(self, 5, function()
            UIHelper.LayoutDoLayout(self.LayoutCell)    
            UIHelper.LayoutDoLayout(self.WidgetMoZhuBagCellGroup)
        end)
    end)
end

function UIMoZhuBagCellGroup:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end
-- ----------------------------------------------------------
-- Please write your own code below  
-- ----------------------------------------------------------

function UIMoZhuBagCellGroup:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.szKey)
    for k, v in pairs(self.tList) do
        local widgetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutCell) 
        if self.szType == "Target" then
            widgetItem:OnInitWithTabID(v.dwTabType, v.dwIndex)
        else
            widgetItem:OnInit(v.dwBox, v.dwX)
        end
        widgetItem:SetClickCallback(function()
            local tips, scriptItemTip = nil, nil
            if self.szType == "Target" then
                tips, scriptItemTip = TipsHelper.ShowItemTips(widgetItem._rootNode, v.dwTabType, v.dwIndex, false)
            else
                tips, scriptItemTip = TipsHelper.ShowItemTips(widgetItem._rootNode, v.dwBox, v.dwX, true)
            end
            local tbBtnState = {{
                szName = "选择",
                OnClick = function ()
                    local script = UIMgr.GetViewScript(VIEW_ID.PanelShenBingUpgrade)
                    if script then
                        local widget = UIHelper.GetChildByName(script.WidgetPageContent, "WidgetMoZhu")
                        local  widgetMoZhu = UIHelper.GetBindScript(widget)
                        widgetMoZhu:UpdateEquipment(self.szType, v.dwTabType, v.dwIndex, v.dwBox, v.dwX)
                    end
                    TipsHelper.DeleteAllHoverTips()
                    local RightBag = UIMgr.GetViewScript(VIEW_ID.PanelMoZhuRightBag)
                    UIMgr.Close(RightBag)
                end
            }}

            scriptItemTip:SetBtnState(tbBtnState)
            if UIHelper.GetSelected(widgetItem.ToggleSelect) then
                UIHelper.SetSelected(widgetItem.ToggleSelect, false)
            end
        end)
    end
    UIHelper.LayoutDoLayout(self.LayoutCell)    
    UIHelper.LayoutDoLayout(self.WidgetMoZhuBagCellGroup)
end


return UIMoZhuBagCellGroup