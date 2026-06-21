-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIManufactureFilterCell
-- Date: 2022-11-28 19:56:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIManufactureFilterCell = class("UIManufactureFilterCell")

function UIManufactureFilterCell:OnEnter(tRecipeInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tRecipe = tRecipeInfo.tRecipe
    self.fCallBack = tRecipeInfo.fCallBack
    UIHelper.SetVisible(self.ImgAffixTips, false)
    self:UpdateInfo()
end

function UIManufactureFilterCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIManufactureFilterCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.fCallBack(self.tRecipe)
        end
        UIHelper.CascadeDoLayoutDoWidget(self.ToggleSelect, true, true)
    end)
end

function UIManufactureFilterCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIManufactureFilterCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIManufactureFilterCell:UpdateInfo()
    self:SetLabelTittle(string.format("[%d]%s", self.tRecipe.nLevel, self.tRecipe.szName), self.tRecipe.bHasLearned)
    self:SetProfessionIcon(self.tRecipe.bNeedExpertise)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end

function UIManufactureFilterCell:SetLabelTittle(value, bLearn)
    UIHelper.SetString(self.LabelTitle, value)
    UIHelper.SetString(self.LabelTitleSelected, value)
    if GetStringCharCount(value) > 15 then
        UIHelper.SetFontSize(self.LabelTitle, 20)
        UIHelper.SetFontSize(self.LabelTitleSelected, 20)
    end
    UIHelper.SetTextColor(self.LabelTitle, cc.c4b(0xAE, 0xD9, 0xE0, 0xFF))
    UIHelper.SetTextColor(self.LabelTitleSelected, cc.c4b(0xFF, 0xFF, 0xFF, 0xFF))
    if bLearn then
        UIHelper.SetVisible(self.ImgUndo, false)

    else
        UIHelper.SetVisible(self.ImgUndo, true)
        UIHelper.SetTextColor(self.LabelTitle, cc.c4b(0xAE, 0xD9, 0xE0, 76))
        UIHelper.SetTextColor(self.LabelTitleSelected, cc.c4b(0xFF, 0xFF, 0xFF, 76))
    end
end

function UIManufactureFilterCell:SetVisible(value)
    UIHelper.SetVisible(self._rootNode, value)
end

function UIManufactureFilterCell:SetProfessionIcon(value)
    UIHelper.SetVisible(self.ImgSpecializationBg, value)
end

return UIManufactureFilterCell