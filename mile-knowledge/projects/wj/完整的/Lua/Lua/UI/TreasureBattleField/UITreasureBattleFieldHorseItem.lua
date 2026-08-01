-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldHorseItem
-- Date: 2023-05-22 14:55:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldHorseItem = class("UITreasureBattleFieldHorseItem")

function UITreasureBattleFieldHorseItem:OnEnter(dwBox, dwX, tipsNode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwBox = dwBox
    self.dwX = dwX
    self.tipsNode = tipsNode
    self:UpdateInfo()
end

function UITreasureBattleFieldHorseItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldHorseItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogHores, EventType.OnSelectChanged, function (_, bSelected)
        self:OnSelected(bSelected)
    end)
end

function UITreasureBattleFieldHorseItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldHorseItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldHorseItem:UpdateInfo()
    local dwEquipBox, dwEquipX = g_pClientPlayer.GetEquippedHorsePos()
    local bCurrent = dwEquipBox == self.dwBox and dwEquipX == self.dwX
    UIHelper.SetVisible(self.ImgTab, bCurrent)

    local item = ItemData.GetItemByPos(self.dwBox, self.dwX)
    if item then
        if not self.itemScript then
            self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
            self.itemScript:SetSelectEnable(false)
            self.itemScript:EnableTimeLimitFlag(true)
        end
        self.itemScript:OnInit(self.dwBox, self.dwX)

        local szName = UIHelper.GBKToUTF8(Table_GetItemName(item.nUiId))
        UIHelper.SetString(self.LabelName, szName)
        UIHelper.SetString(self.LabelNameSelected, szName)
        local fCurFullMeasure = item.GetHorseFullMeasure()
        local fMaxFullMeasure = item.GetHorseMaxFullMeasure()
        local nPercent = math.ceil(fCurFullMeasure * 100 / fMaxFullMeasure)

        local baseAttib = item.GetBaseAttrib()
        for _, v in pairs(baseAttib) do
            local nID = v.nID
            local nValue1 = v.nValue1 or v.nMin
            local nValue2 = v.nValue2 or v.nMax
            if nID == ATTRIBUTE_TYPE.MOVE_SPEED_PERCENT then
                local nValue = math.floor(nValue1 * 100 / 1024 + 0.5)
                UIHelper.SetString(self.LabelState01, string.format("跑速 %d%%", nValue))
                UIHelper.SetString(self.LabelStateSelected01, string.format("跑速 %d%%", nValue))
            end
        end
        UIHelper.SetString(self.LabelState02, string.format("饱食度 %d%%", nPercent))
        UIHelper.SetString(self.LabelStateSelected02, string.format("饱食度 %d%%", nPercent))
        UIHelper.LayoutDoLayout(self.LayoutState)
        UIHelper.LayoutDoLayout(self.LayoutStateSelected)

        UIHelper.SetNodeGray(self._rootNode, fCurFullMeasure == 0, true)
    end
end

function UITreasureBattleFieldHorseItem:OnSelected(bSelected)
    if bSelected then
        local _, itemTips = TipsHelper.ShowItemTips(self.tipsNode, self.dwBox, self.dwX, true)
        if itemTips then
            local tbFuncButtons = {}
            local fnFeed = {
                szName = "喂食",
                OnClick = function ()
                    local player = g_pClientPlayer
                    if not player then
                        return
                    end
                    local dwMapID = player.GetMapID()
                    if player.GetItemAmount(5, TreasureBattleFieldData.tHorseFood[dwMapID]) > 0 then
                        local dwBox, dwX = player.GetItemPos(5, TreasureBattleFieldData.tHorseFood[dwMapID])
                        local nResult = player.FeedHorse(self.dwBox, self.dwX, dwBox, dwX)
                        if nResult ~= DOMESTICATE_OPERATION_RESULT_CODE.SUCCESS then
                            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tDometicateError[nResult])
                        end
                    else
                        TipsHelper.ShowNormalTip("你没有食料")
                    end
                end
            }
            table.insert(tbFuncButtons, fnFeed)
            local fnSet = {
                szName = "设为当前",
                OnClick = function ()
                    local player = g_pClientPlayer
                    if not player then
                        return
                    end
                    local nRet =  player.EquipHorse(self.dwBox, self.dwX)
                    if nRet ~= ITEM_RESULT_CODE.SUCCESS then
                        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tItem_Msg[nRet])
                    else
                        TipsHelper.ShowNormalTip("设置成功")
                    end
                end
            }
            table.insert(tbFuncButtons, fnSet)
            itemTips:SetBtnState(tbFuncButtons)
        end
    else
        UIHelper.SetSelected(self.TogHores, false, false)
    end
end

function UITreasureBattleFieldHorseItem:IsSelected()
    return UIHelper.GetSelected(self.TogHores)
end

return UITreasureBattleFieldHorseItem