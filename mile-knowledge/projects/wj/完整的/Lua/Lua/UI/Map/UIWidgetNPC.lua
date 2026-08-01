-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetNPC
-- Date: 2024-03-07 10:07:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetNPC = class("UIWidgetNPC")

function UIWidgetNPC:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetNPC:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetNPC:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTrace_NPC, EventType.OnClick, function()
        local bTrace = self:IsTrace()
        if bTrace then
            MapMgr.ClearTracePoint()
        else
            local tbPoint = self.tbInfo.tbPoint
            local szImage = self.tbInfo.szTraceImg
            MapMgr.SetTracePoint(self.tbInfo.szName, self.nMapID, tbPoint, nil, szImage)
        end
        self:Hide()
    end)

    UIHelper.BindUIEvent(self.BtnWalk_NPC, EventType.OnClick, function()

        if self.bInTransmit then
            if self.funcTransmit then
                self.funcTransmit()
            end
            return
        end

        local bNavTo = self:IsAutoNav()
        if bNavTo then
            AutoNav.StopNav()
        else
            local tbPoint = self.tbInfo.tbPoint
            local szRemark = "NPC_" .. self.tbInfo.szName .. "_" .. self.tbInfo.szType
            szRemark = UIHelper.LimitUtf8Len(szRemark, 64)
            AutoNav.NavTo(self.nMapID, tbPoint[1], tbPoint[2], tbPoint[3], AutoNav.DefaultNavCutTailCellCount, szRemark)
        end
        self:Hide()
    end)
end

function UIWidgetNPC:RegEvent()

end

function UIWidgetNPC:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetNPC:Show(tbInfo, nX, nY, nMapID)
    self.tbInfo = tbInfo
    self.nMapID = nMapID

    local szType = tbInfo.szType
    local szName = tbInfo.szName
    local szDesc = tbInfo.szDesc

    local szContent = ""
    local tbStr = {}
    if szType and szType ~= "" then
        table.insert(tbStr, szType)
    end

    if szName and szName ~= "" then
        table.insert(tbStr, szName)
    end

    for nIndex, szName in ipairs(tbStr) do
        if nIndex ~= 1 then
            szContent = szContent .. "·" .. szName
        else
            szContent = szName
        end
    end

    if szDesc and szDesc ~= "" then
        UIHelper.SetRichText(self.LabelNPCDes, "<color=#aef6ff>" .. szDesc .. "</c>")
    end
    UIHelper.SetString(self.LabelNpc, szContent)
    UIHelper.SetSpriteFrame(self.ImgNpcType, tbInfo.szImgType)

    local bButtonGray = tbInfo.bButtonGray or false
    UIHelper.SetNodeGray(self.ImgNpcType, bButtonGray, true)

    UIHelper.SetVisible(self.LabelNPCDes, szDesc and szDesc ~= "")
    UIHelper.SetVisible(self.ImgBg, szType ~= "")

    UIHelper.LayoutDoLayout(self.LayoutNPCDes)
    UIHelper.LayoutDoLayout(self.WidgetTitle)
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    local bTrace = self:IsTrace()
    local bNavTo = self:IsAutoNav()

    UIHelper.SetString(self.LabelTrace_NPC, bTrace and "取消追踪" or "追踪")
    UIHelper.SetString(self.LabelWalk_NPC, bNavTo and "取消寻路" or "自动寻路")

    UIHelper.SetPosition(self._rootNode, nX, nY)
    UIHelper.SetVisible(self._rootNode, true)

    self:HideTransmit()

end

function UIWidgetNPC:HideTransmit()
    self.bInTransmit = false
    self.funcTransmit = nil
end

function UIWidgetNPC:ShowTransmit(funcTransmit)
    self.bInTransmit = true
    self.funcTransmit = funcTransmit
    UIHelper.SetString(self.LabelWalk_NPC, "传送")
end

function UIWidgetNPC:Hide()
    self.tbInfo = nil
    UIHelper.SetVisible(self._rootNode, false)
end

function UIWidgetNPC:IsTrace()
    local tbPoint = self.tbInfo.tbPoint
    local bTrace = MapMgr.IsNodeTraced(self.nMapID, tbPoint)
    return bTrace
end

function UIWidgetNPC:IsAutoNav()
    local tbPoint = self.tbInfo and self.tbInfo.tbPoint
    if not tbPoint then return false end
    local bAutoNav = AutoNav.IsCurNavPoint(self.nMapID, tbPoint[1], tbPoint[2], tbPoint[3])
    return bAutoNav
end

return UIWidgetNPC