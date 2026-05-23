-- ---------------------------------------------------------------------------------
-- Name: UIInvitationLikeCell
-- Date: 2023-10-24
-- WidgetInvitationLikeCell
-- ---------------------------------------------------------------------------------

local UIInvitationLikeCell = class("UIInvitationLikeCell")

function UIInvitationLikeCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIInvitationLikeCell:OnExit()
    self.bInit = false
end

function UIInvitationLikeCell:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnLike, EventType.OnClick, function ()
        if g_pClientPlayer and g_pClientPlayer.dwID and self.tLike and self.nLikeType then
            RemoteCallToServer("On_FriendPraise_AddRequest", g_pClientPlayer.dwID, self.tLike.dwID, self.nLikeType, self.tLike.szGID)
        end

        UIHelper.SetVisible(self.BtnLike, false)
        UIHelper.SetVisible(self.BtnRefuse, false)
        UIHelper.SetVisible(self.ImgBgMark, true)
        self:RemoveLikeInfo(false, self.tLike)
    end)

    UIHelper.BindUIEvent(self.BtnRefuse, EventType.OnClick, function ()
        self:RemoveLikeInfo(true, self.tLike)
    end)

end

function UIInvitationLikeCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

-- bHave = true 已点赞
function UIInvitationLikeCell:UpdateInfo(tLike, bHave, nLikeType)
    self.tLike = tLike
    self.nLikeType = nLikeType
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tLike.szName))
    local scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, tLike.dwID)

    local dwMiniAvatarID = tLike.dwMiniAvatarID
    if dwMiniAvatarID < 0 then
        dwMiniAvatarID = 0
    end
    scriptHead:SetHeadInfo(tLike.dwID, dwMiniAvatarID, tLike.nRoleType, tLike.dwForceID)
    if bHave == true then
        UIHelper.SetVisible(self.BtnLike, false)
        UIHelper.SetVisible(self.BtnRefuse, false)
        UIHelper.SetVisible(self.ImgBgMark, true)
    end
end

function UIInvitationLikeCell:RemoveLikeInfo(bDelete, tLike)
    Event.Dispatch(EventType.OnUpdateLikeMessage, bDelete, tLike)
end

return UIInvitationLikeCell