-- ---------------------------------------------------------------------------------
-- Name: UIWidgetTitleCell
-- Desc: 名片中称号cell
-- ---------------------------------------------------------------------------------

local UIWidgetTitleCell = class("UIWidgetTitleCell")

function UIWidgetTitleCell:OnEnter()
    if not self.bInit then
        self.bInit = true
        self:BindUIEvent()
    end
end

function UIWidgetTitleCell:OnExit()
    self.bInit = false
end

function UIWidgetTitleCell:RegEvent()
    
end

function UIWidgetTitleCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTitle, EventType.OnSelectChanged, function()
        if self.fnSelectedCallback then
            self.fnSelectedCallback()
        end
    end)
end

function UIWidgetTitleCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
-- self player
function UIWidgetTitleCell:UpdateInfo(szLabel)
    UIHelper.SetString(self.LabelTitleName, szLabel)
end

function UIWidgetTitleCell:SetSelectedCallback(fnSelectedCallback)
    self.fnSelectedCallback = fnSelectedCallback
end

function UIWidgetTitleCell:SetTogUnable()
    UIHelper.SetTouchEnabled(self.TogTitle, false)
end


return UIWidgetTitleCell