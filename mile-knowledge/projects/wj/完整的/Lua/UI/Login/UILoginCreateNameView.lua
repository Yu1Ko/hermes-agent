-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILoginCreateNameView
-- Date: 2022-12-09 14:17:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UILoginCreateNameView = class("UILoginCreateNameView")

function UILoginCreateNameView:OnEnter(bReName, nRoleType, szOldName, nRenameChanceCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not self.bReName then
        XGSDK_TrackEvent("game.createname.begin", "buileface", {})
    end

    self.bReName = bReName
    self.szOldName = szOldName
    self.nRenameChanceCount = nRenameChanceCount
    self.nRoleType = nRoleType

    self:UpdateInfo()

    UIHelper.SetMaxLength(self.EditBox, 20)
end

function UILoginCreateNameView:OnExit()
    self.bInit = false
end

function UILoginCreateNameView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.bReName then
            local nType, bVerified = Login_GetMibaoMode()
            if nType ~= PASSPOD_MODE.UNBIND and (not bVerified) then
                LOG.ERROR("UILoginCreateNameView error, nType = %s", tostring(nType))

                if nType == PASSPOD_MODE.TOKEN then
                    --Login.ShowLoginTokenPanel(true)
                elseif nType == PASSPOD_MODE.MATRIX then
                    -- Login.ShowSecurityCard(true)
                    -- local pos = login_GetMibaoMatrixPosition()
                    -- SecurityCard.SetSecurityCardPosion(pos)
                elseif nType == PASSPOD_MODE.PHONE then
                    UIMgr.Open(VIEW_ID.PanelEnterDynamicPassword)
                end

                return
            end
        end

        local szRoleName = UIHelper.GetText(self.EditBox)
        if string.is_nil(szRoleName) then
            TipsHelper.ShowNormalTip(g_tStrings.tbLoginString.INPUT_NAME)
            return
        end

        local nLen = UIHelper.GetUtf8Len(szRoleName)
        if nLen < 2 then
            TipsHelper.ShowNormalTip(g_tStrings.tbLoginString.CREATE_ROLE_NAME_TOO_SHORT)
            return
        end

        if nLen > 6 then
            TipsHelper.ShowNormalTip(g_tStrings.tbLoginString.CREATE_ROLE_NAME_TOO_LONG)
            return
        end

        if self.bReName then
            UIHelper.ShowConfirm(string.format(g_tStrings.tbLoginString.RENAME_CONFIRM, szRoleName), function()
                Login_Rename(self.szOldName, UIHelper.UTF8ToGBK(szRoleName))
                -- UIMgr.Close(self)
            end)
        else
            Event.Dispatch(EventType.OnCreateRoleName, szRoleName)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
        --捏脸时没有确认创建，算作新一轮捏脸，上报开始，同时计时
        if not self.bReName then
            XGSDK_TrackEvent("game.buileface.begin", "buileface", {})
            BuildFaceData.SetStartBuildFaceTime()
        end
        if self.fnCancel then
            self.fnCancel()
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
        if not self.bReName then
            XGSDK_TrackEvent("game.buileface.begin", "buileface", {})
            BuildFaceData.SetStartBuildFaceTime()
        end
        if self.fnCancel then
            self.fnCancel()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRandom, EventType.OnClick, function()
        local szRoleName = RandomName(self.nRoleType)
        UIHelper.SetText(self.EditBox, szRoleName)
    end)
end

function UILoginCreateNameView:RegEvent()
    Event.Reg(self, "LOGIN_NOTIFY", function(nEvent)
        if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			Timer.Add(self, 0.3, function ()
                UIMgr.Close(self)
            end)
        elseif nEvent == LOGIN.RENAME_SUCCESS then
            TipsHelper.ShowNormalTip("改名成功", false)
            UIMgr.Close(self)
        end
    end)
end

function UILoginCreateNameView:UpdateInfo()
    UIHelper.SetVisible(self.BtnRandom, not self.bReName)
    UIHelper.SetVisible(self.LabelDes, self.bReName)

    if self.bReName then
        UIHelper.SetRichText(self.LabelDes, string.format("剩余改名次数：%d次", self.nRenameChanceCount))
    end

    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UILoginCreateNameView:SetCancelCallback(fnCancel)
    self.fnCancel = fnCancel
end

return UILoginCreateNameView