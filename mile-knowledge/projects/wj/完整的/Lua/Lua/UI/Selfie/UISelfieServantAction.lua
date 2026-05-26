-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieServantAction
-- Date: 2023-05-10 17:31:24
-- Desc: 幻境云图 -- 知交动作
-- ---------------------------------------------------------------------------------

local UISelfieServantAction = class("UISelfieServantAction")

function UISelfieServantAction:OnEnter(tbActionInfo,onClickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbActionInfo = tbActionInfo
    self.onClickCallback = onClickCallback
    self:UpdateInfo()
end

function UISelfieServantAction:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieServantAction:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRenownFriendAction , EventType.OnClick , function ()
        if self.onClickCallback then
            self.onClickCallback(self.tbActionInfo.dwActionID)
        else
            Servant_DoActionByID(self.tbActionInfo.dwActionID)
        end
    end)

end

function UISelfieServantAction:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieServantAction:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieServantAction:UpdateInfo()
    if self.tbActionInfo.nIconID then
        UIHelper.SetItemIconByIconID(self.ImgSymbol, self.tbActionInfo.nIconID)
    end
    if self.tbActionInfo.szIconPath then
        UIHelper.SetSpriteFrame(self.ImgSymbol, self.tbActionInfo.szIconPath)
    end
    UIHelper.SetString(self.LabelName , UIHelper.GBKToUTF8(self.tbActionInfo.szName) or g_tStrings.STR_NONE)
end


return UISelfieServantAction