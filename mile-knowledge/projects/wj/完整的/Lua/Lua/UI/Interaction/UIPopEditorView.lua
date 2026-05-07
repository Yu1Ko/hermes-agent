-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPopEditorView
-- Date: 2022-11-25 10:05:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPopEditorView = class("UIPopEditorView")

function UIPopEditorView:OnEnter(szDefaultText, szTipContent, confirmCallback)
    self.szText = szDefaultText
    self.szTipContent = szTipContent
    self.ConfirmCallback = confirmCallback

    self.bConfirmCloseSelf = true

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPopEditorView:OnExit()
    self.bInit = false
    Timer.DelAllTimer(self)
    self:UnRegEvent()
end

function UIPopEditorView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.ConfirmCallback then
            self.ConfirmCallback(UIHelper.GetString(self.EditBox))
        end

        if self.bConfirmCloseSelf then
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPopEditorView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPopEditorView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPopEditorView:UpdateInfo()
    UIHelper.SetString(self.LaberRemarks, self.szTipContent)
    UIHelper.SetString(self.EditBox, self.szText)
    self.EditBox:setPlaceHolder(self.szPlaceHolder or self.szTipContent)
end

function UIPopEditorView:SetTitle(szTitle)
    UIHelper.SetString(self.LabelTitle, szTitle)
end

function UIPopEditorView:SetMaxLength(nMaxLength)
    UIHelper.SetMaxLength(self.EditBox, nMaxLength)
end

function UIPopEditorView:SetPlaceHolder(szText)
    self.szPlaceHolder = szText
    self.EditBox:setPlaceHolder(self.szPlaceHolder)
end

function UIPopEditorView:SetConfirmCloseSelf(bValue)
    self.bConfirmCloseSelf = bValue
end

return UIPopEditorView