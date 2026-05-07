-- ---------------------------------------------------------------------------------
-- Name: UIOrangeUpgradePop
-- Date: 2023-10-30
-- PanelOrangeUpgradePop
-- Desc: 橙武升级确认弹窗 策划 hehuangjing
-- ---------------------------------------------------------------------------------

local UIOrangeUpgradePop = class("UIOrangeUpgradePop")

function UIOrangeUpgradePop:OnEnter(szTitle, szFunction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(szTitle, szFunction)
end

function UIOrangeUpgradePop:OnExit()
    self.bInit = false
end

function UIOrangeUpgradePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIOrangeUpgradePop:RegEvent()
    
end

function UIOrangeUpgradePop:UpdateInfo(szTitle, szFunction)
	local fnSure = function(szInput)
        RemoteCallToServer(szFunction, szInput)
    end

    UIHelper.SetRichText(self.RichtextDes, UIHelper.GBKToUTF8(szTitle))

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        local szTxt = UIHelper.GetText(self.EditBox)
        fnSure(UIHelper.UTF8ToGBK(szTxt))
        UIMgr.Close(self)
    end)
end

return UIOrangeUpgradePop