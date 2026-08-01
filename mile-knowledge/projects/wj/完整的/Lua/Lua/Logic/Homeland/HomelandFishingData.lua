HomelandFishingData = HomelandFishingData or {className = "HomelandFishingData"}
local self = HomelandFishingData
local tFishSkillGroup = {[0] = 1111, 1111, 1141, 1141, 1141, 1141, 1142, 1142, 1142, 1143, 1143, 1143, 1144, 1144, 1144, 1144, 1144}--钓鱼等级和动态技能栏
local HLIdentityType = { FISH = 1 }
local HLPriorityType = { FISH = 2 }
function HomelandFishingData.Init()
    self.tFishData = {}
    self.dwID = nil
    self.tExpData = {}
    self.tbFishPriorityInfo = {}

    self.nFishExpCache = 0
	self.tbFishCache = {}   -- 自动钓鱼的渔获延迟领取列表

    self.Update()
	self.RegEvent()
end

function HomelandFishingData.MarkCurFishPond(tbData)
    local tbInfo = {}
    if not table.is_empty(tbData) then
        tbInfo.nLandIndex = tbData.nLandIndex or 0
        tbInfo.nRepsesentID = tbData.dwRepresentID or 0
        tbInfo.nInstID = tbData.nFurnitureInstanceID or 0
    end
    self.tbCurFishPondInfo = tbInfo -- 记录进入钓鱼界面的鱼塘信息
end

function HomelandFishingData.UnInit()
    self.tFishData = nil
    self.dwID = nil
    self.tExpData = nil
    self.tbFishPriorityInfo = nil
    self.tbCurFishPondInfo = nil

    if not table.is_empty(self.tbFishCache) then
        RemoteCallToServer("On_HomeLand_GetFish", self.tbFishCache, Storage.HLIdentity.bIsAutoGetFish)
        Event.Dispatch(EventType.OnGetFishTips, self.tbFishCache, self.nFishExpCache)
    end
    self.nFishExpCache = nil
    self.tbFishCache = nil
    self.nGetFishTimer = nil

    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function HomelandFishingData.Update()
    local tIdentityUIInfo   = GDAPI_GetHLIdentityInfo()
    self.tFishData          = tIdentityUIInfo[HLIdentityType.FISH]
    self.dwID               = self.tFishData.dwID
    self.tExpData           = GDAPI_GetHLIdentityExp(self.dwID)
    self.tbFishPriorityInfo = self.GetFishPriorityInfo()
end

function HomelandFishingData.RegEvent()
    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelHomeFishGet then
            self.Update()
        end
    end)
    Event.Reg(self, EventType.OnGetFishTips, function()
        self.Update()
    end)
end

function HomelandFishingData.OnAutoGetFish(tGetFishNew, nExp)
	if not Storage.HLIdentity.bIsAutoGetFish then
        return
    end

    self.nFishExpCache = self.nFishExpCache + nExp
    for _, tFish in pairs(tGetFishNew) do
        table.insert(self.tbFishCache, {nFishIndex = tFish.nFishIndex, num = tFish.num})
    end

    if self.nGetFishTimer then
        Timer.DelTimer(self, self.nGetFishTimer)
        self.nGetFishTimer = nil
    end

    self.nGetFishTimer = Timer.Add(self, 0.5, function ()
        if table_is_empty(self.tbFishCache) then
            return
        end
        RemoteCallToServer("On_HomeLand_GetFish", self.tbFishCache, Storage.HLIdentity.bIsAutoGetFish)
        Event.Dispatch(EventType.OnGetFishTips, self.tbFishCache, self.nFishExpCache)

        self.tbFishCache = {}
        self.nFishExpCache = 0
    end)
end

function HomelandFishingData.GetFishPriorityInfo()
    local tRes = {}
    local tbFishExt = self.tFishData.tExtInfo
    for index, tbInfo in ipairs(tbFishExt) do
        local tbPriorityInfo = clone(Table_GetHLIdentityPriorityByID(tbInfo.dwID))
        if tbPriorityInfo.nType == HLPriorityType.FISH then
            tbPriorityInfo.bLock = tbInfo.bLock
            table.insert(tRes, tbPriorityInfo)
        end
    end
    return tRes
end

function HomelandFishingData.IsSkillLock(nSlot)
    -- 技能栏从2开始算，所以要转一下
    nSlot = nSlot - 1
    if nSlot <= 0 then
        return false
    end
    return self.tbFishPriorityInfo[nSlot] and self.tbFishPriorityInfo[nSlot].bLock
end

function HomelandFishingData.GetLockTips(nSlot)
    local szTip = ""
    nSlot = nSlot - 1
    if nSlot <= 0 then
        return
    end
    local tbPriority = self.tbFishPriorityInfo[nSlot]
    if tbPriority and tbPriority.szLockDesc then
        szTip = string.pure_text(UIHelper.GBKToUTF8(tbPriority.szLockDesc))
    end
    return szTip
end

function HomelandFishingData.GetCurFishPondInfo()
    return self.tbCurFishPondInfo
end