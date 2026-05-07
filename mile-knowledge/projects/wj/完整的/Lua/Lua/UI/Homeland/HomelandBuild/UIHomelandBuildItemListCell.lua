-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildItemListCell
-- Date: 2023-05-24 16:53:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildItemListCell = class("UIHomelandBuildItemListCell")

function UIHomelandBuildItemListCell:OnEnter(tbInfo)
    self.szName         = tbInfo and tbInfo.szName
    self.tbInfo         = tbInfo and tbInfo.tbInfo
    self.dwObjID        = tbInfo and tbInfo.dwObjID
    self.dwModelID      = tbInfo and tbInfo.dwModelID
    self.dwModelGroupID = tbInfo and tbInfo.dwModelGroupID

    if tbInfo and tbInfo.bMulti then
        local tArgs     = tbInfo.tbInfos[1].tArgs
        self.tbItemList = tbInfo.tbInfos
        self.szTitle    = tbInfo.szTitle
        self.bMulti     = true
        self.tbInfo     = tArgs.tbInfo
        self.dwObjID    = tArgs.dwObjID
        self.dwModelID  = tArgs.dwModelID
        self.szName     = tArgs.szName
        self.dwModelGroupID = tArgs.dwModelGroupID
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildItemListCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildItemListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        if self.bMulti then
            Event.Dispatch("OnHomelandBulidOpenItemTableview", self.tbItemList, self.szTitle)
            return
        end

        if self.dwModelGroupID then
            local tInfo = HLBOp_Group.GetGroupInfo(self.dwModelGroupID)
            if tInfo then
                HLBOp_Select.SelectOneGroup(self.dwModelGroupID)
                -- HLBView_Main.ChangeFocusToHLB()
            end
        else
            HLBOp_Select.SetItemSelect(self.dwObjID)
            HLBOp_Other.FocusObject(self.dwObjID)
        end
    end)

    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
end

function UIHomelandBuildItemListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildItemListCell:UpdateInfo()
    if not self.tbInfo then
        return
    end

    local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(self.tbInfo.nFurnitureType, self.tbInfo.dwFurnitureID)
	local tAddInfo = FurnitureData.GetFurnAddInfo(dwFurnitureUiId)

    local tRGB = Homeland_GetFurnitureRGBByQuality(self.tbInfo.nQuality)

    if self.szName then
        tRGB = Homeland_GetFurnitureRGBByQuality(1)
        UIHelper.SetRichText(self.RichTextItemName, GetFormatText(self.szName, nil, tRGB[1], tRGB[2], tRGB[3]))
    else
        UIHelper.SetRichText(self.RichTextItemName, GetFormatText(UIHelper.GBKToUTF8(self.tbInfo.szName), nil, tRGB[1], tRGB[2], tRGB[3]))
    end

	if tAddInfo then
		local szPath = string.gsub(tAddInfo.szPath, "ui/Image/", "Resource/")
		szPath = string.gsub(szPath, ".tga", ".png")
        UIHelper.SetTexture(self.ImgItemIcon, szPath)
	end
    UIHelper.SetVisible(self.LabelTypeName, self.bMulti)
    UIHelper.SetVisible(self.ImgArrow, self.bMulti)
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIHomelandBuildItemListCell:AddToggleGroup(toggleGroup)
    if not self.bAddToggleGroup then
        UIHelper.ToggleGroupAddToggle(toggleGroup, self.ToggleSelect)
        self.bAddToggleGroup = true
        UIHelper.SetSelected(self.ToggleSelect, false)
    end
end

return UIHomelandBuildItemListCell