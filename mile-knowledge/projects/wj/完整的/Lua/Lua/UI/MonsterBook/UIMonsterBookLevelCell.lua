local UIMonsterBookLevelCell = class("UIMonsterBookLevelCell")
local LEVEL_PER_GROUP = 10
local LEVEL_STATE = 
{
    UNABLE = 0,
    ENABLE = 1,
    PASSED = 2,
}
local STEP = 
{
    GOTO         = -1,  -- 定向转移
    START        = 0,   -- 初始化
    GUESS        = 1,   -- 随机跃迁-预测
    GUESS_WAIT   = 1.5, -- 随机跃迁-等待队友预测
    ROLL         = 2,   -- 随机跃迁-掷骰子
    ROLL_END     = 2.5, -- 随机跃迁-掷骰子完毕
    JUMP         = 3,   -- 随机跃迁-走格子
    EFFECT       = 4,   -- 随机跃迁-显示结果
}

local function CanChangeBoss(nLevel)
    if nLevel == 90 or nLevel == 100 then
        return true
    end
    return false
end

function UIMonsterBookLevelCell:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(tData)
end

function UIMonsterBookLevelCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookLevelCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        self.tData.fCallBack()
        if self.tData.nEffectID > 0 then
            local nLevel = self.tData.nLevel
            local szBossName = self.tData.szBossName
            local szEffectName = UIHelper.GBKToUTF8(self.tData.tEffectInfo.szName)
            if not self.tData.tLevelInfo.bCanGetBuff then
                szEffectName = szEffectName .. "(已获得)"
            end
            local szDescription = UIHelper.GBKToUTF8(self.tData.tEffectInfo.szDescription)
            local szMsg = string.format("第%d层 首领：%s\n特殊效果：%s\n<color=#FFE26E>%s</color>", nLevel, szBossName, szEffectName, szDescription)
            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self._rootNode, szMsg)
        elseif MonsterBookData.IsFreeLevel(self.tData.nLevel) then
            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self._rootNode, g_tStrings.MONSTER_BOOK_FREE_LEVEL_TIP)
        end
    end)
end

function UIMonsterBookLevelCell:RegEvent()
    Event.Reg(self, EventType.OnMonsterBookLevelChange, function (nCurLevel)
        UIHelper.SetVisible(self.WidgetCurrent, nCurLevel == self.tData.nLevel)
    end)
end

function UIMonsterBookLevelCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMonsterBookLevelCell:UpdateInfo(tData)
    self.tData = tData
    local nLevel = tData.nLevel
    local nEffectID = tData.nEffectID
    local tLevelInfo = tData.tLevelInfo
    local tEffectInfo = tData.tEffectInfo
    local bShowElite = nLevel % LEVEL_PER_GROUP == 0
    local bCanGetBuff = tLevelInfo.bCanGetBuff and nEffectID ~= 0
    local szImagePath = UIHelper.GetIconPathByIconID(tEffectInfo.dwIconID)
    local bCanChange = CanChangeBoss(nLevel)
    UIHelper.SetTexture(self.WidgetItem60, szImagePath)
    UIHelper.SetString(self.LabelLevel, tostring(nLevel))
    UIHelper.SetVisible(self.ImgLevelNumNormal, not bCanGetBuff)
    UIHelper.SetVisible(self.ImgLevelNumSpecial, bCanGetBuff)
    UIHelper.SetVisible(self.WidgetFinished, tLevelInfo.nLevelState == LEVEL_STATE.PASSED)
    UIHelper.SetVisible(self.ImgFrameBoss, bShowElite)
    UIHelper.SetVisible(self.ImgFreeCost, MonsterBookData.IsFreeLevel(nLevel))
    UIHelper.SetVisible(self.ImgVariantCost, tLevelInfo.bVariant)
    UIHelper.SetVisible(self.ImgSwitchCost, bCanChange)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end

function UIMonsterBookLevelCell:OnUpdateState(tState)
    UIHelper.SetVisible(self.WidgetCurrent, tState.nCurrentLevel == self.tData.nLevel)
    UIHelper.SetVisible(self.ImgPredictable, tState.bLightLevel)
end

return UIMonsterBookLevelCell