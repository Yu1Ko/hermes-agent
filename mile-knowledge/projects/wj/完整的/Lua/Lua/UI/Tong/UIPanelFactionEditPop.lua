-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelFactionEditPop
-- Date: 2023-01-09 14:08:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelFactionEditPop = class("UIPanelFactionEditPop")

function UIPanelFactionEditPop:OnEnter(szTitle, szDefault, fnCallback, nMaxLength, szEmptyTips)
    self.fnCallback = fnCallback
    self.szDefault = szDefault or ""
    self.nMaxLength = nMaxLength or 256
    self.szEmptyTips = szEmptyTips
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

function UIPanelFactionEditPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelFactionEditPop:BindUIEvent()
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

function UIPanelFactionEditPop:OnEditChanged()
    local sz = UIHelper.GetText(self.EditBox)
    local bEnable = sz ~= nil and sz ~= self.szDefault
    UIHelper.SetEnable(self.BtnConfirm, bEnable)
    UIHelper.SetNodeGray(self.BtnConfirm, not bEnable, true) 
    
    -- 无内容时的提示
    if self.szEmptyTips then
        if sz ~= nil or sz == "" then
            self.EditBox:setPlaceHolder(self.szEmptyTips)
        end
    end
end

function UIPanelFactionEditPop:Close()
    local fnCallback = self.fnCallback
    local szText
    if self.bConfirm then
        szText = UIHelper.GetText(self.EditBox)
    end
    UIMgr.Close(self)

    if fnCallback then
        fnCallback(szText)
    end
end

function UIPanelFactionEditPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelFactionEditPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------



return UIPanelFactionEditPop