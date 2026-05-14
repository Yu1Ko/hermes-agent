-- ---------------------------------------------------------------------------------
-- Name: UIWidgetPersonalCard
-- Desc: 名片形象
-- ---------------------------------------------------------------------------------

local UIWidgetPersonalCard = class("UIWidgetPersonalCard")
-- local FixShowDataNum = 6
local PERSONAL_CARD_REPORT_CD = 60

function UIWidgetPersonalCard:OnEnter(szGlobalID, tInfo, tbRoleEntryInfo)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end

    if self.bSetPersonalInfo then
        return
    end
    self.szGlobalID = szGlobalID
    if tInfo then
        self.bEdit = tInfo.bEdit
        self.bSetBirth = tInfo.bSetBirth
        self.fnCallBackCloseView = tInfo.fnCallBackClose
        self.fnCallBackOpenLeft = tInfo.fnCallBackOpenLeft
        self.bDecoration = tInfo.bDecoration
    end

    self.tbRoleEntryInfo = tbRoleEntryInfo

    if not g_pClientPlayer then
        return
    end
    UIHelper.SetVisible(self.WidgetBtn, false)
    UIHelper.SetVisible(self.WidgetOwnBtn, false)
    local uSelfGlobalID = g_pClientPlayer.GetGlobalID()
    self.bSelf = uSelfGlobalID == szGlobalID
    if szGlobalID and not self.bSelf then
        UIHelper.SetVisible(self.WidgetBtn, true)
        self:ApplyPersonalData()
        self:UpdateOtherPlayer()
    elseif self.bSelf then
        UIHelper.SetVisible(self.WidgetOwnBtn, true)
        self:DownloadImageDataAndCache()
        self:ApplyImageData()
        self:UpdateBasicData()
    else
        self.bSelf = true
        self:UpdateBasicData()
        if not self.bDecoration then
            UIHelper.SetVisible(self.WidgetOwnBtn, true)
        end
    end

    self.m_nLastFreshTime = 0
    self:UpdateCardPraiseNum()

    Event.Dispatch(EventType.OnLookUpPersonalCard, szGlobalID)
end

function UIWidgetPersonalCard:OnExit()
    self.bInit = false
    if self.picTexture then
        self.picTexture:release()
        self.picTexture = nil
    end
    self:UnRegEvent()
end

function UIWidgetPersonalCard:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCall, EventType.OnClick , function ()
        local szName = UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName)
        local dwTalkerID = self.tbRoleEntryInfo.dwPlayerID
        local dwForceID = self.bHasPlayer and self.tbRoleEntryInfo.dwForceID or self.tbRoleEntryInfo.nForceID
        local dwMiniAvatarID = self.tbRoleEntryInfo.dwMiniAvatarID
        local nRoleType = self.tbRoleEntryInfo.nRoleType
        local nLevel = self.tbRoleEntryInfo.nLevel
        local szGlobalID = self.szGlobalID--self.tbRoleEntryInfo.szGlobalID
        local dwCenterID = self.tbRoleEntryInfo.dwCenterID
        local nCamp = self.tbRoleEntryInfo.nCamp
        if self.dwPlayer then
            local targetPlayer = GetPlayer(self.dwPlayer)
            dwMiniAvatarID = targetPlayer.dwMiniAvatarID
        end
        local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID, dwCenterID = dwCenterID}
        --local tbData = {szGlobalID = szGlobalID, byCamp = nCamp, byForceID = dwForceID, id = szGlobalID, byRoleType = nRoleType, szName = szName, byLevel = nLevel, dwMiniAvatarID = dwMiniAvatarID, dwCenterID = dwCenterID}
        ChatHelper.WhisperTo(szName, tbData)

        TipsHelper.DeleteAllHoverTips()
    end)

    UIHelper.BindUIEvent(self.BtnTeam, EventType.OnClick , function ()
        if self.targetPlayer then
            TeamData.InviteJoinTeam(self.targetPlayer.szName)
        else
            TeamData.InviteJoinTeam(self.tbRoleEntryInfo.szName)
        end

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
    end)

    UIHelper.BindUIEvent(self.BtnPermissions, EventType.OnSelectChanged , function (_, bSelected)
        if bSelected then
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetInteractionMorePop, self.BtnPermissions, TipsLayoutDir.BOTTOM_RIGHT)

            local nRootHeight = UIHelper.GetHeight(self.BtnPermissions)
            tips:SetOffset(0, -nRootHeight)
            tips:ShowNodeTips(self.BtnPermissions)

            if #self.tbTeamMenus >= 5 then
                self:CreateMenus(self.tbTeamMenus, tipsScriptView.ScrollviewMore)
                UIHelper.SetVisible(tipsScriptView.ScrollviewMore, true)
                UIHelper.ScrollViewDoLayoutAndToTop(tipsScriptView.ScrollviewMore)
            else
                self:CreateMenus(self.tbTeamMenus, tipsScriptView.LayoutMore)
                UIHelper.SetVisible(tipsScriptView.ScrollviewMore, false)
                UIHelper.LayoutDoLayout(tipsScriptView.LayoutMore)
            end

            UIHelper.SetTouchDownHideTips(tipsScriptView.ScrollviewMore, false)

            if UIHelper.GetSelected(self.Btnmark) then
                UIHelper.SetSelected(self.Btnmark, false)
            end
        else
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
        end

    end)

    UIHelper.BindUIEvent(self.Btnmark, EventType.OnSelectChanged , function (_, bSelected)
        if bSelected then
            local tips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetTipTargetgetMark, self.BtnExpand, self.dwPlayer)

            local nRootHeight = UIHelper.GetHeight(self.BtnExpand)
            tips:SetOffset(0, -nRootHeight)
            tips:ShowNodeTips(self.BtnExpand)

            if UIHelper.GetSelected(self.BtnPermissions) then
                UIHelper.SetSelected(self.BtnPermissions, false)
            end
        else
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipTargetgetMark)
        end
    end)

    UIHelper.BindUIEvent(self.BtnPersonalCard, EventType.OnClick , function ()
        UIMgr.Open(VIEW_ID.PanelPersonalCard, function ()
            UIMgr.Close(VIEW_ID.PanelCharacter)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnChangeHead, EventType.OnClick , function ()
        -- UIMgr.Open(VIEW_ID.PanelCustomAvatar)
        if UIMgr.IsViewOpened(VIEW_ID.PanelCharacter) then
            UIMgr.Open(VIEW_ID.PanelAccessory, nil,  4)
        else
            UIMgr.Open(VIEW_ID.PanelCharacter)
            UIMgr.Open(VIEW_ID.PanelAccessory, true,  4)
        end
    end)

    UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick , function ()
        UIHelper.ShowConfirm(g_tStrings.STR_SHOW_CARD_REPORT_CONFIRM, function ()
            local nTime = GetGSCurrentTime()
            if PersonalCardData.nReportTime and nTime - PersonalCardData.nReportTime < PERSONAL_CARD_REPORT_CD then
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_PERSONALCARD_REPORT_ERROR)
                OutputMessage("MSG_SYS", g_tStrings.STR_PERSONALCARD_REPORT_ERROR)
            else
                PersonalCardData.nReportTime = nTime
                local tNowTime = TimeToDate(nTime)
                local szTime = FormatString(g_tStrings.STR_TIME_2, tNowTime.year, tNowTime.month, tNowTime.day, tNowTime.hour, tNowTime.minute, tNowTime.second)
                local szContent = "(" .. g_tStrings.tReportType[9] .. ")" .. szTime
                local szPlatform = "vkWin"
                if Platform.IsAndroid() then
                    szPlatform = "Android"
                elseif Platform.IsIos() then
                    szPlatform = "Ios"
                end
                RemoteCallToServer("OnReportTrick", self.szGBKName, UIHelper.UTF8ToGBK(szContent), "", self.szGlobalID, szPlatform)
                OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_PERSONALCARD_REPORT_SUCCESS)
                OutputMessage("MSG_SYS", g_tStrings.STR_PERSONALCARD_REPORT_SUCCESS)
            end
        end)
    end)

    local REClick_CD = 500
    UIHelper.BindUIEvent(self.BtnPraiseOther, EventType.OnClick , function ()
        if not self.bSelf then
            local nThisTime = GetTickCount()
            if nThisTime < self.m_nLastFreshTime + REClick_CD then
                OutputMessage("MSG_ANNOUNCE_RED", "你的操作过于频繁，请稍后再试\n")
            else
                self.m_nLastFreshTime = nThisTime
                RemoteCallToServer("On_ShowCard_AddPraiseRequest", PRAISE_TYPE.PERSONAL_CARD, self.dwPlayerID, self.szGlobalID)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnPraise, EventType.OnClick , function ()
        TipsHelper.ShowImportantRedTip("不能给自己点赞喔~")
    end)

    UIHelper.BindUIEvent(self.BtnBirthday, EventType.OnClick , function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
            return
        end
        UIMgr.Open(VIEW_ID.PanelPop_BirthdaySetting)
    end)

    UIHelper.BindUIEvent(self.BtnBirthdaySetted, EventType.OnClick , function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
            return
        end
        UIMgr.Open(VIEW_ID.PanelPop_BirthdaySetting)
    end)
