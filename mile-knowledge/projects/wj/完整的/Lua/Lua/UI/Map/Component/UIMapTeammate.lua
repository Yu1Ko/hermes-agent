local UIMapTeammate = class("UIMapTeammate")

local MAX_SIZE = 32

function UIMapTeammate:OnEnter()
    UIHelper.SetVisible(self.ImgNameBg, false)

    if not self.nOriginW or not self.nOriginH then
        self.nOriginW, self.nOriginH = UIHelper.GetContentSize(self.ImgTeammate)
    end
end

function UIMapTeammate:OnShow()
    UIHelper.SetVisible(self.LabelTime, false)
    UIHelper.SetVisible(self.WidgetSchedule, false)
    UIHelper.SetVisible(self.ImgBg, false)

    UIHelper.SetContentSize(self.ImgTeammate, self.nOriginW, self.nOriginH)
    UIHelper.SetRotation(self.ImgTeammate, 0)
    UIHelper.SetPosition(self.ImgTeammate, 0, 0)
end

function UIMapTeammate:OnHide()
    UIHelper.SetVisible(self.LabelTime, false)
    UIHelper.SetVisible(self.WidgetSchedule, false)
    UIHelper.SetVisible(self.ImgBg, false)

    UIHelper.SetContentSize(self.ImgTeammate, self.nOriginW, self.nOriginH)
    UIHelper.SetRotation(self.ImgTeammate, 0)
    UIHelper.SetPosition(self.ImgTeammate, 0, 0)
end

function UIMapTeammate:UpdateFrame(szFrame, nScale, bKeepSize)
    nScale = nScale or 1

    UIHelper.SetVisible(self.ImgTeammate, true)
    UIHelper.SetVisible(self.Eff_YaoLing, false)
    UIHelper.SetVisible(self.WidgteFighting, false)

    if not UISpriteNameToFileTab.tbSpriteNameToFileMap[szFrame] and not UISpriteNameToFileTab.tbSpriteNameToFileMap[szFrame .. ".png"] then
        LOG.ERROR("UIMapTeammate:UpdateFrame Error, %s", tostring(szFrame))
    end

    UIHelper.SetSpriteFrame(self.ImgTeammate, szFrame, bKeepSize)
    UIHelper.SetScale(self.ImgTeammate, nScale, nScale)

    --限制图标最大大小
    local nW, nH = UIHelper.GetContentSize(self.ImgTeammate)
    if nW > MAX_SIZE or nH > MAX_SIZE then
        UIHelper.SetContentSize(self.ImgTeammate, MAX_SIZE, MAX_SIZE)
    end
end

function UIMapTeammate:UpdateBg(szFrame, nScale)
    nScale = nScale or 1

    UIHelper.SetVisible(self.ImgBg, true)

    UIHelper.SetSpriteFrame(self.ImgBg, szFrame)
    UIHelper.SetScale(self.ImgBg, nScale, nScale)
end

function UIMapTeammate:SetTeamSignPost()
    UIHelper.SetVisible(self.ImgTeammate, false)
    UIHelper.SetVisible(self.Eff_YaoLing, true)
    UIHelper.SetVisible(self.WidgteFighting, false)
end

function UIMapTeammate:SetArrow(PosComponent, tbArrowInfo)
    UIHelper.SetVisible(self.ImgTeammate, true)
    UIHelper.SetVisible(self.Eff_YaoLing, false)
    UIHelper.SetVisible(self.WidgteFighting, false)

    local tInfo = MapMgr.GetMarkInfoByTypeID(tbArrowInfo.nType)
    local szFrame = UIHelper.GBKToUTF8(tInfo.szMobileImage)
    UIHelper.SetSpriteFrame(self.ImgTeammate, szFrame)

    local nStartX, nStartY = PosComponent:LogicPosToMapPos(tbArrowInfo.nX, tbArrowInfo.nY)
    local nEndX, nEndY = PosComponent:LogicPosToMapPos(tbArrowInfo.nEndX, tbArrowInfo.nEndY)

    local nOriginLen = UIHelper.GetWidth(self.ImgTeammate)
    local nLogicLenth = math.sqrt((nEndX - nStartX) * (nEndX - nStartX) + (nEndY - nStartY) * (nEndY - nStartY))
    local nScale = nLogicLenth / nOriginLen

    local nCos = (nEndX - nStartX) / nLogicLenth
    local nRotation = math.acos(nCos) * 180 / math.pi

    if nEndY > nStartY then
        nRotation = 360 - nRotation
    end

    UIHelper.SetWorldPosition(self.ImgTeammate, (nEndX + nStartX) / 2, (nEndY + nStartY) / 2)
    UIHelper.SetScale(self.ImgTeammate, nScale, 1)
    UIHelper.SetRotation(self.ImgTeammate, nRotation)
end

function UIMapTeammate:SetFighting()
    UIHelper.SetVisible(self.ImgTeammate, false)
    UIHelper.SetVisible(self.Eff_YaoLing, false)
    UIHelper.SetVisible(self.WidgteFighting, true)
end

function UIMapTeammate:UpdatePosition(PosComponent, nX, nY)
    local x, y = PosComponent:LogicPosToMapPos(nX, nY)
    UIHelper.SetWorldPosition(self._rootNode, x, y)
end

function UIMapTeammate:UpdateEndTime(szTime)
    if szTime ~= -1 then
        UIHelper.SetVisible(self.LabelTime, true)
        UIHelper.SetString(self.LabelTime, szTime)
    else
        UIHelper.SetVisible(self.LabelTime, false)
    end
end

function UIMapTeammate:UpdateProgress(nProgress)
    if nProgress and nProgress ~= 0 then
        UIHelper.SetVisible(self.WidgetSchedule, true)
        UIHelper.SetProgressBarPercent(self.SliderSchedule, nProgress)
        UIHelper.SetString(self.LabelScheduleNum, tostring(nProgress) .. "%")
    else
        UIHelper.SetVisible(self.WidgetSchedule, false)
    end
end

function UIMapTeammate:UpdateNodeName(szName)
    UIHelper.SetName(self._rootNode, szName)
end

return UIMapTeammate