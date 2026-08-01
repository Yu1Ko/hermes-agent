-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBlueprintChooseCell
-- Date: 2024-05-06 11:20:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBlueprintChooseCell = class("UIBlueprintChooseCell")

function UIBlueprintChooseCell:OnEnter(nCellIndex, tbConfig)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCellIndex = nCellIndex
    self.tbConfig = tbConfig
    self:UpdateInfo()
end

function UIBlueprintChooseCell:OnExit()
    self.bInit = false
end

function UIBlueprintChooseCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPreview, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelBlueprintChoosePreview, self.tbConfig)
    end)

    UIHelper.BindUIEvent(self.TogItem, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnChoiceBlueprintCell, self.tbConfig)
    end)
end

function UIBlueprintChooseCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBlueprintChooseCell:UpdateInfo()
    local szPath = UIHelper.FixDXUIImagePath(self.tbConfig.szTipImgPath)
    UIHelper.SetTexture(self.ImgPicBluePrint, szPath, true, function()
        UIHelper.UpdateMask(self.MaskItem)
    end)
    UIHelper.UpdateMask(self.MaskItem)

    UIHelper.SetString(self.LabelNameBlueprint, UIHelper.GBKToUTF8(self.tbConfig.szName))
    UIHelper.SetString(self.LabelNameAuthor, UIHelper.GBKToUTF8(self.tbConfig.szAuthor))

end


return UIBlueprintChooseCell