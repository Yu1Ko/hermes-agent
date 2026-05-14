-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetAttrPage
-- Date: 2024-07-15 14:54:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetAttrPage = class("UICustomizedSetAttrPage")

function UICustomizedSetAttrPage:OnEnter(tbInfo, nTotalScore, nCellPrefabID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nTotalScore = nTotalScore
    self.tbInfo = tbInfo
    self.nCellPrefabID = nCellPrefabID or PREFAB_ID.WidgetCustomAttriCell
    self:UpdateInfo()
end

function UICustomizedSetAttrPage:OnExit()
    self.bInit = false
end

function UICustomizedSetAttrPage:BindUIEvent()

end

function UICustomizedSetAttrPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end
function UICustomizedSetAttrPage:UpdateInfo()
    UIHelper.SetString(self.LabelRankNum, self.nTotalScore)

    UIHelper.HideAllChildren(self.LayoutMainAttriList)
    UIHelper.HideAllChildren(self.ScrollViewSubAttriList)
    self.tbMainCells = self.tbMainCells or {}
    self.tbSubCells = self.tbSubCells or {}
    local bMainAttr = true
    for i, v in ipairs(self.tbInfo) do
        local parent = self.LayoutMainAttriList
        local tbCells = self.tbMainCells
        if i > 4 then
            parent = self.ScrollViewSubAttriList
            tbCells = self.tbSubCells
            bMainAttr = false
        end

        if not tbCells[i] then
            local cell = UIHelper.AddPrefab(self.nCellPrefabID, parent)
            tbCells[i] = cell
        end

        UIHelper.SetVisible(tbCells[i]._rootNode, true)
        local nValue = v.Value or 0
        if v.Percent then
            tbCells[i]:OnEnter(g_tStrings.tAttributeName[v.Key], string.format("%.2f%%", nValue), bMainAttr)
        else
            tbCells[i]:OnEnter(g_tStrings.tAttributeName[v.Key], nValue, bMainAttr)
        end

    end

    UIHelper.LayoutDoLayout(self.LayoutMainAttriList)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSubAttriList)
end


return UICustomizedSetAttrPage