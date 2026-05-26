-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelectTipsApprentice
-- Date: 2023-02-22 14:41:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelectTipsApprentice = class("UISelectTipsApprentice")

function UISelectTipsApprentice:OnEnter(dwForceID,szName,szSelectorName,selectValue)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwForceID = dwForceID
    self.szSelectorName = szSelectorName
    self.selectValue = selectValue
    self:UpdateInfo(szName)
    UIHelper.SetNodeSwallowTouches(self.TogPitchBg, false, true)
end

function UISelectTipsApprentice:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelectTipsApprentice:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPitchBg,EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnShopSelectorSelectChanged, self.szSelectorName, self.selectValue)
        end
    end)
end

function UISelectTipsApprentice:RegEvent()
end

function UISelectTipsApprentice:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelectTipsApprentice:UpdateInfo(szName)
    UIHelper.SetString(self.LabelDesc,szName)
end


return UISelectTipsApprentice