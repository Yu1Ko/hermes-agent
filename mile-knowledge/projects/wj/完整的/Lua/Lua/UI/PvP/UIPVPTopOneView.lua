-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPVPTopOneView
-- Date: 2022-12-16 09:12:45
-- Desc: 战场优秀表现界面 PanelPVPTopOne
-- ---------------------------------------------------------------------------------

local UIPVPTopOneView = class("UIPVPTopOneView")

local m_nLeftTimer
local TIME_NUM_COLOR = "#F0DC82"

local tExcellentIDToImgTextIndex = {
    [1] = 5,    --全场最佳
    [2] = 13,   --战无不胜
    [3] = 5,    --全场最佳
    [4] = 14,   --最佳连伤
    [5] = 16,   --最佳治疗
    [6] = 3,    --击伤第一
    [7] = 15,   --最佳协伤
    [8] = 6,    --伤害第一
    [9] = 0,    --空的
    [10] = 1,   --超神
    [11] = 17,  --最佳助攻
    [12] = 11,  --一击必杀
    [13] = 2,   --汗马功劳
    [14] = 9,   --万劫不灭
    [15] = 4,   --凌波微步
    [16] = 12,  --斩将搴旗
    [17] = 8,   --万夫莫开
    [18] = 7,   --神输鬼运
    [19] = 7,   --神输鬼运
    [20] = 10,  --眼疾手快
    [21] = 12,  --斩将搴旗
    [22] = 1,   --超神
    [23] = 0,   --富甲一方 TODO
    [24] = 0,   --势破星阵 TODO
}

function UIPVPTopOneView:OnEnter(tExcellentData, nBanishTime, funcCloseCallback)
    if not tExcellentData then
        LOG.ERROR("[BattleField] UIPVPTopOneView, tExcellentData is nil")
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.funcCloseCallback = funcCloseCallback

        self:InitImgText()

        self:SetCountDown(nBanishTime)

        local t = {}
        for k, v in ipairs(tExcellentData) do
            local tInfo = g_tTable.BFArenaExcellent:Search(v)
            table.insert(t, tInfo)
        end
        
        local fnSort = function(tLeft, tRight)
            return tLeft.nIndex < tRight.nIndex
        end
        table.sort(t, fnSort)

        self.tLine = t[1]
        self.nExcellentID = self.tLine and self.tLine.dwID or 1
        self:UpdateInfo()
    end
end

function UIPVPTopOneView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    Event.Dispatch(EventType.HideAllHoverTips)
end

function UIPVPTopOneView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        if self.funcCloseCallback then
            self.funcCloseCallback()
        else
            BattleFieldData.OpenBattleFieldSettle()
        end
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnHelpMessage, EventType.OnClick, function()
        if self.tLine and not string.is_nil(self.tLine.szTip) then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelpMessage, TipsLayoutDir.RIGHT_CENTER, UIHelper.GBKToUTF8(self.tLine.szTip))
        end
    end)
end

function UIPVPTopOneView:RegEvent()
    Event.Reg(self, EventType.OnClientPlayerLeave, function(nPlayerID)
        UIMgr.Close(self)
    end)
end

function UIPVPTopOneView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPVPTopOneView:UpdateInfo()
    local player = GetClientPlayer()
    local szPlayerName = player and player.szName or ""
    UIHelper.SetString(self.LabelPlayerName, UIHelper.TruncateStringReturnOnlyResult(UIHelper.GBKToUTF8(szPlayerName), 7))

    LOG.INFO("UIPVPTopOneView.nExcellentID %s", tostring(self.nExcellentID))
    local nImgTextIndex = self.nExcellentID and tExcellentIDToImgTextIndex[self.nExcellentID]
    for i = 1, self.nChildCount do
        UIHelper.SetVisible(self["ImgText" .. i], i == nImgTextIndex)
    end
end

function UIPVPTopOneView:InitImgText()
    --ImgText1 ~ ImgText17
    local tChildren = UIHelper.GetChildren(self.WidgetAchievementText)
    self.nChildCount = (tChildren and #tChildren) or 0
    for _, child in ipairs(tChildren) do
        local szName = child:getName()
        self[szName] = child
    end
end

function UIPVPTopOneView:SetCountDown(nEndTime)
    if not nEndTime then return end

    m_nLeftTimer = nEndTime - GetCurrentTime()
    if m_nLeftTimer < 0 then
        m_nLeftTimer = 0
    end
    self:SetTipsTime(m_nLeftTimer)
    if m_nLeftTimer > 0 then
        Timer.DelAllTimer(self)
        Timer.AddCountDown(self, m_nLeftTimer, function()
            m_nLeftTimer = m_nLeftTimer - 1
            self:SetTipsTime(m_nLeftTimer)
        end)
    end

end

function UIPVPTopOneView:SetTipsTime(nTime)
    local szContent
    if BattleFieldData.IsInBattleField() then
        --"将在XX秒后传出战场"
        szContent = string.format("%s<color=%s>%d</color>%s%s", g_tStrings.STR_NEW_BANISH_1,
        TIME_NUM_COLOR, nTime, g_tStrings.STR_NEW_BANISH_2, g_tStrings.STR_BATTLEFIELD_NAME)
    end

    UIHelper.SetRichText(self.RichTextTips, szContent)

    --UIHelper.SetString(self.LabelTipsNum, string.format("%d", m_nLeftTimer))
end


return UIPVPTopOneView