-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetYangDaoSettleData
-- Date: 2026-03-04 16:16:27
-- Desc: 扬刀大会-结算界面 数据行 WidgetYangDaoSettleData WidgetYangDaoSettleDataLeft/WidgetYangDaoSettleDataRight(PanelYangDaoSettleData)
-- ---------------------------------------------------------------------------------

local UIWidgetYangDaoSettleData = class("UIWidgetYangDaoSettleData")

function UIWidgetYangDaoSettleData:OnEnter(tData, tExcellent)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tData = tData
    self.tExcellent = tExcellent
    self:UpdateInfo()
end

function UIWidgetYangDaoSettleData:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetYangDaoSettleData:BindUIEvent()
    -- UIHelper.BindUIEvent(self.BtnPriaise, EventType.OnClick, function()
    --     if self.bPraised then
    --         return
    --     end
    --     local dwPlayerID = self.tData and self.tData.dwPlayerID
    --     if not dwPlayerID then
    --         return
    --     end

    --     BattleFieldData.ReqPraise(dwPlayerID)
    --     self.bPraised = true
    --     self:UpdateBtnState()
    -- end)
end

function UIWidgetYangDaoSettleData:RegEvent()
    -- Event.Reg(self, EventType.BF_WidgetPlayerUpdatePraiseInfo, function()
    --     local dwPlayerID = self.tData and self.tData.dwPlayerID
    --     if not dwPlayerID then
    --         return
    --     end

    --     self.bPraised = BattleFieldData.IsAddPraise(dwPlayerID)
    --     self:UpdateBtnState()
    -- end)
end

function UIWidgetYangDaoSettleData:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetYangDaoSettleData:UpdateInfo()
    local tData = self.tData
    local tExcellent = self.tExcellent
    if not tData then
        return
    end

    local player = GetClientPlayer()
    local bSelf = tData.dwPlayerID == (player and player.dwID or 0)
    local szName = UIHelper.GBKToUTF8(tData.Name)
    local bMvp = tExcellent and table.contain_value(tExcellent, EXCELLENT_ID.ARENA_TOWER_MVP)

    local nKillCount = tData[PQ_STATISTICS_INDEX.DECAPITATE_COUNT] or 0 -- 击伤
    local nDamage = self:NumberToTenThousand(tData[PQ_STATISTICS_INDEX.HARM_OUTPUT] or 0, 1)  -- 伤害量
    local nHeal = self:NumberToTenThousand(tData[PQ_STATISTICS_INDEX.TREAT_OUTPUT] or 0, 1) -- 治疗量

    UIHelper.SetString(self.LabelPlayerName, szName, 6)

    UIHelper.SetString(self.LabelDamageNum, nDamage)
    UIHelper.SetString(self.LabelWoundNum, nKillCount)
    UIHelper.SetString(self.LabelHealNum, nHeal)

    -- UIHelper.SetVisible(self.ImgSelf, bSelf)
    UIHelper.SetVisible(self.ImgMvp, bMvp)
    self:UpdateBtnState()

    if bSelf then
        UIHelper.SetTextColor(self.LabelPlayerName, ArenaFinishDataColor.SelfColor)
        UIHelper.SetTextColor(self.LabelWoundNum, ArenaFinishDataColor.SelfColor)
        UIHelper.SetTextColor(self.LabelDamageNum, ArenaFinishDataColor.SelfColor)
        UIHelper.SetTextColor(self.LabelHealNum, ArenaFinishDataColor.SelfColor)
    else
        UIHelper.SetTextColor(self.LabelPlayerName, ArenaFinishDataColor.OtherColor)
        UIHelper.SetTextColor(self.LabelWoundNum, ArenaFinishDataColor.OtherColor)
        UIHelper.SetTextColor(self.LabelDamageNum, ArenaFinishDataColor.OtherColor)
        UIHelper.SetTextColor(self.LabelHealNum, ArenaFinishDataColor.OtherColor)
    end

    self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, tData.dwPlayerID)
    Timer.AddFrame(self, 1, function ()
        self.scriptHead:SetHeadInfo(0, 0, nil, tData.ForceID)
        self.scriptHead:SetHeadWithMountKungfuID(tData.dwMountKungfuID)
        self.scriptHead:SetShowSelf(bSelf)
    end)
    self.scriptHead:SetClickCallback(function ()
        if self.WidgetPersonalCard then
            UIHelper.RemoveAllChildren(self.WidgetPersonalCard)
            UIHelper.SetVisible(self.WidgetPersonalCard, true)
            local tipsScriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCard, tData.GlobalID)
            if tipsScriptView then
                tipsScriptView:OnEnter(tData.GlobalID)
                tipsScriptView:SetPlayerId(tData.dwPlayerID)
                local tInfo = {
                    szName = UIHelper.GBKToUTF8(tData.Name),
                    dwPlayerID = tData.dwPlayerID,
                    dwForceID = tData.ForceID,
                    szHeadIconPath = PlayerForceID2SchoolImg2[tData.ForceID],
                }
                tipsScriptView:SetPersonalInfo(tInfo)
            end
        end
    end)
