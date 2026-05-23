-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityLeftCard
-- Date: 2024-01-18 10:50:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandIdentityLeftCard = class("UIHomelandIdentityLeftCard")
local DataModel = {}
function UIHomelandIdentityLeftCard:OnEnter(tbDataModel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szExpTips = ""
    DataModel = tbDataModel
end

function UIHomelandIdentityLeftCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityLeftCard:BindUIEvent()
	UIHelper.SetVisible(self.ImgRedDot, false)
    UIHelper.BindUIEvent(self.BtnStageIcon, EventType.OnClick, function ()
        local tbBaseDataTip = self:GetIdentityBaseTip()
        Event.Dispatch(EventType.OnHomeIdentityOpenTips, tbBaseDataTip)
    end)

    UIHelper.BindUIEvent(self.BtnDetails, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnHomeIdentityOpenDetailsPop)
    end)

    UIHelper.BindUIEvent(self.BtnExplain, EventType.OnClick, function ()
        local tbBaseDataTip = self:GetIdentityBaseTip()
        Event.Dispatch(EventType.OnHomeIdentityOpenTips, tbBaseDataTip)
    end)

    UIHelper.BindUIEvent(self.BtnIdentityReward, EventType.OnClick, function ()
        local scriptReward = UIMgr.Open(VIEW_ID.PanelFurnitureReward)
        scriptReward:UpdateHomeIdentityAward(self.dwID)
    end)

    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewOrderDetailsList, false)
end

function UIHomelandIdentityLeftCard:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityLeftCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityLeftCard:UpdateInfo(nTypeIndex)
    local tIdentityUIInfo   = DataModel.tIdentityInfo[nTypeIndex]
    self.dwID               = tIdentityUIInfo.dwID
    self.tBaseList          = DataModel.GetBaseList(self.dwID)
    self.tInfo              = DataModel.GetIdentityInfo(self.dwID)
    self.szExpTip           = UIHelper.GBKToUTF8(self.tInfo.szExpTip)
    self.tExpData           = GDAPI_GetHLIdentityExp(self.dwID)

    local nLevel     = self.tExpData.nLevel or 0
    local nExp       = self.tExpData.nExp or 0
    local nNextExp   = self.tExpData.nNextExp or 0
    local fPercent   = self.tExpData.fExpPercent or 0
    local szExp      = FormatString(g_tStrings.STR_HOMELAND_NEXT_LEVEL, nExp, nNextExp)
    local szIconPath = UIHelper.FixDXUIImagePath(tIdentityUIInfo.szIconPath)
    local tExtList   = DataModel.GetExtList(tIdentityUIInfo.dwID)

    UIHelper.RemoveAllChildren(self.ScrollViewOrderDetailsList)
    for nType, tData in pairs(tExtList) do
        local tType         = DataModel.GetPriorityType(nType)
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOrderDetailsList, self.ScrollViewOrderDetailsList)
        for _, tInfo in ipairs(tData) do
            local tExtData      = DataModel.GetExtData(self.dwID , tInfo.dwID) or {}
            tInfo.bLock = tExtData.bLock
            tInfo.bCanUse = tExtData.bCanUse
            tInfo.bCurUse = tExtData.bCurUse
        end
        script:OnEnter(tType, tData)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewOrderDetailsList)

    UIHelper.SetTexture(self.ImgGradeIcon, szIconPath)
    UIHelper.SetProgressBarStarPercentPt(self.ImgSliderExperience, 0.5 , 0)
	UIHelper.SetProgressBarPercent(self.ImgSliderExperience, fPercent * 100)
    UIHelper.SetString(self.LabelLevel, nLevel)
    UIHelper.SetString(self.LabelPercentage, szExp)

	UIHelper.SetVisible(self.ImgSliderExperience, not not fPercent)
    UIHelper.LayoutDoLayout(self.LayoutPercentageNum)
end

function UIHomelandIdentityLeftCard:GetIdentityBaseTip()    -- 获取等级和能力Tips
    local tbTips = {
        {
            szTitle = "身份等级", tbTip = {{szName = "", szContent = self.szExpTip}}
        }
    }
    local tbBaseTip = {}
    for _, dwPriorityID in ipairs(self.tBaseList) do
        local tInfo = DataModel.GetPriorityInfo(dwPriorityID) or {}
        local tData = DataModel.GetBaseData(self.dwID, dwPriorityID) or {}

        local szName = UIHelper.GBKToUTF8(tInfo.szName)
        local szDesc = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tInfo.szDesc))
        local szLockDesc = UIHelper.GBKToUTF8(tInfo.szLockDesc)
        local bLock = tData.bLock
        if not string.is_nil(szLockDesc) then
            szLockDesc = ParseTextHelper.ParseNormalText(szLockDesc, false)
            szDesc = szDesc.."\n"
        end
        table.insert(tbBaseTip, {szName = szName, szContent = szDesc..szLockDesc, bLock = bLock})
    end

    table.insert(tbTips, {szTitle = "属性详情", tbTip = tbBaseTip})
    return tbTips
end

return UIHomelandIdentityLeftCard