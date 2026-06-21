-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMView
-- Date: 2022-11-08 11:21:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGMView = class("UIGMView")

function UIGMView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:SetPosition()
    self.tbLastData = GMMgr.tbLastGMPanel
    if self.tbLastData~=nil and next(self.tbLastData) then
        self.PanelRightView:setVisible(self.tbLastData.PanelRightView)
        self.tbGMPanelRight = self.tbLastData.tbLastFunction
        self.tbRawDataRight = self.tbLastData.tbLastRawDataRight
        self.tbSearchResultLeft = self.tbLastData.tbLastSearchLeft
        self.tbSearchResultRight = self.tbLastData.tbLastSearchRight
        UIHelper.SetString(self.EditSearchLeft, self.tbLastData.EditLabelLeft)
        if self.tbGMPanelRight.ShowSubWindow then
            self:InitLayOut()
            self.tbGMPanelRight:ShowSubWindow(self)
        end
        UIHelper.TableView_init(self.LuaTableViewLeft, #self.tbSearchResultLeft, PREFAB_ID.WidgetGmLtem)
        UIHelper.TableView_reloadData(self.LuaTableViewLeft)
        UIHelper.TableView_init(self.LuaTableViewRight, #self.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
        UIHelper.TableView_reloadData(self.LuaTableViewRight)
        self:UpdateInfo_Middle()
        if self.tbLastData.CMDEditorView then
            UIMgr.Open(VIEW_ID.PanelCMDEditor, self, self.tbLastData.CMDEditorView)
        end
    else
        self.tbGMPanelRight = {}
        self.tbRawDataLeft = {}
        self.tbRawDataRight = {}
        self.tbSearchResultLeft = {}
        self.tbSearchResultRight = {}
        self:UpdateInfo()
    end

    self:UpdateInfo_Operation()
end

function UIGMView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self.tbLastData.PanelRightView = UIHelper.GetVisible(self.PanelRightView)
    self.tbLastData.tbLastFunction = self.tbGMPanelRight
    self.tbLastData.tbLastRawDataRight = self.tbRawDataRight
    self.tbLastData.tbLastSearchLeft = self.tbSearchResultLeft
    self.tbLastData.tbLastSearchRight = self.tbSearchResultRight
    self.tbLastData.EditLabelLeft = UIHelper.GetString(self.EditSearchLeft)
    self.tbLastData.EditLabelRight = UIHelper.GetString(self.EditSearchRight)
    self.tbLastData.bSameModel = UIHelper.GetSelected(self.ToggleSameModel)

    UIMgr.Close(VIEW_ID.PanelConfigureAccount)
end

function UIGMView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(VIEW_ID.PanelGMRightExpansion)
        UIMgr.Close(VIEW_ID.PanelConfigureAccount)
        UIMgr.Close(VIEW_ID.PanelCMDEditor)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnDeleteLeft, EventType.OnClick, function(btn)
        UIHelper.SetString(self.EditSearchLeft, "")
        self:UpdateInfo_Left()
    end)

    UIHelper.BindUIEvent(self.BtnSearchPanel, EventType.OnClick, function(btn)
        if UIMgr.GetView(VIEW_ID.PanelSearchPanel) then
            UIMgr.Close(VIEW_ID.PanelSearchPanel)
        else
            UIMgr.Open(VIEW_ID.PanelSearchPanel)
        end
        UIMgr.Close(VIEW_ID.PanelConfigureAccount)
        UIMgr.Close(VIEW_ID.PanelGMRightExpansion)
        UIMgr.Close(VIEW_ID.PanelCMDEditor)
        UIMgr.Close(self)
    end)


    UIHelper.BindUIEvent(self.BtnExecute, EventType.OnClick, function(btn)
        self.tbGMPanelRight:BtnExecute(self)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchLeft, EventType.OnClick, function(btn)
        if self.tbGMPanelRight.SwitchLeft then
            self.tbGMPanelRight:SwitchLeft(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSwitchRight, EventType.OnClick, function(btn)
        if self.tbGMPanelRight.SwitchRight then
            self.tbGMPanelRight:SwitchRight(self)
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditSearchLeft, function()
        local szSearchkey = UIHelper.GetString(self.EditSearchLeft)
        self:UpdateInfo_Left(szSearchkey)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditSearchLeft, function()
        local szSearchkey = UIHelper.GetString(self.EditSearchLeft)
        self:UpdateInfo_Left(szSearchkey)
    end)

    UIHelper.BindUIEvent(self.BtnDeleteRight, EventType.OnClick, function(btn)
        UIHelper.SetString(self.EditSearchRight, "")
        UIHelper.SetString(self.LabelExteriorDescript, "")
        if self.tbGMPanelRight.GetAllData then
            self.tbGMPanelRight:GetAllData(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSummon, EventType.OnClick, function(btn)
        self.tbGMPanelRight:BtnSummon(self)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditSearchRight, function()
        local szSearchkey = UIHelper.GetString(self.EditSearchRight)
        self:UpdateInfo_Right(szSearchkey)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditSearchRight, function()
        local szSearchkey = UIHelper.GetString(self.EditSearchRight)
        self:UpdateInfo_Right(szSearchkey)
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.LuaTableViewLeft, function(tableView, nIndex, script, node, cell)
        local tbCMD = self.tbSearchResultLeft[nIndex]
        if script and tbCMD then
            script:OnEnter(self, tbCMD)
        end
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.LuaTableViewMiddle, function(tableView, nIndex, script, node, cell)
        local tbSelectCell = self.tbMiddleData[nIndex]
        if script and tbSelectCell then
            script:OnEnter(self, tbSelectCell)
        end
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.LuaTableViewRight, function(tableView, nIndex, script, node, cell)
        local tbSelectCell = self.tbSearchResultRight[nIndex]
        if script and tbSelectCell then
            script:OnEnter(self.tbGMPanelRight, tbSelectCell)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDrag, EventType.OnTouchBegan, function(btn, nX, nY)
        if Platform.IsMobile() then return end
    end)

    UIHelper.BindUIEvent(self.BtnDrag, EventType.OnTouchMoved, function(btn, nX, nY)
        if Platform.IsMobile() then return end

        if not self.nLastX then
            self.nLastX = nX
            self.nLastY = nY
            return
        end

        local parentNode = UIHelper.GetParent(self._rootNode)
        local parentNodeX, parentNodeY = UIHelper.GetPosition(parentNode)
        local screenSize = UIHelper.GetSafeAreaRect()

        local nScale = Storage.Debug.nUIScale or 1

        local nNodeWitdh = UIHelper.GetWidth(self._rootNode) * nScale / 2
        local nNodeHeight = UIHelper.GetHeight(self._rootNode) * nScale / 2
        local nNewX = nX - self.nLastX + UIHelper.GetPositionX(self._rootNode)
        local nNewY = nY - self.nLastY + UIHelper.GetPositionY(self._rootNode)

        if nNewX - nNodeWitdh < parentNodeX then
            nNewX = parentNodeX +  nNodeWitdh
        elseif (nNewX + nNodeWitdh) > (parentNodeX + screenSize.width) then
            nNewX = parentNodeX + screenSize.width - nNodeWitdh
        end

        if (nNewY - nNodeHeight) < parentNodeY then
            nNewY = parentNodeY + nNodeHeight
        elseif nNewY + nNodeHeight > parentNodeY + screenSize.height then
            nNewY = parentNodeY + screenSize.height - nNodeHeight
        end
        UIHelper.SetPosition(self._rootNode, nNewX, nNewY)

        self.nLastX = nX
        self.nLastY = nY
    end)

    UIHelper.BindUIEvent(self.BtnDrag, EventType.OnTouchEnded, function(btn, nX, nY)
        if Platform.IsMobile() then return end

        self.nLastX = nil
        self.nLastY = nil
    end)

    -- NPC同模
    UIHelper.BindUIEvent(self.ToggleSameModel, EventType.OnSelectChanged, function(btn, bSelected)
        -- 再次打开界面,同模状态不变时不应再次发送指令
        if GMMgr.bSameModel ~= bSelected then
            if bSelected then
                local szCMD = "RemoteCallToClient(player.dwID, 'CallUIGlobalFunction', 'rlcmd', 'npc uniform 1')"
                SendGMCommand(UIHelper.UTF8ToGBK(szCMD))
                OutputMessage("MSG_ANNOUNCE_RED","启用NPC同模")
            else
                local szCMD = "RemoteCallToClient(player.dwID, 'CallUIGlobalFunction', 'rlcmd', 'npc uniform 0')"
                SendGMCommand(UIHelper.UTF8ToGBK(szCMD))
                OutputMessage("MSG_ANNOUNCE_RED","关闭NPC同模")
            end
        end
        GMMgr.bSameModel = bSelected
    end)
end

function UIGMView:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            self:SetPosition()
        end)
    end)
end

function UIGMView:UnRegEvent()
    Event.UnReg(self, EventType.OnWindowsSizeChanged)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIGMView:SetPosition()
    if Storage.Debug.nUIScale == nil then
        return
    end
    local parentNode = UIHelper.GetParent(self._rootNode)
    local parentNodeX, parentNodeY = UIHelper.GetPosition(parentNode)
    local screenSize = UIHelper.GetSafeAreaRect()
    local nNodeWitdh = UIHelper.GetWidth(self._rootNode) * Storage.Debug.nUIScale / 2
    local nNodeHeight = UIHelper.GetHeight(self._rootNode) * Storage.Debug.nUIScale / 2
    UIHelper.SetPosition(self._rootNode, parentNodeX + nNodeWitdh, parentNodeY + screenSize.height - nNodeHeight)
end

function UIGMView:InitLayOut()
    self.LabelExtension:setVisible(false)
    self.BtnExecute:setVisible(false)
    self.WidgetExterior:setVisible(false)
    self.WidgetBuffInfo:setVisible(false)
    self.WidgetCraft:setVisible(false)
end

function UIGMView:UpdateInfo()
    self:UpdateInfo_Left()
    self:UpdateInfo_Middle()
end

function UIGMView:UpdateInfo_Left(szSearchkey)
    self.tbSearchResultLeft = GMMgr.GetLeftData(szSearchkey)
    UIHelper.TableView_init(self.LuaTableViewLeft, #self.tbSearchResultLeft, PREFAB_ID.WidgetGmLtem)
    UIHelper.TableView_reloadData(self.LuaTableViewLeft)
end

function UIGMView:UpdateInfo_Right(szSearchkey)
    if self.tbGMPanelRight.Search then
        self.tbSearchResultRight = self.tbGMPanelRight:Search(szSearchkey)
    else
        self.tbSearchResultRight = GMMgr.GetRightData(szSearchkey, self.tbRawDataRight)
    end
    UIHelper.TableView_init(self.LuaTableViewRight, #self.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(self.LuaTableViewRight)
end

function UIGMView:UpdateInfo_Middle()
    self.tbMiddleData = GMMgr.GetMiddleData()
    UIHelper.TableView_init(self.LuaTableViewMiddle, #self.tbMiddleData, PREFAB_ID.WidgetTogOrnaments)
    UIHelper.TableView_reloadData(self.LuaTableViewMiddle)
end

function UIGMView:UpdateInfo_Operation()
    -- 缩放值
    if Platform.IsMobile() then
        UIHelper.SetVisible(self.SliderAlpha, false)
    else
        local nScale = Storage.Debug.nUIScale
        local nMin, nMax = 0.3, 1
        if nScale == nil then nScale = 1 end
        if nScale < nMin then nScale = 0.5 end
        if nScale > nMax then nScale = 1 end

        UIHelper.SetString(self.LabelAlpha, nScale)
        UIHelper.SetProgressBarPercent(self.SliderAlpha, nScale * 100)
        UIHelper.SetScale(self._rootNode, nScale, nScale)

        UIHelper.BindUIEvent(self.SliderAlpha, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
            if nSliderEvent == ccui.SliderEventType.slideBallDown then
                self.bSliding = true
            elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
                self.bSliding = false
                -- 强制修正滑块进度
                local szValue = UIHelper.GetString(self.LabelAlpha)
                local nScale = tonumber(szValue)
                UIHelper.SetScale(self._rootNode, nScale, nScale)
                Storage.Debug.nUIScale = nScale
                Storage.Debug.Flush()

                self:SetPosition()
            end

            if self.bSliding then
                local nPercent = UIHelper.GetProgressBarPercent(self.SliderAlpha)
                nPercent = math.min(nPercent, 100)
                nPercent = math.max(nPercent, 30)

                local nScale = nPercent / 100
                UIHelper.SetString(self.LabelAlpha, nScale)
            end
        end)
    end

    -- 穿透
    UIHelper.SetSelected(self.ToggleTouch, G_UIGMView_Toggle)
    UIHelper.BindUIEvent(self.ToggleTouch, EventType.OnSelectChanged, function(btn, bSelected)
        UIHelper.SetVisible(self._scriptBG._rootNode, not bSelected)
    end)

    -- 是否显示Debug
    local bShowDebugInfo = Storage.Debug.bShowDebugInfo
    UIHelper.SetSelected(self.ToggleDebugInfo, bShowDebugInfo)
    UIHelper.BindUIEvent(self.ToggleDebugInfo, EventType.OnSelectChanged, function(btn, bSelected)
        KG3DEngine.SetMobileEngineOption({bRenderUIDebug = bSelected})
        Storage.Debug.bShowDebugInfo = bSelected
        Storage.Debug.Flush()
    end)

    -- 同模选择
    if GMMgr.bSameModel~=nil then
        local bSameModel = self.tbLastData.bSameModel or false
        UIHelper.SetSelected(self.ToggleSameModel, bSameModel)
    else
        GMMgr.bSameModel = UIHelper.GetSelected(self.ToggleSameModel)
        UIHelper.SetSelected(self.ToggleSameModel, GMMgr.bSameModel)
    end

    -- 省电模式
    UIHelper.SetVisible(self.TogglePSM, Platform.IsMobile())
    local bPSMFlag = Storage.Debug.bPSMFlag
    UIHelper.SetSelected(self.TogglePSM, bPSMFlag)
    UIHelper.BindUIEvent(self.TogglePSM, EventType.OnSelectChanged, function(btn, bSelected)
        Storage.Debug.bPSMFlag = bSelected
        Storage.Debug.Flush()
    end)
end

return UIGMView