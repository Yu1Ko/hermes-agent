-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookItem
-- Date: 2022-12-09 10:31:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBookItem = class("UIBookItem")

function UIBookItem:OnEnter(tbCell)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local colorTextUnread = cc.c3b(0xB6,0xD4,0xDC)
    local colorTextread = cc.c3b(0xE2,0xF6,0xFB)
    local colorNumUnread = cc.c3b(0xB6,0xD4,0xDC)
    local colorNumRead = cc.c3b(0xFF,0xFF,0xFF)
    local colorNumReadAll = cc.c3b(0x5A,0xE3,0xA2)
    self.nBookID = tbCell.nBookID
    UIHelper.SetString(self.LabelNormalTitle, tbCell.szName)
    UIHelper.SetString(self.LabelSelectedTitle, tbCell.szName)
    UIHelper.SetString(self.LabelNormalNum, tbCell.szBookNum)

    if tbCell.nReadNum == 0 then
        UIHelper.SetColor(self.LabelNormalTitle, colorTextUnread)
        UIHelper.SetColor(self.LabelNormalNum, colorNumUnread)
    elseif tbCell.nReadNum == tbCell.nBookNum then
        UIHelper.SetColor(self.LabelNormalTitle, colorTextread)
        UIHelper.SetColor(self.LabelNormalNum, colorNumReadAll)
    else
        UIHelper.SetColor(self.LabelNormalTitle, colorTextread)
        UIHelper.SetColor(self.LabelNormalNum, colorNumRead)
    end
end

function UIBookItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBookItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogBookName, EventType.OnSelectChanged, function (_, bSelected)
        Event.Dispatch(EventType.OnBookItemSelect, self.nBookID, bSelected)
    end) 
end

function UIBookItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBookItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIBookItem:UpdateInfo()
    
end

return UIBookItem