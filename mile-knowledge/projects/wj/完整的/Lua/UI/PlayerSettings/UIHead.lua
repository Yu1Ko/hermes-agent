-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHead
-- Date: 2022-12-20 09:38:05
-- Desc: WidgetHead_108
-- ---------------------------------------------------------------------------------

---@class UIHead
local UIHead = class("UIHead")

function UIHead:OnEnter(dwID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwID = dwID
    self:UpdateInfo()
end

function UIHead:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHead:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHead, EventType.OnClick, function()
        if self.funcClickCallback then
            self.funcClickCallback(self.dwID)
        end
    end)
end

function UIHead:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "TARGET_MINI_AVATAR_MISC", function ()
        local player  = GetPlayer(self.dwID)
        if player then
            UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon,player.dwMiniAvatarID,self.SFXPlayerIcon,self.AnimatePlayerIcon,player.nRoleType,player.dwForceID,true)
        end
    end)

    Event.Reg(self, EventType.PLAYER_MINI_AVATAR_UPDATE, function ()
        if PlayerData.IsSelf(self.dwID) then
            local player = g_pClientPlayer
            UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon,player.dwMiniAvatarID,self.SFXPlayerIcon,self.AnimatePlayerIcon,player.nRoleType,player.dwForceID,true)
        end
    end)
end

function UIHead:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHead:UpdateInfo()
    local player  = GetPlayer(self.dwID)
    if not player then return end
    UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, player.dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, player.nRoleType, player.dwForceID,true)
end

function UIHead:SetHeadInfo(dwID, dwMiniAvatarID, nRoleType, dwForceID)
    self.dwID = dwID
    if self.bRank then
        UIHelper.RoleChange_UpdateRankAvatar(self.ImgPlayerIcon, dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, nRoleType, dwForceID, self.bWanted, true)
    else
        UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, nRoleType, dwForceID, true, false)
    end
end

function UIHead:SetHeadWithForceID(dwForceID)
    local szImage = DefaultAvatar[dwForceID or g_pClientPlayer.dwForceID]
    UIHelper.SetTexture(self.ImgPlayerIcon, szImage)
end

function UIHead:SetHeadWithMountKungfuID(dwMountKungfuID)
    local szImage = PlayerKungfuImg[dwMountKungfuID]
    if szImage then
        UIHelper.SetSpriteFrame(self.ImgKungfu, szImage)
        UIHelper.SetVisible(self.ImgKungfu, true)
    end
end

function UIHead:SetShowSelf(bShow)
    UIHelper.SetVisible(self.WidgetSelf, bShow)
end

-- JJC连胜
function UIHead:SetShowPvPConstantlyWin(bShow)
    UIHelper.SetVisible(self.WIdgetPvPConstantlyWin, bShow)
end

function UIHead:SetHeadWithImg(szImage)
    UIHelper.ClearTexture(self.ImgPlayerIcon)
    UIHelper.SetSpriteFrame(self.ImgPlayerIcon, szImage)
end

function UIHead:SetHeadContentSize(nWidth, nHeight)
    UIHelper.SetContentSize(self.ImgPlayerIcon, nWidth, nHeight)
end

function UIHead:SetHeadWithTex(szTexPath)
    UIHelper.SetTexture(self.ImgPlayerIcon, szTexPath)
end

function UIHead:SetAccountHeadInfo(nUserAvatar)
    local tLine = Table_GetAccountFriendAvatar(nUserAvatar)
    if not tLine then return end
    local szImage = string.gsub(tLine.szPath,"ui\\Image\\PlayerAvatar\\","Resource/PlayerAvatar/")
    szImage = string.gsub(szImage,"tga","png")
    UIHelper.SetTexture(self.ImgPlayerIcon, szImage)
end

function UIHead:SetOfflineState(bOffline)
    -- UIHelper.SetNodeGray(self._rootNode, bOffline, true)
    UIHelper.SetVisible(self.ImgPlayerFrameOffline, bOffline)
    UIHelper.SetColor(self.ImgPersonalFrame, bOffline and cc.c3b(109, 109, 109) or cc.c3b(255, 255, 255))
    UIHelper.SetColor(self.ImgPlayerFrame2, bOffline and cc.c3b(109, 109, 109) or cc.c3b(255, 255, 255))
end

function UIHead:SetPersonalFrame(szFrame)
    if not szFrame or szFrame == "" then
        UIHelper.ClearTexture(self.ImgPersonalFrame)
        UIHelper.ClearTexture(self.ImgPlayerFrame2)
        UIHelper.SetVisible(self.ImgPlayerFrameLine, true)
    else
        UIHelper.SetTexture(self.ImgPersonalFrame, szFrame)
        UIHelper.SetTexture(self.ImgPlayerFrame2, szFrame)
        UIHelper.SetVisible(self.ImgPersonalFrame, true)
        UIHelper.SetVisible(self.ImgPlayerFrame2, true)
        UIHelper.SetVisible(self.ImgPlayerFrameLine, false)
    end
end

function UIHead:SetRankFlag(bRank, bWanted)
    self.bRank = bRank
    self.bWanted = bWanted
end

function UIHead:SetClickCallback(funcClickCallback)
    self.funcClickCallback = funcClickCallback
end

function UIHead:SetTouchEnabled(bEnable)
    UIHelper.SetTouchEnabled(self.BtnHead, bEnable)
end

return UIHead