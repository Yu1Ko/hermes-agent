local UIMiddleMapTraceMerchant = class("UIMiddleMapTraceMerchant")

function UIMiddleMapTraceMerchant:OnEnter()
    
end

function UIMiddleMapTraceMerchant:OnExit()
end

function UIMiddleMapTraceMerchant:Show(tbInfo, nMapID, tPoint, szFrame, bTrace)
    self._rootNode:setVisible(true)

    self.tbInfo = tbInfo
    local szName = Table_GetNpcTemplateName(tbInfo.nNpcID)
    self.szName = GBKToUTF8(szName)

    self.LabelTitle02:setString(self.szName)
    UIHelper.SetSpriteFrame(self.ImgTitleIcon02, szFrame)
    self.RichTextMessage:setElementText(0, tbInfo.szKind)

    local szText = bTrace and g_tStrings.STR_MAP_TRACE_CANCCEL or g_tStrings.STR_MAP_TRACE_BEGIN
    self.LabelTtrace02:setString(szText)

    UIHelper.BindUIEvent(self.BtnTrace02, EventType.OnClick, function()
        if bTrace then
            MapMgr.ClearTracePoint()
            Event.Dispatch("ON_MIDDLE_MAP_MARK_UNCHECK")
        else
            MapMgr.SetTracePoint(self.szName, nMapID, tPoint)
            Event.Dispatch("ON_MIDDLE_MAP_MARK_UNCHECK")
        end
    end)
end

function UIMiddleMapTraceMerchant:UpdateInfo(tbDisplay, tbButton)
    self.LabelTitle02:setString(tbDisplay.szName)
    UIHelper.SetSpriteFrame(self.ImgTitleIcon02, tbDisplay.szFrame)
    self.RichTextMessage:setElementText(0, tbDisplay.szDesc)
    if tbDisplay.szLabel then
        self.LabelTtrace02:setString(tbDisplay.szLabel)
    end

    UIHelper.BindUIEvent(self.BtnTrace02, EventType.OnClick, function()
        if tbButton.bTrace then
            MapMgr.ClearTracePoint()
            Event.Dispatch("ON_MIDDLE_MAP_MARK_UNCHECK")
        else
            MapMgr.SetTracePoint(tbButton.szName, tbButton.nMapID, tbButton.tPoint)
            Event.Dispatch("ON_MIDDLE_MAP_MARK_UNCHECK")
        end
    end)
end

return UIMiddleMapTraceMerchant