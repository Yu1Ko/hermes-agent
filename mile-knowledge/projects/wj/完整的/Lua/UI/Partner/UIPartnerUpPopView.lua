-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerUpPopView
-- Date: 2023-03-30 11:04:32
-- Desc: 侠客-升级
-- Prefab: PanelPartnerUpPop
-- ---------------------------------------------------------------------------------

local UIPartnerUpPopView = class("UIPartnerUpPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerUpPopView:_LuaBindList()
    self.BtnClose                  = self.BtnClose --- 关闭界面

    self.LayouMiddlePartnertUpItem = self.LayouMiddlePartnertUpItem --- 升级道具的layout

    self.LabelSikllLevelNum        = self.LabelSikllLevelNum --- 当前等级与使用后提升的等级
    self.LabelExpAdd               = self.LabelExpAdd --- 使用后增加的经验
    self.LabelExp                  = self.LabelExp --- 当前经验进度
    self.ProgressBarAfter          = self.ProgressBarAfter --- 使用后的升级进度条
    self.ProgressBarBefore         = self.ProgressBarBefore --- 使用前的升级进度条

    self.LayoutExp                 = self.LayoutExp --- 使用前后经验外层的layout

    self.BtnMinus                  = self.BtnMinus --- 使用数目-1
    self.BtnAdd                    = self.BtnAdd --- 使用数目+1
    self.EditUseCount              = self.EditUseCount --- 当前选中道具的准备使用数目
    self.BtnMax                    = self.BtnMax --- 使用数目设为最大

    self.BtnCancel                 = self.BtnCancel --- 取消
    self.BtnConfirm                = self.BtnConfirm --- 确认
end

function UIPartnerUpPopView:OnEnter(dwID)
    self.dwID         = dwID

    self.nSelectIndex = 1
    self.nUseCount    = self:GetInitialCount()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerUpPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerUpPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND) then
            return
        end

        local dwID      = self.dwID
        local nSelIndex = self.nSelectIndex
        local nAmount   = self.nUseCount
        if not nSelIndex or not nAmount then
            return
        end
        local tInfo         = Partner_GetUpGradeItemSetting()
        local tCostItem     = tInfo[nSelIndex]
        local tCostItemInfo = { tCostItem.nType, tCostItem.dwIndex, nAmount }
        RemoteCallToServer("On_Hero_LevelUp", dwID, tCostItemInfo)
    end)

    UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function()
        if self.nUseCount <= 0 then
            return
        end

        self.nUseCount = self.nUseCount - 1
        self:UpdateStatus()
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function()
        if self.nUseCount >= self:GetMaxUseCount() then
            return
        end

        self.nUseCount = self.nUseCount + 1
        self:UpdateStatus()
    end)

    UIHelper.BindUIEvent(self.BtnMax, EventType.OnClick, function()
        self.nUseCount = self:GetMaxUseCount()
        self:UpdateStatus()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditUseCount, function()
        self:OnEditUseCountChanged()
    end)
end

function UIPartnerUpPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nRetCode, dwID)
        if dwID ~= self.dwID then
            return
        end

        --数据变动
        if nRetCode == NPC_ASSISTED_RESULT_CODE.NPC_ASSISTED_INFO_CHANGE then
            -- 与端游保持一致，使用后数目初始化
            self.nUseCount = self:GetInitialCount()

            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditUseCount then return end

        self:OnEditUseCountChanged()
    end)

    --- 通过点击升级道具的tips中的获取途径，打开 秘境大全、大侠之路、交易行 界面时隐藏升级界面，等他们关闭后再恢复显示
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelSearchItem or
                nViewID == VIEW_ID.PanelDungeonEntrance or
                nViewID == VIEW_ID.PanelRoadCollection
        then
            UIMgr.Close(self)
        end
    end)
end

function UIPartnerUpPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerUpPopView:UpdateInfo()
    self:SetUpgradeItemList()
    self:UpdateStatus()
end

function UIPartnerUpPopView:SetUpgradeItemList()
    UIHelper.RemoveAllChildren(self.LayouMiddlePartnertUpItem)

    local tItemInfo = Partner_GetUpGradeItemSetting()
    for idx, tItem in ipairs(tItemInfo) do
        local nType   = tItem.nType
        local dwIndex = tItem.dwIndex

        local script  = UIMgr.AddPrefab(PREFAB_ID.WidgetPartnerUpItem, self.LayouMiddlePartnertUpItem, nType, dwIndex)
        UIHelper.BindUIEvent(script.TogPartnerUpItem, EventType.OnClick, function()
            self.nSelectIndex = idx
            self.nUseCount    = self:GetInitialCount()
            self:UpdateStatus()
        end)
        Timer.AddFrame(self, 1, function()
            if idx == self.nSelectIndex then
                UIHelper.SetSelected(script.TogPartnerUpItem, true)
            end
        end)
    end

    UIHelper.LayoutDoLayout(self.LayouMiddlePartnertUpItem)
end

