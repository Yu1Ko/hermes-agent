-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOperRecordItem
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOperRecordItem = class("UIWidgetOperRecordItem")

function UIWidgetOperRecordItem:OnEnter(tRecord)
    if not tRecord then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tRecord = tRecord
    self:UpdateInfo(tRecord)
end

function UIWidgetOperRecordItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetOperRecordItem:BindUIEvent()

end

function UIWidgetOperRecordItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOperRecordItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOperRecordItem:UpdateInfo(tRecord)
    local szImagePath = PlayerForceID2SchoolImg2[tRecord.dwForceID]
    local szDateTime = os.date("%Y-%m-%d %H:%M:%S", tRecord.nFinishTime)
    UIHelper.SetString(self.LabelPlayerName, tRecord.szOperatorName, 9)
    UIHelper.SetSpriteFrame(self.ImgSchool, szImagePath)
    UIHelper.SetRichText(self.RichTextOperContent, tRecord.szMsg)
    UIHelper.SetString(self.LabelTime, szDateTime)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutPlayerContent, true, true)
end

return UIWidgetOperRecordItem