end

function UIWidgetPersonalCard:RegEvent()
    Event.Reg(self, "ON_UPDATE_SHOW_CARD_DATA_NOTIFY", function (szGlobalID)
        if szGlobalID == self.szGlobalID then
            -- if not self.bDownload then
            --     self:ApplyDownloadShowCardImage()
            -- end

            self.tShowData = PersonalCardData.GetShowData(self.szGlobalID)
            if GDAPI_InitShowCardData and self.tShowData then
                self.tConstData = GDAPI_InitShowCardData(self.tShowData)
            end
            self:UpdateShowData()
            self:UpdateOtherTitle()
        end
    end)

    Event.Reg(self, "ON_UPDATE_SHOW_CARD_DECORATION_PRESET_NOTIFY", function (szGlobalID)
        if szGlobalID == self.szGlobalID then
            if self.bSelf and not self.picTexture then
                return
            end
            self.tDecorationPresetLogic = PersonalCardData.GetDecorationPreset(self.szGlobalID)
            self:UpdateDecorationPreset()

            if not self.bDownload then
                self:ApplyDownloadShowCardImage()
            end
        end
    end)

    Event.Reg(self, "DOWNLOAD_SHOW_IMAGE_RESPOND", function (uGlobalID, bSuccess, dwImageIndex)
        if self.szGlobalID == uGlobalID then
            if bSuccess == 1 then
                self:DownloadImageDataAndCache(dwImageIndex)
                UIHelper.SetVisible(self.WidgetBtnReport, not self.bSelf)
                if self.bSelf then
                    local nIndex = g_pClientPlayer.GetSelectedShowCardDecorationPresetIndex()
                    self:InitDecorationPreset(nIndex)
                end
            end
        end
    end)

    Event.Reg(self,"FELLOWSHIP_ROLE_ENTRY_UPDATE",function (szGlobalID)
        if szGlobalID == self.szGlobalID then
            self.tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(self.szGlobalID)
            self:UpdateOtherPlayerBaseInfo()
        end
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function ()
        if self.bShowOtherPlayerBtn then
            self:UpdatTeamMenusBtn(self.dwPlayer)
            self:UpdateMarkBtn(self.dwPlayer)
            UIHelper.LayoutDoLayout(self.WidgetBtn)
        end
    end)

    Event.Reg(self, "SET_MINI_AVATAR", function (dwID)
		if dwID == g_pClientPlayer.dwMiniAvatarID and self.headScript then
            self.headScript:UpdateInfo()
		end
    end)

    Event.Reg(self, "ON_SET_SHOW_CARD_DECORATION_PRESET_NOTIFY", function (nIndex)
        if self.nIndex and self.nIndex == nIndex then
            self:InitDecorationPreset(nIndex)
        end
    end)

    Event.Reg(self, "ON_UPDATE_SHOW_CARD_PRAISE_DATA", function (bAddSuccess, szMsg, szGlobalID)
        if not bAddSuccess then
            OutputMessage("MSG_ANNOUNCE_RED", UIHelper.GBKToUTF8(szMsg))
        else
            if szMsg then
                OutputMessage("MSG_ANNOUNCE_YELLOW", UIHelper.GBKToUTF8(szMsg))
            end
            if szGlobalID and self.szGlobalID and szGlobalID == self.szGlobalID then
                self:UpdateCardPraiseNum(true)
            end
        end
    end)

    Event.Reg(self, "UPDATE_FELLOWSHIP_CARD", function (tbGlobalID)
        for _, gid in ipairs(tbGlobalID) do
            if (not self.bSelf and gid == self.szGlobalID) or
                (self.bSelf and gid == g_pClientPlayer.GetGlobalID()) then
                local tbPlayerCard = FellowshipData.GetFellowshipCardInfo(gid)
                self.Praiseinfo = tbPlayerCard and tbPlayerCard.Praiseinfo or {}
                self:UpdateCardPraiseNum()
                break
            end
        end
    end)

    Event.Reg(self , "ON_BIRTHDAY_SET_SUCCESS" , function()
        self:OnBirthdaySetSuccess()
    end)