function UIPartnerUpPopView:UpdateStatus()
    local dwID  = self.dwID
    local tInfo = Partner_GetPartnerInfo(dwID)
    if not tInfo then
        return
    end
    local nLevel       = tInfo.nLevel
    local tLevelConfig = PartnerData.GetNpcAssistedLevelUpData(dwID, nLevel)
    if not tLevelConfig then
        return
    end
    local dwExp     = tInfo.dwExp
    local dwMaxExp  = tLevelConfig.nExperience

    local nMaxLevel = Partner_GetPartnerMaxLevel()
    if nLevel >= nMaxLevel then
        UIHelper.SetString(self.LabelExp, g_tStrings.STR_PARTNER_GET_MAX_LEVEL)
    else
        local dwSimpleExp    = Partner_GetSimpleExp(dwExp)
        local dwSimpleMaxExp = Partner_GetSimpleExp(dwMaxExp)
        UIHelper.SetString(self.LabelExp, dwSimpleExp .. "/" .. dwSimpleMaxExp)
    end

    UIHelper.SetProgressBarPercent(self.ProgressBarBefore, 100 * dwExp / dwMaxExp)

    UIHelper.SetString(self.EditUseCount, self.nUseCount)

    local bCanUse = self.nUseCount > 0
    UIHelper.SetEnable(self.BtnConfirm, bCanUse)
    UIHelper.SetNodeGray(self.BtnConfirm, not bCanUse, true)

    UIHelper.SetVisible(self.LabelExpAdd, self.nUseCount > 0)
    UIHelper.SetVisible(self.ProgressBarAfter, self.nUseCount > 0)
    if self.nUseCount > 0 then
        local tItemInfo           = Partner_GetUpGradeItemSetting()
        local tItem               = tItemInfo[self.nSelectIndex]
        local dwAddExp            = tItem.dwExp * self.nUseCount
        local nAddLevel, fPercent = self:GetAddLevel(dwAddExp)
        UIHelper.SetVisible(self.ProgressBarBefore, nAddLevel <= 0)
        UIHelper.SetProgressBarPercent(self.ProgressBarAfter, 100 * fPercent)

        UIHelper.SetRichText(self.LabelSikllLevelNum, string.format("<color=#DCF1F5>%d</c><color=#ffc224>+%d</color>", nLevel, nAddLevel))

        local dwSimpleAddExp = Partner_GetSimpleExp(dwAddExp)
        UIHelper.SetString(self.LabelExpAdd, string.format("+%s", tostring(dwSimpleAddExp)))
    else
        UIHelper.SetVisible(self.ProgressBarBefore, true)
        UIHelper.SetRichText(self.LabelSikllLevelNum, nLevel)
    end

    UIHelper.LayoutDoLayout(self.LayoutExp)
end

function UIPartnerUpPopView:GetMaxUseCount()
    local tItemInfo      = Partner_GetUpGradeItemSetting()
    local tItem          = tItemInfo[self.nSelectIndex]
    local nMaxCount      = ItemData.GetItemAmountInPackage(tItem.nType, tItem.dwIndex)

    local nMaxLevel      = Partner_GetPartnerMaxLevel()
    local nNeedMaxAmount = self:GetUpGradeNeedItemAmount(tItem, nMaxLevel)

    local nAmount        = math.min(nMaxCount, nNeedMaxAmount)

    return nAmount
end

function UIPartnerUpPopView:GetInitialCount()
    local tItemInfo = Partner_GetUpGradeItemSetting()
    local tItem     = tItemInfo[self.nSelectIndex]
    local nMaxCount = ItemData.GetItemAmountInPackage(tItem.nType, tItem.dwIndex)

    if nMaxCount > 0 then
        return 1
    else
        return 0
    end
end

function UIPartnerUpPopView:GetUpGradeNeedItemAmount(tItem, nTargetLevel)
    local dwID             = self.dwID
    local tPartner         = Partner_GetPartnerInfo(dwID)
    local nLevel           = tPartner.nLevel
    local tCurLevelSetting = PartnerData.GetNpcAssistedLevelUpData(dwID, nLevel)
    local nCurLevelNeedExp = tCurLevelSetting.nExperience - tPartner.dwExp
    local nNeedAllExp      = nCurLevelNeedExp
    for i = nLevel + 1, nTargetLevel - 1 do
        local tNeedExp = PartnerData.GetNpcAssistedLevelUpData(dwID, i)
        if tNeedExp then
            nNeedAllExp = nNeedAllExp + tNeedExp.nExperience
        end
    end
    local dwSingleExp = tItem.dwExp
    return math.ceil(nNeedAllExp / dwSingleExp)
end

function UIPartnerUpPopView:GetAddLevel(dwAddExp)
    local dwID         = self.dwID
    local tPartnerInfo = Partner_GetPartnerInfo(dwID)
    local nMaxLevel    = Partner_GetPartnerMaxLevel()
    local nAddLevel    = -1
    local fAddPercent  = 0
    if tPartnerInfo then
        local nLevel   = tPartnerInfo.nLevel
        local dwCurExp = tPartnerInfo.dwExp
        while dwAddExp >= 0 do
            nAddLevel    = nAddLevel + 1
            local tLevel = PartnerData.GetNpcAssistedLevelUpData(dwID, nLevel)
            if not tLevel or nLevel >= nMaxLevel then
                return nAddLevel, 0
            end
            local dwMaxExp  = tLevel.nExperience
            fAddPercent     = (dwCurExp + dwAddExp) / dwMaxExp
            local dwNeedExp = dwMaxExp - dwCurExp
            dwAddExp        = dwAddExp - dwNeedExp
            nLevel          = nLevel + 1
            dwCurExp        = 0
        end
    end
    return nAddLevel, fAddPercent
end

function UIPartnerUpPopView:OnEditUseCountChanged()
    self.nUseCount = tonumber(UIHelper.GetString(self.EditUseCount))

    local nMax     = self:GetMaxUseCount()
    if self.nUseCount >= nMax then
        self.nUseCount = nMax
    elseif self.nUseCount <= 0 then
        self.nUseCount = 0
    end

    self:UpdateStatus()
end

return UIPartnerUpPopView