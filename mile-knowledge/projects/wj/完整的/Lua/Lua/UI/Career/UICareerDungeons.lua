-- WidgetCareerDungeons

local UICareerDungeons = class("UICareerDungeons")

local REMOTE_NEWTRIAL_CUSTOM = 1036

function UICareerDungeons:_LuaBindList()
    self.LabelRecordNum01      = self.LabelRecordNum01 --- 试炼
    self.LabelRecordNum02      = self.LabelRecordNum02 --- 四时
    self.LabelRecordNum03      = self.LabelRecordNum03 --- 百战
    self.LabelRecordNum04      = self.LabelRecordNum04 --- 浪客

    self.LabelDataNum01        = self.LabelDataNum01 --- 击杀首领数量
    self.LabelDataNum02        = self.LabelDataNum02 --- 击杀首领数量
    self.LabelDataNum03        = self.LabelDataNum03 --- 击杀首领数量
    self.LabelDataNum04        = self.LabelDataNum04 --- 击杀首领数量
    self.LabelDataNum05        = self.LabelDataNum05 --- 击杀首领数量
end

function UICareerDungeons:OnEnter()
    self.player = GetClientPlayer()
    if not self.bInit then
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateData()
end

function UICareerDungeons:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerDungeons:Init()
    --
end

function UICareerDungeons:BindUIEvent()
    --
end

function UICareerDungeons:RegEvent()
    Event.Reg(self, "CAREER_TRAIN_GYM_CUSTOM_DATA", function(dwPlayerID, nEventID)
        if not g_pClientPlayer or dwPlayerID ~= g_pClientPlayer.dwID or nEventID ~= REMOTE_NEWTRIAL_CUSTOM then
			return
        end
        CareerData.UpdateDungeonsDataOfNewTrials()
        self:UpdateInfo(CareerData.tDungeonsInfo)
    end)

    Event.Reg(self, "Get_Career_Trial_Maxlevel", function(nlevel)
        CareerData.UpdateDungeonsDataOfTrials(nlevel)
        self:UpdateInfo(CareerData.tDungeonsInfo)
    end)

    Event.Reg(self, "UpdateFellowshipRankData", function(arg0, arg1, arg2, arg3)
        if arg0 == 10 then
            CareerData.UpdateDungeonsDataOfKillBoss()
            self:UpdateInfo(CareerData.tDungeonsInfo)
        end
    end)
end

function UICareerDungeons:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerDungeons:UpdateData()
    CareerData.UpdateDungeonsData()
    if not CareerData.tDungeonsInfo.NewTrials or not CareerData.tDungeonsInfo.Trials then
        CareerData.ApplyDungeonsDataOfNewTrials()
    else
        local nowTime = GetCurrentTime()
        local nDelta = nowTime - CareerData.nDungeonsTime
        if nDelta > 60 then
            CareerData.ApplyDungeonsDataOfNewTrials()
        end
    end
    self:UpdateInfo(CareerData.tDungeonsInfo)
end

function UICareerDungeons:UpdateInfo(tInfo)

    local szLable = ""

    if tInfo.Trials then
        szLable = tInfo.Trials .. "层"
        UIHelper.SetString(self.LabelRecordNum01, szLable)
    else
        UIHelper.SetString(self.LabelRecordNum01, "0层")
    end

    if tInfo.NewTrials then
        szLable = tInfo.NewTrials .. "层"
        UIHelper.SetString(self.LabelRecordNum02, szLable)
    else
        UIHelper.SetString(self.LabelRecordNum02, "0层")
    end

    if tInfo.szBaizhan then
        UIHelper.SetString(self.LabelRecordNum03, tInfo.szBaizhan)
    end

    if tInfo.LangKe then
        szLable = tInfo.LangKe .. "天"
        UIHelper.SetString(self.LabelRecordNum04, szLable)
    end

    if tInfo.nKillBossNum then
        UIHelper.SetString(self.LabelDataNum03, tInfo.nKillBossNum)
    else
        UIHelper.SetString(self.LabelDataNum03, "0")
    end

    UIHelper.SetVisible(self.tbWidgetData[1], false)
    UIHelper.SetVisible(self.tbWidgetData[2], false)
    UIHelper.SetVisible(self.tbWidgetData[4], false)
    UIHelper.SetVisible(self.tbWidgetData[5], false)
end

return UICareerDungeons