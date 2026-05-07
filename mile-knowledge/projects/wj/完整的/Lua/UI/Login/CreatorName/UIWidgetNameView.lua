-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetNameView
-- Date: 2023-07-24 10:28:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetNameView = class("UIWidgetNameView")

function UIWidgetNameView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetNameView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetNameView:BindUIEvent()

end

function UIWidgetNameView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetNameView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetNameView:AddChild(tbName)
    if not self.tbNameList then
        self.tbNameList = {}
    end
    if #self.tbNameList == 2 then return false end
    table.insert(self.tbNameList, tbName)
    self:UpdateInfo()
    return true
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetNameView:UpdateInfo()
    local nDataLen = #self.tbNameList
    UIHelper.SetVisible(self.LabelName1, nDataLen >= 1)
    UIHelper.SetVisible(self.LabelName2, nDataLen >= 2)

    if nDataLen >= 1 then
        local szName = self.tbNameList[1] and self.tbNameList[1][4]
        szName = string.is_nil(szName) and "" or GBKToUTF8(self.tbNameList[1][4])
        UIHelper.SetString(self.LabelName1, szName)
    end

    if nDataLen >= 2 then
        local szName = self.tbNameList[2] and self.tbNameList[2][4]
        szName = string.is_nil(szName) and "" or GBKToUTF8(self.tbNameList[2][4])
        UIHelper.SetString(self.LabelName2, szName)
    end
end



return UIWidgetNameView