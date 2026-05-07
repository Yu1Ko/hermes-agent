-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMahjongHeadView
-- Date: 2023-07-31 16:32:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMahjongHeadView = class("UIWidgetMahjongHeadView")

function UIWidgetMahjongHeadView:OnEnter(tbPlayerInfo, scriptMahjong)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbPlayerInfo = tbPlayerInfo
    self.scriptMahjong = scriptMahjong
    self:UpdateInfo(tbPlayerInfo)
end

function UIWidgetMahjongHeadView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMahjongHeadView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAvatarBg2, EventType.OnClick, function()
        if not self.bShow then 
            self.scriptMahjong:ClosePlayerTips()
            self:ShowGameInfo()
        else
            self:CloseGameInfo()
        end
    end)
end

function UIWidgetMahjongHeadView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMahjongHeadView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMahjongHeadView:UpdateInfo(tbPlayerInfo)
    local player = GetPlayer(tbPlayerInfo[1])
    local szName = ""
    if player then
        local tbAvatar = MahjongData.GetPlayerAvatar(player.GetGlobalID())
        if tbAvatar then
            szName = UIHelper.GBKToUTF8(tbAvatar.szName)
            UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, tbAvatar.dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, tbAvatar.nRoleType, tbAvatar.dwForceID, true)
        end
    end
    UIHelper.SetString(self.TextName, szName)
    UIHelper.SetString(self.TextMoney, tbPlayerInfo[3])
    local nState = tbPlayerInfo[2]
    local bShow = nState == tPlayerState.nReady and (not MahjongData.GetGameStart())

    self:UpdateReady(bShow)
    UIHelper.SetVisible(self.ImgLeave, nState == tPlayerState.nLeave)

    local nLackType = tbPlayerInfo[5]
    UIHelper.SetVisible(self.ImgSelectType, nLackType ~= nil)

    if nLackType then
        UIHelper.SetSpriteFrame(self.ImgSelectType, HomeLandHeadLackTypeImg[nLackType])
    end

    local bDingQue = tbPlayerInfo[6]--定缺
    local bSelectCard = tbPlayerInfo[7]--选牌
    local bChangeCard = tbPlayerInfo[8]--换牌

    self:UpdateChange(bChangeCard)
    self:UpdateSelect(bSelectCard)
    self:UpdateDingQue(bDingQue)
 
    local bAgent = tbPlayerInfo[9]--是否托管
    self:UpdateTuoguan(bAgent)
    
    if self.LayoutMoney then
        UIHelper.LayoutDoLayout(self.LayoutMoney)
    end

    local nDataDirection = MahjongData.GetPlayerDataDirectionByPlayerID(tbPlayerInfo[1])
    local nUIDirection = nDataDirection and MahjongData.ConvertDataDirectionToUIDirection(nDataDirection) or nil
    
    if self.WidgetHandleStateUp and nUIDirection then
        UIHelper.SetVisible(self.WidgetHandleStateUp, nUIDirection == tUIPosIndex.Up)
    end

    if self.WidgetHandleStateDown and nUIDirection then
        UIHelper.SetVisible(self.WidgetHandleStateDown, nUIDirection == tUIPosIndex.Down)
    end

    self:UpdateSkin()
end

function UIWidgetMahjongHeadView:UpdateSkin()
    local nSkinID = MahjongData.GetSkinInfoID("SettlementPanel")
    if not nSkinID then
        return
    end

    local szSkinID = nSkinID == 1 and "" or "_" .. string.format("%02d", nSkinID)
    local szAvatarPath = "UIAtlas2_Mahjong_MahjongMix_HeadCommon0" .. szSkinID
    local szBtnAvatar = "UIAtlas2_Mahjong_MahjongMix_HeadCommon1" .. szSkinID

    UIHelper.SetSpriteFrame(self.ImgAvatarBg1, szAvatarPath)
    UIHelper.SetSpriteFrame(self.ImgBtnAvatarBg, szBtnAvatar)
end

function UIWidgetMahjongHeadView:UpdateReady(bShow)
    for index, img in ipairs(self.tbImageReady) do
        UIHelper.SetVisible(img, bShow)
    end
end

function UIWidgetMahjongHeadView:UpdateSelect(bShow)
    for index, img in ipairs(self.tbImageSelect) do
        UIHelper.SetVisible(img, bShow)
    end
end

function UIWidgetMahjongHeadView:UpdateDingQue(bShow)
    for index, img in ipairs(self.tbImageDingQue) do
        UIHelper.SetVisible(img, bShow)
    end
end

function UIWidgetMahjongHeadView:UpdateChange(bShow)
    for index, img in ipairs(self.tbImageChange) do
        UIHelper.SetVisible(img, bShow)
    end
end

function UIWidgetMahjongHeadView:UpdateTuoguan(bShow)
    for index, img in ipairs(self.tbImageTuoGuan) do
        UIHelper.SetVisible(img, bShow)
    end
end

function UIWidgetMahjongHeadView:UpdateFail(bShow)
    for index, img in ipairs(self.tbImageFail) do
        UIHelper.SetVisible(img, bShow)
    end
end


function UIWidgetMahjongHeadView:ShowGameInfo()
    local tbPlayerInfo = self.tbPlayerInfo
    local nDataDirection = MahjongData.GetPlayerDataDirectionByPlayerID(tbPlayerInfo[1])
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    if self.WidgetInfoUp then 
        UIHelper.SetVisible(self.WidgetInfoUp, nUIDirection == tUIPosIndex.Up)
    end

    if self.WidgetInfoDown then 
        UIHelper.SetVisible(self.WidgetInfoDown, nUIDirection == tUIPosIndex.Down)
    end

    if self.WidgetInfoLeft then 
        UIHelper.SetVisible(self.WidgetInfoLeft, nUIDirection == tUIPosIndex.Right)
    end

    if self.WidgetInfoRight then 
        UIHelper.SetVisible(self.WidgetInfoRight, nUIDirection == tUIPosIndex.Left)
    end

    local szContent = MahjongData.GetMahjongRecordText(tbPlayerInfo[1])

    if self.LableLeftAll then UIHelper.SetString(self.LableLeftAll, szContent) end
    if self.LableRightAll then UIHelper.SetString(self.LableRightAll, szContent) end
    if self.LableUpAll then UIHelper.SetString(self.LableUpAll, szContent) end
    if self.LableDownAll then UIHelper.SetString(self.LableDownAll, szContent) end

    self.bShow = true
end

function UIWidgetMahjongHeadView:CloseGameInfo()
    if self.WidgetInfoUp then 
        UIHelper.SetVisible(self.WidgetInfoUp, false)
    end

    if self.WidgetInfoDown then 
        UIHelper.SetVisible(self.WidgetInfoDown, false)
    end

    if self.WidgetInfoLeft then 
        UIHelper.SetVisible(self.WidgetInfoLeft, false)
    end

    if self.WidgetInfoRight then 
        UIHelper.SetVisible(self.WidgetInfoRight, false)
    end
    self.bShow = false
end

return UIWidgetMahjongHeadView