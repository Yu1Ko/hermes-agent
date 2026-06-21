-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetCustom
-- Date: 2024-05-06 20:07:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetCustom = class("UIWidgetCustom")

function UIWidgetCustom:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
end

function UIWidgetCustom:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetCustom:BindUIEvent()
    --UIHelper.BindUIEvent(self.BtnSelectZone, EventType.OnClick, function()
    --    LOG.INFO("WidgetPlayerInfoAnchor.BtnSelectZone")
    --end)
end

function UIWidgetCustom:RegEvent()
    Event.Reg(self, "ON_ENTER_SINGLENODE_CUSTOM", function (nRangeType, nNodeType, nMode)
        self.bCustom = true
        self.nNodeType = nNodeType
        self.nBtnZoneX, self.nBtnZoneY = UIHelper.GetPosition(self.BtnSelectZone)
        --if self.tbCurNode then
        --    self:UpdatePosition()   --缩放后可能超出边界
        --end
    end)

    Event.Reg(self, "ON_CHANGE_FONT_SIZE", function(tbSizeType, nType, nNodeType)
        if self.tbCurNode then
            self:UpdatePosition(nType, nNodeType)   --缩放后可能超出边界
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        --if not self.bCustom then
        --    return
        --end
        --self.nAreaWidth = UIHelper.GetWidth(self.ImgBlackBg)
        --self.nAreaHeight = UIHelper.GetHeight(self.ImgBlackBg)
        self:UpdateEdgeLengthInfo()
        --Timer.Add(self, 1, function ()
        --    if self.tbCurNode then
        --        self:UpdatePosition(CUSTOM_BTNSTATE.ENTER)   --偏移后可能超出边界
        --    end
        --end)
    end)

    Event.Reg(self, "ON_TOUCH_BLANK_REGION", function ()--点击空白区域
        self.bCustom = false
    end)
end

function UIWidgetCustom:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCustom:UpdateInfo()

end

