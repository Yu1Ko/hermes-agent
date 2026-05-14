-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceClassCell
-- Date: 2023-09-08 14:49:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBuildFaceClassCell = class("UIBuildFaceClassCell")

function UIBuildFaceClassCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo.tbClassConfig
    self.onClickCallback = tbInfo.funcClickCallback
    self:UpdateInfo()
end

function UIBuildFaceClassCell:OnExit()
    self.bInit = false
end

function UIBuildFaceClassCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.TogLeftTabCell, false)
    UIHelper.BindUIEvent(self.TogLeftTabCell, EventType.OnClick, function ()
        if self.onClickCallback then
            self.onClickCallback(self.tbInfo)
        end
    end)
end

function UIBuildFaceClassCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFaceClassCell:UpdateInfo()
    local szName = UIHelper.GBKToUTF8(self.tbInfo.szClassName or self.tbInfo.szBodyName or self.tbInfo.szName)
    UIHelper.SetString(self.LabelType, szName)
    UIHelper.SetString(self.LabelTypeSelected, szName)

    local nLabel = self.tbInfo.nLabel
    local bDis = false
    local bNew = false
    if nLabel then
        if kmath.andOperator(nLabel, NEWFACE_LABEL.DISCOUNT) ~= 0 then
            bDis = true
        elseif kmath.andOperator(nLabel, NEWFACE_LABEL.NEW) ~= 0 then
            bNew = true
        end
    end
    UIHelper.SetVisible(self.ImgNew, bNew)
end

function UIBuildFaceClassCell:AddTogGroup(togGroup)
    UIHelper.ToggleGroupAddToggle(togGroup, self.TogLeftTabCell)
end

return UIBuildFaceClassCell