end

function UIWidgetPersonalCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- --------------------------------------------------------------------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- --------------------------------------------------------------------------------------------------------------------
-- self player
function UIWidgetPersonalCard:UpdateBasicData()
    if g_pClientPlayer then
        self.headScript = self.headScript or UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetHead, g_pClientPlayer.dwID)
        -- if self.HeadTouchEnable ~= nil then
        --     self.headScript:SetTouchEnabled(self.HeadTouchEnable)
        -- end
        -- self.headScript:SetClickCallback(function()
        --     if not UIMgr.GetView(VIEW_ID.PanelCustomAvatar) then
        --         UIMgr.Open(VIEW_ID.PanelCustomAvatar)
        --     end
        -- end)
        self.headScript:SetTouchEnabled(false)
        self.headScript:SetPersonalFrame(self.szPersonalFrame)
        UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(g_pClientPlayer.szName), 6)
        CampData.SetUICampImgByPlayer(self.ImgCamp, g_pClientPlayer, true)
        UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[g_pClientPlayer.dwForceID])
        UIHelper.SetString(self.LabelLevel, g_pClientPlayer.nLevel)
        UIHelper.SetString(self.LabelEquipNum, PlayerData.GetPlayerTotalEquipScore(g_pClientPlayer))

        -- 称号
        local szName = self:GetPlayerCurrentDesignation()
        self:UpdateBasicDataOfTitle(szName)

        -- 数据
        -- self:InitShowDataTogggle()
        self:UpdateShowData()

        -- 贴花特效
        if not self.bDecoration then
            self:InitDecorationPreset()
        end

        -- 生日设置按钮
        if self.bSetBirth then
            self:UpdateBirthdayBtn(self.bSelf)
        end
    end
end

function UIWidgetPersonalCard:SetHeadBtnUnEnabled()
    if self.headScript then
        self.headScript:SetTouchEnabled(false)
    end
end

function UIWidgetPersonalCard:ApplyImageData()
    if g_pClientPlayer then
        local hManager = GetShowCardCacheManager()
        local uGlobalID = g_pClientPlayer.GetGlobalID()
        if hManager then
            local nIndex = g_pClientPlayer.GetSelectedShowCardDecorationPresetIndex()
            if PersonalCardData.tSelfImageData[nIndex] then
                self:UpdateImageByPlayerData(nIndex)
            else
                if PersonalCardData.GetShowCardPresetState(nIndex, SHOW_CARD_PRESET_STATE_TYPE.UPLOAD_IMAGE) == true then
                    hManager.DownloadShowCardImage(uGlobalID, nIndex)
                    UIHelper.SetVisible(self.ImgPersonalCardNewBg, true)
                    if self.picTexture then
                        self:InitDecorationPreset(nIndex)
                    end
                else
                    PersonalCardData.tSelfImageData[nIndex] = {}
                    PersonalCardData.tSelfImageData[nIndex].bHave = false
                    self:UpdateImageByPlayerData(nIndex)
                end
            end
        end
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- 称号相关
-- --------------------------------------------------------------------------------------------------------------------
function UIWidgetPersonalCard:UpdateBasicDataOfTitle(szName)
    local fnCallBackSelectTitle = function()
        if self.fnCallBackOpenLeft then
            self.fnCallBackOpenLeft(PREFAB_ID.WidgetPersonalCardLeftPop, function(szName)
                self:UpdateBasicDataOfTitle(szName)
            end)
        end
    end

    if szName then
        UIHelper.SetVisible(self.BtnTitleAdd, false)
        UIHelper.RemoveAllChildren(self.WidgetTitleCell)
        local scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetTitleCell, self.WidgetTitleCell) assert(scriptTitle)
        scriptTitle:UpdateInfo(szName)
        if self.bEdit then
            scriptTitle:SetSelectedCallback(fnCallBackSelectTitle)
        else
            scriptTitle:SetTogUnable()
        end
    else
        UIHelper.RemoveAllChildren(self.WidgetTitleCell)
        if self.bEdit then
            UIHelper.SetVisible(self.BtnTitleAdd, true)
            UIHelper.BindUIEvent(self.BtnTitleAdd, EventType.OnClick, fnCallBackSelectTitle)
        else
            UIHelper.SetVisible(self.BtnTitleAdd, false)
        end
    end
end

function UIWidgetPersonalCard:GetGenerationDesignation()
    if not g_pClientPlayer then
        return
    end
    if not self.tCourtesyTitle then
        local tGen
        if self.tConstData and self.tbRoleEntryInfo then
            tGen = g_tTable.Designation_Generation:Search(self.bHasPlayer and self.tbRoleEntryInfo.dwForceID or self.tbRoleEntryInfo.nForceID, self.tConstData.nGeneration)
        elseif self.tConstData and self.dwForceID then
            tGen = g_tTable.Designation_Generation:Search(self.dwForceID, self.tConstData.nGeneration)
        else
            tGen = g_tTable.Designation_Generation:Search(g_pClientPlayer.dwForceID, g_pClientPlayer.GetDesignationGeneration())
        end

        if tGen then
            if tGen.szCharacter and tGen.szCharacter ~= "" and not tGen.bSetNewName then
                local tCharacter
                if self.tConstData and self.tConstData.nGeneration > 0 then
                    tCharacter = g_tTable[tGen.szCharacter]:Search(self.tConstData.nCharacter)
                else
                    tCharacter = g_tTable[tGen.szCharacter]:Search(g_pClientPlayer.GetDesignationByname())
                end
                if tCharacter then
                    tGen.szName = tGen.szName .. tCharacter.szName
                    tGen.bSetNewName = true
                end
            end
        end
        self.tCourtesyTitle = tGen
    end
    return self.tCourtesyTitle
end

