-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelModifyNamePop
-- Date: 2023-01-09 14:08:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelModifyNamePop = class("UIPanelModifyNamePop")

function UIPanelModifyNamePop:OnEnter(szTitle, szDefault, fnCallback, nMaxLength)
    self.fnCallback = fnCallback
    self.szDefault = szDefault or ""
    self.nMaxLength = nMaxLength or 30
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if szTitle then
        UIHelper.SetString(self.LabelTitle, szTitle)
    end

    UIHelper.SetMaxLength(self.EditBox, self.nMaxLength)
    UIHelper.SetString(self.EditBox, self.szDefault)    
    self:OnEditChanged()
end

function UIPanelModifyNamePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelModifyNamePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self.bConfirm = true
        self:Close()
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:Close()
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBox, function()
        self:OnEditChanged()
    end)

end

function UIPanelModifyNamePop:OnEditChanged()
    local sz = UIHelper.GetText(self.EditBox)
    local bEnable = sz ~= nil and sz ~= self.szDefault
    UIHelper.SetEnable(self.BtnConfirm, bEnable)
    UIHelper.SetNodeGray(self.BtnConfirm, not bEnable, true)    
end

function UIPanelModifyNamePop:Close()
    local fnCallback = self.fnCallback
    local szName
    if self.bConfirm then
        szName = UIHelper.GetText(self.EditBox)
    end
    UIMgr.Close(self)

    if fnCallback then
        fnCallback(szName)
    end
end

function UIPanelModifyNamePop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelModifyNamePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------



return UIPanelModifyNamePop