function UIWidgetCustom:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd, tbCurNode, nNodeType, tbFakeScript)
    --self.tbCurNode = tbCurNode
    self.fnDragMoved = fnDragMoved
	UIHelper.BindUIEvent(self.BtnSelectZone, EventType.OnTouchBegan, function(btn, nX, nY)
        self.nTouchBeganX, self.nTouchBeganY = nX, nY
        self.nWx, self.nWy = UIHelper.GetWorldPosition(self._rootNode)
        self.bDragging = false
        fnDragStart(nX, nY)
        return true
    end)

    UIHelper.BindUIEvent(self.BtnSelectZone, EventType.OnTouchMoved, function(btn, nX, nY)
        local w, h = UIHelper.GetContentSize(self.BtnSelectZone)
        if self.nType == CUSTOM_TYPE.CHAT or self.nType == CUSTOM_TYPE.SKILL then
            w, h = UIHelper.GetContentSize(tbFakeScript.ImgSelectZone)
        end
        local nScaleX = UIHelper.GetScaleX(self._rootNode)
        nScaleX = self.nType == CUSTOM_TYPE.TASK and UIHelper.GetScaleX(self.BtnSelectZone) or nScaleX
        w, h = w * nScaleX, h * nScaleX
        local ndx = nX - self.nTouchBeganX
        local ndy = nY - self.nTouchBeganY
        local nNewX = self.nWx + ndx
        local nNewY = self.nWy + ndy
        if self.nType == CUSTOM_TYPE.CUSTOMBTN then
            nNewX = nNewX + w + self.nBtnZoneX > self.nRight and self.nRight - w - self.nBtnZoneX or nNewX + self.nBtnZoneX < self.nLeft and self.nLeft - self.nBtnZoneX or nNewX
            nNewY = nNewY < self.nBottom and self.nBottom or nNewY + h > self.nTop and self.nTop - h or nNewY
        elseif self.nType == CUSTOM_TYPE.QUICKUSE or self.nType == CUSTOM_TYPE.BUFF or self.nType == CUSTOM_TYPE.KILL_FEED then
            nNewX = nNewX + w / 2 + self.nBtnZoneX > self.nRight and self.nRight - w / 2 - self.nBtnZoneX or nNewX + self.nBtnZoneX - w / 2 < self.nLeft and self.nLeft - self.nBtnZoneX + w / 2 or nNewX
            nNewY = nNewY + self.nBtnZoneY +  h / 2 > self.nTop and self.nTop - self.nBtnZoneY - h / 2 or nNewY - h / 2 + self.nBtnZoneY < self.nBottom and self.nBottom + h / 2 - self.nBtnZoneY or nNewY
        elseif self.nType == CUSTOM_TYPE.MENU then
            nNewX = nNewX + self.nBtnZoneX > self.nRight and self.nRight or nNewX + self.nBtnZoneX - w < self.nLeft and self.nLeft + w or nNewX
            nNewY = nNewY + self.nBtnZoneY > self.nTop and self.nTop - self.nBtnZoneY or nNewY - h + self.nBtnZoneY < self.nBottom and self.nBottom + h - self.nBtnZoneY or nNewY
        elseif self.nType == CUSTOM_TYPE.SKILL then
            nNewX = nNewX + self.nBtnZoneX > self.nRight and self.nRight or nNewX + self.nBtnZoneX - w < self.nLeft and self.nLeft + w or nNewX
            nNewY = nNewY + self.nBtnZoneY + h > self.nTop and self.nTop - self.nBtnZoneY - h or nNewY + self.nBtnZoneY < self.nBottom and self.nBottom or nNewY
        elseif self.nType == CUSTOM_TYPE.CHAT then
            nNewX = nNewX + self.nBtnZoneX + w > self.nRight and self.nRight - w - self.nBtnZoneX  * nScaleX or nNewX + self.nBtnZoneX < self.nLeft and self.nLeft or nNewX
            nNewY = nNewY + self.nBtnZoneY + h > self.nTop and self.nTop - self.nBtnZoneY - h or nNewY + self.nBtnZoneY < self.nBottom and self.nBottom or nNewY
        elseif self.nType == CUSTOM_TYPE.ENERGYBAR or self.nType == CUSTOM_TYPE.SPECIALSKILLBUFF then
            nNewX = nNewX + self.nBtnZoneX > self.nRight and self.nRight or nNewX + self.nBtnZoneX - w < self.nLeft and self.nLeft + w or nNewX
            nNewY = nNewY < self.nBottom and self.nBottom or nNewY + h > self.nTop and self.nTop - h or nNewY
        else
            nNewX = nNewX + w + self.nBtnZoneX * nScaleX > self.nRight and self.nRight - w - self.nBtnZoneX * nScaleX or
                nNewX + self.nBtnZoneX * nScaleX < self.nLeft and self.nLeft - self.nBtnZoneX * nScaleX or nNewX
            nNewY = nNewY + self.nBtnZoneY > self.nTop and self.nTop - self.nBtnZoneY or nNewY - h + self.nBtnZoneY < self.nBottom and self.nBottom + h - self.nBtnZoneY or nNewY
        end
        UIHelper.SetWorldPosition(self._rootNode, nNewX, nNewY)
        UIHelper.SetWorldPosition(tbCurNode, nNewX, nNewY)
        fnDragMoved(nX, nY, self)
    end)

    UIHelper.BindUIEvent(self.BtnSelectZone, EventType.OnTouchEnded, function(btn, nX, nY)
        --if self.bDragging then
            fnDragEnd(nX, nY)
            self.bDragging = false
            self.nTouchBeganX, self.nTouchBeganY = nil, nil
            self.nWx, self.nWy = nil, nil
        --end

    end)

    UIHelper.BindUIEvent(self.BtnSelectZone, EventType.OnTouchCanceled, function(btn, nX, nY)
        fnDragEnd(nX, nY)
        self.bDragging = false
        self.nTouchBeganX, self.nTouchBeganY = nil, nil
        self.nWx, self.nWy = nil, nil
    end)
end

