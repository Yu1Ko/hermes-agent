-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterDetailView
-- Date: 2022-11-10 10:49:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterDetailView = class("UICharacterDetailView")

function UICharacterDetailView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UICharacterDetailView:OnExit()
    self.bInit = false
end

function UICharacterDetailView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UICharacterDetailView:RegEvent()
    Event.Reg(self, EventType.OnSelectedMoreDetailTog2, function (script)
        UIHelper.LayoutDoLayout(self.LayoutBasis)
        UIHelper.LayoutDoLayout(self.LayoutHurt)
        UIHelper.LayoutDoLayout(self.LayoutSurvive)
        UIHelper.LayoutDoLayout(self.LayoutOther)
        UIHelper.ScrollViewDoLayout(self.ScrollViewCenter)
        UIHelper.ScrollLocateToPreviewItem(self.ScrollViewCenter, script._rootNode, Locate.TO_CENTER)
    end)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICharacterDetailView:UpdateInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local tbInfo = PlayerData.GetAttribInfo(player)
    local tbAttribShowConfig = PlayerData.GetShowInfo(player)
    local tbType2Count = {}
    for i, tbAttribInfo in ipairs(tbInfo) do
        local parent = self.LayoutBasis
        tbType2Count[tbAttribInfo.nType] = (tbType2Count[tbAttribInfo.nType] or 0) + 1
        if tbAttribInfo.nType == 1 then
            parent = self.LayoutBasis
        elseif tbAttribInfo.nType == 2 then
            parent = self.LayoutHurt
        elseif tbAttribInfo.nType == 3 then
            parent = self.LayoutSurvive
        elseif tbAttribInfo.nType == 4 then
            parent = self.LayoutOther
        end
        UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterDetailCell, parent, player, i, tbType2Count[tbAttribInfo.nType], tbAttribInfo)
    end
    UIHelper.LayoutDoLayout(self.LayoutBasis)
    UIHelper.LayoutDoLayout(self.LayoutHurt)
    UIHelper.LayoutDoLayout(self.LayoutSurvive)
    UIHelper.LayoutDoLayout(self.LayoutOther)
    UIHelper.ScrollViewDoLayout(self.ScrollViewCenter)
    UIHelper.ScrollToTop(self.ScrollViewCenter, 0, false)

    if tbAttribShowConfig.bShowTherapy then
        UIHelper.SetString(self.LabelHurt, "治疗")
    else
        UIHelper.SetString(self.LabelHurt, "伤害")
    end
end

return UICharacterDetailView