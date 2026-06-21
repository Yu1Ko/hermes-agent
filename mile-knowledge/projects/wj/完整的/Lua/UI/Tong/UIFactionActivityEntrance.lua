-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFactionActivityEntrance
-- Date: 2023-05-16 16:53:11
-- Desc: 帮会活动-概览-活动组件
-- Prefab: WidgetFactionActivityEntrance
-- ---------------------------------------------------------------------------------

local UIFactionActivityEntrance = class("UIFactionActivityEntrance")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFactionActivityEntrance:_LuaBindList()
    self.BtnOpenActivity               = self.BtnOpenActivity --- 打开对应帮会活动

    self.LabelFactionActivityName      = self.LabelFactionActivityName --- 名称
    self.LabelFactionActivityCountdown = self.LabelFactionActivityCountdown --- 倒计时（若无则隐藏）
    self.LabelFactionActivityState     = self.LabelFactionActivityState --- 活动状态描述
    self.WidgetIcon                    = self.WidgetIcon --- 图标

    self.ImgGo                         = self.ImgGo --- 活动操作的箭头图标

    self.ImgActivityState              = self.ImgActivityState --- 活动开启时的图片
    self.ImgFactionActivityBg          = self.ImgFactionActivityBg  ---活动底图
end

function UIFactionActivityEntrance:OnEnter(tActivityData)
    if not tActivityData then
        return
    end

    self.tActivityData = tActivityData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFactionActivityEntrance:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFactionActivityEntrance:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOpenActivity, EventType.OnClick, function()
        local tActivityData = self.tActivityData

        local nClassID      = tActivityData.nID1
        local nSubClassID   = tActivityData.nID2

        if tActivityData.szLink then
            Event.Dispatch("EVENT_LINK_NOTIFY", tActivityData.szLink)
            return
        end

        local tRecord       = Table_GetTongActivityContent(nClassID, nSubClassID, 0)
        if not tRecord then
            return
        end

        if tActivityData.nFlag == TongData.ACTIVITY_STATE.Closed then
            -- 已结束活动在主页不显示 无操作
        elseif tActivityData.nFlag == TongData.ACTIVITY_STATE.Opening then
            -- 已开启的所有活动：弹出中地图神行界面
            if tRecord.szLinkIDList == "" then
                return
            end

            local tLinkIDList = string.split(tRecord.szLinkIDList, ";")

            local tTargetList = {}
            for _, szID in ipairs(tLinkIDList) do
                local nLinkID      = tonumber(szID)
                local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
                for _, tInfo in pairs(tAllLinkInfo) do
                    table.insert(tTargetList, tInfo)
                end
            end

            -- todo: 这个要做多个地点的话，具体方案后面定了再调整，先用第一个
            if #tTargetList ~= 0 then
                local tLink  = tTargetList[1]

                local tPoint = { tLink.fX, tLink.fY, tLink.fZ }
                MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tLink.szNpcName), tLink.dwMapID, tPoint)
                UIMgr.Open(VIEW_ID.PanelMiddleMap, tLink.dwMapID, 0)
            end
        else

            if tRecord.bCanOpen then
                -- 未开启的手动开启活动：弹出开启二次确认
                TongData.StartActivity(nClassID, nSubClassID)
            else
                -- 未开启的自动开启活动：无操作
                --Event.Dispatch("SwitchToTongActivityPage", nClassID)
            end
        end
    end)
end

function UIFactionActivityEntrance:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFactionActivityEntrance:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function _FormatTime(nTime)
    if nTime > 0 then
        local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nTime, false)
        local nDay       = math.floor(nH / 24)
        nH               = nH - nDay * 24

        local szTime     = ""
        if nDay and nDay > 0 then
            szTime = szTime .. nDay .. g_tStrings.STR_BUFF_H_TIME_D_SHORT
        end

        if nH and nH > 0 then
            szTime = szTime .. FormatString(g_tStrings.STR_MAIL_LEFT_HOURE, nH)
        end
        if nDay == 0 and nM and nM > 0 then
            szTime = szTime .. FormatString(g_tStrings.STR_MAIL_LEFT_MINUTE, nM)
        end

        if szTime == "" then
            szTime = g_tStrings.STR_MAIL_LEFT_LESS_ONE_M
        end

        return szTime
    else
        return ""
    end
end

