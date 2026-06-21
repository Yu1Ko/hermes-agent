-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeListCell
-- Date: 2023-04-11 15:33:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeListCell = class("UIHomelandMyHomeListCell")

local MapID2HomeName = {
    [455] = "广陵邑",
    [462] = "九寨沟·镜海",
    [471] = "枫叶泊·乐苑",
    [486] = "枫叶泊·天苑",
    [565] = "私邸宅园",
    [674] = "浣花水榭"
}

local MapID2GroupBuyHomeName = {
    [455] = "广陵邑定制",
    [462] = "九寨沟定制",
    [471] = "枫叶泊定制",
    [486] = "枫叶泊定制",
    [674] = "浣花水榭定制",
}

function UIHomelandMyHomeListCell:OnEnter(tbInfo)
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomeListCell:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogHome, EventType.OnClick, function ()
        if self.tbInfo and self.tbInfo.funcClickCallback then
            self.tbInfo.funcClickCallback()
        end
    end)

    UIHelper.BindUIEvent(self.TogCustom, EventType.OnClick, function ()
        if self.tbInfo and self.tbInfo.funcClickCallback and self.tbInfo.bGroupBuy then
            self.tbInfo.funcClickCallback()
        end
    end)
    -- UIHelper.SetTouchDownHideTips(self.TogHome, false)
end

function UIHomelandMyHomeListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandMyHomeListCell:UpdateInfo()
    if self.tbInfo.bGroupBuy then
        self:UpdateGroupBuyInfo()
        return
    end
    local nMapId = self.tbInfo.tHomeData.nMapID
    local bPrivateHome = HomelandData.IsPrivateHome(nMapId)
    if bPrivateHome then
        UIHelper.SetVisible(self.ImgLock, not self.tbInfo.bOwn)
    end
    UIHelper.SetVisible(self.ImgHouseholdBg, self.tbInfo.bCohabitHome)
    UIHelper.SetString(self.LabelHomeName, MapID2HomeName[nMapId])
    UIHelper.SetSpriteFrame(self.ImgHomeIocn, HomeLandMainPageHouseholdIcon[nMapId])
    if not self.tbInfo.bOwn and nMapId == 565 then
        UIHelper.SetSpriteFrame(self.ImgHomeIocn, HomeLandMainPageHouseholdIcon[0])
    end
end

function UIHomelandMyHomeListCell:UpdatePlayerHomeTog(nMapID, nCopyIndex, nLandIndex)
    local bSelected = false
    local tbHomeData = self.tbInfo and self.tbInfo.tHomeData
    local bPrivateHome = HomelandData.IsPrivateHome(nMapID)

    if bPrivateHome and tbHomeData and tbHomeData.nMapID == nMapID then
        bSelected = true    --选中私宅则只判断地图是否一样
    elseif tbHomeData and tbHomeData.nMapID == nMapID and tbHomeData.nCopyIndex == nCopyIndex and tbHomeData.nLandIndex == nLandIndex then
        bSelected = true    --选中社区地图判断nCopyIndex, nLandIndex
    end
    UIHelper.SetSelected(self.TogHome, bSelected)
end

function UIHomelandMyHomeListCell:UpdateGroupBuyInfo()
    UIHelper.SetVisible(self.TogCustom, true)
    UIHelper.SetVisible(self.TogHome, false)

    local nMapId = self.tbInfo.tHomeData.nMapID
    UIHelper.SetString(self.LabelHomeName, MapID2GroupBuyHomeName[nMapId])
    UIHelper.SetSpriteFrame(self.ImgHomeIocnCustom, HomeLandGroupBuyHouseholdIcon[nMapId])
end
return UIHomelandMyHomeListCell