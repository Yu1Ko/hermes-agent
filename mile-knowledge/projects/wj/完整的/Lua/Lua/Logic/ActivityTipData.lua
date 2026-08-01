-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: ActivityTipData
-- Date: 2023-05-23 15:13:09
-- Desc: 动态信息Tip
-- ---------------------------------------------------------------------------------

ActivityTipData = ActivityTipData or {className = "ActivityTipData"}
local self = ActivityTipData
-------------------------------- 消息定义 --------------------------------
ActivityTipData.Event = {}
ActivityTipData.Event.XXX = "ActivityTipData.Msg.XXX"

local tAutoShowActivityTip = {17, 22, 26, 27, 44, 50} --自动显示的ActivityTip

local APPLY_CD_ID = 3114
local TIME_MINUTE = 60

local tActivityTipList = {} --当前同时存在的ActivityTip

function ActivityTipData.Init()
    self.RegEvent()
end

function ActivityTipData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function ActivityTipData.OnLogin()

end

function ActivityTipData.OnFirstLoadEnd()

end

function ActivityTipData.RegEvent()
    Event.Reg(self, EventType.OnClientPlayerEnter, function(dwID)
        self.ClearActivityTip()
    end)

    Event.Reg(self, "ON_ACTIVITY_TIPS_UPDATE", function(dwActivityID, nTime, tValue)
        self.OnUpdate(dwActivityID, nTime, tValue)
    end)

    Event.Reg(self, "ON_ACTIVITY_TIPS_CLOSE", function(dwActivityID)
        self.Close(dwActivityID)
    end)
end

--RemoteCommand Call By OnActivityTipUpdate
function ActivityTipData.OnUpdate(dwActivityID, nTime, tValue)
    --print("[ActivityTipData] OnUpdate", dwActivityID, nTime)
    --print_table(tValue)

    local tTip = self.GetActivityTip(dwActivityID)
    local bFirst = not tTip
    if bFirst then
        if not nTime then
            LOG.ERROR("ActivityTipPanel must open with live time")
            return
        end
        print("[ActivityTipData] AddActivityTip", dwActivityID, nTime)
        tTip = self.AddActivityTip(dwActivityID)
    end

    self.UpdateActivityTip(dwActivityID, nTime, tValue)

    if bFirst then
        Event.Dispatch(EventType.OnTogActivityTip, true, dwActivityID)
        if table.contain_value(tAutoShowActivityTip, dwActivityID) then
            --自动切换优先显示
            Event.Dispatch(EventType.OnSetTraceInfoPriority, TraceInfoType.ActivityTip, dwActivityID)
        end
    end

    Event.Dispatch(EventType.OnActivityTipUpdate, dwActivityID)
end

--RemoteCommand Call By OnActivityTipClose
function ActivityTipData.Close(dwActivityID)
    self.RemoveActivityTip(dwActivityID)
end

function ActivityTipData.GetActivityTip(dwActivityID)
    for i, tTip in ipairs(tActivityTipList) do
        if tTip.dwActivityID == dwActivityID then
            return tTip, i
        end
    end
end

function ActivityTipData.GetActivityTipByIndex(nIndex)
    return tActivityTipList[nIndex]
end

function ActivityTipData.AddActivityTip(dwActivityID)
    if self.GetActivityTip(dwActivityID) then
        return
    end

    --print("[ActivityTipData] AddActivityTip", dwActivityID)

    local tTip = {}

    tTip.dwActivityID = dwActivityID

    --ActivityTipPanel.lua: 98, ActivityTipPanel_Base.Init(hFrame)
    local tDesc = Table_GetActiviyTipDesc(dwActivityID)
    tTip.szName = UIHelper.GBKToUTF8(tDesc.szName)
    --tTip.szTimeDesc = UIHelper.GBKToUTF8(tDesc.szTimeDesc)
    tTip.szLink = tDesc.szLink

    local function loadtitle(szTitle)
        if not szTitle or szTitle == "" then
            return
        end
        local title  = loadstring("return " .. szTitle)
        setfenv(title, {})
        title = title()
        return title
    end

    tTip.tTitle = loadtitle(UIHelper.GBKToUTF8(tDesc.szTitle)) or {}

    table.insert(tActivityTipList, tTip)
