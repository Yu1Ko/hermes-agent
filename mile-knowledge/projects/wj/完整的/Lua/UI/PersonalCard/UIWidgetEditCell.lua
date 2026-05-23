-- ---------------------------------------------------------------------------------
-- Name: UIWidgetEditCell
-- Desc: 备用名片cell
-- ---------------------------------------------------------------------------------

local UIWidgetEditCell = class("UIWidgetEditCell")

function UIWidgetEditCell:OnEnter()
    if not self.bInit then
        self.bInit = true
        self:BindUIEvent()
        self:RegEvent()
    end
end

function UIWidgetEditCell:OnExit()
    self.bInit = false
end

function UIWidgetEditCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogLock, EventType.OnClick, function ()
        local bUnLock = PersonalCardData.GetShowCardPresetState(self.nIndex, SHOW_CARD_PRESET_STATE_TYPE.UNLOCK)
        UIHelper.SetSelected(self.TogLock, bUnLock)

        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
            return
        end

        PersonalCardData.SetShowCardPresetState(self.nIndex, SHOW_CARD_PRESET_STATE_TYPE.UNLOCK, not bUnLock)
    end)
end

function UIWidgetEditCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_SYNC_SHOW_CARD_DECORATION_PRESET_STATE_NOTIFY", function (dwIndex, stateType)
        if self.nIndex == dwIndex then
            if stateType == SHOW_CARD_PRESET_STATE_TYPE.UNLOCK then
                local bUnLock   = PersonalCardData.GetShowCardPresetState(dwIndex, SHOW_CARD_PRESET_STATE_TYPE.UNLOCK)
                UIHelper.SetSelected(self.TogLock, bUnLock)
                if not bUnLock then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHOW_CARD_LOCK_SUCCESS_TIPS)
                else
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHOW_CARD_UNLOCK_SUCCESS_TIPS)
                end
            elseif stateType == SHOW_CARD_PRESET_STATE_TYPE.UPLOAD_IMAGE then
                self:UpdateDecorationPreset()
            end
           
        end
    end)

    Event.Reg(self, "ON_SET_SHOW_CARD_DECORATION_PRESET_NOTIFY", function (nIndex)
        if self.nIndex == nIndex then
            self:UpdateDecorationPreset()
        end
    end)

    Event.Reg(self, "UPLOAD_SHOW_IMAGE_RESPOND", function ()
        if arg0 == 1 then
            self:UpdateDecorationPreset()
        end
    end)
end

function UIWidgetEditCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetEditCell:UpdateImageData(nIndex)
    self.nIndex = nIndex
    if PersonalCardData.tSelfImageData[nIndex] then
        local bUnLock = PersonalCardData.GetShowCardPresetState(nIndex, SHOW_CARD_PRESET_STATE_TYPE.UNLOCK)
        UIHelper.SetSelected(self.TogLock, bUnLock)

        if PersonalCardData.tSelfImageData[nIndex].bHave == true then
            UIHelper.SetVisible(self.BtnNew, false)
            UIHelper.SetVisible(self.LabelLoading, false)
            UIHelper.SetVisible(self.BtnAgain, true)
            UIHelper.SetVisible(self.BtnEdit, true)
            UIHelper.SetVisible(self.TogUse, true)
            local layoutBtn = UIHelper.GetParent(self.BtnAgain)
            UIHelper.LayoutDoLayout(layoutBtn)

            if PersonalCardData.tSelfImageData[nIndex].pRetTexture then
                local picTexture = PersonalCardData.tSelfImageData[nIndex].pRetTexture
                UIHelper.SetTextureWithBlur(self.ImgInUseBg, picTexture, false)
            elseif PersonalCardData.tSelfImageData[nIndex].fileName then
                local fileName = PersonalCardData.tSelfImageData[nIndex].fileName
                UIHelper.SetTexture(self.ImgInUseBg, fileName, false)
            end

            -- 切换
            UIHelper.BindUIEvent(self.TogUse, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then
                    if self.fnSelected then
                        self.fnSelected(nIndex)
                    end
                end
            end)

            -- 编辑
            local tInfo = {
                bUseImage = true,
                picTexture = PersonalCardData.tSelfImageData[nIndex].pRetTexture,
            }
            UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick , function ()
                local bUnLock = PersonalCardData.GetShowCardPresetState(nIndex, SHOW_CARD_PRESET_STATE_TYPE.UNLOCK)
                if not bUnLock then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHOW_CARD_LOCK_TIPS)
                    return
                end

                local nViewID = VIEW_ID.PanelPersonalCardAdorn
                if not UIMgr.GetView(nViewID) then
                    UIMgr.Open(nViewID, tInfo, nIndex)
                end
            end)

            -- 重拍
            UIHelper.BindUIEvent(self.BtnAgain, EventType.OnClick , function ()
                local bUnLock = PersonalCardData.GetShowCardPresetState(nIndex, SHOW_CARD_PRESET_STATE_TYPE.UNLOCK)
                if not bUnLock then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHOW_CARD_LOCK_TIPS)
                    return
                end

                if IsInLishijie() then
                    return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_UNABLE_TO_USE_SELFIE)
                end

                if UIMgr.IsViewOpened(VIEW_ID.PanelCharacter) then
                    Event.Reg(self, EventType.OnViewClose, function(nViewID)
                        if nViewID == VIEW_ID.PanelCharacter then
                            Timer.Add(Global, 0.5, function()
                                UIMgr.Open(VIEW_ID.PanelCamera, true, self.nIndex)
                            end)
                            Event.UnReg(self, EventType.OnViewClose)
                        end
                    end)
                else
                    UIMgr.Open(VIEW_ID.PanelCamera, true, self.nIndex)
                end

                if self.fnCallBackCloseView then
                    self.fnCallBackCloseView()
                end

            end)
        else
            UIHelper.SetVisible(self.TogUse, false)
            UIHelper.SetVisible(self.BtnAgain, false)
            UIHelper.SetVisible(self.BtnNew, true)
            UIHelper.SetVisible(self.BtnEdit, false)

            -- 重拍
            UIHelper.BindUIEvent(self.BtnNew, EventType.OnClick , function ()
                LOG.INFO("Editor New Image %d",self.nIndex)
                local bUnLock = PersonalCardData.GetShowCardPresetState(self.nIndex, SHOW_CARD_PRESET_STATE_TYPE.UNLOCK)
                if not bUnLock then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHOW_CARD_LOCK_TIPS)
                    return
                end

                if IsInLishijie() then
                    return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_UNABLE_TO_USE_SELFIE)
                end

                if UIMgr.IsViewOpened(VIEW_ID.PanelCharacter) then
                    Event.Reg(self, EventType.OnViewClose, function(nViewID)
                        if nViewID == VIEW_ID.PanelCharacter then
                            Timer.Add(Global, 0.5, function()
                                UIMgr.Open(VIEW_ID.PanelCamera, true, self.nIndex)
                            end)
                            Event.UnReg(self, EventType.OnViewClose)
                        end
                    end)
                else
                    UIMgr.Open(VIEW_ID.PanelCamera, true, self.nIndex)
                end
                
                if self.fnCallBackCloseView then
                    self.fnCallBackCloseView()
                end
            end)
        end

        self:UpdateDecorationPreset()
    end
