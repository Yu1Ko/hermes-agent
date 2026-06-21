-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieStudioCell
-- Date: 2025-03-07 10:23:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieStudioCell = class("UISelfieStudioCell")

function UISelfieStudioCell:OnEnter(tbDataInfo, onGetState, onClickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbDataInfo = tbDataInfo
    self.onGetState = onGetState
    self.onClickCallback = onClickCallback
    self:UpdateInfo()
end

function UISelfieStudioCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieStudioCell:BindUIEvent()
    for k, v in pairs(self.tbTogWidget) do
        UIHelper.BindUIEvent(v  , EventType.OnClick , function ()
            if self.onClickCallback then
                self.onClickCallback(self.tbDataInfo[k].dwID, self.tbDataInfo[k].dwMapID)
            end
        end)
   end
end

function UISelfieStudioCell:RegEvent()
    Event.Reg(self, EventType.OnSelfieStuidoCellSelect, function (dwID)
        for k, v in pairs(self.tbDataInfo) do
            UIHelper.SetVisible(self.tbImagSelected[k] , v.dwID == dwID)
        end
    end)
end

function UISelfieStudioCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieStudioCell:UpdateInfo()
    self.tStateInfo = {}
    for k, v in pairs(self.tbTogWidget) do
        UIHelper.SetVisible(v , self.tbDataInfo[k] ~= nil)
        if self.tbDataInfo[k] then
            self.tStateInfo[k] = self.onGetState(self.tbDataInfo[k].dwID)
            local name = UIHelper.GBKToUTF8(self.tbDataInfo[k].szName)
            UIHelper.SetSpriteFrame(self.tbImage[k], "Resource_UICommon_Camera_SelfieStudio_"..(self.tbDataInfo[k].dwID)..".png")
            UIHelper.SetString(self.tbLabelName[k],name)
            UIHelper.SetVisible(self.tbTip[k],self.tStateInfo[k].bSelect)
            UIHelper.SetVisible(self.tbImagSelected[k], self.tStateInfo[k].bSelect)
        end
    end
end

return UISelfieStudioCell