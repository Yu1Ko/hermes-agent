-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetCardAndSeasonLayout
-- Date: 2026-03-11 11:13:01
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIWidgetCardAndSeasonLayout = class("UIWidgetCardAndSeasonLayout")

function UIWidgetCardAndSeasonLayout:OnEnter(tBcardInfo, nClass2)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tBcardInfo = tBcardInfo
    self.nClass = nClass2
    self:UpdateInfo()
end

function UIWidgetCardAndSeasonLayout:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCardAndSeasonLayout:BindUIEvent()
    
end

function UIWidgetCardAndSeasonLayout:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCardAndSeasonLayout:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCardAndSeasonLayout:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutRoafCard)

    for _, tCardInfo in ipairs(self.tBcardInfo) do
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRoafCardCell, self.LayoutRoafCard, tCardInfo)
        if tbScript and tbScript.BtnSecretArea then
            UIHelper.SetSwallowTouches(tbScript.BtnSecretArea, false)
        end
    end

    self:UpdateSeasonLevelInfo()
    UIHelper.LayoutDoLayout(self.LayoutRoafCard)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIWidgetCardAndSeasonLayout:UpdateSeasonLevelInfo()
    local nClass = self.nClass
    if not nClass then
        return
    end
    local nRankLv, _, _, _, nTotalScores = GDAPI_SA_GetRankBaseInfo(nClass)
    local tRankInfo = Table_GetRankInfoByLevel(nRankLv)
    UIHelper.RemoveAllChildren(self.WidgetSeasonLevelTitle)
    UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonLevelTitle, self.WidgetSeasonLevelTitle, nClass, tRankInfo, nTotalScores)
end

return UIWidgetCardAndSeasonLayout