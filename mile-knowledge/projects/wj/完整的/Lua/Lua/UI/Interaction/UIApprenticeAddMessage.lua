-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIApprenticeAddMessage
-- Date: 2024-03-20 14:40:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIApprenticeAddMessage = class("UIApprenticeAddMessage")

local ERROR_CODE = { --这个序号对应string.lua里tFindAppErrorCode等表格，来提示玩家为什么不能拜师或者收徒
	NORMAL = 0,
	ONE = 1,
	TWO = 2,
	THREE = 3,
}

function UIApprenticeAddMessage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIApprenticeAddMessage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIApprenticeAddMessage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function ()
        self:OnClickChat()
    end)

    UIHelper.BindUIEvent(self.BtnEquipment, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelOtherPlayer, self.tInfo.dwRoleID)
    end)

    UIHelper.BindUIEvent(self.BtnStudent, EventType.OnClick, function ()
        local szName = self.tInfo.szName
        RemoteCallToServer("OnApplyApprentice", szName) -- 申请收徒，后面是名字
    end)

    UIHelper.BindUIEvent(self.BtnTeacher, EventType.OnClick, function ()
        if FellowshipData.m_FindMasterErrorCode ~= ERROR_CODE.NORMAL then
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.tFindMasterErrorCode[FellowshipData.m_FindMasterErrorCode])
            return
        end
        local szName = self.tInfo.szName
        RemoteCallToServer("OnApplyMentor", szName)
    end)

    UIHelper.BindUIEvent(self.BtnTeacher1, EventType.OnClick, function ()
        if FellowshipData.m_FindDirectMasterErrorCode ~= ERROR_CODE.NORMAL then
            TipsHelper.ShowNormalTip(g_tStrings.tFindDirectMasterErrorCode[FellowshipData.m_FindDirectMasterErrorCode])
            return
        end
        local szName = self.tInfo.szName
        RemoteCallToServer("OnApplyDirectMentor", szName)
    end)

    UIHelper.BindUIEvent(self.BtnPlayerIcon, EventType.OnClick, function ()
        if self.tSocialInfo then
            self.tSortPraiseinfo = self:SortPraiseInfo()
            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPraiseStatus, self.BtnPlayerIcon, self.tSortPraiseinfo)
        end
    end)

    UIHelper.BindUIEvent(self.BtnWarning, EventType.OnClick, function ()
        self:GoToReport()
    end)
end

function UIApprenticeAddMessage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "APPLY_SOCIAL_INFO_RESPOND", function(tPlayerID)
        for _, dwPlayerID in ipairs(tPlayerID) do
            if self.tInfo and self.tInfo.dwRoleID == dwPlayerID then
                self.tSocialInfo = FellowshipData.GetSocialInfo(dwPlayerID)
                if self.tSocialInfo then
                    local  labels = self.tSocialInfo.Praiseinfo or {}
                    local tRes = Table_GetAllPersonLabel()
                    for i, info in ipairs(tRes) do
                        local nCount = labels[info.id] or 0
                        UIHelper.SetString(self.tbPersonLabelNum[i], PersonLabel_GetLevel(nCount, info.id))
                    end
                end
            end
        end
	end)
end

function UIApprenticeAddMessage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIApprenticeAddMessage:SetMessageInfo(table, bFindMas)
    self.tInfo = table
    self:UpdateInfo()
    UIHelper.SetVisible(self.BtnTeacher, bFindMas)
    UIHelper.SetVisible(self.BtnTeacher1, bFindMas)
    UIHelper.SetVisible(self.BtnStudent, not bFindMas)
    UIHelper.SetVisible(self.ImgLeftLine, true)
    UIHelper.SetVisible(self.ImgRightBg, true)
end

