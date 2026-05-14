-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelDeleteCharacterPicConfirm
-- Date: 2023-02-13 17:51:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelDeleteCharacterPicConfirm = class("UIPanelDeleteCharacterPicConfirm")

function UIPanelDeleteCharacterPicConfirm:OnEnter(tbRoleInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
    self.tbRoleInfo = tbRoleInfo
    self.moduleRole:GetCaptcha()
    self:UpdateInfo()
end

function UIPanelDeleteCharacterPicConfirm:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelDeleteCharacterPicConfirm:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChangePic, EventType.OnClick, function()
        self.moduleRole:GetCaptcha()
    end)
    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function ()
        local szText = UIHelper.GetText(self.EditBox)
        Login_VerifyCaptcha(UIHelper.UTF8ToGBK(szText))
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
        self.moduleRole:OnCancelDeleteRole()
    end)
    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function ()
        UIMgr.Close(self)
        self.moduleRole:OnCancelDeleteRole()
    end)

    if Platform.IsMobile() then
        UIHelper.RegisterEditBox(self.EditBox, function (szType)
            if szType == "began" then
                self:EnterMobileInputMode()
            elseif szType == "ended" or szType == "return" then
                self:ExitMobileInputMode()
            end
        end)
        self.EditBox:enableInputFieldHidden(true)
    end
end

function UIPanelDeleteCharacterPicConfirm:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_GET_CAPTCHA_RESPOND", function(szCaptchaFilePath)
        local res = UIHelper.ReloadTexture(szCaptchaFilePath)
        UIHelper.SetTexture(self.ImgPic, szCaptchaFilePath)
    end)
    Event.Reg(self, "ON_VERIFY_CAPTCHA_RESPOND", function(nReturnCode)
        if nReturnCode == VERIFY_CAPTCHA_RET_CODE.SUCCESS then
			self.moduleRole.DeleteRole(self.tbRoleInfo.RoleName)
            UIMgr.Close(self)
        else
            TipsHelper.ShowNormalTip(g_tStrings.tLoginVerifyResult[nReturnCode])
            self.moduleRole:GetCaptcha()
        end
    end)
end

function UIPanelDeleteCharacterPicConfirm:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelDeleteCharacterPicConfirm:UpdateInfo()
    local szContent = self.tbRoleInfo.RoleLevel >= 20 and g_tStrings.STR_DELETE_ROLE_TIP1 or g_tStrings.STR_DELETE_ROLE_TIP2
    local szRoleInfo = tostring(UIHelper.GBKToUTF8(self.tbRoleInfo.RoleName)).."("..tostring(UIHelper.GBKToUTF8(self.tbRoleInfo.RoleLevel))..
    g_tStrings.STR_LEVEL..")"
    szContent = szRoleInfo.."\n"..szContent.."\n"..g_tStrings.STR_DELETE_ROLE_TIP3.."\n"..g_tStrings.STR_DELETE_ROLE_TIP4
    UIHelper.SetString(self.LabelContent, szContent)
end


function UIPanelDeleteCharacterPicConfirm:EnterMobileInputMode()
    local nX , nY = UIHelper.GetPosition(self.WidgetAnchorContent)
    self.tbEditorBoxPos = {x = nX , y = nY}
    self.nLastCursorPosY = -100


    -- 增加定时器，监听输入框变化
    Timer.DelTimer(self, self.nInputTimerID)
    self.nInputTimerID = Timer.AddCycle(self, 0.2, function()
        -- 获取当前输入法位置
        local cursorPosition = self.EditBox:getInputFieldCursorPosition()
        if self.nLastCursorPosY == cursorPosition.y then
            return
        end
        self.nLastCursorPosY = cursorPosition.y
        -- 判断是否已经关闭 或者 浮窗模式
        if math.abs(cursorPosition.y) <= 100  then
            self:ExitMobileInputMode()
        else
            local screenSize = UIHelper.GetScreenSize()
            local nScaleX , nScaleY = UIHelper.GetScreenToResolutionScale()
            local nWidgetSendHeight = UIHelper.GetHeight(self.WidgetAnchorContent)
            local nSDScaleX , nSDScaleY = UIHelper.GetScreenToDeviceScale()
            -- 获取新的位置坐标

            LOG.INFO("-------EnterMobileInputMode Start:nX:%f  nY:%f---------", tostring(nX), tostring(nY))

            local nOffset = Platform.IsAndroid() and 120 or (-nWidgetSendHeight/2*nSDScaleY)
            cursorPosition.y = ((screenSize.height + cursorPosition.y)/nScaleY + nOffset)
            UIHelper.SetPosition(self.WidgetAnchorContent, self.tbEditorBoxPos.x, cursorPosition.y)

            nX , nY = UIHelper.GetPosition(self.WidgetAnchorContent)
            LOG.INFO("-------EnterMobileInputMode End:nX:%f  nY:%f---------", tostring(nX), tostring(nY))
        end
    end)
end

function UIPanelDeleteCharacterPicConfirm:ExitMobileInputMode()
    Timer.DelTimer(self, self.nInputTimerID)
    UIHelper.SetPosition(self.WidgetAnchorContent , self.tbEditorBoxPos.x , self.tbEditorBoxPos.y)
end

return UIPanelDeleteCharacterPicConfirm