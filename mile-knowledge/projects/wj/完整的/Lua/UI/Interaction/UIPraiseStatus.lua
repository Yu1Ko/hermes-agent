-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPraiseStatus
-- Date: 2023-01-06 17:42:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPraiseStatus = class("UIPraiseStatus")

function UIPraiseStatus:OnEnter(tbLabels)
    self.tbLabels = tbLabels

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPraiseStatus:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPraiseStatus:BindUIEvent()

end

function UIPraiseStatus:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPraiseStatus:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPraiseStatus:UpdateInfo()

    UIHelper.RemoveAllChildren(self.ScrollViewStatus)
    for _, tInfo in ipairs(self.tbLabels) do
        local nodeScript = UIHelper.AddPrefab(PREFAB_ID.WidgetStatus, self.ScrollViewStatus)
        if nodeScript then
            nodeScript:UpdateInfo(tInfo)
        end
    end

    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStatus)
        self.ScrollViewStatus:setTouchDownHideTips(false)
    end)
end

function UIPraiseStatus:UpdateInfoOld()
    local tRes = Table_GetAllPersonLabel()
    for i, info in ipairs(tRes) do
        local item = {}
        item.count = self.tbLabels[info.id] or 0
        item.title = info.title
        item.desc  = info.desc
        item.id    = info.id
        item.count_coff = info.count_coff

        --cimg.nor   = info.image_norframe
        --cimg.light = info.image_overframe

        local nLevel = PersonLabel_GetLevel(item.count, info.id)
        UIHelper.SetString(self.tbLabelLevel[i], string.format(g_tStrings.STR_LEVEL_FARMAT, nLevel))

        local nLevelTotalCapacity = PersonLabel_GetLevelCount(nLevel, item.id)
        if nLevelTotalCapacity == 1 and nLevel == 1 then
            nLevelTotalCapacity = 0
        end

        local nNextLevelTotalCapacity = PersonLabel_GetLevelCount(nLevel + 1, item.id)
        local nNextLevelCapacity = nNextLevelTotalCapacity - nLevelTotalCapacity
        if nNextLevelCapacity == 0 then
            nNextLevelCapacity = 1
        end

        local nExp = item.count - nLevelTotalCapacity

        local szNum = string.format("%d/%d", nExp, nNextLevelCapacity)
        UIHelper.SetString(self.tbLabelNum[i], szNum)

        UIHelper.SetProgressBarPercent(self.tbProgressBar[i], nExp * 100.0/ nNextLevelCapacity)
        --cimg:FromUITex(info.image_file, info.image_norframe)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStatus)

    self.ScrollViewStatus:setTouchDownHideTips(false)
end


return UIPraiseStatus