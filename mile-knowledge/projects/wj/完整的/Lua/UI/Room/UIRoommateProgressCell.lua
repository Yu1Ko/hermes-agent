-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRoommateProgressCell
-- Date: 2024-02-18 15:07:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRoommateProgressCell = class("UIRoommateProgressCell")

function UIRoommateProgressCell:OnEnter(tPlayerInfo, tProgress)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tPlayerInfo = tPlayerInfo
    self.tProgress = tProgress
    self:UpdateInfo()
end

function UIRoommateProgressCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoommateProgressCell:BindUIEvent()

end

function UIRoommateProgressCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRoommateProgressCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoommateProgressCell:UpdateInfo()
    local tPlayer = self.tPlayerInfo

    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerKungfuImg[tPlayer.dwKungfuID])
    UIHelper.SetString(self.LabelName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tPlayer.szName), 7))
    CampData.SetUICampImg(self.ImgCamp, tPlayer["nCamp"])
    UIHelper.LayoutDoLayout(self.LayoutName)

    UIHelper.SetVisible(self.WidgetRoomHost, RoomData.GetRoomOwner() == tPlayer.szGlobalID)

    local szCenterName = GetCenterNameByCenterID(tPlayer.dwCenterID)
    UIHelper.SetString(self.LabelServer, "@" .. UIHelper.GBKToUTF8(szCenterName))
    UIHelper.SetString(self.LabelLevel, tPlayer.nLevel .. "级")
    UIHelper.SetString(self.LabelEquipScore, "装分" .. tPlayer.nEquipScore)

    for i = 1, #self.tImgPointsBg do
        if i <= #self.tProgress then
            local bFlag = self.tProgress[i]
            local imgKill = UIHelper.GetChildByName(self.tImgPointsBg[i], "ImgPoint")
            local imgNotKill = UIHelper.GetChildByName(self.tImgPointsBg[i], "ImgPointBg")
            UIHelper.SetVisible(imgKill, bFlag)
            UIHelper.SetVisible(imgNotKill, not bFlag)
            UIHelper.SetVisible(self.tImgPointsBg[i], true)
        else
            UIHelper.SetVisible(self.tImgPointsBg[i], false)
        end
    end
    UIHelper.LayoutDoLayout(self.WidgetPoints)
end

return UIRoommateProgressCell