function UIWidgetPersonalCard:GetPlayerCurrentDesignation(tData)
    if not g_pClientPlayer then
        return
    end

    local nPrefixID, nPostfixID, nCourtesyID, dwForceID = 0, 0, 0, 0
    if not tData then
        nPrefixID   = g_pClientPlayer.GetCurrentDesignationPrefix()
        nPostfixID  = g_pClientPlayer.GetCurrentDesignationPostfix()
        nCourtesyID = g_pClientPlayer.GetDesignationBynameDisplayFlag() and g_pClientPlayer.GetDesignationGeneration() or 0
        dwForceID   = g_pClientPlayer.dwForceID
    else
        nPrefixID = tData.nPrefix
        nPostfixID = tData.nPostfix
        nCourtesyID = tData.nGeneration
        if self.tbRoleEntryInfo then dwForceID = self.bHasPlayer and self.tbRoleEntryInfo.dwForceID or self.tbRoleEntryInfo.nForceID end
        if not dwForceID then dwForceID = self.dwForceID end
        dwForceID = dwForceID or 0
    end

    local szName

    if nPrefixID ~= 0 or nPostfixID ~= 0 or nCourtesyID ~= 0 then
        local tPrefixInfo = nPrefixID and nPrefixID ~= 0 and GetDesignationPrefixInfo(nPrefixID)
        if tPrefixInfo and tPrefixInfo.nType ~= DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
            local t = Table_GetDesignationPrefixByID(nPrefixID, dwForceID)
            szName = t and UIHelper.GBKToUTF8(t.szName) or ""
        else
            local szPrefixName    = ""
            local szPostfixName   = ""
            local szCourtesyName  = ""
            if nPrefixID and nPrefixID ~= 0 then
                if tPrefixInfo.nType == DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
                    local t = Table_GetDesignationPrefixByID(nPrefixID, dwForceID)
                    szPrefixName = t and t.szName or ""
                end
            end
            if nPostfixID and nPostfixID ~= 0 then
                szPostfixName = g_tTable.Designation_Postfix:Search(nPostfixID).szName
            end
            local tGen = self:GetGenerationDesignation()
            if tGen and nCourtesyID and nCourtesyID ~= 0 then
                szCourtesyName = tGen.szName
            end
            szName = UIHelper.GBKToUTF8(szPrefixName .. szPostfixName .. szCourtesyName)
        end
    end

    return szName
end

-- --------------------------------------------------------------------------------------------------------------------
-- 数据相关
-- --------------------------------------------------------------------------------------------------------------------
function UIWidgetPersonalCard:InitShowDataTogggle()
    for _, tog in pairs(self.tbBtnInformationAdd) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupInformation, tog)
    end
end

function UIWidgetPersonalCard:UpdateShowData()
    if not g_pClientPlayer then return end

    local tData
    local uSelfGlobalID = g_pClientPlayer.GetGlobalID()
    if self.szGlobalID and not self.bSelf then
        tData = self.tShowData or {}
    else
        tData = g_pClientPlayer.GetAllShowCardData()
    end

    local tShowData = {}
    local FixShowDataNum = 0
    for _, v in ipairs(tData) do
        if v.bConstKey == true then
            FixShowDataNum = FixShowDataNum + 1
        end
    end
    if #tData > FixShowDataNum then
        for nIndex = 1, #tData - FixShowDataNum do
            tShowData[nIndex] = {}
            local nKey = tData[nIndex + FixShowDataNum].dwKey
            tShowData[nIndex].dwKey = tData[nIndex + FixShowDataNum].dwKey
            tShowData[nIndex].nValue1 = tData[nIndex + FixShowDataNum].nValue1
            local tSettingLine = Table_GetPersonalCardData(nKey)
            tShowData[nIndex].szName = UIHelper.GBKToUTF8(tSettingLine.szName)
            local nValue = 1
            if tSettingLine.nLevelValue1 > tShowData[nIndex].nValue1 then
                nValue = 0
            elseif tSettingLine.nLevelValue2 > tShowData[nIndex].nValue1 then
                nValue = 1
            elseif tSettingLine.nLevelValue3 > tShowData[nIndex].nValue1 then
                nValue = 2
            elseif tSettingLine.nLevelValue4 > tShowData[nIndex].nValue1 then
                nValue = 3
            elseif tSettingLine.nLevelValue5 > tShowData[nIndex].nValue1 then
                nValue = 4
            else
                nValue = 5
            end
            tShowData[nIndex].nGrade = nValue
            tShowData[nIndex].Img = PersonalCardData.GetImageOfShowCardData(nKey, nValue)
        end
    end
    self:UpdateShowDataOfAllReverse(tShowData)
end

function UIWidgetPersonalCard:UpdateShowDataOfAllReverse(tShowData)
    local function fnADegree(a, b)
        if a.nGrade == b.nGrade then
            return a.dwKey < b.dwKey
        else
            return a.nGrade > b.nGrade
        end
    end

    local nLen = tShowData and #tShowData or 0
    table.sort(tShowData, fnADegree)
    nLen = math.min(nLen, 3)
    for nIndex = 1, nLen do
        self:UpdateShowDataOfIndex(nIndex + 3 - nLen, tShowData[nIndex])
    end
    for nIndex = 1, 3 - nLen do
        self:UpdateShowDataOfIndex(nIndex, nil)
    end
end

function UIWidgetPersonalCard:UpdateShowDataOfAll(tShowData)
    for nIndex = 1, 3 do
        self:UpdateShowDataOfIndex(4 - nIndex, tShowData[nIndex])
    end
end

