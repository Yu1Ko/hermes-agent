-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIWidgetRefineInfoCell
-- Date: 2022-12-22 14:39
-- Desc: UIWidgetRefineInfoCell
-- ---------------------------------------------------------------------------------

---@class UIWidgetRefineInfoCell
---@field WidgetGoodsGenerate
---@field LabelGoodsName
---@field LabelTxtNum
local UIWidgetRefineInfoCell = class("UIWidgetRefineInfoCell")

local szEmphasize = "#FFE26E"

function UIWidgetRefineInfoCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetRefineInfoCell:OnInit(pItemInfo, fRate, bBind)
    if pItemInfo == nil or fRate == nil then
        LOG.ERROR("UIWidgetRefineInfoCell:OnInit pItemInfo or fRate invalid")
        return
    end

    if self.itemIconScript == nil then
        self.itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.WidgetGoodsGenerate) ---@type UICharacterRefineMaterialCell
    end
    self.itemIconScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.DISPLAY, nil, pItemInfo.nUiId, pItemInfo.nQuality)
    self.itemIconScript:SetBind(bBind)

    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(pItemInfo.nQuality)
    local szMainStoneName = pItemInfo.szName
    local nStart =  string.len(szMainStoneName) - 7
    if pItemInfo.nGenre == ITEM_GENRE.COLOR_DIAMOND then
        szMainStoneName = string.sub(szMainStoneName, nStart)
    end
    szMainStoneName = UIHelper.GBKToUTF8(szMainStoneName)
    --szMainStoneName = GetFormatText(szMainStoneName, nil, nDiamondR, nDiamondG, nDiamondB)
    UIHelper.SetRichText(self.LabelGoodsName, GetFormatText(szMainStoneName, nil, nDiamondR, nDiamondG, nDiamondB))
    UIHelper.SetRichText(self.LabelTxtNum, UIHelper.AttachTextColor(fRate .. "%", szEmphasize))
end

function UIWidgetRefineInfoCell:OnExit()
    self.bInit = false
end

function UIWidgetRefineInfoCell:BindUIEvent()
end

function UIWidgetRefineInfoCell:RegEvent()

end

function UIWidgetRefineInfoCell:SetVisible(bValue)
    UIHelper.SetActiveAndCache(self, self._rootNode, bValue)
end

return UIWidgetRefineInfoCell