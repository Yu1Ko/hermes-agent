-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldInfo
-- Date: 2023-05-19 10:40:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldInfo = class("UITreasureBattleFieldInfo")

function UITreasureBattleFieldInfo:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
    Timer.AddCycle(self, 1, function ()
        self:Tick()
    end)
end

function UITreasureBattleFieldInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITreasureBattleFieldInfo:BindUIEvent()
    UIHelper.SetTouchEnabled(self.WidgetStatus, true)
    UIHelper.SetTouchDownHideTips(self.WidgetStatus, false)
    UIHelper.BindUIEvent(self.WidgetStatus, EventType.OnTouchBegan, function(node, x, y)
		TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSingleTextTips, node, TipsLayoutDir.BOTTOM_CENTER, self.szEventDes)
	end)
end

function UITreasureBattleFieldInfo:RegEvent()
    Event.Reg(self, EventType.OnTreasureBattleFieldHideTime, function ()
        self.nTimeLimit = nil
        UIHelper.SetVisible(self.WidgetStorm, false)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutBattleFieldPubg, true, false)
    end)

    Event.Reg(self, EventType.OnTreasureBattleFieldHidePlayerNum, function ()
        UIHelper.SetVisible(self.WidgetRemainder, false)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutBattleFieldPubg, true, false)
    end)

    Event.Reg(self, EventType.OnTreasureBattleFieldUpdateFrameTime, function (nPublicTime)
        local nTime = GetCurrentTime()
        self.nTimeLimit = nPublicTime + nTime
        self.nLastHintTime = nil
        UIHelper.SetVisible(self.WidgetStorm, true)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutBattleFieldPubg, true, false)
    end)

    Event.Reg(self, EventType.OnTreasureBattleFieldUpdateFramePlayerNum, function (nAlivePlayer)
        if BattleFieldData.IsInXunBaoBattleFieldMap() then
            return
        end

        UIHelper.SetString(self.LabelRemainder, string.format("剩余: %d", nAlivePlayer))
        UIHelper.SetVisible(self.WidgetRemainder, true)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutBattleFieldPubg, true, false)
        self.nAlivePlayer = nAlivePlayer
    end)

    Event.Reg(self, EventType.OnTreasureHuntInfoOpen, function (dwID, nTime)
        self:UpdateMapEvent(dwID, nTime)
    end)

    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function (tbInfo)
        if tbInfo.szName ~= "ThermometerPanel" then
            return
        end
        self:UpdateTemperature(tbInfo.nMolecular)
        UIHelper.SetVisible(self.WidgetStatus, true)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutBattleFieldPubg, true, false)
    end)

    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function (szName)
        if szName ~= "ThermometerPanel" then
            return
        end
        UIHelper.SetVisible(self.WidgetStatus, false)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutBattleFieldPubg, true, false)
    end)

    Event.Reg(self, EventType.ShowTreasureBattleFieldPlayerNumHint, function()
        if self.nAlivePlayer then
            local tbData = {
                szText = string.format("剩余%d人", self.nAlivePlayer),
                szImagePath = "UIAtlas2_Public_PublicHint_PublicHint_HintChiJi2",
                bRichText = false,
                callback = function(node) end
            }
            Event.Dispatch(EventType.ShowTreasureBattleFieldHint, tbData)
        end
    end)
end

function UITreasureBattleFieldInfo:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldInfo:UpdateInfo()
    UIHelper.SetVisible(self.WidgetStatus, false)
    UIHelper.SetVisible(self.WidgetRemainder, false)
    UIHelper.SetVisible(self.WidgetStorm, false)
    UIHelper.SetVisible(self.WidgetSafeArean, false)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutBattleFieldPubg, true, false)
end

