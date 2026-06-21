-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTaskItemUseView
-- Date: 2023-09-19 14:47:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTaskItemUseView = class("UIWidgetTaskItemUseView")

function UIWidgetTaskItemUseView:OnEnter(dwItemType, dwItemIndex, nAmount, bAutoNav)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwItemType = dwItemType
    self.dwItemIndex = dwItemIndex
    self.nAmount = nAmount
    self.bAutoNav = bAutoNav
    self:UpdateInfo()

    --仅教学用，获取任务道具使用按钮
    if not g_btnTaskUseItem then
        g_btnTaskUseItem = self.BtnItemUse1
    end
end

function UIWidgetTaskItemUseView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if g_btnTaskUseItem == self.BtnItemUse1 then
        g_btnTaskUseItem = nil
    end
end

function UIWidgetTaskItemUseView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnItemUse1, EventType.OnClick, function(btn)
        if self.bAutoNav then
            local nMapID, nX, nY, nZ, szName = self:GetNavMapAndPoint()
            if nMapID then
                local nMapID, nX, nY, nZ, szName = self:GetNavMapAndPoint()
                local szRemark = "NPC_" .. szName .. "_" .. "BossInfo"
                szRemark = UIHelper.LimitUtf8Len(szRemark, 64)
                AutoNav.NavTo(nMapID, nX, nY, nZ, AutoNav.DefaultNavCutTailCellCount, szRemark)
            end
        else
            if ItemData.CanQuickUseOnSkillSlot(self.dwItemType, self.dwItemIndex, ItemData.QuickUseOperateType.TrackQuest) then
                ItemData.AddQuickUseSlotType(self.dwItemType, self.dwItemIndex, ItemData.QuickUseOperateType.TrackQuest)
            else
                ItemData.QuickUseItem(self.dwItemType, self.dwItemIndex)    -- 功能更强大！
                -- local nBox, nIndex = ItemData.GetItemPos(self.dwItemType, self.dwItemIndex)
                -- if IsNumber(nBox) and IsNumber(nIndex) then
                --     ItemData.UseItem(nBox, nIndex)
                -- end
            end
        end
    end)
end

function UIWidgetTaskItemUseView:RegEvent()
    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        local nOldAmount = self.nAmount
        self.nAmount = ItemData.GetItemAmountInPackage(self.dwItemType, self.dwItemIndex)

        if nOldAmount ~= self.nAmount then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnAutoNavResult, function(bSuccess)
        if self.bAutoNav then
            self:UpdateNavState()
        end
    end)
end

function UIWidgetTaskItemUseView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetTaskItemUseView:UpdateNavState()
    if not self.bAutoNav then return end
    local nMapID, nX, nY, nZ, szName = self:GetNavMapAndPoint()
    local bNav = AutoNav.IsCurNavPoint(nMapID, nX, nY, nZ)
    if bNav then
        UIHelper.PlayAni(self, self.ImgTaskAuto, "AniTaskAuto2", function() 
            UIHelper.PlayAni(self, self.ImgTaskAuto, "AniTaskAuto2", nil, nil, true)
        end, 2)
    else
        UIHelper.StopAni(self, self.ImgTaskAuto, "AniTaskAuto2")
    end
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTaskItemUseView:UpdateInfo()
    if not self.bAutoNav then
        self.itemScript = self.itemScript or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItemIcon1)
        self.itemScript:OnInitWithTabID(self.dwItemType, self.dwItemIndex, self.nAmount)
        self.itemScript:SetIconGray(self.nAmount <= 0)  -- 未持有时置灰
        self.itemScript:HideButton()--屏蔽toggle功能
        self.itemScript:SetToggleSwallowTouches(false)--点击图标也需要支持使用物品
    end
    UIHelper.SetVisible(self.WidgetItemIcon1, not self.bAutoNav)
    UIHelper.SetVisible(self.LabelTaskItemUse, not self.bAutoNav)
    UIHelper.SetVisible(self.widgetWalk, self.bAutoNav)
    self:UpdateNavState()
end

function UIWidgetTaskItemUseView:GetNavMapAndPoint()
    local player = g_pClientPlayer
    if player then
        local nMapID = player.GetMapID()
        local tbBossInfo = DungeonData.GetFirstUnKillBoss(nMapID)
        if tbBossInfo then
            return nMapID, tbBossInfo.nX, tbBossInfo.nY, tbBossInfo.nZ, tbBossInfo.szName
        end
    end
    return nil
end


return UIWidgetTaskItemUseView