function UIWidgetCustom:UnBindMoveFunction()
    UIHelper.UnBindUIEvent(self.BtnSelectZone, EventType.OnTouchBegan)
    UIHelper.UnBindUIEvent(self.BtnSelectZone, EventType.OnTouchMoved)
    UIHelper.UnBindUIEvent(self.BtnSelectZone, EventType.OnTouchEnded)
    UIHelper.UnBindUIEvent(self.BtnSelectZone, EventType.OnTouchCanceled)
    self.fnDragMoved = nil
end

function UIWidgetCustom:Init(ImgBlackBg, nType, tbCurNode, fnJudgeOverLapping)
    self.ImgBlackBg = ImgBlackBg
    --self.nAreaWidth = UIHelper.GetWidth(ImgBlackBg)
    --self.nAreaHeight = UIHelper.GetHeight(ImgBlackBg)
    self:UpdateEdgeLengthInfo()

    self.nType = nType
    self.tbCurNode = tbCurNode
    self.fnJudgeOverLapping = fnJudgeOverLapping
end

function UIWidgetCustom:UpdatePosition(nType, nNodeType)
    if nNodeType and nNodeType ~= self.nType then
        return
    end

    local w, h = UIHelper.GetContentSize(self.BtnSelectZone)
    local nScaleX = UIHelper.GetScaleX(self._rootNode)
    nScaleX = self.nType == CUSTOM_TYPE.TASK and UIHelper.GetScaleX(self.BtnSelectZone) or nScaleX
    w, h = w * nScaleX, h * nScaleX

    local nNewX, nNewY = UIHelper.GetWorldPosition(self._rootNode)

    if self.nType == CUSTOM_TYPE.SKILL or self.nType == CUSTOM_TYPE.ENERGYBAR or self.nType == CUSTOM_TYPE.SPECIALSKILLBUFF then
        nNewX = nNewX - w < self.nLeft and self.nLeft + w or nNewX
        nNewY = nNewY + h > self.nTop and self.nTop - h or nNewY
    elseif self.nType == CUSTOM_TYPE.MENU then
        nNewX = nNewX - w < self.nLeft and self.nLeft + w or nNewX
        nNewY = nNewY - h < self.nBottom and self.nBottom + h or nNewY
    elseif self.nType == CUSTOM_TYPE.CUSTOMBTN then
        nNewX = nNewX + w > self.nRight and self.nRight - w or nNewX
        nNewY = nNewY + h > self.nTop and self.nTop - h or nNewY
    elseif self.nType == CUSTOM_TYPE.CHAT then
        nNewX = nNewX + w > self.nRight and self.nRight - w or nNewX < self.nLeft and self.nLeft or nNewX
        nNewY = nNewY + h > self.nTop and self.nTop - h or nNewY
    elseif self.nType == CUSTOM_TYPE.QUICKUSE or self.nType == CUSTOM_TYPE.BUFF or self.nType == CUSTOM_TYPE.KILL_FEED then
        nNewX = nNewX + w / 2 > self.nRight and self.nRight - w / 2 or nNewX - w / 2 < self.nLeft and self.nLeft + w / 2 or nNewX
        nNewY = nNewY + h / 2 > self.nTop and self.nTop - h / 2 or nNewY - h / 2 < self.nBottom and self.nBottom + h / 2 or nNewY
    else
        nNewX = nNewX + w > self.nRight and self.nRight - w or nNewX < self.nLeft and self.nLeft or nNewX
        nNewY = nNewY - h < self.nBottom and self.nBottom + h or nNewY > self.nTop and self.nTop or nNewY
    end
    UIHelper.SetWorldPosition(self._rootNode, nNewX, nNewY)
    UIHelper.SetWorldPosition(self.tbCurNode, nNewX, nNewY)

    if self.fnDragMoved then
        self.fnDragMoved(nil, nil, self)
    else
        self.fnJudgeOverLapping(nType)
    end

end

function UIWidgetCustom:UpdateEdgeLengthInfo()
    if not self.ImgBlackBg then return end

    local nWidth = UIHelper.GetWidth(self.ImgBlackBg)
    local nHeight = UIHelper.GetHeight(self.ImgBlackBg)

    local nImgX, nImgY = UIHelper.GetWorldPosition(self.ImgBlackBg)
    self.nLeft = nImgX - nWidth / 2
    self.nRight = nImgX + nWidth / 2
    self.nTop = nImgY + nHeight / 2
    self.nBottom = nImgY - nHeight / 2