function UITreasureBattleFieldInfo:UpdateTemperature(nTemperature)
    local szText
    local szFramePath
    if nTemperature < 10 then
        szText = "极寒"
        szFramePath = "UIAtlas2_BattleFieldPubg_BattleFieldPubg1_icon_hanleng.png"
    elseif nTemperature < 30 then
        szText = "寒冷"
        szFramePath = "UIAtlas2_BattleFieldPubg_BattleFieldPubg1_icon_hanleng.png"
    else
        szText = "正常"
        szFramePath = "UIAtlas2_BattleFieldPubg_BattleFieldPubg1_icon_yanre.png"
    end
    UIHelper.SetSpriteFrame(self.ImgStatus, szFramePath)
    UIHelper.SetString(self.LabelStatus, szText)
end

function UITreasureBattleFieldInfo:UpdateMapEvent(dwID, nTime)
    dwID = dwID or PvpExtractData.GetCurEventID()
    if not dwID then
        return
    end

    if self.nMapEventID and self.nMapEventID == dwID then
        return
    end

    local tEffectInfo = Table_GetTreasureHuntEffect(dwID)
    if not tEffectInfo then
        return
    end

    if string.is_nil(tEffectInfo.szDesc) then
        return
    end

    local szText
    local szFramePath
    self.nMapEventID = dwID
    self.szEventDes = UIHelper.GBKToUTF8(tEffectInfo.szDesc)

    szText = UIHelper.GBKToUTF8(tEffectInfo.szTitle)
    local tbText = string.split(tEffectInfo.szImagePath, "/")

    szFramePath = tbText[#tbText - 1] .. "_".. string.gsub(tbText[#tbText], ".UITex", "")
    szFramePath = "Resource_" .. szFramePath .. "_" .. tostring(tEffectInfo.nFrame)

    UIHelper.SetString(self.LabelStatus, szText)
    UIHelper.SetSpriteFrame(self.ImgStatus, szFramePath)
    UIHelper.LayoutDoLayout(self.WidgetStatus)
    UIHelper.SetVisible(self.WidgetStatus, true)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutBattleFieldPubg, true, false)
end

function UITreasureBattleFieldInfo:StormCountDown()
    if self.nTimeLimit then
        local nTime = GetCurrentTime()
		local nPoor = math.max(0, self.nTimeLimit - nTime)
        UIHelper.SetString(self.LabelStorm, nPoor .. "秒")

        local tbHintTime = {1,2,3,10,30,60}
        if table.contain_value(tbHintTime, nPoor) and nPoor ~= self.nLastHintTime then
            local tbData = {
                szText = string.format("距离下次缩圈还剩%d秒", nPoor),
                szImagePath = "UIAtlas2_Public_PublicHint_PublicHint_HintChiJi1",
                bRichText = false,
                callback = function(node) end
            }
            Event.Dispatch(EventType.ShowTreasureBattleFieldHint, tbData)
            self.nLastHintTime = nPoor
        end
    end
end

function UITreasureBattleFieldInfo:Tick()
    local player = g_pClientPlayer
    if not player then
        return
    end

    if BattleFieldData.IsInXunBaoBattleFieldMap() then
        self:UpdateMapEvent()
        return
    end

    self:StormCountDown()

    local tCircle
    local nIndexSafe = TreasureBattleFieldData.tSafeMapCircle[player.GetMapID()]
    if nIndexSafe then
        tCircle = TreasureBattleFieldData.tCircle[nIndexSafe]
    end
    local szDisText = "安全"
    if not tCircle then
        szDisText = "无"
    else
        local distance = math.sqrt((player.nX - tCircle.nEndX) ^ 2 + (player.nY - tCircle.nEndY) ^ 2) / 64
        if distance > tCircle.fEndtDistance then -- 安全区外
            local nDis = distance - tCircle.fEndtDistance
            if nDis >= 10 then
                nDis = string.format("%d", nDis)
            else
                nDis = string.format("%.1f", nDis)
            end
            szDisText = string.format("%s尺", nDis)
        end
    end
    UIHelper.SetString(self.LabelSafeArean, szDisText)
    UIHelper.SetVisible(self.WidgetSafeArean, true)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutBattleFieldPubg, true, false)
end

return UITreasureBattleFieldInfo