function UIWidgetPersonalCard:UpdateShowDataOfIndex(nIndex, tData)
    local fnCallBackSelectData = function(nIndex, dwKey)
        if self.fnCallBackOpenLeft then
            self.fnCallBackOpenLeft(PREFAB_ID.WidgetPersonalCardSelectLeftPop, function(ttData)
                -- if ttData.bClose == true then
                --     self:SetShowDataSelected(nIndex)
                -- else
                    self:UpdateShowDataOfAll(ttData)
                -- end
            end, dwKey)
        end
    end

    local dwKey = tData and tData.dwKey
    if tData then
        UIHelper.SetVisible(self.tbBtnInformationAdd[nIndex], true)
        UIHelper.HideAllChildren(self.tbBtnInformationAdd[nIndex])
        UIHelper.SetVisible(self.tbWidgetInformation[nIndex], true)
        local script = UIHelper.GetBindScript(self.tbWidgetInformation[nIndex])
        script:UpdateInfo(tData)
        UIHelper.SetVisible(self.tbInformationNoneImg[nIndex], false)
    else
        UIHelper.SetVisible(self.tbWidgetInformation[nIndex], false)
        if self.bEdit then
            UIHelper.SetVisible(self.tbBtnInformationAdd[nIndex], true)
            UIHelper.ShowAllChildren(self.tbBtnInformationAdd[nIndex])
        elseif self.szGlobalID then
            UIHelper.SetVisible(self.tbBtnInformationAdd[nIndex], false)
            UIHelper.SetVisible(self.tbInformationNoneImg[nIndex], true)
            UIHelper.SetTexture(self.tbInformationNoneImg[nIndex], "Resource/PersonalCard/PersonalIcon/mpk1.png")
        else
            UIHelper.SetVisible(self.tbBtnInformationAdd[nIndex], false)
        end
    end

    if self.bEdit then
        UIHelper.BindUIEvent(self.tbBtnInformationAdd[nIndex], EventType.OnClick,
            function ()
                if fnCallBackSelectData then
                    fnCallBackSelectData(nIndex, dwKey)
                end
            end
        )
    else
        UIHelper.SetTouchEnabled(self.tbBtnInformationAdd[nIndex], false)
    end
end

function UIWidgetPersonalCard:SetShowDataSelected(nIndex)
    UIHelper.SetVisible(self.tbShowDataSelect[nIndex], false)
end

-- --------------------------------------------------------------------------------------------------------------------
-- 图片相关
-- --------------------------------------------------------------------------------------------------------------------
function UIWidgetPersonalCard:UpdateImageByPlayerData(nIndex, bEdit)

    if PersonalCardData.tSelfImageData[nIndex] then
        if PersonalCardData.tSelfImageData[nIndex].bHave == true then
            UIHelper.SetVisible(self.BtnPersonalCardNew, false)
            UIHelper.SetVisible(self.ImgPersonalCardNewBg, false)
            UIHelper.SetVisible(self.LabelLoading, false)
            UIHelper.SetVisible(self.ImgPersonalCardNowBg, true)

            if PersonalCardData.tSelfImageData[nIndex].pRetTexture then
                local picTexture = PersonalCardData.tSelfImageData[nIndex].pRetTexture
                UIHelper.SetTextureWithBlur(self.ImgPersonalCardNowBg, picTexture, false)
            elseif PersonalCardData.tSelfImageData[nIndex].fileName then
                local fileName = PersonalCardData.tSelfImageData[nIndex].fileName
                UIHelper.SetTexture(self.ImgPersonalCardNowBg, fileName, false)
            end
        else
            UIHelper.SetVisible(self.BtnPersonalCardNew, bEdit and true or false)
            UIHelper.SetVisible(self.ImgPersonalCardNewBg, true)
            UIHelper.SetVisible(self.ImgPersonalCardNowBg, false)

            UIHelper.BindUIEvent(self.BtnPersonalCardNew, EventType.OnClick , function ()
                if IsInLishijie() then
                    return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_UNABLE_TO_USE_SELFIE)
                end

                local bUnLock = PersonalCardData.GetShowCardPresetState(nIndex, SHOW_CARD_PRESET_STATE_TYPE.UNLOCK)
                if not bUnLock then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHOW_CARD_LOCK_TIPS)
                    return
                end

                if UIMgr.IsViewOpened(VIEW_ID.PanelCharacter) then
                    Event.Reg(self, EventType.OnViewClose, function(nViewID)
                        if nViewID == VIEW_ID.PanelCharacter then
                            Timer.Add(Global, 0.5, function()
                                UIMgr.Open(VIEW_ID.PanelCamera, true, nIndex)
                            end)
                            Event.UnReg(self, EventType.OnViewClose)
                        end
                    end)
                else
                    UIMgr.Open(VIEW_ID.PanelCamera, true, nIndex)
                end

                if self.fnCallBackCloseView then
                    self.fnCallBackCloseView()
                end
            end)
        end
    end

    self.nIndex = nIndex
    self:InitDecorationPreset(nIndex)
end

function UIWidgetPersonalCard:UpdateImageByPic(picTexture)
    UIHelper.SetTextureWithBlur(self.ImgPersonalCardNowBg, picTexture)
end

function UIWidgetPersonalCard:AdjustViewScale()
    local tbScreenSize = UIHelper.DeviceScreenSize()
    local nodeW , nodeH =  UIHelper.GetContentSize(self.ImgPersonalCardNowBg)
    local newNodeW = nodeH / tbScreenSize.height * tbScreenSize.width
    if newNodeW < nodeW then
        nodeH = nodeW / tbScreenSize.width * tbScreenSize.height
    else
        nodeW = newNodeW
    end
    UIHelper.SetContentSize(self.ImgPersonalCardNowBg , nodeW , nodeH)
end

function UIWidgetPersonalCard:UpdateLoadState()
    -- Timer.AddFrame(self, 30, function()
        UIHelper.SetVisible(self.BtnPersonalCardNew, false)
        UIHelper.SetVisible(self.ImgPersonalCardNewBg, true)
        -- UIHelper.SetVisible(self.LabelLoading, true)
        UIHelper.SetVisible(self.ImgPersonalCardNowBg, false)
    -- end)
end

-- --------------------------------------------------------------------------------------------------------------------
-- 页面组件相关 一键隐藏/展示 裁剪截图用
-- --------------------------------------------------------------------------------------------------------------------
function UIWidgetPersonalCard:HideOrShowAllNode(bVisible)
    for index, _ in pairs(self.tbWidgetShow) do
        UIHelper.SetVisible(self.tbWidgetShow[index], bVisible)
    end
end

-- --------------------------------------------------------------------------------------------------------------------
-- OtherPlayer
-- --------------------------------------------------------------------------------------------------------------------
function UIWidgetPersonalCard:ApplyPersonalData()
    self.tDecorationPresetLogic = PersonalCardData.GetDecorationPreset(self.szGlobalID)
    self.tShowData = PersonalCardData.GetShowData(self.szGlobalID)

    if not self.tDecorationPresetLogic or not self.tShowData or table_is_empty(self.tShowData) then
        PersonalCardData.ApplyShowCardData(self.szGlobalID)
    else
        self:ApplyDownloadShowCardImage()
    end

    if GDAPI_InitShowCardData and self.tShowData then
        self.tConstData = GDAPI_InitShowCardData(self.tShowData)
    end
end