end

function UIWidgetEditCell:UpdateDecorationPreset()
    self.tDecorationPresetLogic = g_pClientPlayer.GetShowCardDecorationPreset(self.nIndex)
    local tDecorationPresetDataUI = PersonalCardData.LogicLayer2UILayer(self.tDecorationPresetLogic)

    for k, v in ipairs(self.tbWidgetAllAttachment) do
        if k == 1 then
            UIHelper.ClearTexture(self.tbWidgetAllAttachment[k])
        elseif k == #self.tbWidgetAllAttachment then
            UIHelper.SetVisible(self.tbWidgetAllAttachment[k], true)
        else
            UIHelper.RemoveAllChildren(self.tbWidgetAllAttachment[k])
        end
    end
    UIHelper.SetVisible(self.ImgFrame_Special, false)
    if not table_is_empty(self.tDecorationPresetLogic) then
        for k, v in ipairs(self.tbWidgetAllAttachment) do
            if tDecorationPresetDataUI[k] then
                local tData = Table_GetPersonalCardByDecorationID(tDecorationPresetDataUI[k].wID)
                if tDecorationPresetDataUI[k].nDecorationType == SHOW_CARD_DECORATION_TYPE.BACK_GROUND or
                tDecorationPresetDataUI[k].nDecorationType == SHOW_CARD_DECORATION_TYPE.FRAME then
                    if tData.szVKPath and tData.szVKPath ~= "" then
                        UIHelper.SetVisible(self.tbWidgetAllAttachment[k], false)
                        UIHelper.SetVisible(self.ImgFrame_Special, true)
                        UIHelper.SetTexture(self.ImgFrame_Special, tData.szVKPath)
                    else
                        UIHelper.SetVisible(self.tbWidgetAllAttachment[k], true)
                        UIHelper.SetVisible(self.ImgFrame_Special, false)
                    end
                else
                    local Zoom = UIHelper.AddPrefab(PREFAB_ID.WidgetZoom, self.tbWidgetAllAttachment[k])
                    if Zoom then
                        UIHelper.SetScale(Zoom._rootNode, tDecorationPresetDataUI[k].fScale, tDecorationPresetDataUI[k].fScale)
                        local nWidgetWidth = UIHelper.GetWidth(self.tbWidgetAllAttachment[k])
                        local nWidgetHeight = UIHelper.GetHeight(self.tbWidgetAllAttachment[k])
                        local fOffsetX, fOffsetY = PersonalCardData.DXOffsetTranslate2VK(tDecorationPresetDataUI, k, nWidgetWidth, nWidgetHeight)
                        UIHelper.SetPosition(Zoom._rootNode, fOffsetX, fOffsetY)
                        if tDecorationPresetDataUI[k].nDecorationType == SHOW_CARD_DECORATION_TYPE.DECAL then
                            UIHelper.SetTexture(Zoom.ImgZoomBg, tData.szVKPath)
                        else
                            UIHelper.SetSFXPath(Zoom.sfxBg, tData.szSFX, true)
                        end
                        self:UpdateZoomRotation(Zoom, tDecorationPresetDataUI[k].byRotation or 0)
                    end
                end
            end
        end
    end
end

function UIWidgetEditCell:UpdateZoomRotation(Zoom, byRotation)
    local nRotation = byRotation * 360 / 255
    for index, node in ipairs(Zoom.tbRotateNode) do
        UIHelper.SetRotation(node, nRotation)
    end
    UIHelper.Set2DRotation(Zoom.sfxBg, -nRotation * math.pi / 180)
end

function UIWidgetEditCell:RawSetSelected(bSelected)
    UIHelper.SetSelected(self.TogUse, bSelected, false)
    UIHelper.SetVisible(self.ImgInUseTab, bSelected)
end

function UIWidgetEditCell:SetfnSelected(fnSelected)
    self.fnSelected = fnSelected
end

function UIWidgetEditCell:SetfnCallBackCloseView(fnCallBackCloseView)
    self.fnCallBackCloseView = fnCallBackCloseView
end

function UIWidgetEditCell:UpdateLoadState()

end

return UIWidgetEditCell