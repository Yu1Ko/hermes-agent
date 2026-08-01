-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandGroupBuyAddFriendCell
-- Date: 2024-02-18 16:13:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandGroupBuyAddFriendCell = class("UIHomelandGroupBuyAddFriendCell")

function UIHomelandGroupBuyAddFriendCell:OnEnter(tPlayer)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bIsGroupBuyMember = false
    self.tPlayer = tPlayer
    self:UpdateInfo()
end

function UIHomelandGroupBuyAddFriendCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandGroupBuyAddFriendCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFriend, EventType.OnClick, function()
        if UIHelper.GetSelected(self.TogFriend) and not self.bIsGroupBuyMember then
            Event.Dispatch(EventType.OnHomelandGroupBuyInviteFriend, self.tPlayer)
        end
    end)
end

function UIHomelandGroupBuyAddFriendCell:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function ()
        if arg0 == HOMELAND_RESULT_CODE.BUY_LAND_GROUPON_ADD_PLAYER then
            self:UpdateInfo()
        end
    end)
end

function UIHomelandGroupBuyAddFriendCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandGroupBuyAddFriendCell:UpdateInfo()
    local tPlayer = self.tPlayer
    local aRoleEntery = tPlayer.aRoleEntery
    local szName = UIHelper.GBKToUTF8(tPlayer.name)
    local szLevel = tostring(aRoleEntery.nLevel)
    local szCampImage = CampData.GetCampImgPath(aRoleEntery.nCamp, false, true)
    local szSchoolPath = PlayerForceID2SchoolImg[aRoleEntery.nForceID]

    UIHelper.SetString(self.LabelPlayerName, szName)
    UIHelper.SetString(self.LabelLevel, szLevel)
    UIHelper.SetSpriteFrame(self.ImgCamp, szCampImage)
    UIHelper.SetSpriteFrame(self.ImgSchool, szSchoolPath)
    self.scriptHead = self.scriptHead or UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
    self.scriptHead:SetHeadInfo(nil, aRoleEntery.dwMiniAvatarID or 0, aRoleEntery.nRoleType, aRoleEntery.nForceID)
    UIHelper.SetTouchEnabled(self.scriptHead.BtnHead, false)

    UIHelper.SetSelected(self.TogFriend, false)
    for i, tbInfo in ipairs(HomelandGroupBuyData.tMemberInfo) do
        if tbInfo.GlobalRoleID == tPlayer.id then
            UIHelper.SetSelected(self.TogFriend, true)
            UIHelper.SetEnable(self.TogFriend, false)
            self.bIsGroupBuyMember = true
            break
        end
    end
end

return UIHomelandGroupBuyAddFriendCell