function UIWidgetPersonalCard:ApplyDownloadShowCardImage()
    local nIndex, bState = PersonalCardData.GetImageIndexAndState(self.szGlobalID)
    if nIndex ~= - 1 then
        self.bDownload = true
        if #self.tDecorationPresetLogic <= 0 and not bState then
        else
            UIHelper.SetVisible(self.LabelLoading, true)
            PersonalCardData.DownloadShowCardImage(self.szGlobalID, nIndex)
        end
    end
end

function UIWidgetPersonalCard:UpdateOtherPlayer()
    self.BtnCall:setTouchDownHideTips(false)
    self.BtnPermissions:setTouchDownHideTips(false)
    self.BtnTeam:setTouchDownHideTips(false)
    self.BtnExpand:setTouchDownHideTips(false)
    self.Btnmark:setTouchDownHideTips(false)
    self.BtnPersonalCardNew:setTouchDownHideTips(false)
    self.BtnMask:setTouchDownHideTips(false)
    self.BtnReport:setTouchDownHideTips(false)
    UIHelper.SetVisible(self.BtnMask, true)

    self:UpdateOtherPlayerBaseInfo()
    self:UpdateOtherTitle()
    self:UpdateShowData()
    self:UpdateOtherPlayerPhoto()
    self.tDecorationPresetLogic = PersonalCardData.GetDecorationPreset(self.szGlobalID)
    self:UpdateDecorationPreset()
end

function UIWidgetPersonalCard:DownloadImageDataAndCache(dwImageIndex)
    local hManager = GetShowCardCacheManager()
    if hManager then
        local pdata, nsize
        if dwImageIndex then
            pdata, nsize = hManager.GetImageDataForMobile(self.szGlobalID, dwImageIndex, 1)
        elseif self.bSelf then
            pdata, nsize = PersonalCardData.GetShowSelfImage()
        end

        if pdata and nsize then
            UIHelper.GetImageFromPngData(function(pRetTexture, pImage)
                pRetTexture:retain()
                UIHelper.SetVisible(self.BtnPersonalCardNew, false)
                UIHelper.SetTextureWithBlur(self.ImgPersonalCardNowBg, pRetTexture, false)

                if self.picTexture then
                    self.picTexture:release()
                    self.picTexture = nil
                end
                self.picTexture = pRetTexture
            end, pdata, nsize)
            if self.bSelf then
                PersonalCardData.SetShowSelfImage(pdata, nsize)
            end
        end
    end
    UIHelper.SetVisible(self.ImgPersonalCardNewBg, false)
end

function UIWidgetPersonalCard:UpdateOtherTitle()
    if self.tConstData then
        local szName = self:GetPlayerCurrentDesignation(self.tConstData)

        UIHelper.RemoveAllChildren(self.WidgetTitleCell)
        if szName and szName ~= "" then
            local scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetTitleCell, self.WidgetTitleCell) assert(scriptTitle)
            scriptTitle:UpdateInfo(szName)
        end

        UIHelper.SetVisible(self.BtnTitleAdd, false)
        UIHelper.SetString(self.LabelEquipNum, self.tConstData.dwEquipScore)
    end
end

function UIWidgetPersonalCard:UpdateOtherPlayerBaseInfo()
    self.bHasPlayer = false
    if not self.tbRoleEntryInfo then
        self.tbRoleEntryInfo = GetPlayerByGlobalID(self.szGlobalID)
        self.bHasPlayer = true
    end

    if self.tbRoleEntryInfo then
        -- 通过GetPlayerByGlobalID得到的角色信息对应的key不同，简单处理一下
        local dwMiniAvatarID    = self.tbRoleEntryInfo.dwMiniAvatarID
        local nRoleType         = self.tbRoleEntryInfo.nRoleType
        local nForceID          = self.bHasPlayer and self.tbRoleEntryInfo.dwForceID or self.tbRoleEntryInfo.nForceID
        local nCamp             = self.tbRoleEntryInfo.nCamp
        local nLevel            = self.tbRoleEntryInfo.nLevel

        self.headScript = self.headScript or UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetHead)
        if self.headScript then
            self.headScript:SetHeadInfo(self.dwPlayer, dwMiniAvatarID, nRoleType, nForceID)
            self.headScript:SetTouchEnabled(false)
        end

        self.szGBKName = self.tbRoleEntryInfo.szName
        local szUtfName = UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName)
        if szUtfName == "" then
            UIHelper.SetVisible(self.ImgCamp, false)
            szUtfName = g_tStrings.MENTOR_DELETE_ROLE
        else
            CampData.SetUICampImg(self.ImgCamp, nCamp, nil, true)
        end

        UIHelper.SetString(self.LabelName, szUtfName, 6)
        UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[nForceID])
        UIHelper.SetString(self.LabelLevel, nLevel)
    end
end

function UIWidgetPersonalCard:SetPersonalInfo(tInfo)
    if tInfo then
        UIHelper.SetString(self.LabelName, tInfo.szName, 6)
        self.szGBKName = UIHelper.UTF8ToGBK(tInfo.szName)
        if tInfo.nLevel then
            UIHelper.SetString(self.LabelLevel, tInfo.nLevel)
        end

        UIHelper.RemoveAllChildren(self.WidgetHead)
        self.headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetHead)
        if tInfo.szHeadIconPath and self.headScript then
            UIHelper.SetSpriteFrame(self.headScript.ImgPlayerIcon, tInfo.szHeadIconPath)
        elseif self.headScript then
            self.headScript:SetHeadInfo(tInfo.dwPlayerID, tInfo.dwMiniAvatarID, tInfo.nRoleType, tInfo.dwForceID)
        end
        self.dwForceID = tInfo.dwForceID
        self.bSetPersonalInfo = true
    end
end

function UIWidgetPersonalCard:InitDecorationPreset(nIndex)
    if nIndex then
        self.tDecorationPresetLogic = g_pClientPlayer.GetShowCardDecorationPreset(nIndex)
        self:UpdateDecorationPreset()
    end
end

