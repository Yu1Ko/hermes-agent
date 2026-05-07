-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldPopListItem
-- Date: 2023-05-17 16:22:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tText 	= {
	{"Name", 											"Text_PlayerName"}, 	--名字
	{PQ_STATISTICS_INDEX.DECAPITATE_COUNT, 				"Text_KillNum"}, 		--击伤
	{PQ_STATISTICS_INDEX.KILL_COUNT, 					"Text_XSNum"}, 			--协助击伤
	{PQ_STATISTICS_INDEX.HARM_OUTPUT,					"Text_HarmNum"},		--伤害量
 	{PQ_STATISTICS_INDEX.SPECIAL_OP_3,					"Text_JJFenNum"},		--个人贡献点

	{PQ_STATISTICS_INDEX.SPECIAL_OP_6,					"Text_ResultNum"},		--个人评分变化
	{PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT,		"Text_BestZGNum"},		--最佳助攻
}

local UITreasureBattleFieldPopListItem = class("UITreasureBattleFieldPopListItem")

function UITreasureBattleFieldPopListItem:OnEnter(v)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(v)
end

function UITreasureBattleFieldPopListItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldPopListItem:BindUIEvent()

end

function UITreasureBattleFieldPopListItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldPopListItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldPopListItem:UpdateInfo(v)
    local szName = v["Name"]
    local dwForceID = v["ForceID"]
    local nHitNum = v[PQ_STATISTICS_INDEX.DECAPITATE_COUNT]
    local nHelpHitNum = v[PQ_STATISTICS_INDEX.KILL_COUNT]
    local nAssistNum = v[PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT]
    local nHurtNum = v[PQ_STATISTICS_INDEX.HARM_OUTPUT]

    UIHelper.SetString(self.LabelName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(szName), 6))
    UIHelper.SetString(self.LabelHitNum, nHitNum)
    UIHelper.SetString(self.LabelHelpHitNum, nHelpHitNum)
    UIHelper.SetString(self.LabelAssistsNum, nAssistNum)
    UIHelper.SetString(self.LabelHurtNum, nHurtNum)

    if not self.widgetHead then
        self.widgetHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
    end
    local bFound = false
    TeamData.Generator(function (dwID, tMemberInfo)
        if tMemberInfo.szName == szName then
            self.widgetHead:SetHeadInfo(dwID, tMemberInfo.dwMiniAvatarID, tMemberInfo.nRoleType, tMemberInfo.dwForceID)
            bFound = true
        end
    end)
    if not bFound then
        self.widgetHead:SetHeadInfo(nil, 0, nil, dwForceID)
    end
end


return UITreasureBattleFieldPopListItem