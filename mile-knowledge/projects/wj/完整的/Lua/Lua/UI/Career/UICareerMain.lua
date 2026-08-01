--PanelCareerMain

local UICareerMain = class("UICareerMain")

function UICareerMain:_LuaBindList()
    self.WidgetHeadShot      = self.WidgetHeadShot --- 头像
    self.LabelName           = self.LabelName --- 名字
    self.LabelLevel          = self.LabelLevel --- 等级
    self.ImgPlayerSchool     = self.ImgPlayerSchool ---门派
    self.ImgSchoolIcon       = self.ImgSchoolIcon --- 帮会图标
    self.LabelDistrict       = self.LabelDistrict --- 区服
    self.LabelFaction        = self.LabelFaction --- 帮会名字
    self.LabelDiscrepancy    = self.LabelDiscrepancy --- 出入江湖
    self.EditBox             = self.EditBox --- 玩家签名
    self.LabelLikeNum        = self.LabelLikeNum --- 点赞数量

    self.LabelScoreNum       = self.LabelScoreNum --- 装备评分
    self.LabelCredentialsNum = self.LabelCredentialsNum --- 江湖资历
    self.LabelReputationNum  = self.LabelReputationNum --- 声望点数
end

function UICareerMain:OnEnter()
    self.player = GetClientPlayer()
    if not self.bInit then
        self:Init()
        self:ApplyData()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateData()
end

function UICareerMain:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerMain:Init()
    --
end

function UICareerMain:ApplyData()
    local SMClient = GetSocialManagerClient()
    if not SMClient or  not g_pClientPlayer then
        return
    end
    SMClient.ApplyFellowshipCard(g_pClientPlayer.GetGlobalID())
end

function UICareerMain:BindUIEvent()
    -- UIHelper.BindUIEvent(self.BtnEditBox, EventType.OnClick, function()
    --     self:ModifySignature()
    -- end)
end

function UICareerMain:RegEvent()
    Event.Reg(self, "ON_GET_DOCUMENT", function(dwPlayerID, tInfo)
        CareerData.UpdateReportData(tInfo)
        CareerData.UpdateMainDataOfAdventureNum()
        self.tInfo = CareerData.tMainInfo
        self:UpdateInfo()
    end)

    Event.Reg(self, "Get_Player_Play_Time", function(nDay, nHour, nMinute, nSecond)
        CareerData.UpdateMainDataOfPlayTime(nDay, nHour, nMinute, nSecond)
        self.tInfo = CareerData.tMainInfo
        self:UpdateInfo()
    end)

    Event.Reg(self,"FELLOWSHIP_ROLE_ENTRY_UPDATE",function (dwGlobalID)
        if dwGlobalID == UI_GetClientPlayerGlobalID() then
            CareerData.UpdateMainDataOfnPraiseCount()
            self.tInfo = CareerData.tMainInfo
            self:UpdateInfo()
        end
    end)
end

function UICareerMain:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerMain:UpdateData()
    CareerData.UpdateGlobalID()
    CareerData.UpdateMainData()
    local nowTime = GetCurrentTime()
    local bApplyData = true
    if CareerData.tReportInfo then
        CareerData.tMainInfo.nAdventureNum = CareerData.tReportInfo.nAdventureCount
        local nDelta = nowTime - CareerData.tReportInfoTime
        if nDelta <= 60 then
            bApplyData = false
        end
    end

    if bApplyData then
        if self.player then
            RemoteCallToServer("On_Achievement_GetDocumentInfo", self.player.dwID)
        end
    end

    if CareerData.nMainInfoTime then
        local nDelta = nowTime - CareerData.nMainInfoTime
        if nDelta > 60 then
            RemoteCallToServer("OnApplyPlayTime")
        end
    else
        RemoteCallToServer("OnApplyPlayTime")
    end

    self.tInfo = CareerData.tMainInfo
    self:UpdateInfo()
end