function UIWidgetPersonalCard:UpdateDecorationPreset()
    local tDecorationPresetDataUI = PersonalCardData.LogicLayer2UILayer(self.tDecorationPresetLogic)

    for k, v in ipairs(self.tbWidgetAllAttachment) do
        if k == 1 then
            UIHelper.ClearTexture(self.tbWidgetAllAttachment[k])
        elseif k == #self.tbWidgetAllAttachment then
            UIHelper.SetVisible(self.tbWidgetAllAttachment[k], true)
        else
            UIHelper.RemoveAllChildren(self.tbWidgetAllAttachment[k])
        end
    end
    UIHelper.ClearTexture(self.ImgFrame_Special)
    self:SetPersonalFrame()

    if self.tDecorationPresetLogic and not table_is_empty(self.tDecorationPresetLogic) then
        for k, v in ipairs(self.tbWidgetAllAttachment) do
            if tDecorationPresetDataUI[k] then
                local tData = Table_GetPersonalCardByDecorationID(tDecorationPresetDataUI[k].wID)
                if tDecorationPresetDataUI[k].nDecorationType == SHOW_CARD_DECORATION_TYPE.FRAME then
                    if tData.szVKPath and tData.szVKPath ~= "" then
                        UIHelper.SetVisible(self.tbWidgetAllAttachment[k], false)
                        UIHelper.SetVisible(self.ImgFrame_Special, true)
                        UIHelper.SetTexture(self.ImgFrame_Special, tData.szVKPath)
                    else
                        UIHelper.SetVisible(self.tbWidgetAllAttachment[k], true)
                        UIHelper.SetVisible(self.ImgFrame_Special, false)
                    end

                    self:SetPersonalFrame(tData.szVKSmallPath)
                else
                    local Zoom = UIHelper.AddPrefab(PREFAB_ID.WidgetZoom, self.tbWidgetAllAttachment[k])
                    if Zoom then
                        UIHelper.SetScale(Zoom._rootNode, tDecorationPresetDataUI[k].fScale, tDecorationPresetDataUI[k].fScale)
                        local nWidgetWidth = UIHelper.GetWidth(self.tbWidgetAllAttachment[k])
                        local nWidgetHeight = UIHelper.GetHeight(self.tbWidgetAllAttachment[k])
                        local fOffsetX, fOffsetY = PersonalCardData.DXOffsetTranslate2VK(tDecorationPresetDataUI, k, nWidgetWidth, nWidgetHeight)
                        UIHelper.SetPosition(Zoom._rootNode, fOffsetX, fOffsetY)
                       if tDecorationPresetDataUI[k].nDecorationType == SHOW_CARD_DECORATION_TYPE.DECAL then
                            UIHelper.SetTexture(Zoom.ImgZoomBg, tData.szVKPath)
                       else
                            UIHelper.SetSFXPath(Zoom.sfxBg, tData.szSFX, true)
                       end
                        self:UpdateZoomRotation(Zoom, tDecorationPresetDataUI[k].byRotation or 0)
                    end
                end
            end
        end
        UIHelper.UpdateMask(self.ImgAttachmentMask)
    end
end

function UIWidgetPersonalCard:UpdateOtherPlayerPhoto()
    if not self.bHavePhoto then
        UIHelper.SetVisible(self.BtnPersonalCardNew, true)
        UIHelper.SetVisible(self.ImgPersonalCardNewBg, true)
        UIHelper.SetVisible(self.ImgCameraIcon, false)
        UIHelper.SetVisible(self.LabelNew, false)
    end
end

function UIWidgetPersonalCard:UpdateOtherPlayerBtn(fnOnClickMore, tbRoleEntryInfo, dwPlayerID)
    self.bShowOtherPlayerBtn = true
    UIHelper.SetVisible(self.WidgetBtn, true)
    UIHelper.SetVisible(self.BtnExpand, true)
    UIHelper.SetVisible(self.BtnCall, true)

    self.tbRoleEntryInfo = self.tbRoleEntryInfo or tbRoleEntryInfo
    self.dwPlayer = dwPlayerID
    self.targetPlayer = GetPlayer(dwPlayerID)

    self:UpdatTeamMenusBtn(dwPlayerID)
    self:UpdateMarkBtn(dwPlayerID)

    UIHelper.BindUIEvent(self.BtnExpand, EventType.OnClick , function ()
        if fnOnClickMore then
            fnOnClickMore(self.WidgetPlayerPop)
        end
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipTargetgetMark)
    end)
end

function UIWidgetPersonalCard:UpdatTeamMenusBtn(dwPlayerID)
    local bVisibleGroup
    if not dwPlayerID then
        bVisibleGroup = TeamData.CanMakeParty() and FellowshipData.IsOnline(self.szGlobalID)
    else
        bVisibleGroup = TeamData.CanMakeParty()
    end
    UIHelper.SetVisible(self.BtnTeam, bVisibleGroup)

    --组队权限
    self.tbTeamMenus = {}
    if dwPlayerID then
        if g_pClientPlayer.IsInParty() and g_pClientPlayer.IsPlayerInMyParty(dwPlayerID) then
            TeamData.InsertTeammateMenus(self.tbTeamMenus, dwPlayerID)
        end
        local bVisiblePermissions = not table_is_empty(self.tbTeamMenus)
        UIHelper.SetVisible(self.BtnPermissions, bVisiblePermissions)
        UIHelper.SetVisible(self.BtnTeam, not bVisiblePermissions and bVisibleGroup)
    else
        UIHelper.SetVisible(self.BtnPermissions, false)
    end
end

function UIWidgetPersonalCard:UpdateMarkBtn(dwPlayerID)
    -- 标记菜单
    if dwPlayerID then
        local dwMark = GetClientTeam().GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK)
        UIHelper.SetVisible(self.Btnmark, dwMark == g_pClientPlayer.dwID)
    else
        UIHelper.SetVisible(self.Btnmark, false)
    end
end

function UIWidgetPersonalCard:ShowOwnBtn(bShow)
    UIHelper.SetVisible(self.WidgetOwnBtn, bShow)
    UIHelper.SetVisible(self.BtnPersonalCard, bShow)
    UIHelper.SetVisible(self.BtnChangeHead, bShow)
    self:UpdateBirthdayBtn(bShow)
end

function UIWidgetPersonalCard:HideAllDate(bHide)
    UIHelper.SetVisible(self.WidgetPersonalCardContent, not bHide)
end

