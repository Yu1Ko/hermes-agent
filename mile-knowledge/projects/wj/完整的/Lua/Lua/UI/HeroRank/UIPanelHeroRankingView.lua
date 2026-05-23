-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelHeroRankingView
-- Date: 2024-09-19 11:22:27
-- Desc: ?
-- ---------------------------------------------------------------------------------
local LAYER_HERO_COUNT =
{
    [1] = 8,
    [2] = 4,
    [3] = 2,
    [4] = 1,
}

local LAYER_HERO_PREFAB =
{
    [1] = PREFAB_ID.WidgetHeroRankingBest16Cell,
    [2] = PREFAB_ID.WidgetHeroRankingBest8Cell,
    [3] = PREFAB_ID.WidgetHeroRankingBest4Cell,
    [4] = PREFAB_ID.WidgetHeroRankingBest2Cell,
}
local UIPanelHeroRankingView = class("UIPanelHeroRankingView")

function UIPanelHeroRankingView:OnEnter(nContestPhase)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    HeroRankData.Init(nContestPhase)
    self:UpdateInfo()
end

function UIPanelHeroRankingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelHeroRankingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end) 
end

function UIPanelHeroRankingView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelHeroRankingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelHeroRankingView:GetPrefebByPhase(nPhase)

end

function UIPanelHeroRankingView:UpdateInfo()
    local tbScript = {}
    for nPhase = 1, HeroRankData.TOTAL_PHASE do
        local nLayer = HeroRankData.GetLayerByPhase(nPhase)
        local nCount = LAYER_HERO_COUNT[nLayer]
        local nPrefabID = LAYER_HERO_PREFAB[nLayer]
        if nCount and nPrefabID and not tbScript[nLayer] then
            for nIndex = 1, nCount do
                local scriptView = UIHelper.AddPrefab(nPrefabID, self.tbBestLayout[nLayer])
                if not tbScript[nLayer] then
                    tbScript[nLayer] = {}
                end
                table.insert(tbScript[nLayer], scriptView)
            end
        end
	end

    for nPhase = 1, HeroRankData.TOTAL_PHASE do
        local nLayer = HeroRankData.GetLayerByPhase(nPhase)
        local tbLayerScript = tbScript[nLayer]
       
        local aNpcInfoList = HeroRankData.aWulinShenghuiDuizhenbiao[nPhase] or {}
		if aNpcInfoList[1] and tbLayerScript then
			for dwNpcIndex, dwNpcID in ipairs(aNpcInfoList[1]) do
				local nNpcUIIndex = HeroRankData.GetNpcUIIndexInLayer(dwNpcID, nPhase)
				local scriptView = tbLayerScript[math.ceil(nNpcUIIndex / 2)]
                local nCellIndex = nNpcUIIndex % 2 == 0 and 2 or 1
                scriptView:UpdateInfo(nCellIndex, aNpcInfoList, dwNpcIndex)
			end
		end

        for nIndex, scriptView in ipairs(tbLayerScript) do
            scriptView:UpdateEmpty()
        end
       
	end

    local nLayer = 6
    local scriptView = UIHelper.GetBindScript(self.WidgetChampion)
    scriptView:UpdateInfo(1, HeroRankData.aWulinShenghuiDuizhenbiao[nLayer], 1)
    scriptView:UpdateEmpty()

    UIHelper.SetString(self.LabelTitle, g_tStrings.tStrWulinShenghuiPhaseTitle[HeroRankData.nCurContestPhase])
end

return UIPanelHeroRankingView