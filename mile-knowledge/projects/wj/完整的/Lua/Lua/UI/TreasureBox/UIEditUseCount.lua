-- ---------------------------------------------------------------------------------
-- 调整使用数量
-- ---------------------------------------------------------------------------------

local UIEditUseCount = class("UIEditUseCount")

function UIEditUseCount:_LuaBindList()
    self.EditPaginate            = self.EditPaginate --- 编辑框
    self.SliderCount             = self.SliderCount --- 滑动条
    self.ButtonAdd               = self.ButtonAdd --- 加数量
    self.ButtonDecrease          = self.ButtonDecrease --- 减数量
    self.WidgetCount             = self.WidgetCount --- 数量显示上层 家园隐藏
    self.BtnConfirm              = self.BtnConfirm --- 开启btn 家园置灰
    self.WidgetHome              = self.WidgetHome --- 家园显示
    self.BtnGoHome               = self.BtnGoHome --- 前往家园
end

function UIEditUseCount:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nImgSize = UIHelper.GetWidth(self.ImgBg)
    UIHelper.SetTouchDownHideTips(self.BtnConfirm, false)
    UIHelper.SetTouchDownHideTips(self.ButtonAdd, false)
    UIHelper.SetTouchDownHideTips(self.ButtonDecrease, false)
    UIHelper.SetTouchDownHideTips(self.SliderCount, false)
    UIHelper.SetTouchDownHideTips(self.EditPaginate, false)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
end

function UIEditUseCount:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIEditUseCount:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.bRandom then
            local bLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP)
            if bLocked then
                UIMgr.OpenSingle(false, VIEW_ID.PanelLingLongMiBao, SAFE_LOCK_EFFECT_TYPE.EQUIP)
                return
            end
            RemoteCallToServer("On_BoxOpenUI_Open", self.nCurCount, self.nBoxIndex, self.nBoxID, self.nContentType)
            if self.fnCallBack then
                local nFixNum = self.nCount - self.nCurCount
                Timer.AddFrame(self, 10, self.fnCallBack(self.nBoxID, self.nContentType, nFixNum))
            end
            UIMgr.Close(VIEW_ID.PanelRandomTreasureBox)
        else
        end
    end)

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function()
        if self.nCurCount == self.nCount then
            return
        end
        self.nCurCount = self.nCurCount + 1
        self.nCurCount = math.min(self.nCount, self.nCurCount)

        UIHelper.SetString(self.EditPaginate, tostring(self.nCurCount))
        UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
        UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function()
        if self.nCurCount == 1 then
            return
        end
        self.nCurCount = self.nCurCount - 1
        self.nCurCount = math.max(0, self.nCurCount)

        UIHelper.SetString(self.EditPaginate, tostring(self.nCurCount))
        UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
        UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
    end)

    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            self.nCurCount = math.ceil(self.nCurCount)
            UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
            UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
        end

        if self.bSliding then
            local percent = UIHelper.GetProgressBarPercent(self.SliderCount) / 100
            self.nCurCount = percent * self.nCount
            -- self.nCurCount = math.ceil(self.nCurCount)
            if self.nCurCount <= 1 then
                self.nCurCount = 1
            elseif self.nCurCount >= self.nCount then
                self.nCurCount = self.nCount
            end
            UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
            UIHelper.SetString(self.EditPaginate, tostring(math.ceil(self.nCurCount)))
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
        local nInput = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
        nInput = math.min(nInput, self.nCount)
        nInput = math.max(nInput, self.nCount > 0 and 1 or 0)
        self.nCurCount = nInput
        UIHelper.SetString(self.EditPaginate, nInput)
        UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
        UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
    end)

    UIHelper.BindUIEvent(self.BtnGoHome, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHome)
    end)

    UIHelper.BindUIEvent(self.BtnGetWay, EventType.OnClick, function()
        TipsHelper.DeleteAllHoverTips()
        local _, uiItemTipScript = TipsHelper.ShowItemTips(self.BtnGetWay, self.dwGetType, self.dwGetIndex)
        uiItemTipScript:SetBtnState({})
    end)
end

function UIEditUseCount:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox ~= self.EditPaginate then return end
        UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, 1, self.nCount)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then return end

        local nInput = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
        nInput = math.min(nInput, self.nCount)
        nInput = math.max(nInput, 1)
        self.nCurCount = nInput
        UIHelper.SetString(self.EditPaginate, nInput)
        UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
        UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
    end)
end

function UIEditUseCount:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------


--- 随机宝箱 begin ----------------------------------------------------------
function UIEditUseCount:UpdateRandomTreasureBox(dwBoxID, nFixNum)
    local tInfo = Tabel_GetTreasureBoxListByID(dwBoxID)
    local dwType, dwIndex = TreasureBoxData.SplitItemID(tInfo.szBoxItem)
    self.dwGetType = dwType
    self.dwGetIndex = dwIndex
    local BoxItem = ItemData.GetItemInfo(dwType, dwIndex)
    local _, nBagNum, _, _ = ItemData.GetItemAllStackNum(BoxItem, false)

    self.bRandom = true
    self.nBoxID = dwBoxID
    self.nBoxIndex = BoxItem.dwID
    self.nCount = nFixNum or nBagNum
    self.nCurCount = nFixNum or nBagNum

    UIHelper.SetString(self.EditPaginate, self.nCurCount)
    UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
    self.nImgSize = UIHelper.GetWidth(self.ImgBg)
    UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)

    if nBagNum == 0 or not self.bShowNum then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
    end
end


function UIEditUseCount:SetContentType(nType)
    self.nContentType = nType
end

function UIEditUseCount:SetCallBack(fnCallBack)
    self.fnCallBack = fnCallBack
end

-- 随机宝箱 end ----------------------------------------------------------

function UIEditUseCount:SetHomeLand(bHomeLand)
    if bHomeLand then
        local dwMapID = g_pClientPlayer.GetMapID()
        self.bShowNum = HomelandData.IsHomelandMap(dwMapID)
    else
        self.bShowNum = true
    end

    UIHelper.SetVisible(self.WidgetCount, self.bShowNum)
    UIHelper.SetVisible(self.WidgetHome, not self.bShowNum)
end

return UIEditUseCount