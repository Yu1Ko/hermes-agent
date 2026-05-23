-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRoomCell
-- Date: 2024-02-19 10:05:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRoomCell = class("UIRoomCell")

function UIRoomCell:OnEnter(bPuppet, nGroup, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bPuppet = bPuppet
    self.nGroup = nGroup
    self.nIndex = nIndex

    self:UpdateInfo()
end

function UIRoomCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoomCell:BindUIEvent()
    if self.bPuppet then
        return
    end

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function()
        local tInfo = self.tInfo

        local tbMenuConfig = self:GenerateMenuConfig()
        local tbPlayerCard = {
            -- dwID = tInfo.dwID,
            nRoleType = tInfo.nRoleType,
            nForceID = tInfo.dwForceID,
            nLevel = tInfo.nLevel,
            szName = tInfo.szName,
            nCamp = tInfo.nCamp,
            dwMiniAvatarID = tInfo.dwMiniAvatarID or 0,
        }

        local tips, script = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPlayerPop, self._rootNode, nil, tbMenuConfig, tbPlayerCard)
        local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(script.LayoutPlayer)
        local _, nCellHeight = UIHelper.GetContentSize(self._rootNode)
        tips:SetSize(nTipsWidth, nTipsHeight)
        local nDir
        local nOffsetY
        if self.bScene then
            if self.nIndex <= 2 then
                nDir = TipsLayoutDir.TOP_RIGHT
                nOffsetY = -nCellHeight
            else
                nDir = TipsLayoutDir.TOP_LEFT
                nOffsetY = -nCellHeight
            end
        else
            if self.nGroup <= 2 then
                nDir = TipsLayoutDir.TOP_RIGHT
            else
                nDir = TipsLayoutDir.TOP_LEFT
            end
            if self.nIndex <= 2 then
                nOffsetY = -nTipsHeight
            else
                nOffsetY = -nCellHeight
            end
        end
        tips:SetDisplayLayoutDir(nDir)
        tips:SetOffset(2, nOffsetY)
        tips:UpdatePosByNode(self._rootNode)
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnTouchBegan, function (btn, x, y)
        self.nStartX = x
        self.nStartY = y
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnTouchMoved, function (btn, x, y)
        if self.bMoving then
            Event.Dispatch(EventType.OnRoomCellTouchMoved, self.tInfo, self.nGroup, self.nIndex, x, y)
        else
            if TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetPlayerPop) then
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
            end
            local nWidth, _ = UIHelper.GetContentSize(self._rootNode)
            local dist = math.sqrt(math.abs(x-self.nStartX)^2 + math.abs(y-self.nStartY)^2)
            if dist > nWidth / 8 then
                self.bMoving = true
            end
        end
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnTouchEnded, function (btn, x, y)
        if self.bMoving then
            self.bMoving = false
            Event.Dispatch(EventType.OnRoomCellTouchEnded, self.tInfo)
        end
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnTouchCanceled, function (btn)
        if self.bMoving then
            self.bMoving = false
            Event.Dispatch(EventType.OnRoomCellTouchEnded, self.tInfo)
        end
    end)
end

function UIRoomCell:RegEvent()
    Event.Reg(self, EventType.OnRoomCellToggleSelectedByPos, function (nGroup, nIndex)
        if self.bPuppet then
            return
        end
        UIHelper.SetSelected(self.TogSelect, self.nGroup == nGroup and self.nIndex == nIndex, false)
    end)
end

function UIRoomCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoomCell:UpdateInfo()
    if not self.tInfo then
        UIHelper.SetVisible(self.WidgetMemberIn, false)
        UIHelper.SetVisible(self.WidgetAddMember, false)
        return
    end

    UIHelper.SetVisible(self.WidgetMemberIn, true)
    UIHelper.SetVisible(self.WidgetAddMember, false)

    local tInfo = self.tInfo
    -- UIHelper.SetSpriteFrame(self.ImgIcon, PlayerKungfuImg[tInfo.dwKungfuID])
    if tInfo.dwForceID == 0 then
        UIHelper.SetSpriteFrame(self.ImgIcon, PlayerForceID2SchoolImg2[tInfo.dwForceID])
    else
        PlayerData.SetMountKungfuIcon(self.ImgIcon, tInfo.dwKungfuID, tInfo.nClientVersionType)
    end
    UIHelper.SetString(self.LabelName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tInfo.szName), 7))
    local szCenterName = GetCenterNameByCenterID(tInfo.dwCenterID)
    UIHelper.SetString(self.LabelServerName, "@" .. UIHelper.GBKToUTF8(szCenterName))
    UIHelper.SetVisible(self.WidgetRoomHost, tInfo.szGlobalID == RoomData.GetRoomOwner())
    PlayerData.SetPlayerLogionSite(self.ImgLoginSite, tInfo.nClientVersionType)
    UIHelper.LayoutDoLayout(self.LayoutInfo)

    UIHelper.SetVisible(self.LabelNotEntered, self.bNotInRaid)
    UIHelper.SetVisible(self.LabelDisconnected, self.bOffline)
end

function UIRoomCell:SetInfo(tInfo, bOffline, bNotInRaid)
    self.tInfo = tInfo
    self.bOffline = bOffline or false
    self.bNotInRaid = bNotInRaid or false
    self:UpdateInfo()
end

function UIRoomCell:Clear()
    self.tInfo = nil
    self:UpdateInfo()
end

function UIRoomCell:MemberIndex()
    return self.nGroup * 5 + self.nIndex + 1
end

function UIRoomCell:GenerateMenuConfig()
    return RoomData.InsertRoommateMenu(self.tInfo.szGlobalID)
end

return UIRoomCell