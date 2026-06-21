-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelStatisticBall
-- Date: 2022-11-07 20:11:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelStatisticBall = class("UIPanelStatisticBall")

local STAT_TYPE2NAME = {
    [STAT_TYPE.DAMAGE] = "伤害",
    [STAT_TYPE.THERAPY] = "治疗",
    [STAT_TYPE.BE_DAMAGE] = "承伤",
    [STAT_TYPE.HATRED] = "仇恨",
}

local STAT_TYPE2BG = {
    [STAT_TYPE.DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_imge_omen_dps.png",
    [STAT_TYPE.THERAPY] = "UIAtlas2_HurtStatistics_HurtStatistics_imge_omen_cure.png",
    [STAT_TYPE.BE_DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_imge_omen_tank.png",
    [STAT_TYPE.HATRED] = "UIAtlas2_HurtStatistics_HurtStatistics_imge_omen_aggro.png",
}

function UIPanelStatisticBall:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    FightSkillLog.Start()

    if self.hurtStatisticsScript then
        UIHelper.RemoveAllChildren(self.WidgetStatisticsParent)
        self.hurtStatisticsScript = nil
    end
    if self.targetListScript then
        UIHelper.RemoveAllChildren(self.WidgetTargetFocusParent)
        self.targetListScript = nil
    end
    self.hurtStatisticsScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHurtStatistics, self.WidgetStatisticsParent, STAT_TYPE.DAMAGE, self)
    self.targetListScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTargetFocusList, self.WidgetTargetFocusParent, self)
    self.seeMeListScript = self.seeMeListScript or UIHelper.AddPrefab(PREFAB_ID.WidgetWhoSeeMeList, self.WidgetWhoSeeMeParent, self)
    UIHelper.SetVisible(self.BtnHurtStatistics, Storage.HurtStatisticSettings.IsStatisticOpen)
    UIHelper.SetVisible(self.TogTargetFocus, JX_TargetList.IsShow())
    UIHelper.SetVisible(self.BtnWhoSeeMe, Storage.HurtStatisticSettings.IsSeeMeOpen)

    self:UpdateVisible()

    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.BtnHurtStatistics)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogTargetFocus)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.BtnWhoSeeMe)

    local tbSizeInfo = MainCityCustomData.GetFontSizeInfo()
	if tbSizeInfo then
		UIHelper.SetScale(self._rootNode, tbSizeInfo["nDps"]  or 1, tbSizeInfo["nDps"] or 1)
	end
end

function UIPanelStatisticBall:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelStatisticBall:BindUIEvent()
    UIHelper.SetTouchEnabled(self.LayoutHurt, true)
    UIHelper.BindFreeDrag(self, self.BtnHurtStatistics)
    UIHelper.BindFreeDrag(self, self.TogTargetFocus)
    UIHelper.BindFreeDrag(self, self.LayoutHurt)
    UIHelper.BindFreeDrag(self, self.BtnWhoSeeMe)

    UIHelper.BindUIEvent(self.TogTargetFocus, EventType.OnSelectChanged, function(tog, bSelected)
        if bSelected then
            self.targetListScript:RefreshList()
        end
    end)
end

function UIPanelStatisticBall:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function(nMode)
        UIHelper.UpdateNodeInsideScreen(self._rootNode)
    end)

    --Event.Reg(self, "ON_CHANGE_FONT_SIZE", function(tbSizeType)
    --    UIHelper.SetScale(self._rootNode, tbSizeType["nTeam"], tbSizeType["nTeam"])
    --end)