function UICareerMain:UpdateInfo()
    if not self.player then
        return
    end
    UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetHeadShot, self.player.dwID)

    local szName = self.player.szName or ""
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(szName))
    
    UIHelper.SetSpriteFrame(self.ImgPlayerSchool, PlayerForceID2SchoolImg[self.player.dwForceID])

    UIHelper.SetString(self.LabelLevel, self.player.nLevel)
    
    CampData.SetUICampImg(self.ImgSchoolIcon, self.player.nCamp)

    -- UIHelper.SetText(self.EditBox, UIHelper.GBKToUTF8(self.tInfo.szSignature))

    UIHelper.SetString(self.LabelLikeNum, self.tInfo.nPraiseCount)

    UIHelper.SetString(self.LabelDistrict, "区服："..self.tInfo.szServerName)

    local szTongName = "无"
    if self.player.dwTongID ~= 0 then
        szTongName = UIHelper.GBKToUTF8(GetTongClient().ApplyGetTongName(self.player.dwTongID)) or "无"
    end
	UIHelper.SetString(self.LabelFaction, "帮会："..szTongName)

    if self.tInfo.nCreateTime then
		local tStartTime = TimeToDate(self.tInfo.nCreateTime)
		local szCreateTime = "出入江湖：" .. FormatString(g_tStrings.STR_TIME_3, tStartTime.year, tStartTime.month, tStartTime.day)
        UIHelper.SetString(self.LabelDiscrepancy, szCreateTime)
	else
        UIHelper.SetString(self.LabelDiscrepancy, "加载中")
    end


    UIHelper.SetString(self.LabelScoreNum, self.tInfo.nEquipScore)
    UIHelper.SetString(self.LabelCredentialsNum, self.tInfo.nCredentialsScore)
    UIHelper.SetString(self.LabelReputationNum, self.tInfo.nReputation)
    
    if self.tInfo.nAdventureNum then
        UIHelper.SetString(self.tbLableUnder[1], self.tInfo.nAdventureNum)
    else
        UIHelper.SetString(self.tbLableUnder[1], "")
    end
    UIHelper.SetString(self.tbLableUnder[2], self.tInfo.nBookNum)
    UIHelper.SetString(self.tbLableUnder[3], self.tInfo.nNpcAssistedNum)
    UIHelper.SetString(self.tbLableUnder[4], self.tInfo.nSpecialAchievementNum)
    UIHelper.SetString(self.tbLableUnder[5], self.tInfo.nDesignationNum)
    UIHelper.SetString(self.tbLableUnder[6], self.tInfo.nExtPoint)
    UIHelper.SetString(self.tbLableUnder[7], self.tInfo.nFame)
    if self.tInfo.tPlayerPlayTime then
        if self.tInfo.tPlayerPlayTime.nDay > 0 then
            UIHelper.SetString(self.tbLableUnder[8], self.tInfo.tPlayerPlayTime.nDay.."天")
        elseif self.tInfo.tPlayerPlayTime.nHour > 0 then
            UIHelper.SetString(self.tbLableUnder[8], self.tInfo.tPlayerPlayTime.nHour.."时")
        elseif self.tInfo.tPlayerPlayTime.nMinute > 0 then
            UIHelper.SetString(self.tbLableUnder[8], self.tInfo.tPlayerPlayTime.nMinute.."分")
        elseif self.tInfo.tPlayerPlayTime.nSecond > 0 then
            UIHelper.SetString(self.tbLableUnder[8], self.tInfo.tPlayerPlayTime.nSecond.."秒")
        else
            UIHelper.SetString(self.tbLableUnder[8], "--")
        end
    else
        UIHelper.SetString(self.tbLableUnder[8], "--")
    end
end

function UICareerMain:ModifySignature()
    local szSignature = UIHelper.GetText(self.EditBox)
    GetSocialManagerClient().SetSignature(UIHelper.UTF8ToGBK(szSignature))
end

return UICareerMain