-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieServantCell
-- Date: 2023-05-10 15:08:39
-- Desc: 幻境云图 -- 知交动作
-- ---------------------------------------------------------------------------------

local UISelfieServantCell = class("UISelfieServantCell")

function UISelfieServantCell:OnEnter(tbServantsInfo  , clickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    --{nNpcIndex  , bReceive}
    self.tbServantsInfo = tbServantsInfo
    self.clickCallback = clickCallback
    self:UpdateInfo()
end

function UISelfieServantCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieServantCell:BindUIEvent()
   for k, v in pairs(self.tbTogWidget) do
        UIHelper.BindUIEvent(v  , EventType.OnClick , function ()
            if self.clickCallback then
                self.clickCallback(self.tbServantsInfo[k].nNpcIndex , self.tbServantsInfo[k].bReceive)
            end
        end)
   end
end

function UISelfieServantCell:RegEvent()
    Event.Reg(self, EventType.OnSelfieServantCellSelect, function (nNpcIndex)
        for k, v in pairs(self.tbServantsInfo) do
            UIHelper.SetSelected(self.tbTogWidget[k] ,v.nNpcIndex == nNpcIndex)
        end
    end)
end

function UISelfieServantCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieServantCell:UpdateInfo()
    local dwCurServantNpcIndex = Servant_GetCurServantNpcIndex()
    for k, v in pairs(self.tbTogWidget) do
        UIHelper.SetVisible(v , self.tbServantsInfo[k] ~= nil)
        if self.tbServantsInfo[k] then
            if self.tbServantsInfo[k].nNpcIndex == -1  then
                UIHelper.SetString(self.tbLabelName[k] , g_tStrings.STR_REPUTATION_DISMISS_SERVANT2) 
                UIHelper.SetTexture(self.tbTogImage[k] , "Resource/ReputationPanel/partner/null.png")
            else
                local tServantInfo = Table_GetServantInfo(self.tbServantsInfo[k].nNpcIndex)
                if tServantInfo then
                    UIHelper.SetString(self.tbLabelName[k] ,  UIHelper.GBKToUTF8(tServantInfo.szNpcName) or g_tStrings.STR_NONE) 
                    UIHelper.SetTexture(self.tbTogImage[k] ,  tServantInfo.szImagePath)
                end
            end
            UIHelper.SetNodeGray(self.tbTogImage[k] , not self.tbServantsInfo[k].bReceive)
            UIHelper.SetSelected(v , dwCurServantNpcIndex == self.tbServantsInfo[k].nNpcIndex)
        end
    end
end


return UISelfieServantCell