--
    --Event.Reg(self, "ON_CHANGE_MAINCITYPOSITION", function(nMode)
    --    local tbSizeInfo = Storage.ControlMode.tbMainCityNodeScaleType[nMode]
    --    UIHelper.SetScale(self._rootNode, tbSizeInfo["nTeam"], tbSizeInfo["nTeam"])
    --end)

    Event.Reg(self, EventType.SwitchStatistVisibility, function()
        local bShow = not UIHelper.GetVisible(self.BtnHurtStatistics)
        UIHelper.SetVisible(self.BtnHurtStatistics, bShow)
        Storage.HurtStatisticSettings["IsStatisticOpen"] = bShow
        GameSettingData.StoreNewValue(UISettingKey.ShowFightData, bShow)
        Event.Dispatch("OnStatistVisibilityChanged")
        self:UpdateVisible()
    end)

    Event.Reg(self, EventType.SwitchWhoSeeMeVisibility, function()
        local bShow = not UIHelper.GetVisible(self.BtnWhoSeeMe)
        UIHelper.SetVisible(self.BtnWhoSeeMe, bShow)
        Storage.HurtStatisticSettings["IsSeeMeOpen"] = bShow
        GameSettingData.StoreNewValue(UISettingKey.ShowWhoSeeMe, bShow)
        Event.Dispatch("OnWhoSeeMeVisibilityChanged")
        local bSelected = UIHelper.GetSelected(self.BtnWhoSeeMe)
        UIHelper.SetVisible(self.WidgetWhoSeeMeParent, bShow and bSelected)
        self:UpdateVisible()
    end)

    Event.Reg(self, EventType.SwitchFocusVisibility, function(bNotifyChangeOnly)
        local bShow
        if bNotifyChangeOnly == true then
            bShow = JX_TargetList.IsShow()
        else
            bShow = not UIHelper.GetVisible(self.TogTargetFocus)
            JX_TargetList.SetVisible(bShow)
        end

        if bShow and BattleFieldData.IsInMobaBattleFieldMap() then
            bShow = false
            TipsHelper.ShowNormalTip("该玩法暂不支持")
        end

        if bShow and BattleFieldData.IsInXunBaoBattleFieldMap() then
            bShow = false
            TipsHelper.ShowNormalTip("该玩法暂不支持")
        end

        if bShow then
            UIHelper.SetVisible(self.TogTargetFocus, bShow)
            UIHelper.SetVisible(self.WidgetTargetFocusParent, UIHelper.GetSelected(self.TogTargetFocus))
        else
            UIHelper.SetVisible(self.TogTargetFocus, bShow)
            UIHelper.SetVisible(self.WidgetTargetFocusParent, bShow)
        end

        JX_TargetList.bShowList = bShow
        if bShow then
            self.targetListScript:InitRefreshList()
        end
        Event.Dispatch("OnFocusVisibilityChanged")
        self:UpdateVisible()
    end)

    Event.Reg(self, EventType.OnSetDragNodeScale, function (tbSizeType)
        if tbSizeType then
            UIHelper.SetScale(self._rootNode, tbSizeType["nDps"] or 1, tbSizeType["nDps"] or 1)
        end
        
    end)

    Event.Reg(self, EventType.OnUpdateDragNodeCustomState, function (bSubsidiaryCustomState)
        local bStatisticsVisible = UIHelper.GetVisible(self.WidgetStatisticsParent)
        local bFocusVisible = UIHelper.GetVisible(self.WidgetTargetFocusParent)
        local bSeeMeVisible = UIHelper.GetVisible(self.WidgetWhoSeeMeParent)
        if bSubsidiaryCustomState then
            self:EnterCustomInfo(bStatisticsVisible, bFocusVisible, bSeeMeVisible)
        else
            self:ExitCustomInfo()
            self:OnEnter()
        end
    end)

    Event.Reg(self, EventType.OnSaveDragNodePosition, function ()
		local size = UIHelper.GetCurResolutionSize()
		local szNodeName = self._rootNode:getName()
		Storage.MainCityNode.tbMaincityNodePos[szNodeName] =
		{
			nX = UIHelper.GetWorldPositionX(self._rootNode),
			nY = UIHelper.GetWorldPositionY(self._rootNode),
			Height = size.height,
			Width = size.width,
		}
		Storage.MainCityNode.Dirty()
    end)

    Event.Reg(self, EventType.OnResetDragNodePosition, function (tbDefaultPositionList, nType)
        if nType ~= DRAGNODE_TYPE.DPS then
			return
		end
        local size = UIHelper.GetCurResolutionSize()
        local tbDefaultPosition = tbDefaultPositionList[DRAGNODE_TYPE.DPS]
        local nX, nY = table.unpack(tbDefaultPosition)
        local nRadioX, nRadioY = size.width / 1600, size.height / 900
        UIHelper.SetWorldPosition(self._rootNode, nX * nRadioX, nY * nRadioY)
        MainCityCustomData.ShowScaleSetTip(self, DRAGNODE_TYPE.DPS)
    end)
