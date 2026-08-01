-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMapPQ_Arrow
-- Date: 2024-04-02 16:10:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMapPQ_Arrow = class("UIWidgetMapPQ_Arrow")

function UIWidgetMapPQ_Arrow:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetMapPQ_Arrow:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMapPQ_Arrow:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnArrow, EventType.OnClick, function()
        if self.fnSelected then
            self.fnSelected()
        end
    end)
end

function UIWidgetMapPQ_Arrow:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_START_MOVE_BOARD_NODE", function(script)
        UIHelper.SetTouchEnabled(self.BtnArrow, false)
    end)

    Event.Reg(self, "ON_END_MOVE_BOARD_NODE", function(script)
        UIHelper.SetTouchEnabled(self.BtnArrow, true)
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_SCALE_CHANGE", function()
        local tbInfo = {
            nType = self.tbInfo.nType,
            nX = self.nLogicStartX,
            nY = self.nLogicStartY,
            nEndX = self.nEndX,
            nEndY = self.nEndY, 
        }
        Event.Dispatch("ON_MIDDLE_UPDATE_MAP_ARROW_POS", tbInfo, self)
    end)
end

function UIWidgetMapPQ_Arrow:UnRegEvent()
    
end

function UIWidgetMapPQ_Arrow:SetArrow(tbInfo, nStartX, nStartY, nEndX, nEndY, nLogicStartX, nLogicStartY)
    self.tbInfo = tbInfo
    self.tbCommand = MapMgr.GetMarkInfoByTypeID(tbInfo.nType)
    self.nStartX = nStartX
    self.nStartY = nStartY
    self.nLogicStartX = nLogicStartX
    self.nLogicStartY = nLogicStartY
    self.szFrame = UIHelper.GBKToUTF8(self.tbCommand.szMobileImage)

    UIHelper.SetSpriteFrame(self.ImgArrow, self.szFrame)

    UIHelper.SetPressedActionEnabled(self.BtnArrow, false)--屏蔽掉鼠标Hover过后按钮scale自动还原

    self.nOriginX, self.nOriginY = UIHelper.GetPosition(self.BtnArrow)
    self.nOriginLen = UIHelper.GetWidth(self.BtnArrow)
    self:UpdateArrowRotationAndLenth(nEndX, nEndY, tbInfo.nEndX, tbInfo.nEndY)
    UIHelper.SetTouchEnabled(self.BtnArrow, MapMgr.IsPlayerCanDraw())
end


function UIWidgetMapPQ_Arrow:UpdateArrowRotationAndLenth(nEndX, nEndY, nLogicEndX, nLogicEndY)
    local nLogicLenth = math.sqrt((nEndY - self.nStartY)*(nEndY - self.nStartY)
                            +(nEndX - self.nStartX)*(nEndX - self.nStartX))
    local nScale = nLogicLenth / self.nOriginLen

    local nCos = (nEndX - self.nStartX) / nLogicLenth--cos值
    local nRotation = math.acos(nCos) * 180 / math.pi

    if nEndY > self.nStartY then
        nRotation = 360 - nRotation
    end

    UIHelper.SetScale(self.BtnArrow, nScale, 1)
    UIHelper.SetRotation(self.BtnArrow, nRotation)

    UIHelper.SetPosition(self.BtnArrow, self.nOriginX + (nEndX - self.nStartX) / 2, self.nOriginY + (nEndY - self.nStartY) / 2)
    self.nEndX = nLogicEndX
    self.nEndY = nLogicEndY
end



function UIWidgetMapPQ_Arrow:GetArrowInfo()
    local tbInfo = {}
    tbInfo.nType = self.tbInfo.nType
    tbInfo.nX = self.tbInfo.nX
    tbInfo.nY = self.tbInfo.nY
    tbInfo.nImageWidth = self.nEndX
    tbInfo.nRotateDegree = self.nEndY
    return tbInfo
end

function UIWidgetMapPQ_Arrow:SetPosition(x, y, nLogicX, nLogicY)
    self.nX = x
    self.nY = y
    self.nLogicX = nLogicX
    self.nLogicY = nLogicY
    if safe_check(self.BtnArrow) then
        local offsetX, offsetY = self.BtnArrow:getPosition()
        self._rootNode:setPosition(x - offsetX, y - offsetY)
    end
end

function UIWidgetMapPQ_Arrow:CanShow()
    return true
end

return UIWidgetMapPQ_Arrow