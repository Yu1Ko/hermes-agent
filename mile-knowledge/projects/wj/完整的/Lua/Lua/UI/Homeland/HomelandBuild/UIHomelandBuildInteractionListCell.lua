-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildInteractionListCell
-- Date: 2024-01-25 10:25:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildInteractionListCell = class("UIHomelandBuildInteractionListCell")
local DataModel = nil
function UIHomelandBuildInteractionListCell:OnEnter(tbInfo)
    self.tbInfo = tbInfo.tbBaseInfo
    DataModel = tbInfo.DataModel

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildInteractionListCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildInteractionListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnSelectedHomelandBuildInteractionListCell, self.tbInfo.nInstanceID)
    end)

    UIHelper.BindUIEvent(self.BtnTrace, EventType.OnClick, function ()
        if QTEMgr.IsInDynamicSkillState() then
            TipsHelper.ShowNormalTip("请先退出交互技能栏")
            return
        end

        if not DataModel.tInstID2Info[self.tbInfo.nInstanceID] then
            return
        end

        local tbData = DataModel.tInstID2Info[self.tbInfo.nInstanceID]
        local nX, nY, nZ = tbData.nX, tbData.nY, tbData.nZ
        if nX then
            GetHomelandMgr().SetPosition(nX, nY, nZ)
        end
    end)
end

function UIHomelandBuildInteractionListCell:RegEvent()
    Event.Reg(self, EventType.OnUpdateHomelandBuildInteractionListData, function (nInstID)
        if self.tbInfo.nInstanceID == nInstID then
            self:UpdateInfo()
        end
    end)
end

function UIHomelandBuildInteractionListCell:UpdateInfo()
    if not DataModel.tInstID2Info[self.tbInfo.nInstanceID] then
        return
    end

    local tbData = DataModel.tInstID2Info[self.tbInfo.nInstanceID]

    local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(tbData.nFurnitureType, tbData.dwFurnitureID)
	local tAddInfo = FurnitureData.GetFurnAddInfo(dwFurnitureUiId)

    local tRGB = Homeland_GetFurnitureRGBByQuality(tbData.nQuality)
    UIHelper.SetRichText(self.RichTextItemName, GetFormatText(UIHelper.GBKToUTF8(tbData.szName), nil, tRGB[1], tRGB[2], tRGB[3]))

	if tAddInfo then
		local szPath = string.gsub(tAddInfo.szPath, "ui/Image/", "Resource/")
		szPath = string.gsub(szPath, ".tga", ".png")
        UIHelper.SetTexture(self.ImgItemIcon, szPath)
	end
end

function UIHomelandBuildInteractionListCell:AddToggleGroup(toggleGroup)
    -- if not self.bAddToggleGroup then
    --     UIHelper.ToggleGroupAddToggle(toggleGroup, self.ToggleSelect)
    --     self.bAddToggleGroup = true
    --     UIHelper.SetSelected(self.ToggleSelect, false)
    -- end
end


return UIHomelandBuildInteractionListCell