end

function ActivityTipData.UpdateActivityTip(dwActivityID, nTime, tValue)
    local tTip = self.GetActivityTip(dwActivityID)
    if not tTip then
        return
    end

    --print("[ActivityTipData] UpdateActivityTip", dwActivityID, nTime, tValue)
    --print_table(tValue)

    if nTime then
        tTip.nEndTime = GetTickCount() + nTime * 1000
        local szTimeDesc = ""
    end

    tTip.tValue = {}
    for k, v in ipairs(tValue) do
        local szValue = UIHelper.GBKToUTF8(tostring(v))

        local nEndTime = nil
        szValue = string.gsub(szValue, "<time (%d+)>", function(nTime)
            nEndTime = GetTickCount() + nTime * 1000
            return "<D0>"
        end)

        tTip.tValue[k] = {
            szValue = szValue,
            nEndTime = nEndTime,
        }
    end
end

function ActivityTipData.RemoveActivityTip(dwActivityID)
    local tTip, nIndex = self.GetActivityTip(dwActivityID)
    if not tTip then
        return
    end

    print("[ActivityTipData] RemoveActivityTip", dwActivityID)

    table.remove(tActivityTipList, nIndex)

    Event.Dispatch(EventType.OnTogActivityTip, false, dwActivityID)
end

function ActivityTipData.ClearActivityTip()
    --OnTogActivityTip事件里有时候GetActivityTip会用到tActivityTipList里的tTip，所以先清避免显示不正确
    local tTemp = clone(tActivityTipList)
    tActivityTipList = {}
    for i, tTip in ipairs(tTemp) do
        Event.Dispatch(EventType.OnTogActivityTip, false, tTip.dwActivityID)
    end
end

function ActivityTipData.GetActivityTipTimeDescText(dwActivityID)
    local szTimeDesc = ""
    local nLeftTime = self.GetLeftTime(dwActivityID)
    if nLeftTime then
        if nLeftTime <= 0 then
            szTimeDesc = UIHelper.GBKToUTF8(Table_GetActiviyTimeDesc(dwActivityID))
            if szTimeDesc == "" then
                szTimeDesc = g_tStrings.ACTIVITY_TIP_STATE_END
            end
        else
            szTimeDesc = g_tStrings.ACTIVITY_TIP_STATE .. g_tStrings.STR_COLON
            local szTime = self.FormatTime(nLeftTime / 1000)
            szTimeDesc = szTimeDesc .. szTime
        end
    end
    return szTimeDesc
end

function ActivityTipData.GetActivityTipLineText(dwActivityID, nIndexTitle, nIndexValue, bFormatTime, bColor)
    local tTip = self.GetActivityTip(dwActivityID)
    if not tTip then
        return
    end

    if bColor == nil then
        bColor = true
    end

    local szTitle = tTip.tTitle[nIndexTitle]
    szTitle = szTitle and (szTitle .. ": ") or ""

    if bColor then
        szTitle = UIHelper.AttachTextColor(szTitle, FontColorID.ImportantYellow)
    end

    local tValueLine = tTip.tValue[nIndexValue] or {}
    local szValue = tValueLine.szValue or ""

    local nLeftTime = self.GetLeftTime(dwActivityID, nIndexValue)
    if nLeftTime and nLeftTime > 0 then
        local szTime = self.FormatTime(nLeftTime / 1000)
        szValue = FormatString(szValue, szTime)
    elseif bFormatTime then
        szValue = string.gsub(szValue, "(%d+)分[钟]?(%d+)秒", function(nMin, nSec)
            nMin = tonumber(nMin) or 0
            nSec = tonumber(nSec) or 0
            if nMin > 0 then
                return nMin .. g_tStrings.STR_MINUTE
            else
                return nSec .. g_tStrings.STR_SECOND
            end
        end)
    end

    return szTitle .. szValue
