-- ---------------------------------------------------------------------------------
-- Name: UIWidgetInformationCell
-- Desc: 名片形象 - 展示数据cell(中间卡片的)(弃用)
-- ---------------------------------------------------------------------------------

local UIWidgetInformationCell = class("UIWidgetInformationCell")

function UIWidgetInformationCell:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetInformationCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetInformationCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogInformation, EventType.OnSelectChanged, function(_, bSelected)
        if not bSelected then return end
        if self.fnSelectedCallback then
            self.fnSelectedCallback(self.dwKey)
        end
    end)
end

function UIWidgetInformationCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetInformationCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetInformationCell:UpdateInfo(tData)
    if not tData then return end
    self.dwKey = tData.dwKey

    UIHelper.SetSpriteFrame(self.ImgIcon, tData.Img)
    UIHelper.SetString(self.LabelInformationName, tData.szName)
    UIHelper.SetString(self.LabelInformationNum, tData.nValue)
    UIHelper.SetVisible(self.ImgSelect, tData.bChoice)
end

function UIWidgetInformationCell:SetSelectedCallback(fnSelectedCallback)
    self.fnSelectedCallback = fnSelectedCallback
end

return UIWidgetInformationCell