-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintTagCell
-- Date: 2024-10-11 14:41:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintTagCell = class("UIHomelandBuildBlueprintTagCell")

function UIHomelandBuildBlueprintTagCell:OnEnter(nIndex, tbTag)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bDeleteMode = false
    self.nIndex = nIndex
    self.tbTag = tbTag
    self:UpdateInfo()
end

function UIHomelandBuildBlueprintTagCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandBuildBlueprintTagCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.TogCell, false)
    UIHelper.SetSwallowTouches(self.BtnCell, false)

    UIHelper.BindUIEvent(self.TogCell, EventType.OnSelectChanged, function (tog, bSelected)
        Event.Dispatch(EventType.OnSelectUploadBlueprintTagCell, self.tbTag.szName, bSelected, tog)
    end)
end

function UIHomelandBuildBlueprintTagCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildBlueprintTagCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ¡ý¡ý¡ý
-- ----------------------------------------------------------

function UIHomelandBuildBlueprintTagCell:UpdateInfo()
    UIHelper.SetVisible(self.TogCell, not self.bDeleteMode)
    UIHelper.SetVisible(self.BtnCell, self.bDeleteMode)

    local szName = UIHelper.GBKToUTF8(self.tbTag.szName)
    UIHelper.SetString(self.LabelTagNormal, szName)
    UIHelper.SetString(self.LabelTagUp, szName)
    UIHelper.SetString(self.LabelTitle, szName)

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIHomelandBuildBlueprintTagCell:TagDoLayout()
    local nLabelWidth, _ = UIHelper.GetContentSize(self.LabelTagNormal)
    local _, nImgHeight = UIHelper.GetContentSize(self.ImgNormal)
    UIHelper.SetContentSize(self.ImgNormal, nLabelWidth + 24, nImgHeight)
    UIHelper.SetContentSize(self.ImgUp, nLabelWidth + 24, nImgHeight)
    UIHelper.SetContentSize(self.TogCell, nLabelWidth + 24, nImgHeight)

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

return UIHomelandBuildBlueprintTagCell