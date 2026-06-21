-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMedalChilNavigation
-- Date: 2023-03-31 15:52:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMedalChilNavigation = class("UIMedalChilNavigation")

function UIMedalChilNavigation:OnEnter(tMedalInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nGroupID = tMedalInfo[2]
    self.nGroupIndex = tMedalInfo[3]
    UIHelper.SetString(self.LabelChildNavigationNormal,tMedalInfo[1])
    UIHelper.SetString(self.LabelChildNavigationSelect,tMedalInfo[1])
    UIHelper.SetVisible(self.WidgetDown,tMedalInfo[4])
    if self.nGroupID == 1 and self.nGroupIndex == 1 then
        UIHelper.SetSelected(self.ToggleChildNavigation,true)
    end
    UIHelper.SetNodeSwallowTouches(self.WidgetChilNavigation,false,true)
end

function UIMedalChilNavigation:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMedalChilNavigation:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleChildNavigation,EventType.OnSelectChanged,function (_,bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnSelectPetMedal,self.nGroupID,self.nGroupIndex)
        end
    end)
end

function UIMedalChilNavigation:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMedalChilNavigation:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMedalChilNavigation:UpdateInfo()
    
end


return UIMedalChilNavigation