end

function UIWidgetYangDaoSettleData:UpdateBtnState()
    UIHelper.SetVisible(self.BtnPriaise, false)
    -- local dwPlayerID = self.tData and self.tData.dwPlayerID
    -- if not dwPlayerID then
    --     return
    -- end

    -- local bShowPraise = BattleFieldData.CanAddPraise(self.tData.dwPlayerID)
    -- local nPraiseCount = BattleFieldData.GetPraiseCount(self.tData.dwPlayerID)

    -- UIHelper.SetVisible(self.BtnPriaise, bShowPraise or nPraiseCount > 0)
    -- UIHelper.SetTouchEnabled(self.BtnPriaise, not self.bPraised)
    -- UIHelper.SetSpriteFrame(self.ImgPraise, self.bPraised and ArenaPraiseIconPath.PraisedIconPath or ArenaPraiseIconPath.CanPraiseIconPath)

    -- if nPraiseCount > 0 then
    --     UIHelper.SetVisible(self.LabelPraiseNum, true)
    --     UIHelper.SetString(self.LabelPraiseNum, nPraiseCount)
    -- else
    --     UIHelper.SetVisible(self.LabelPraiseNum, false)
    -- end
end

function UIWidgetYangDaoSettleData:SetWidgetPersonalCard(WidgetPersonalCard)
    self.WidgetPersonalCard = WidgetPersonalCard
end

function UIWidgetYangDaoSettleData:NumberToTenThousand(szContent, nDecimal)
    local numVal = tonumber(szContent)
    local strVal = tostring(szContent)
    local szResult = strVal
    if numVal then
        if not IsNumber(nDecimal) or nDecimal < 0 then
            nDecimal = 0
        end
        nDecimal = math.floor(nDecimal)

        local nFloor = math.floor(numVal)
        local len = string.len(nFloor)
        -- if len > 8 then
        --     local szTemp = string.sub(strVal, 1, len - 8 + nDecimal)
        --     if nDecimal > 0 then
        --         local nTempLen = string.len(szTemp)
        --         szTemp = string.sub(szTemp, 1, nTempLen - nDecimal) .. "." .. string.sub(szTemp, nTempLen - nDecimal + 1, nTempLen)
        --     end
        --     szResult = szTemp .. "亿"
        -- elseif len > 4 then
        if len > 4 then
            local szTemp = string.sub(strVal, 1, len - 4 + nDecimal)
            if nDecimal > 0 then
                local nTempLen = string.len(szTemp)
                szTemp = string.sub(szTemp, 1, nTempLen - nDecimal) .. "." .. string.sub(szTemp, nTempLen - nDecimal + 1, nTempLen)
            end
            szResult = szTemp .. "万"
        else
            -- return string.format("%.1f", numVal)
            return string.format("%.0f", numVal)
        end
    end

    return szResult
end

return UIWidgetYangDaoSettleData