end

function ActivityTipData.GetLeftTime(dwActivityID, nIndexValue)
    local tTip = self.GetActivityTip(dwActivityID)
    if not tTip then
        return
    end

    if nIndexValue then
        local tValueLine = tTip.tValue[nIndexValue] or {}
        local nLeftTime = tValueLine.nEndTime and (tValueLine.nEndTime - GetTickCount())
        return nLeftTime
    else
        local nLeftTime = tTip.nEndTime - GetTickCount()
        return nLeftTime
    end
end

function ActivityTipData.FormatTime(nTime)
    local szTime = ""
    local nShowTime = math.floor(nTime / TIME_MINUTE)
    if nShowTime >= 1 then
        szTime = nShowTime .. g_tStrings.STR_MINUTE --XX分钟
    else
        szTime = math.floor(nTime) .. g_tStrings.STR_SECOND --XX秒
    end
    return szTime
end

function ActivityTipData.SetupCampContribution(scriptView, dwActivityID)
    if not scriptView or not dwActivityID then
        return
    end

    scriptView:SetFontSize(20)
    scriptView:SetBtnHintVis(true)
    scriptView:SetClickCallBack(function()

        --这里填的文本是备用的，实际还是会读下面StringComman表里的内容
        local szContent = "个人贡献值规则说明\n\n" .. 
        "满足以下两条任意规则，即可进入本场攻防战利品拍卖分红排行榜，在排行榜前列的侠士，在战利品拍卖结束后，将获得拍卖分红金币.\n" ..
        "1.侠士需满足活跃分≥550\n【可前往微信公众号【剑网3】查询活跃值】\n" .. 
        "2.对抗类装备分数不低于当前阵营侠士们的平均对抗类装备分数20000以内\n\n"
        
        local tTitle = g_tTable.StringComman:Search("STR_PERSONVALUETIP")
        local szTitle = tTitle and UIHelper.GBKToUTF8(tTitle.szString)
        local tRule = g_tTable.StringComman:Search("STR_VALUETIP")
        local szRule = tRule and UIHelper.GBKToUTF8(tRule.szString)
        local tScoreTitle = g_tTable.StringComman:Search("STR_CHECKTITLE1")
        local szScoreTitle = tScoreTitle and UIHelper.GBKToUTF8(tScoreTitle.szString)

        if not string.is_nil(szTitle) and not string.is_nil(szRule) then
            szContent = szTitle .. "\n\n" .. ParseTextHelper.ParseNormalText(szRule, false) .. "\n\n"
        end
        if string.is_nil(szScoreTitle) then
            szScoreTitle = "平均装分："
        end

        local _, scriptTips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, scriptView.BtnHint, TipsLayoutDir.RIGHT_CENTER, szContent)
        
        local function _setScore(nScore, bLegal)
            if not nScore then
                nScore = self.nCampScore
                bLegal = self.bLegal
            else
                self.nCampScore = nScore
                self.bLegal = bLegal
            end

            local szScore = tostring(nScore)
            if bLegal then
                szScore = szScore .. "（装分已达成）"
            end

            scriptTips.szName = szContent .. szScoreTitle .. szScore
            scriptTips:UpdateInfo()
        end

        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        if hPlayer.GetCDLeft(APPLY_CD_ID) > 0 then
            _setScore()
            return
        end

        Event.Reg(scriptTips, "OnUpdateCampAvgEquipScore", function(nActivityID, nScore, bLegal)
            -- print("[CampData] OnUpdateCampAvgEquipScore", nActivityID, nScore, bLegal)
            if nActivityID ~= dwActivityID then
                return
            end
            _setScore(nScore, bLegal)
        end)

        RemoteCallToServer("On_Camp_GetCampAvgEquipScore", dwActivityID)
    end)
end