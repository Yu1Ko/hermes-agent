-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetXunBaoHintCell
-- Date: 2025-04-25 09:56:34
-- Desc: ?
-- ---------------------------------------------------------------------------------
local RESULE_TIME = 3 --撤离提示3s后消失
local REMAIN_TIME = 5 --5s后消失
local EXTRACT_COUNTER_ID = 2 -- 撤离倒计时ID
local UIWidgetXunBaoHintCell = class("UIWidgetXunBaoHintCell")

function UIWidgetXunBaoHintCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetXunBaoHintCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetXunBaoHintCell:BindUIEvent()
    
end

function UIWidgetXunBaoHintCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetXunBaoHintCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetXunBaoHintCell:ResetState()
    if self.nResultTimer then
        return
    end

    if self.nRemainTimer then
        Timer.DelTimer(self, self.nRemainTimer)
        self.nRemainTimer = nil
    end

    if self.nExtractTimer then
        Timer.DelTimer(self, self.nExtractTimer)
        self.nExtractTimer = nil
    end

    if self.nCloseTimer then
        Timer.DelTimer(self, self.nCloseTimer)
        self.nCloseTimer = nil
    end

    self.bReaminingTime = false
    self.bExtractCounter = false

    UIHelper.SetVisible(self.ImgXunBaoBg, false)
    UIHelper.SetVisible(self.ImgXunBaoHint, false)
    UIHelper.SetVisible(self.LabelEventName, false)
    UIHelper.SetVisible(self.LabelEventTime, false)
    UIHelper.SetVisible(self.Eff_Tip, false)
    UIHelper.SetVisible(self.Eff_CountDown, false)

    for index, node in ipairs(self.tbSettlementResultEff) do
        UIHelper.SetVisible(node, false)
    end
end

function UIWidgetXunBaoHintCell:ShowExtractCounter(dwID, nCount)
    if self.nResultTimer then
        return
    end

    if dwID and dwID ~= EXTRACT_COUNTER_ID then
        self:OnClose()
        return
    elseif not nCount or nCount <= 0 then
        self:OnClose()
        return
    end

    if not self.bExtractCounter then
        self:ResetState()
        UIHelper.SetVisible(self.ImgXunBaoBg, true)
        UIHelper.SetVisible(self.LabelEventName, true)
        UIHelper.SetVisible(self.LabelEventTime, true)
        UIHelper.SetVisible(self.Eff_CountDown, true)
        UIHelper.SetString(self.LabelEventName, "即将撤离")
        UIHelper.PlayAni(self, self.AniHintXunbaoHint, "AniHintXunbaoShow")
    end

    if self.nCloseTimer then
        Timer.DelTimer(self, self.nCloseTimer)
        self.nCloseTimer = nil
    end

    self.nExtractTimer = Timer.AddCountDown(self, REMAIN_TIME, nil, function()
        self:OnClose()
    end)

    self.bExtractCounter = true
    UIHelper.SetString(self.LabelEventTime, tostring(nCount))
    UIHelper.SetSpriteFrame(self.ImgXunBaoBg, tbExtractHintBg[2])
    UIHelper.PlayAni(self, self.AniHintXunbaoHint, "AniEventTime")
end

function UIWidgetXunBaoHintCell:ShowExtractReaminingTime(nSecond)
    if self.nResultTimer then
        return
    end

    self:ResetState()
    if nSecond <= 0 then
        return
    end

    local function fnSetLabel(nRemain)
        local nCount = nSecond - nRemain
        local nM = math.floor(nCount / 60)
        local nS = nCount % 60

        local text = ""
        text = string.format("%02d:%02d", nM, nS)
        UIHelper.SetString(self.LabelEventTime, text)
    end

    self.nRemainTimer = Timer.AddCountDown(self, REMAIN_TIME, function (nRemain)
        fnSetLabel(REMAIN_TIME - nRemain)
    end, function()
        self.bReaminingTime = false
        self:OnClose()
    end)

    self.bReaminingTime = true
    fnSetLabel(0)
    UIHelper.SetVisible(self.ImgXunBaoBg, true)
    UIHelper.SetVisible(self.LabelEventName, true)
    UIHelper.SetVisible(self.LabelEventTime, true)
    UIHelper.SetString(self.LabelEventName, "请尽快前往撤离点")
    UIHelper.SetSpriteFrame(self.ImgXunBaoBg, tbExtractHintBg[1])
    UIHelper.PlayAni(self, self.AniHintXunbaoHint, "AniHintXunbaoShow")
end

function UIWidgetXunBaoHintCell:ShowExtractSettlement(tbInfo)
    if not tbInfo then
        return
    end

    if self.nResultTimer then
        Timer.DelTimer(self, self.nResultTimer)
        self.nResultTimer = nil
    end

    self:ResetState()
    local bSuccess = true
    if PlayerData.IsPlayerDeath() then
        bSuccess = false
    end
    local nPathIndex = bSuccess and 2 or 1

    UIHelper.SetVisible(self.ImgXunBaoHint, true)
    UIHelper.SetVisible(self.ImgXunBaoBg, true)
    UIHelper.SetVisible(self.tbSettlementResultEff[nPathIndex], true)

    UIHelper.SetSpriteFrame(self.ImgXunBaoHint, tbExtractResultImg[nPathIndex])
    UIHelper.SetSpriteFrame(self.ImgXunBaoBg, tbExtractHintBg[nPathIndex])
    UIHelper.PlayAni(self, self.AniHintXunbaoHint, "AniHintXunbaoShow")

    self.nResultTimer = Timer.Add(self, RESULE_TIME, function()
        self.nResultTimer = nil
        self:ResetState()
        UIMgr.Open(VIEW_ID.PanelBattleFieldXunBaoSettlement, tbInfo)
    end)
end

function UIWidgetXunBaoHintCell:OnClose()
    self.nCloseTimer = self.nCloseTimer or Timer.Add(self, 0.5, function()
        UIHelper.PlayAni(self, self.AniHintXunbaoHint, "AniHintXunbaoHide", function()
            self:ResetState()
        end)
    end)
end

return UIWidgetXunBaoHintCell