-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettlementHeadView
-- Date: 2023-08-08 11:08:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSettlementHeadView = class("UIWidgetSettlementHeadView")

function UIWidgetSettlementHeadView:OnEnter(tbMyAvatarData, tbSettlementDatas)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbMyAvatarData = tbMyAvatarData
    self.tbSettlementDatas = tbSettlementDatas
    self:UpdateInfo()
end

function UIWidgetSettlementHeadView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettlementHeadView:BindUIEvent()
    
end

function UIWidgetSettlementHeadView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSettlementHeadView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSettlementHeadView:UpdateInfo()
    local tbMyAvatarData = self.tbMyAvatarData
    if not tbMyAvatarData then return end
    local tbSettlementDatas = self.tbSettlementDatas
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tbMyAvatarData.szName))
    local nDataDirection = tbMyAvatarData.nDataDirection
    UIHelper.SetVisible(self.LayoutMoney, nDataDirection ~= MahjongData.GetPlayerDataDirection())

    local nGrade = MahjongData.GetThisGameGrade(tbSettlementDatas[nDataDirection])
    local szGrade = nGrade >= 0 and FormatString("+<D0>", nGrade) or FormatString("<D0>", nGrade)
    UIHelper.SetString(self.LabelMoney, szGrade)
    UIHelper.LayoutDoLayout(self.LayoutMoney)
    
    local nLackType = GetPlayerLack(nDataDirection)
    UIHelper.SetSpriteFrame(self.ImgSelectType, HomeLandHeadLackTypeImg[nLackType])

    UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, tbMyAvatarData.dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, tbMyAvatarData.nRoleType, tbMyAvatarData.dwForceID, true)
end


return UIWidgetSettlementHeadView