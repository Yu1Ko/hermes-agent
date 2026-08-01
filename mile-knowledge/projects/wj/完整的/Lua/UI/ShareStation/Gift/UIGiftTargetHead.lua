-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGiftTargetHead
-- Date: 2026-04-08 15:26:40
-- Desc: 打赏目标头像组件，用于副本观战场景显示礼物接收者头像
-- ---------------------------------------------------------------------------------

local UIGiftTargetHead = class("UIGiftTargetHead")

function UIGiftTargetHead:OnEnter(szRoomID, tbParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szGlobalID = tbParam and tbParam.szGlobalID
    self.nPlayerID = tbParam and tbParam.nPlayerID
    self:UpdateInfo()
end

function UIGiftTargetHead:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGiftTargetHead:BindUIEvent()

end

function UIGiftTargetHead:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGiftTargetHead:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGiftTargetHead:UpdateInfo()
    if not self.szGlobalID and not self.nPlayerID then
        return
    end

    local tbInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(self.szGlobalID)
    if not tbInfo and not self.nPlayerID then
        return
    end

    if not self.scriptHead then
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead_72)
    end
    if tbInfo then
        self.scriptHead:SetHeadInfo(nil, tbInfo.dwMiniAvatarID or 0, tbInfo.nRoleType, tbInfo.nForceID)
    else
        self.scriptHead:OnEnter(self.nPlayerID)
    end
    self.scriptHead:SetTouchEnabled(false)
end


return UIGiftTargetHead
