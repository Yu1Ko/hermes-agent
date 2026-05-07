-- ---------------------------------------------------------------------------------
-- Name: UIWidgetContentSelectCell
-- Desc: 名片形象 - 数据选择 - 展示数据cell(左侧的)
-- ---------------------------------------------------------------------------------

local UIWidgetContentSelectCell = class("UIWidgetContentSelectCell")

function UIWidgetContentSelectCell:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetContentSelectCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetContentSelectCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSkill, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnSelectedCallback then
            self.fnSelectedCallback(self.dwKey)
        end
    end)
end

function UIWidgetContentSelectCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetContentSelectCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
-- self player
function UIWidgetContentSelectCell:UpdateInfo(tData)
    if not tData then return end
    self.dwKey = tData.dwKey

    UIHelper.SetTexture(self.ImgIcon, tData.Img)
    UIHelper.SetString(self.LabelSkillName, tData.szName)
    UIHelper.SetString(self.LabelSkillLevel, tData.nValue1)

    if tData.bChoice == true then
        UIHelper.SetVisible(self.ImgCheck, true)
    else
        UIHelper.SetVisible(self.ImgCheck, false)
    end

    if tData.bSelect == true then
        UIHelper.SetVisible(self.ImgSelect, true)
    else
        UIHelper.SetVisible(self.ImgSelect, false)
    end

    if tData.bShow == false then
        UIHelper.SetTouchEnabled(self.TogSkill, false)
    else
        UIHelper.SetTouchEnabled(self.TogSkill, true)
    end
end

function UIWidgetContentSelectCell:ShowEmpty()
    self.dwKey = 0

    UIHelper.SetVisible(self.ImgIcon, false)
    UIHelper.SetVisible(self.LabelSkillName, false)
    UIHelper.SetVisible(self.LabelSkillLevel, false)
    UIHelper.SetVisible(self.ImgCheck, false)
    UIHelper.SetVisible(self.LabelEmpty, true)
end

function UIWidgetContentSelectCell:SetSelectedCallback(fnSelectedCallback)
    self.fnSelectedCallback = fnSelectedCallback
end

function UIWidgetContentSelectCell:HideClickState()
end


return UIWidgetContentSelectCell