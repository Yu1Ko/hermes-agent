-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureChildType
-- Date: 2023-04-21 17:03:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureChildType = class("UIHomelandBuildFurnitureChildType")

function UIHomelandBuildFurnitureChildType:OnEnter(DataModel, tbInfo)
    self.DataModel = DataModel
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildFurnitureChildType:OnExit()
    self.bInit = false
end

function UIHomelandBuildFurnitureChildType:BindUIEvent()
    UIHelper.BindUIEvent(self.TogChildTypeItem, EventType.OnClick, function ()
        if self.DataModel.bInSearch then
			return
		elseif self.DataModel.nCurSubgroup ~= Homeland_GetNullSubgroupID() then
			self.DataModel.nCurSubgroup = Homeland_GetNullSubgroupID()
		end
		self.DataModel.nCurCatg2Index = self.tbInfo.nCatg2Index
        self.DataModel.bNeedScrollToLeft = true
		self.DataModel.UpdateCurItemList()
        Event.Dispatch(EventType.OnUpdateHomelandFurnitureList)
    end)
end

function UIHomelandBuildFurnitureChildType:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildFurnitureChildType:UpdateInfo()
    UIHelper.SetString(self.LabelTypeNameNormal, UIHelper.GBKToUTF8(self.tbInfo.szName))
    UIHelper.SetString(self.LabelTypeNameUp, UIHelper.GBKToUTF8(self.tbInfo.szName))

    if HomelandChildTypeIcon[self.tbInfo.szIconImgPath] then
        if HomelandChildTypeIcon[self.tbInfo.szIconImgPath][self.tbInfo.nIconFrameNormal] then
            UIHelper.SetSpriteFrame(self.ImgTypeIcon, HomelandChildTypeIcon[self.tbInfo.szIconImgPath][self.tbInfo.nIconFrameNormal])
        end

        if HomelandChildTypeIcon[self.tbInfo.szIconImgPath][self.tbInfo.nIconFrameChecked] then
            UIHelper.SetSpriteFrame(self.ImgTypeIconPressed, HomelandChildTypeIcon[self.tbInfo.szIconImgPath][self.tbInfo.nIconFrameChecked])
        end
    end

	self:UpdateNumInfo()
    self:UpdateRedPoint()
end

function UIHomelandBuildFurnitureChildType:UpdateNumInfo()
	local nMode = HLBOp_Main.GetBuildMode()
    if not self.DataModel.bIsBluepList and nMode ~= BUILD_MODE.TEST then
        local hlMgr = GetHomelandMgr()
		local nUsedCount = hlMgr.BuildGetCategoryCount(self.tbInfo.nCatg1Index, self.tbInfo.nCatg2Index)
		local tLevelConfig = hlMgr.GetLevelFurnitureConfig(self.tbInfo.nCatg1Index, self.tbInfo.nCatg2Index, HLBOp_Enter.GetLevel())
		local nLimitAmount = tLevelConfig and tLevelConfig.LimCount
		if nUsedCount and nLimitAmount and nLimitAmount <= 999 then
            UIHelper.SetString(self.LabelCountNormal, string.format("%d/%d", nUsedCount, nLimitAmount))
            UIHelper.SetString(self.LabelCountUp, string.format("%d/%d", nUsedCount, nLimitAmount))
        else
            UIHelper.SetString(self.LabelCountNormal, "")
            UIHelper.SetString(self.LabelCountUp, "")
		end
    end
end

function UIHomelandBuildFurnitureChildType:UpdateRedPoint()
    local tCatg2DotInfo = self.DataModel.tRedDotInfo[self.DataModel.nCurCatg1Index]
    local bShowDot = tCatg2DotInfo and tCatg2DotInfo[self.tbInfo.nCatg2Index]
    UIHelper.SetVisible(self.ImgRedPoint, not not bShowDot)
end


return UIHomelandBuildFurnitureChildType