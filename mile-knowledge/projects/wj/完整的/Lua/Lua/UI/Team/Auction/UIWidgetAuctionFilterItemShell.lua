-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAuctionFilterItemShell
-- Date: 2023-02-14 17:26:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAuctionFilterItemShell = class("UIWidgetAuctionFilterItemShell")

function UIWidgetAuctionFilterItemShell:OnEnter(tbConfig, fnSelect)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbConfig = tbConfig
    self.fnSelect = fnSelect
    self.tbFilterItems = {}
    self:UpdateInfo()
end

function UIWidgetAuctionFilterItemShell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetAuctionFilterItemShell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogChooseAll, EventType.OnSelectChanged, function (_, bSelected)
        self:SetSelected(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogRule, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.TogRule, "未勾选下列选项时，将显示适配当前心法及当前门派另一心法的装备。")
    end)
   
end

function UIWidgetAuctionFilterItemShell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetAuctionFilterItemShell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAuctionFilterItemShell:UpdateInfo()
    UIHelper.SetVisible(self.TogRule, self.tbConfig.bTogRule)
    UIHelper.SetVisible(self.TogChooseAll, self.tbConfig.bShowToggleChooseAll)

    local fnSelect = function (curScript, bSelected)
        local bAllSame = true
        for _, item in ipairs(self.tbFilterItems) do
            if item ~= curScript and item:GetSelected() ~= bSelected then
                bAllSame = false
                break
            end
        end
        if bAllSame then
            UIHelper.SetSelected(self.TogChooseAll, bSelected, false)
        else
            UIHelper.SetSelected(self.TogChooseAll, false, false)
        end
        local tbChecked = {}
        if bSelected then
            table.insert(tbChecked, curScript.tbConfig)
        end
        for _, item in ipairs(self.tbFilterItems) do
            if item ~= curScript and item:GetSelected() then
                table.insert(tbChecked, item.tbConfig)
            end
        end
        self.fnSelect(tbChecked)
    end
    for _, tbSub in ipairs(self.tbConfig) do
        local filterItem = UIHelper.AddPrefab(self.tbConfig.nSubPrefabID, self.LayoutScreenOptiom)
        filterItem:OnEnter(tbSub, fnSelect)
        table.insert(self.tbFilterItems, filterItem)
    end
    UIHelper.SetString(self.LabelTitle, self.tbConfig.szName)
    UIHelper.LayoutDoLayout(self.LayoutScreenOptiom)
    UIHelper.LayoutDoLayout(self.LayoutRecruitScreenSelectTips)
end

function UIWidgetAuctionFilterItemShell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogChooseAll, bSelected, false)
    local tbChecked = {}
    for _, item in ipairs(self.tbFilterItems) do
        item:SetSelected(bSelected)
        if bSelected then
            table.insert(tbChecked, item.tbConfig)
        end
    end
    self.fnSelect(tbChecked)
end

function UIWidgetAuctionFilterItemShell:GetSelected()
    return UIHelper.GetSelected(self.TogChooseAll)
end


return UIWidgetAuctionFilterItemShell