function UIWidgetPersonalCard:CreateMenus(tbAllMenuConfig, layoutParent)
    local tbShowMenuConfig = {}

    for _, tbMenuConfig in ipairs(tbAllMenuConfig or {}) do
        if not tbMenuConfig.fnCheckShow or  tbMenuConfig.fnCheckShow() then
            table.insert(tbShowMenuConfig, tbMenuConfig)
        end
    end

    for idx, tbMenuConfig in ipairs(tbShowMenuConfig) do
        local btnScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMoreBtn, layoutParent)

        UIHelper.SetString(btnScript.LableMpore, tbMenuConfig.szName)
        UIHelper.SetTouchDownHideTips(btnScript.Btn, false)

        UIHelper.BindUIEvent(btnScript.Btn, EventType.OnClick, function(btnClicked)
            if IsFunction(tbMenuConfig.fnDisable) and tbMenuConfig.fnDisable() then
                return
            end

            if tbMenuConfig.bCloseOnClick then
                if UIHelper.GetSelected(self.BtnPermissions) then
                    UIHelper.SetSelected(self.BtnPermissions, false)
                end
            end

            if IsFunction(tbMenuConfig.callback) then
                tbMenuConfig.callback()
            end
        end)

        if IsFunction(tbMenuConfig.fnDisable) and tbMenuConfig.fnDisable() then
            UIHelper.SetButtonState(btnScript.Btn, BTN_STATE.Disable)
        else
            UIHelper.SetButtonState(btnScript.Btn, BTN_STATE.Normal)
        end

    end
end

function UIWidgetPersonalCard:SetBtnMaskFalse()
    UIHelper.SetVisible(self.BtnMask, false)
end

function UIWidgetPersonalCard:SetEquipNumVisible(bVisible)
    UIHelper.SetVisible(self.WidgetEquipNum, bVisible)
end

function UIWidgetPersonalCard:SetXunBaoInfo(bSetVisible, tbStaticInfo)
    if not tbStaticInfo then
        return
    end
    if bSetVisible then
        UIHelper.SetVisible(self.WidgetXunBaoInfo, true)
        UIHelper.SetVisible(self.WidgetInformationAdd, false)
    end
    for nIndex, label in ipairs(self.tbXunBaoInfo) do
        local szText = ""
        local tbInfo = tbStaticInfo[nIndex]
        if tbInfo then
            szText = tbInfo.szTitle .. "：" .. tbInfo.szValue
        end
        UIHelper.SetString(label, szText)
    end
end

function UIWidgetPersonalCard:SetPersonalFrame(szFrame)
    if self.headScript then
        self.headScript:SetPersonalFrame(szFrame)
    elseif szFrame and szFrame ~= "" and not self.headScript then
        self.szPersonalFrame = szFrame
    end
end

function UIWidgetPersonalCard:SetTouchEnabled(bEnable)
    if self.headScript then
        self.headScript:SetTouchEnabled(bEnable)
    else
        self.HeadTouchEnable = false
    end
    UIHelper.SetTouchEnabled(self.BtnTitleAdd, bEnable)
    UIHelper.SetTouchEnabled(self.BtnExpand, bEnable)
    UIHelper.SetTouchEnabled(self.BtnCall, bEnable)
    UIHelper.SetTouchEnabled(self.BtnTeam, bEnable)
    UIHelper.SetTouchEnabled(self.BtnPermissions, bEnable)
    UIHelper.SetTouchEnabled(self.Btnmark, bEnable)
end

function UIWidgetPersonalCard:UpdateZoomRotation(Zoom, byRotation)
    local nRotation = byRotation * 360 / 255
    for index, node in ipairs(Zoom.tbRotateNode) do
        UIHelper.SetRotation(node, nRotation)
    end
    UIHelper.Set2DRotation(Zoom.sfxBg, -nRotation * math.pi / 180)
end

---------------------------------------------------------------------------------------
--- 点赞相关 begin
---------------------------------------------------------------------------------------

function UIWidgetPersonalCard:SetPlayerId(dwID)
    self.dwPlayerID = dwID
end

function UIWidgetPersonalCard:UpdateCardPraiseNum(bAdd)
    local nCardPraiseNum = 0
    if not self.Praiseinfo then
        local szApplyGlobalID
        if self.bSelf then
            szApplyGlobalID = g_pClientPlayer.GetGlobalID()
        else
            szApplyGlobalID = self.szGlobalID
        end

        local tbPlayerCard = FellowshipData.GetFellowshipCardInfo(szApplyGlobalID)
        self.Praiseinfo = tbPlayerCard and tbPlayerCard.Praiseinfo or {}
        nCardPraiseNum = self.Praiseinfo[PRAISE_TYPE.PERSONAL_CARD] or 0
        FellowshipData.ApplyFellowshipCard(szApplyGlobalID)
    end

    nCardPraiseNum = self.Praiseinfo[PRAISE_TYPE.PERSONAL_CARD] or 0

    if bAdd then
        nCardPraiseNum = nCardPraiseNum + 1
        self.Praiseinfo[PRAISE_TYPE.PERSONAL_CARD] = nCardPraiseNum
    end

    self:SetCardPraiseNum(nCardPraiseNum)
end

function UIWidgetPersonalCard:SetCardPraiseNum(nCardPraiseNum)
    local szCardPraise
    if nCardPraiseNum < 10000 then
        szCardPraise = nCardPraiseNum
    else
        local dwNumW = math.modf(nCardPraiseNum / 10000)
        local dwModK = math.fmod(nCardPraiseNum, 10000)
        local dwNumK = math.modf(dwModK / 1000)
        szCardPraise = FormatString("<D0>.<D1>万", dwNumW, dwNumK)
    end

    if self.bSelf then
        UIHelper.SetString(self.LabelPraise, szCardPraise)
    else
        UIHelper.SetString(self.LabelPraiseOther, szCardPraise)
    end
end


---------------------------------------------------------------------------------------
--- 点赞相关 end
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
--- 生日设置相关 begin
---------------------------------------------------------------------------------------

function UIWidgetPersonalCard:OnBirthdaySetSuccess()
    if self.bSelf then
        self:UpdateBirthdayBtn(true)
    end
end

function UIWidgetPersonalCard:UpdateBirthdayBtn(bShow)
    local tData = GDAPI_GetBirthDayData()
    local bSetted = false
    if tData.nMonth and tData.nDay and tData.nMonth > 0 and tData.nDay > 0 then
        bSetted = true
    end
    UIHelper.SetVisible(self.BtnBirthday, bShow and not bSetted)
    UIHelper.SetVisible(self.BtnBirthdaySetted, bShow and bSetted)
    UIHelper.LayoutDoLayout(self.WidgetOwnBtn)
end
---------------------------------------------------------------------------------------
--- 生日设置相关 end
---------------------------------------------------------------------------------------
return UIWidgetPersonalCard