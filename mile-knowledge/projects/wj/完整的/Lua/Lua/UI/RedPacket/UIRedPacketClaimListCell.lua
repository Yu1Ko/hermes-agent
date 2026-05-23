-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRedPacketClaimListCell
-- Date: 2023-11-28 16:16:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRedPacketClaimListCell = class("UIRedPacketClaimListCell")
local tbCoinImagePath =
{
    [1] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big.png",
    [2] = "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Jin_Big.png",
}
function UIRedPacketClaimListCell:OnEnter(tClaimInfo , nCoinType)
    self.tClaimInfo = tClaimInfo
    self.nCoinType = nCoinType
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIRedPacketClaimListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRedPacketClaimListCell:BindUIEvent()

end

function UIRedPacketClaimListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRedPacketClaimListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRedPacketClaimListCell:UpdateInfo()
    UIHelper.SetString(self.LabelName , UIHelper.GBKToUTF8(self.tClaimInfo.szRoleName))

    local _, szComment = TextFilterReplace(self.tClaimInfo.szComment)
    UIHelper.SetString(self.LabelSignature , UIHelper.GBKToUTF8(szComment))
    UIHelper.SetString(self.LabelMonry , self.tClaimInfo.nCurrency)

    UIHelper.SetVisible(self.ImgLuck , false)
    UIHelper.SetSpriteFrame(self.ImgMoney ,tbCoinImagePath[self.nCoinType])
    if not self.WidgetHead then
        self.WidgetHead = UIHelper.GetParent(self.imgPlayerIcon)
    end

    UIHelper.RemoveAllChildren(self.WidgetHead)
    self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
    if self.scriptHead then
        self.scriptHead:SetHeadInfo(nil, self.tClaimInfo.dwMiniAvatarID, self.tClaimInfo.nRoleType,self.tClaimInfo.dwForceID)
    end
end

function UIRedPacketClaimListCell:ShowRedHandInfo()
    UIHelper.SetVisible(self.ImgLuck , true)
end


return UIRedPacketClaimListCell