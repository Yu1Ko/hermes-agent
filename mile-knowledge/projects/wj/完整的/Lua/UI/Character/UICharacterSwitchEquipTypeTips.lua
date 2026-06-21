-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterSwitchEquipTypeTips
-- Date: 2024-05-16 20:27:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterSwitchEquipTypeTips = class("UICharacterSwitchEquipTypeTips")

local tbFilterName = {"武器", "重兵类", "暗器", "上衣", "帽子", "项链", "戒指·一", "戒指·二", "腰带", "腰坠", "下装", "鞋子", "护腕", "暗器弹药"}

function UICharacterSwitchEquipTypeTips:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurPage = self.nCurPage or 1
    self.tbCurSelected = Lib.copyTab(Storage.SwitchEquipSuit)
    self:UpdateInfo()
end

function UICharacterSwitchEquipTypeTips:OnExit()
    self.bInit = false
end

function UICharacterSwitchEquipTypeTips:BindUIEvent()
    for i, tog in ipairs(self.tbTogType) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nCurPage = i
            self:UpdateInfo()
        end)
        UIHelper.SetTouchDownHideTips(tog, false)
    end

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        if table.get_len(self.tbCurSelected["tbEquipType1"]) > 0 or table.get_len(self.tbCurSelected["tbEquipType2"]) > 0 then
            UIHelper.ShowConfirm("切换装备套装时，共用部位的装备会进行互换，是否确认配置共用部位？", function ()
                Storage.SwitchEquipSuit["tbEquipType1"] = self.tbCurSelected["tbEquipType1"]
                Storage.SwitchEquipSuit["tbEquipType2"] = self.tbCurSelected["tbEquipType2"]
                Storage.SwitchEquipSuit.Dirty()
                Event.Dispatch(EventType.HideAllHoverTips)
            end)
        else
            Storage.SwitchEquipSuit["tbEquipType1"] = self.tbCurSelected["tbEquipType1"]
            Storage.SwitchEquipSuit["tbEquipType2"] = self.tbCurSelected["tbEquipType2"]
            Storage.SwitchEquipSuit.Dirty()
            Event.Dispatch(EventType.HideAllHoverTips)
        end
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function(btn)
        self.tbCurSelected["tbEquipType" .. self.nCurPage] = {}
        Storage.SwitchEquipSuit["tbEquipType" .. self.nCurPage] = {}
        Storage.SwitchEquipSuit.Dirty()

        self:UpdateInfo()
    end)
end

function UICharacterSwitchEquipTypeTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICharacterSwitchEquipTypeTips:UpdateInfo()
    local tbConfigs = self.tbCurSelected["tbEquipType" .. self.nCurPage]
    if self.nCurPage == 1 then
        UIHelper.SetString(self.LabelTittle, "配置第1、2套装备方案共用的部位")
    elseif self.nCurPage == 2 then
        UIHelper.SetString(self.LabelTittle, "配置第3、4套装备方案共用的部位")
    end

    for i, cell in ipairs(self.tbCells) do
        local script = UIHelper.GetBindScript(cell)
        UIHelper.BindUIEvent(script.TogType, EventType.OnClick, function(btn)
            tbConfigs[i] = UIHelper.GetSelected(script.TogType)
            Storage.SwitchEquipSuit.Dirty()
        end)
        UIHelper.SetString(script.LabelName, tbFilterName[i])
        UIHelper.SetSelected(script.TogType, not not tbConfigs[i])
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTypeTog)
end


return UICharacterSwitchEquipTypeTips