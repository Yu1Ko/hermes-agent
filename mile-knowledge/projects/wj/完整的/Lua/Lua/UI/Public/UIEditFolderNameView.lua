-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIEditFolderNameView
-- Date: 2023-10-18 19:36:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIEditFolderNameView = class("UIEditFolderNameView")

function UIEditFolderNameView:OnEnter(funcCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.funcCallback = funcCallback
    self:UpdateInfo()
end

function UIEditFolderNameView:OnExit()
    self.bInit = false
end

function UIEditFolderNameView:BindUIEvent()
    UIHelper.RegisterEditBoxChanged(self.EditBox, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        local szFileName = UIHelper.GetText(self.EditBox)
        UIMgr.Close(self)
        if self.funcCallback then
            self.funcCallback(szFileName)
        end
    end)
end

function UIEditFolderNameView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIEditFolderNameView:UpdateInfo()
    local szFileName = UIHelper.GetText(self.EditBox)
    if not string.is_nil(szFileName) then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable, "请先输入文件名")
    end
end


return UIEditFolderNameView