function UIFactionActivityEntrance:UpdateInfo()
    local tActivityData = self.tActivityData

    local tRecord       = Table_GetTongActivityContent(tActivityData.nID1, tActivityData.nID2, 0) or tActivityData.tRecord
    if not tRecord then
        return
    end

    local szName = FormatString(g_tStrings.CYCLOPAEDIA_LINK_FORMAT, tRecord.szName)
    UIHelper.SetString(self.LabelFactionActivityName, UIHelper.GBKToUTF8(szName))
    if tRecord.tFontColor then
        UIHelper.SetTextColor(self.LabelFactionActivityName, tRecord.tFontColor)
    end

    if tRecord.szIconPath then
        UIHelper.SetSpriteFrame(self.WidgetIcon, tRecord.szIconPath)
    else
        UIHelper.SetItemIconByIconID(self.WidgetIcon, tRecord.dwIconID)
    end

    if tRecord.szImgBgPath then
        UIHelper.SetSpriteFrame(self.ImgFactionActivityBg, tRecord.szImgBgPath)
    end

    if tActivityData.nFlag == TongData.ACTIVITY_STATE.Closed then
        UIHelper.SetVisible(self.LabelFactionActivityCountdown, false)
        UIHelper.SetVisible(self.LabelFactionActivityState, false)
        UIHelper.SetVisible(self.ImgGo, false)
        UIHelper.SetVisible(self.ImgActivityState, false)
    elseif tActivityData.nFlag == TongData.ACTIVITY_STATE.Opening then
        UIHelper.SetVisible(self.LabelFactionActivityCountdown, true)
        UIHelper.SetVisible(self.LabelFactionActivityState, false)
        UIHelper.SetVisible(self.ImgGo, false)
        UIHelper.SetVisible(self.ImgActivityState, true)

        local szCountDown = ""
        if tActivityData.nTime > 0 then
            local nEndTime       = tActivityData.nTime
            local nRemainingTime = nEndTime - GetCurrentTime()

            local function _getCountDownTimeStr()
                local nTime  = nEndTime - GetCurrentTime()
                local szTime = _FormatTime(nTime)
                if szTime ~= "" then
                    return string.format("剩余%s", szTime)
                else
                    return ""
                end
            end

            Timer.AddCountDown(self, nRemainingTime, function()
                local szText = _getCountDownTimeStr()
                UIHelper.SetString(self.LabelFactionActivityCountdown, szText)
            end)
            szCountDown = _getCountDownTimeStr()
        elseif tActivityData.szTitle then
            szCountDown = UIHelper.GBKToUTF8(tActivityData.szTitle)
        else
            szCountDown = g_tStrings.STR_TIME_UNLIMITED
        end

        UIHelper.SetString(self.LabelFactionActivityCountdown, szCountDown)
        UIHelper.SetTextColor(self.LabelFactionActivityCountdown, cc.c3b(255, 226, 110))
    else
        -- 未开启
        UIHelper.SetVisible(self.LabelFactionActivityCountdown, not tRecord.bCanOpen)
        UIHelper.SetVisible(self.LabelFactionActivityState, tRecord.bCanOpen)
        UIHelper.SetVisible(self.ImgGo, tRecord.bCanOpen)
        UIHelper.SetVisible(self.ImgActivityState, false)

        if tRecord.bCanOpen then
            local szState = tRecord.szState or "开启"

            UIHelper.SetString(self.LabelFactionActivityState, szState)
            UIHelper.SetTextColor(self.LabelFactionActivityState, cc.c3b(255, 226, 110))
        else
            local szCountDown = ""

            if tActivityData.nTime > 0 then
                local nEndTime       = tActivityData.nTime
                local nRemainingTime = nEndTime - GetCurrentTime()

                local function _getCountDownTimeStr()
                    local nTime  = nEndTime - GetCurrentTime()
                    local szTime = _FormatTime(nTime)
                    if szTime ~= "" then
                        return string.format("%s后开启", szTime)
                    else
                        return ""
                    end
                end

                Timer.AddCountDown(self, nRemainingTime, function()
                    local szText = _getCountDownTimeStr()
                    UIHelper.SetString(self.LabelFactionActivityCountdown, szText)
                end)
                szCountDown = _getCountDownTimeStr()
            elseif tActivityData.szTitle then
                szCountDown = UIHelper.GBKToUTF8(tActivityData.szTitle)
            else
                szCountDown = g_tStrings.STR_TONG_ACTIVITY_NOT_START
            end

            UIHelper.SetString(self.LabelFactionActivityCountdown, szCountDown)
        end
    end
end

return UIFactionActivityEntrance