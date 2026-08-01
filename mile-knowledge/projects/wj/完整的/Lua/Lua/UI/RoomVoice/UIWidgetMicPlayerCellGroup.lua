-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMicPlayerCellGroup
-- Date: 2025-09-16 17:02:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMicPlayerCellGroup = class("UIWidgetMicPlayerCellGroup")

function UIWidgetMicPlayerCellGroup:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetMicPlayerCellGroup:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMicPlayerCellGroup:BindUIEvent()
    
end

function UIWidgetMicPlayerCellGroup:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMicPlayerCellGroup:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMicPlayerCellGroup:InitInfo(szRoomID, tbMemberList, bInBatch, fnSelectPlayer, fnSelect)
    self.szRoomID = szRoomID
    self.tbMemberList = tbMemberList
    self.bInBatch = bInBatch
    self.fnSelectPlayer = fnSelectPlayer
    self.fnSelect = fnSelect
    self:UpdateInfo()
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMicPlayerCellGroup:UpdateInfo()
    for nIndex = 1, #self.tbUIMemberList do
        local tbMember = self.tbMemberList[nIndex]
        local node = self.tbUIMemberList[nIndex]
        if tbMember then
            local script = UIHelper.GetBindScript(node)
            script:OnEnter(self.szRoomID, tbMember, self.bInBatch, self.fnSelectPlayer, self.fnSelect)
        end
        UIHelper.SetVisible(node, tbMember ~= nil)
    end
end


return UIWidgetMicPlayerCellGroup