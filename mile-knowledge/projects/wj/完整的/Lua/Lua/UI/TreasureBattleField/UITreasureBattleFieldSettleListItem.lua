-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldSettleListItem 吃鸡绝境战场结算角色信息
-- Date: 2023-05-18 10:23:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tText 	= {
	{"Name", 											"Text_PlayerName"}, 	--名字
	{PQ_STATISTICS_INDEX.DECAPITATE_COUNT, 				"Text_KillNum"}, 		--击伤
	{PQ_STATISTICS_INDEX.KILL_COUNT, 					"Text_XSNum"}, 			--协助击伤
    {PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT,		"Text_BestZGNum"},		--最佳助攻
	{PQ_STATISTICS_INDEX.HARM_OUTPUT,					"Text_HarmNum"},		--伤害量
 	{PQ_STATISTICS_INDEX.SPECIAL_OP_3,					"Text_JJFenNum"},		--个人贡献点
	{PQ_STATISTICS_INDEX.SPECIAL_OP_6,					"Text_ResultNum"},		--个人评分变化
}

local UITreasureBattleFieldSettleListItem = class("UITreasureBattleFieldSettleListItem")

function UITreasureBattleFieldSettleListItem:OnEnter(v)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(v)
end

function UITreasureBattleFieldSettleListItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldSettleListItem:BindUIEvent()

end

function UITreasureBattleFieldSettleListItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldSettleListItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldSettleListItem:UpdateInfo(v)
    local szName = v["Name"]
    local dwForceID = v["ForceID"]
    local nHitNum = v[PQ_STATISTICS_INDEX.DECAPITATE_COUNT]
    local nHelpHitNum = v[PQ_STATISTICS_INDEX.KILL_COUNT]
    local nAssistNum = v[PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT]
    local nHurtNum = v[PQ_STATISTICS_INDEX.HARM_OUTPUT]
    local nSpOp3Num = v[PQ_STATISTICS_INDEX.SPECIAL_OP_3]
    local nSpOp6Num = v[PQ_STATISTICS_INDEX.SPECIAL_OP_6]

    UIHelper.SetString(self.LabelPlayerName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(szName), 6))
    UIHelper.SetString(self.LabelHitNum, nHitNum)
    UIHelper.SetString(self.LabelHelpHitNum, nHelpHitNum)
    UIHelper.SetString(self.LabelAssistNum, nAssistNum)
    UIHelper.SetString(self.LabelHurtNum, nHurtNum)
    UIHelper.SetString(self.LabelSpOp3Num, nSpOp3Num)
    UIHelper.SetString(self.LabelSpOp6Num, nSpOp6Num)

    UIHelper.SetString(self.LabelRewardNum, 0)
    if v[PQ_STATISTICS_INDEX.AWARD_1] ~= 0 then
        UIHelper.SetString(self.LabelRewardNum, v[PQ_STATISTICS_INDEX.AWARD_1])
    end
    if v[PQ_STATISTICS_INDEX.AWARD_2] ~= 0 then
        UIHelper.SetString(self.LabelRewardNum, v[PQ_STATISTICS_INDEX.AWARD_2])
    end
    if v[PQ_STATISTICS_INDEX.AWARD_3] ~= 0 then
        UIHelper.SetString(self.LabelRewardNum, v[PQ_STATISTICS_INDEX.AWARD_3])
    end

    local dwPlayerID, dwMiniAvatarID, nRoleType = nil, 0, nil

    if not self.widgetHead then
        self.widgetHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
    end
    local bFound = false
    TeamData.Generator(function (dwID, tMemberInfo)
        if tMemberInfo.szName == szName then
            self.widgetHead:SetHeadInfo(dwID, tMemberInfo.dwMiniAvatarID, tMemberInfo.nRoleType, tMemberInfo.dwForceID)
            dwPlayerID, dwMiniAvatarID, nRoleType, dwForceID = dwID, tMemberInfo.dwMiniAvatarID, tMemberInfo.nRoleType, tMemberInfo.dwForceID
            bFound = true
        end
    end)
    if not bFound then
        self.widgetHead:SetHeadInfo(nil, 0, nil, dwForceID)
    end

    if self.widgetHead then
        self.widgetHead:SetClickCallback(function ()
            if self.WidgetPersonalCard then
                UIHelper.RemoveAllChildren(self.WidgetPersonalCard)
                UIHelper.SetVisible(self.WidgetPersonalCard, true)
                local tipsScriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCard, v.GlobalID)
                if tipsScriptView then
                    tipsScriptView:OnEnter(v.GlobalID)
                    tipsScriptView:SetPlayerId(dwPlayerID)
                    local tInfo = {
                        szName = UIHelper.GBKToUTF8(v.Name),
                        dwPlayerID = dwPlayerID,
                        dwMiniAvatarID = dwMiniAvatarID,
                        nRoleType = nRoleType,
                        dwForceID = dwForceID,
                    }
                    tipsScriptView:SetPersonalInfo(tInfo)
                end
            end
        end)
    end
end

function UITreasureBattleFieldSettleListItem:SetWidgetPersonalCard(WidgetPersonalCard)
    self.WidgetPersonalCard = WidgetPersonalCard
end

return UITreasureBattleFieldSettleListItem