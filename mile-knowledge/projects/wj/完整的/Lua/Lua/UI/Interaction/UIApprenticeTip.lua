-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIApprenticeTip
-- Date: 2024-03-20 17:20:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIApprenticeTip = class("UIApprenticeTip")

function UIApprenticeTip:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIApprenticeTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIApprenticeTip:BindUIEvent()
    UIHelper.BindUIEvent(self.TogApprenticeTip, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnSelectedAppprenticeMessage, self.tIndex)
    end)
end

function UIApprenticeTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIApprenticeTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIApprenticeTip:SetAppInfo(tInfo, tIndex)
    self.tIndex = tIndex
    UIHelper.SetVisible(self.ImgStudentTip1, tIndex[1])

    if tInfo then
        local tSocialInfo = FellowshipData.tApplySocialList[tInfo.dwID] or FellowshipData.GetSocialInfo(tInfo.dwID) or {}

        if not tInfo.bDelete then
            UIHelper.SetStringEllipsis(self.LabelChildNavigationNormal, UIHelper.GBKToUTF8(tInfo.szName), 7)
        else
            UIHelper.SetStringEllipsis(self.LabelChildNavigationNormal, tInfo.szName, 7)
        end

        UIHelper.SetVisible(self.ImgStudentTip1, tInfo.bDirect or tIndex[1])
        UIHelper.SetVisible(self.ImgStudentTip2, not tInfo.bDirect and (not tIndex[1]) and tInfo.szRelation ~= "")
        UIHelper.SetString(self.LabelStudentTip, tInfo.szRelation ~= "" and tInfo.szRelation or "亲传")
        UIHelper.SetString(self.LabelStudentTip2, tInfo.szRelation)

        if self.ImgSchoolIcon then
            local szImgName = PlayerForceID2SchoolImg2[tInfo.dwForceID] or ""
            UIHelper.SetSpriteFrame(self.ImgSchoolIcon, szImgName)
            UIHelper.SetVisible(self.ImgSchoolIcon, szImgName ~= "" )
        end

        UIHelper.RemoveAllChildren(self.WidgetHead)
        local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
        if headScript then
            headScript:SetHeadInfo(tInfo.dwID, tSocialInfo.MiniAvatarID or 0, tInfo.nRoleType, tInfo.dwForceID)
            headScript:SetOfflineState(tInfo.bOnLine == false)
        end
    end
end


return UIApprenticeTip