-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPvPCampActivityList
-- Date: 2023-02-24 16:54:30
-- Desc: WidgetPvPCampActivityList
-- ---------------------------------------------------------------------------------

local UIWidgetPvPCampActivityList = class("UIWidgetPvPCampActivityList")

local tCampFuncData = {
    [CampFuncType.Activity] = {
        fnAction = function()
            UIMgr.Open(VIEW_ID.PanelActivityCalendar, ACTIVITY_TYPE.CONFRONT)
        end,
        szImgPath = "UIAtlas2_Pvp_PVPCamp2_icon_calendar.png",
        szTitle = "活动日历",
        szDesc = "可查看当前时间开放的阵营玩法",
    },
    [CampFuncType.CampMaps] = {
        fnAction = function()
            if CheckPlayerIsRemote() then
                return
            end

            local hPlayer = GetClientPlayer()
            if not hPlayer then
                return
            end

            if hPlayer.nCamp == CAMP.NEUTRAL then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_OPEN_CAMPMAPS_LIMIT)
                return
            end

            UIMgr.Open(VIEW_ID.PanelCampMap)
        end,
        szImgPath = "UIAtlas2_Pvp_PVPCamp2_icon_sandtable.png",
        szTitle = "战争沙盘",
        szDesc = "可查看【逐鹿中原】玩法的阵营据点态势",
    },
    [CampFuncType.SwitchServerPK] = {
        fnAction = function()
            UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
        end,
        szImgPath = "UIAtlas2_Pvp_PVPCamp2_icon_confront.png",
        szTitle = "千里伐逐",
        szDesc = "可进入【千里伐逐】玩法的不同服务器",
    },
    [CampFuncType.RankList] = {
        fnAction = function()
            UIMgr.Open(VIEW_ID.PanelFengYunLu, FengYunLuCategory.Normal, 5) --打开风云录界面，并选中个人排名-阵营英雄五十强
        end,
        szImgPath = "UIAtlas2_Pvp_PVPCamp2_icon_hero.png",
        szTitle = "阵营英雄五十强",
        szDesc = "可查看上周战阶积分服务器排名前50的玩家",
    },
    [CampFuncType.BigThing] = {
        fnAction = function()
            UIMgr.Open(VIEW_ID.PanelCityHistoryPop, CUSTOM_RECORDING_TYPE.CAMP_SYSTEM)
        end,
        szImgPath = "UIAtlas2_Pvp_PVPCamp2_Icon_History.png",
        szTitle = "阵营大事记",
        szDesc = "可查看阵营攻防相关的近期历史事件",
    }
}

function UIWidgetPvPCampActivityList:OnEnter(nCampFuncType, scriptCamp)
    self.nCampFuncType = nCampFuncType
    self.scriptCamp = scriptCamp

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetPvPCampActivityList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPvPCampActivityList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCalendar, EventType.OnClick, function()
        if self.scriptCamp and self.scriptCamp.CloseTips then
            self.scriptCamp:CloseTips()
        end

        local tData = tCampFuncData[self.nCampFuncType]
        if tData and tData.fnAction then
            tData.fnAction()
        end
    end)
end

function UIWidgetPvPCampActivityList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPvPCampActivityList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPvPCampActivityList:UpdateInfo()
    UIHelper.SetSelected(self.ToggleCalendar, false)

    local tData = tCampFuncData[self.nCampFuncType]
    if tData then
        UIHelper.SetSpriteFrame(self.ImgTask, tData.szImgPath)
        UIHelper.SetSpriteFrame(self.ImgTask1, tData.szImgPath)
        UIHelper.SetString(self.LabelTitle, tData.szTitle)
        UIHelper.SetString(self.LabelExplain, tData.szDesc)
    end

end

return UIWidgetPvPCampActivityList