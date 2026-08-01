-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHorseSlot
-- Date: 2022-12-06 13:05:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHorseSlot = class("UIHorseSlot")

function UIHorseSlot:OnEnter(tbSelectCell)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not tbSelectCell then
        return
    end

    self.tCell1 = tbSelectCell[1]
    self.tCell2 = tbSelectCell[2]
    local dwEquipBox, dwEquipX = g_pClientPlayer.GetEquippedHorsePos()

    for i = 1,2,1 do
        if tbSelectCell[i] then
            self:UpdateInfo(i,tbSelectCell[i])
            if tbSelectCell[i].dwBox == dwEquipBox and tbSelectCell[i].dwX == dwEquipX then
                self:SetSelectedEquipHorse(i,true)
            else
                self:SetSelectedEquipHorse(i,false)
            end
        end
        UIHelper.SetVisible(self.tbImgLike[i], false)
        UIHelper.LayoutDoLayout(self.tbLayout[i])
        UIHelper.SetVisible(self.tbWidget[i],tbSelectCell[i] and true or false)
    end
end

function UIHorseSlot:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHorseSlot:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAdd1,EventType.OnClick,function ()
        if self.tCell1 then
            UIHelper.SetVisible(self.tbImgNew[1], false)
            Event.Dispatch(EventType.HorseSlotSelectItem, self.tCell1.dwBox, self.tCell1.dwX,self.tCell1.dwItemTabType,self.tCell1.dwItemTabIndex)
        end
    end)
    UIHelper.BindUIEvent(self.BtnAdd2,EventType.OnClick,function ()
        if self.tCell2 then
            UIHelper.SetVisible(self.tbImgNew[2], false)
            Event.Dispatch(EventType.HorseSlotSelectItem, self.tCell2.dwBox, self.tCell2.dwX,self.tCell2.dwItemTabType,self.tCell2.dwItemTabIndex)
        end
    end)
end

function UIHorseSlot:RegEvent()
    Event.Reg(self,EventType.HorseSlotSelectItem,function (dwBox, dwX, dwItemTabType, dwItemTabIndex)
        if (self.tCell1.dwX == dwX and dwBox == self.tCell1.dwBox) or
        (dwItemTabType and self.tCell1.dwItemTabType == dwItemTabType and self.tCell1.dwItemTabIndex == dwItemTabIndex) then
            UIHelper.SetVisible(self.ImgSelectBG1,true)
            UIHelper.SetVisible(self.ImgSelectBG2,false)
        elseif (self.tCell2 and self.tCell2.dwX == dwX and dwBox == self.tCell2.dwBox) or
        (dwItemTabType and self.tCell2.dwItemTabType == dwItemTabType and self.tCell2.dwItemTabIndex == dwItemTabIndex) then
            UIHelper.SetVisible(self.ImgSelectBG2,true)
            UIHelper.SetVisible(self.ImgSelectBG1,false)
        else
            UIHelper.SetVisible(self.ImgSelectBG1,false)
            UIHelper.SetVisible(self.ImgSelectBG2,false)
        end
    end)
end

function UIHorseSlot:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHorseSlot:UpdateInfo(k,v)
    local item = ItemData.GetItemByPos(v.dwBox, v.dwX)
    if not item then
        UIHelper.SetNodeGray(self.tbImgIcon[k],true,true)
        UIHelper.SetOpacity(self.tbWidgetItem[k], 120)
    else
        UIHelper.SetNodeGray(self.tbImgIcon[k],false,true)
        UIHelper.SetOpacity(self.tbWidgetItem[k], 255)
        local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
        UIHelper.SetVisible(self.tbItemTime[k],  itemInfo.nExistType ~= ITEM_EXIST_TYPE.INVALID and itemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT)
    end

    if v.dwItemTabType and v.dwItemTabIndex then
        item = item or ItemData.GetItemInfo(v.dwItemTabType, v.dwItemTabIndex)
    end

    if item then
        local bResult = UIHelper.SetItemIconByItemInfo(self.tbImgIcon[k], item)
        if not bResult then
            UIHelper.ClearTexture(self.tbImgIcon[k])
        end

        UIHelper.SetSpriteFrame(self.tbImgQuality[k], ItemQualityBGColor[item.nQuality + 1])

        local szName = UIHelper.GBKToUTF8(Table_GetItemName(item.nUiId))
        szName = UIHelper.TruncateStringReturnOnlyResult(szName, 3, "...")
        UIHelper.SetString(self.tblabelName[k], szName)
    else
        UIHelper.ClearTexture(self.tbImgIcon[k])
    end

    UIHelper.SetVisible(self.ImgSelectBG1,false)
    UIHelper.SetVisible(self.ImgSelectBG2,false)
    UIHelper.SetVisible(self.tbImgQuality[k], item and true or false)
    UIHelper.SetVisible(self.tblabelName[k], item and true or false)
    UIHelper.SetVisible(self.tbItemAll[k], item and true or false)
    UIHelper.SetNodeSwallowTouches(self.tbBtnAdd[k], false, true)
    UIHelper.SetNodeSwallowTouches(self.tbWidgetItem[k], false, true)

    -- 新
    local bIsNew = RedpointHelper.Horse_Qiqu_IsNew(v.dwBox, v.dwX)
    UIHelper.SetVisible(self.tbImgNew[k], bIsNew)
end

function UIHorseSlot:SetSelectedHorse(bSelected)
    UIHelper.SetSelected(self.ToggleSelect,bSelected)
    if self.itemScript then
        self.itemScript:SetSelected(bSelected)
    end
end

function UIHorseSlot:SetSelectedEquipHorse(k,bVisible)
    UIHelper.SetVisible(self.tbImgNow[k],bVisible)
end
return UIHorseSlot