-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelFactionDonatePop
-- Date: 2023-02-28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelFactionDonatePop = class("UIPanelFactionDonatePop")

function UIPanelFactionDonatePop:OnEnter(szTitle, szDefault, fnCallback, fnEditEnded)
    self.fnCallback = fnCallback
    self.fnEditEnded = fnEditEnded
    self.szDefault = szDefault or ""
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if szTitle then
        UIHelper.SetString(self.LabelTitle, szTitle)
    end

    UIHelper.SetEditBoxInputMode(self.EditBox,cc.EDITBOX_INPUT_MODE_NUMERIC)
    UIHelper.SetString(self.EditBox, self.szDefault)
    self:OnEditEnded()
end

function UIPanelFactionDonatePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelFactionDonatePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        local fnCallback = self.fnCallback
        local szText = UIHelper.GetText(self.EditBox)
        if fnCallback then
            fnCallback(szText)
        end

        -- 弱网络处理，没返回先不能点
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable)
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:Close()
    end)
    UIHelper.BindUIEvent(self.TogTips, EventType.OnClick, function()
		UIHelper.SetTouchLikeTips(self.WidgetTips01, self._rootNode, function ()
			UIHelper.SetSelected(self.TogTips, false)
		end)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBox, function()
        self:OnEditEnded()
    end)



end

function UIPanelFactionDonatePop:OnEditEnded()
    if self.bLogicIgnore then return end
    local sz = UIHelper.GetText(self.EditBox)
    if self.fnEditEnded then
        local szNew = self.fnEditEnded(sz)
        if szNew ~= sz then
            self.bLogicIgnore = true
            UIHelper.SetString(self.EditBox, szNew)
            self.bLogicIgnore = false
        end
    end
    --UIHelper.SetEnable(self.BtnConfirm, bEnable)
    --UIHelper.SetNodeGray(self.BtnConfirm, not bEnable, true)
end

function UIPanelFactionDonatePop:Close()
    UIMgr.Close(self)
end

function UIPanelFactionDonatePop:RegEvent()
    Event.Reg(self, "TONG_EVENT_NOTIFY", function (eEventCode)
        if eEventCode == TONG_EVENT_CODE.SAVE_MONEY_SUCCESS or eEventCode == TONG_EVENT_CODE.SAVE_MONEY_TOO_MUSH_ERROR then
            -- 弱网络处理，有返回了就关闭界面
            self:Close()
        end
	end)
end

function UIPanelFactionDonatePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------



return UIPanelFactionDonatePop