function UIApprenticeAddMessage:OnClickChat()
    local table = self.tInfo
    local szName = UIHelper.GBKToUTF8(table.szName)
    local dwTalkerID = table.dwID
    local dwForceID = table.dwForceID
    local dwMiniAvatarID = table.dwMiniAvatorID
    local nRoleType = table.dwRoleType
    local nLevel = table.nLevel
    local szGlobalID = table.szGlobalID
    local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID}

    ChatHelper.WhisperTo(szName, tbData)
end

function UIApprenticeAddMessage:UpdateInfo()
    local table = self.tInfo
    if table then
        UIHelper.RemoveAllChildren(self.WidgetPlayerHead)

        local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetPlayerHead)
        if headScript then
            headScript:SetHeadInfo(nil,table.dwMiniAvatorID or 0, table.dwRoleType, table.dwForceID)
            headScript:SetTouchEnabled(false)
        end

        UIHelper.SetString(self.LableName,UIHelper.GBKToUTF8(table.szName))
        UIHelper.SetSpriteFrame(self.Imglevel, PlayerForceID2SchoolImg2[table.dwForceID])
        UIHelper.SetString(self.LableLevel1,table.nLevel)
        local szCampIcon = CampData.GetCampImgPath(table.nCamp, nil, true)
        UIHelper.SetSpriteFrame(self.ImgCamp, szCampIcon)
        local szTongName = table.szTongName ~= "" and UIHelper.GBKToUTF8(table.szTongName) or "无"
        UIHelper.SetRichText(self.RichTextMessage01, "<c/><color=#AED9E0>所属帮会：</color><color=#ffffff>".. szTongName .."<c/>")
        UIHelper.SetString(self.LabelIntroduce,UIHelper.GBKToUTF8(table.szComment))
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewIntroduce)

        self.tSocialInfo = FellowshipData.GetSocialInfo(table.dwRoleID)
        if not self.tSocialInfo then
            GetSocialManagerClient().ApplySocialInfo({table.dwRoleID})
        else
            local  labels = self.tSocialInfo.Praiseinfo or {}
            local tRes = Table_GetAllPersonLabel()
            for i, info in ipairs(tRes) do
                local nCount = labels[info.id] or 0
                UIHelper.SetString(self.tbPersonLabelNum[i], PersonLabel_GetLevel(nCount, info.id))
            end
        end

        if table.dwRoleID == g_pClientPlayer.dwID then
            UIHelper.SetButtonState(self.BtnChat, BTN_STATE.Disable)
            UIHelper.SetButtonState(self.BtnEquipment, BTN_STATE.Disable)
        else
            UIHelper.SetButtonState(self.BtnChat, BTN_STATE.Normal)
            UIHelper.SetButtonState(self.BtnEquipment, BTN_STATE.Normal)
        end
        UIHelper.SetVisible(self.BtnWarning, true)
    else
        UIHelper.SetVisible(self.BtnWarning, false)
    end
end

--- 动态加载点赞
function UIApprenticeAddMessage:SortPraiseInfo()
    local labels = self.tSocialInfo.Praiseinfo or {}
    local tbInfo = {}
    local tRes = Table_GetAllPersonLabel()
    for _, info in ipairs(tRes) do
        local id = info.id + 1
        tbInfo[id] = {}
        tbInfo[id].id = info.id
        tbInfo[id].info = info
        local nCount = labels[info.id] or 0
        tbInfo[id].nCount = nCount
        tbInfo[id].nLevel = PersonLabel_GetLevel(nCount, info.id)
    end

    local function fnSort(tA, tB)
        if tA.nLevel == tB.nLevel then
            return tA.info.queue < tB.info.queue
        else
            return tA.nLevel > tB.nLevel
        end
	end
    table.sort(tbInfo, fnSort)
    return tbInfo
end

function UIApprenticeAddMessage:GoToReport()
    local reportView = UIMgr.Open(VIEW_ID.PanelReportPop)
    reportView:UpdateReportInfo(UIHelper.GBKToUTF8(self.tInfo.szName), UIHelper.GBKToUTF8(self.tInfo.szComment) )
end


return UIApprenticeAddMessage