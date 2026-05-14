-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPVPFieldMyRecordView
-- Date: 2023-12-14 14:34:23
-- Desc: 战场-我的战绩 界面 PanelBattleMvpSettle
-- ---------------------------------------------------------------------------------

local UIPVPFieldMyRecordView = class("UIPVPFieldMyRecordView")

local tRecordInfo = {}

local tImgPath = {
    [PQ_STATISTICS_INDEX.SPECIAL_OP_6]              = "UIAtlas2_Pvp_PVPImpasse_img_07", --连伤
    [PQ_STATISTICS_INDEX.DECAPITATE_COUNT]          = "UIAtlas2_Pvp_PVPImpasse_img_09", --击伤
    [PQ_STATISTICS_INDEX.HARM_OUTPUT]               = "UIAtlas2_Pvp_PVPImpasse_img_07", --伤害量
    [PQ_STATISTICS_INDEX.INJURY]                    = "UIAtlas2_Pvp_PVPImpasse_img_11", --承伤
    [PQ_STATISTICS_INDEX.KILL_COUNT]                = "UIAtlas2_Pvp_PVPImpasse_img_10", --协伤
    [PQ_STATISTICS_INDEX.BEST_ASSIST_KILL_COUNT]    = "UIAtlas2_Pvp_PVPImpasse_img_12", --助攻
    [PQ_STATISTICS_INDEX.TREAT_OUTPUT]              = "UIAtlas2_Pvp_PVPImpasse_img_13", --治疗
}

function UIPVPFieldMyRecordView:OnEnter(tMyData, tData, nBanishTime)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:InitRecordInfo()

        Timer.AddFrameCycle(self, 1, function()
            self:UpdateTime()
        end)
    end

    self.tMyData        = tMyData
    self.tData          = tData
    self.nBanishTime    = nBanishTime

    self:UpdateInfo()
end

function UIPVPFieldMyRecordView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPVPFieldMyRecordView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function()
        BattleFieldData.LeaveBattleField()
    end)
    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPVPFieldMyRecordView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPVPFieldMyRecordView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPVPFieldMyRecordView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutMvpCard)

    local tMyData           = self.tMyData
    local tData             = self.tData
    local hPlayer           = GetClientPlayer()
    local dwKungfuMountID   = hPlayer.GetKungfuMountID()
    if not dwKungfuMountID then
        return
    end
    local bDPS              = KungfuMount_IsDPS(dwKungfuMountID)
    for i, v in ipairs(tRecordInfo) do
        if (bDPS and v.bDPS) or (not bDPS and not v.bDPS) then
            local szName = UIHelper.GBKToUTF8(v.szName)
            local nValue = tMyData[PQ_STATISTICS_INDEX[v.szKey]]
            local szImgPath = tImgPath[PQ_STATISTICS_INDEX[v.szKey]]
            local bBreak = nValue > tData[BF_MAP_ROLE_INFO_TYPE[v.szRoleKey]]
            UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerMvpNum, self.LayoutMvpCard, szName, nValue, szImgPath, bBreak)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutMvpCard)
    UIHelper.WidgetFoceDoAlign(self.LayoutMvpCard)
end

function UIPVPFieldMyRecordView:InitRecordInfo()
	if GetTableCount(tRecordInfo) ~= 0 then
		return
	end
		
	local nCount = g_tTable.BattleFieldRecord:GetRowCount()

	for i = 2, nCount do
		local tLine = g_tTable.BattleFieldRecord:GetRow(i)
		table.insert(tRecordInfo, tLine)
	end
end

function UIPVPFieldMyRecordView:UpdateTime()
    local nCurTime = GetCurrentTime()
    if self.nBanishTime and self.nBanishTime > nCurTime then
        local nTime = self.nBanishTime - nCurTime
        -- UIHelper.SetString(self.LabelNum, tostring(nTime))
        -- UIHelper.SetVisible(self.LabelTime, true)

        local szContent = string.format("<color=#d7f6ff>将在</c><color=#ffe26e>%s秒</c><color=#d7f6ff>后传出战场</c>", nTime)
        UIHelper.SetRichText(self.RichTextTime, szContent)
        UIHelper.SetVisible(self.RichTextTime, true)
    else
        self.nBanishTime = nil
        -- UIHelper.SetVisible(self.LabelTime, false)
        UIHelper.SetVisible(self.RichTextTime, false)
    end
end

return UIPVPFieldMyRecordView