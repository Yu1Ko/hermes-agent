-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: FestivalActivities
-- Date: 2024-05-22 18:01:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

FestivalActivities = FestivalActivities or {className = "FestivalActivities"}
local self = FestivalActivities
-------------------------------- 消息定义 --------------------------------
FestivalActivities.Event = {}
FestivalActivities.Event.XXX = "FestivalActivities.Msg.XXX"

function FestivalActivities.Init()
    --龙舟特殊处理，龙舟会跟pq同步显示
    --其他的都显示在other里
    FestivalActivities.bLongZhou = false

    --声明一下GeneralProgressBar的key，按照我们想显示的顺序
    FestivalActivities.tbLongzhouName = {
        "longzhou3",
        "longzhou2",
        "longzhou1",
    }

    FestivalActivities.tbChildrensDayName = {
        "bar130",
        "bar131",
        "bar132",
        "bar133",
        "bar134",
        "bar135",
        "bar136",
        "bar137",
        "bar138",
        "bar139",
        "bar140",
    }

    FestivalActivities.tbChildrensDayDanceName = {
        "Score",
        "SeptDanceCount",
        "SeptDanceTime",
    }

    FestivalActivities.tbProgressBarData = {}

    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        if table.contain_value(FestivalActivities.tbLongzhouName, tbInfo.szName) or
        table.contain_value(FestivalActivities.tbChildrensDayName, tbInfo.szName) or
        table.contain_value(FestivalActivities.tbChildrensDayDanceName, tbInfo.szName) then
            FestivalActivities.tbProgressBarData[tbInfo.szName] = tbInfo
            if table.contain_value(FestivalActivities.tbLongzhouName, tbInfo.szName) then
                FestivalActivities.bLongZhou = true
            end
        end
    end)

    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        if table.contain_value(FestivalActivities.tbLongzhouName, szName) or
        table.contain_value(FestivalActivities.tbChildrensDayName, szName) or
        table.contain_value(FestivalActivities.tbChildrensDayDanceName, szName) then
            FestivalActivities.bLongZhou = false
        end
    end)
end

function FestivalActivities.UnInit()
    Timer.DelAllTimer(self)
end

function FestivalActivities.OnLogin()

end

--龙舟 有pq时跟pq显示在一起，没有的时候放在other里面
function FestivalActivities.UpdateLongZhouSlider(ScrollViewOther, bVisible)
    UIHelper.RemoveAllChildren(ScrollViewOther)
    if bVisible then
        for _, szName in ipairs(FestivalActivities.tbLongzhouName) do
            local tbInfo = FestivalActivities.tbProgressBarData[szName]
            if tbInfo then
                if tbInfo.szTitle and tbInfo.szTitle ~= ""then
                    local szTitle = UIHelper.AttachTextColor(UIHelper.GBKToUTF8(tbInfo.szTitle), 27)
                    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, ScrollViewOther, szTitle)
                end
                UIHelper.AddPrefab(PREFAB_ID.WidgetSliderOtherDescribe, ScrollViewOther, tbInfo.szDiscrible, tbInfo.nMolecular .. "/" .. tbInfo.nDenominator, tbInfo.nMolecular / tbInfo.nDenominator * 100, nil, true)
            end
        end

        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollViewDoLayoutAndToTop(ScrollViewOther)
        end)
    end
end

--非人哉月饼旷工进度条 显示不下特殊处理
function FestivalActivities.UpdateMinerSlider(ScrollViewOther, bVisible)
    UIHelper.RemoveAllChildren(ScrollViewOther)
    if bVisible then
        for _, szName in ipairs(FestivalActivities.tbChildrensDayName) do
            local tbInfo = FestivalActivities.tbProgressBarData[szName]
            if tbInfo then
                if szName == "bar130" then
                    local szTitle = UIHelper.AttachTextColor(UIHelper.GBKToUTF8(tbInfo.szTitle), 27)
                    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, ScrollViewOther, szTitle.."（倒计时："..tbInfo.nMolecular .."秒）")
                end
                if szName == "bar130" then
                    local szTip = ParseTextHelper.ParseFontDesc(UIHelper.GBKToUTF8(tbInfo.szTip))
                    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, ScrollViewOther, szTip)
                end
                if szName ~= "bar130" then
                    UIHelper.AddPrefab(PREFAB_ID.WidgetSliderOtherDescribe, ScrollViewOther, tbInfo.szTitle, tbInfo.nMolecular .. "/" .. tbInfo.nDenominator, tbInfo.nMolecular / tbInfo.nDenominator * 100, 10, true)
                end
            end
        end

        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollViewDoLayoutAndToTop(ScrollViewOther)
        end)
    end
end

--非人哉跳舞 特殊处理 端游用的显示条，我们只显示文本
function FestivalActivities.UpdateDanceSlider(ScrollViewOther, bVisible)
    UIHelper.RemoveAllChildren(ScrollViewOther)

    if bVisible then
        for _, szName in ipairs(FestivalActivities.tbChildrensDayDanceName) do
            local tbInfo = FestivalActivities.tbProgressBarData[szName]
            if tbInfo then
                local szValue, nFontSize

                if szName == "Score" then
                    szValue = "总分数  " .. tbInfo
                    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, ScrollViewOther, "<color=#ffe26e>" .. szValue .. "</color>", nil, 36)
                    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, ScrollViewOther, " ")
                else
                    if tbInfo.nWay == 6 then
                        local nCurrentTime = GetCurrentTime()
                        local nTime = tbInfo.nEndTime - nCurrentTime
                        if nTime > 0 then
                            self.nTimer = self.nTimer or Timer.AddCycle(self, 1, function ()
                                FestivalActivities.UpdateDanceSlider(ScrollViewOther, bVisible)
                            end)
                            local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nTime)
                            szValue = "倒计时  "..string.format("%02d:%02d", nM, nS)
                        else
                            Timer.DelTimer(self, self.nTimer)
                            self.nTimer = nil
                        end
                    else
                        szValue =  "步数  " ..tbInfo.nMolecular .. "/" .. tbInfo.nDenominator
                    end
                    UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, ScrollViewOther, szValue, nil, 26)
                end
            elseif self.nTimer then
                Timer.DelTimer(self, self.nTimer)
                self.nTimer = nil
            end
        end

        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollViewDoLayoutAndToTop(ScrollViewOther)
        end)
    end
end



function FestivalActivities.UpdateFBCountDown(nType, nStartTime, nEndTime)
    self.tbFBCountDown = {
        nType = nType,
        nStartTime = nStartTime,
        nEndTime = nEndTime,
    }
    Event.Dispatch(EventType.UpdateFBCountDown, self.tbFBCountDown)
end

function FestivalActivities.GetFBCountDownData()
    return self.tbFBCountDown
end

function FestivalActivities.ClearFBCountDown()
    self.tbFBCountDown = nil
     Event.Dispatch(EventType.UpdateFBCountDown, self.tbFBCountDown)
end

function FestivalActivities.OnFirstLoadEnd()

end