end

function UIPanelStatisticBall:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelStatisticBall:UpdateVisible()
    local bVisible = UIHelper.GetVisible(self.BtnHurtStatistics) or UIHelper.GetVisible(self.BtnWhoSeeMe)
    bVisible = bVisible or UIHelper.GetVisible(self.TogTargetFocus)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutHurt, true, true)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIPanelStatisticBall:UpdateInfo(nStatType, nDps)
    UIHelper.SetString(self.LabelTitle, STAT_TYPE2NAME[nStatType])
    UIHelper.SetString(self.LabelHurtStatistics, nDps)
    UIHelper.SetSpriteFrame(self.ImgBg, STAT_TYPE2BG[nStatType])
end

function UIPanelStatisticBall:UpdateFocusInfo(nFocusCount)
    UIHelper.SetString(self.LabelFocusTopNum, string.format("%d", nFocusCount))
end

function UIPanelStatisticBall:BindDrag(btn)
    UIHelper.BindFreeDrag(self, btn)
end

function UIPanelStatisticBall:EnterCustomInfo(bStatisticsVisible, bFocusVisible, bSeeMeVisible)
    UIHelper.SetVisible(self.ImgSelectZone, true)
    UIHelper.SetEnable(self.BtnHurtStatistics, false)
    UIHelper.SetEnable(self.TogTargetFocus, false)
    UIHelper.SetEnable(self.BtnWhoSeeMe, false)
    self.bStatisticsVisible = bStatisticsVisible
    self.bFocusVisible = bFocusVisible
    self.bSeeMeVisible = bSeeMeVisible
    self.bMoved = false
    local function callback()
		MainCityCustomData.ShowScaleSetTip(self, DRAGNODE_TYPE.DPS)
	end
    UIHelper.BindFreeDrag(self, self.LayoutHurt, 0, callback)
    UIHelper.SetVisible(self.BtnHurtStatistics, true)
    UIHelper.SetVisible(self.TogTargetFocus, true)
    UIHelper.SetVisible(self.BtnWhoSeeMe, true)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutHurt, true, true)
    UIHelper.SetVisible(self.WidgetStatisticsParent, true)
    self.hurtStatisticsScript:EnterCustomState(true)
    UIHelper.SetVisible(self.WidgetTargetFocusParent, false)
    UIHelper.SetVisible(self.WidgetWhoSeeMeParent, false)
    UIHelper.SetVisible(self._rootNode, true) 
end

function UIPanelStatisticBall:ExitCustomInfo()
    UIHelper.BindFreeDrag(self, self.LayoutHurt)
    UIHelper.SetVisible(self.ImgSelectZone, false)
    UIHelper.SetEnable(self.BtnHurtStatistics, true)
    UIHelper.SetEnable(self.TogTargetFocus, true)
    UIHelper.SetEnable(self.BtnWhoSeeMe, true)
    self.hurtStatisticsScript:EnterCustomState(false)
    UIHelper.SetVisible(self.WidgetStatisticsParent, self.bStatisticsVisible or false)
    UIHelper.SetVisible(self.WidgetTargetFocusParent, self.bFocusVisible or false)
    UIHelper.SetVisible(self.WidgetWhoSeeMeParent, self.bSeeMeVisible or false)
end

return UIPanelStatisticBall