end










function UIWidgetCustom:BindDragSize(nCustomType, btn, bHorizontal, oneScript, imgBlackBg, nMode)
    if not btn then return end
    if not oneScript then return end

    local node = oneScript._rootNode

    local parent = UIHelper.GetParent(node)
    local nMinW, nMinH = Storage.ControlMode.tbChatBtnSelectSize[nMode].nWidth, Storage.ControlMode.tbChatBtnSelectSize[nMode].nHeigh
    local nBgW, nBgH = UIHelper.GetContentSize(imgBlackBg)
    local nBgX, nBgY = UIHelper.GetPosition(imgBlackBg)
    local nBgWX, nBgWY = UIHelper.GetWorldPosition(imgBlackBg)

    local nDeltaW = UIHelper.GetWidth(oneScript.ImgSelectZone) - UIHelper.GetWidth(self.BtnSelectZone)
    nBgW = nBgW - nDeltaW

    UIHelper.BindUIEvent(btn, EventType.OnTouchBegan, function(btn, nX, nY)
        self.nLastDragSizeX = nX
        self.nLastDragSizeY = nY
    end)

    UIHelper.BindUIEvent(btn, EventType.OnTouchMoved, function(btn, nX, nY)
        local nDeltaX = nX - self.nLastDragSizeX
        local nDeltaY = nY - self.nLastDragSizeY

        local nNowW = UIHelper.GetWidth(node) + nDeltaX
        local nNowH = UIHelper.GetHeight(node) + nDeltaY



        if nNowW < nMinW then nNowW = nMinW end
        if nNowH < nMinH then nNowH = nMinH end

        local nNodeX, nNodeY = UIHelper.GetPosition(parent)
        local nNodeScale = UIHelper.GetScale(parent)

        local nNodeWX, nNodeWY = UIHelper.GetWorldPosition(parent)


        if (nNodeX - nBgX) + nNowW * nNodeScale > nBgW / 2 then nNowW = (nBgW / 2 - (nNodeX - nBgX)) / nNodeScale end
        --if (nNodeY - nBgY) + nNowH * nNodeScale > nBgH / 2 then nNowH = (nBgH / 2 - (nNodeY - nBgY)) / nNodeScale end
        if nNodeWY + nNowH * nNodeScale > nBgWY + nBgH / 2 then
            nNowH = (nBgWY + nBgH / 2 - nNodeWY) / nNodeScale
        end

        if bHorizontal then
            UIHelper.SetWidth(node, nNowW)
        else
            UIHelper.SetHeight(node, nNowH)
        end

        UIHelper.WidgetFoceDoAlign(oneScript)

        UIHelper.SetContentSize(self.BtnSelectZone, nNowW, nNowH)

        Event.Dispatch(EventType.OnMainCityCustomSizeChanged, nCustomType, nNowW, nNowH)

        self.nLastDragSizeX = nX
        self.nLastDragSizeY = nY
        MainCityCustomData.SetChatContentSizeChanged(true)
    end)

    UIHelper.BindUIEvent(btn, EventType.OnTouchEnded, function(btn, nX, nY)
        self.fnJudgeOverLapping()
    end)

    UIHelper.BindUIEvent(btn, EventType.OnTouchCanceled, function(btn, nX, nY)
        self.fnJudgeOverLapping()
    end)
end

function UIWidgetCustom:UnBindDragSize(nCustomType, btn, bHorizontal, oneScript)
    UIHelper.UnBindUIEvent(btn, EventType.OnTouchBegan)
    UIHelper.UnBindUIEvent(btn, EventType.OnTouchMoved)
    UIHelper.UnBindUIEvent(btn, EventType.OnTouchEnded)
    UIHelper.UnBindUIEvent(btn, EventType.OnTouchCanceled)
end

return UIWidgetCustom