-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTestPassSplit
-- Desc: 无界裂变
-- ---------------------------------------------------------------------------------

local UIWidgetTestPassSplit = class("UIWidgetTestPassSplit")

function UIWidgetTestPassSplit:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.szNum = {}
    self.nPoint = {}
    self:UpdateInfo()
end

function UIWidgetTestPassSplit:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTestPassSplit:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSecondary[1], EventType.OnClick, function ()
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelHuaELou)
        if scriptView then
            scriptView:OnEnter(119, true)
        else
            UIMgr.Open(VIEW_ID.PanelHuaELou, 119, true)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSecondary[2], EventType.OnClick, function ()
        if not UIMgr.GetView(VIEW_ID.PanelBenefits) then
            UIMgr.Open(VIEW_ID.PanelBenefits, 2)
		end
        UIMgr.Close(VIEW_ID.PanelHuaELou)
    end)

    UIHelper.BindUIEvent(self.BtnSecondary[3], EventType.OnClick, function ()
        if not UIMgr.GetView(VIEW_ID.PanelBenefits) then
            UIMgr.Open(VIEW_ID.PanelBenefits, 2)
		end
        UIMgr.Close(VIEW_ID.PanelHuaELou)
    end)

    UIHelper.BindUIEvent(self.BtnMain[1], EventType.OnClick, function ()
        self:OpenSharePop("m1")
    end)

    UIHelper.BindUIEvent(self.BtnMain[2], EventType.OnClick, function ()
        self:OpenSharePop("m2")
    end)

    UIHelper.BindUIEvent(self.BtnMain[3], EventType.OnClick, function ()
        self:OpenSharePop("m3")
    end)


    UIHelper.BindUIEvent(self.BtnSignIn, EventType.OnClick, function ()
        WebUrl.OpenByID(33)
    end)
end

function UIWidgetTestPassSplit:RegEvent()
    Event.Reg(self, "Get_Ext_Point_Split", function(point0, point1, point2)
        self:UpdatePoint(point0, point1, point2)
        self:UpdatePage()
    end)

    Event.Reg(self, "On_Recharge_CheckWelfare_CallBack", function (_, _, _, _, _, dwID, tCustom, _)
        if dwID == 119 then
            self.szNum[1] = "进行中 " .. string.format("%d/%d", tCustom.nSign or 0, 2)
            UIHelper.SetString(self.LabelOngoing[1], self.szNum[1])
        end
    end)
end

function UIWidgetTestPassSplit:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTestPassSplit:UpdateInfo()
    RemoteCallToServer("On_Get_Ext_Point_Split")
    RemoteCallToServer("On_Recharge_CheckWelfare", {119})

    self.szNum[1] = "进行中 " .. string.format("%d/%d", 0, 2)
    HuaELouData.UpdateExp()
    local nExp = 0
    nExp = HuaELouData.nLevelNow * 1000 + HuaELouData.nExpNow
    if HuaELouData.nLockExtralCanGet == 1 then
        nExp = nExp - 10000
    end
    self.szNum[2] = "进行中 " .. string.format("%d/%d", nExp, 1000)
    self.szNum[3] = "进行中 " .. string.format("%d/%d", nExp, 2000)
end

function UIWidgetTestPassSplit:GetLevelStatus()
    local moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
    local tRole = moduleRoleList and moduleRoleList.GetRoleInfoList()
    for _, tbRoleInfo in ipairs(tRole) do
        if tbRoleInfo.RoleLevel >= 120 then
            return true
        end
    end
    return false
end

function UIWidgetTestPassSplit:UpdateStatus()
    if g_pClientPlayer then
        local bLevel = self:GetLevelStatus()
        if bLevel == true then
            self.nPoint[1] = true
            self.nNum = self.nNum + 1
        end
    end
end

function UIWidgetTestPassSplit:UpdatePoint(point0, point1, point2)
    self.nPoint[1] = point0
    self.nPoint[2] = point1
    self.nPoint[3] = point2
end

function UIWidgetTestPassSplit:UpdatePage()
    for nIndex = 1, 3 do
        if self.nPoint[nIndex] == 0 then
            UIHelper.SetString(self.LabelOngoing[nIndex], self.szNum[nIndex])

            UIHelper.SetVisible(self.WidgetOngoing[nIndex], true)
            UIHelper.SetVisible(self.WidgetFinished[nIndex], false)

            UIHelper.SetVisible(self.BtnSecondary[nIndex], true)
            UIHelper.SetVisible(self.WidgetNotAvailable[nIndex], true)
            UIHelper.SetVisible(self.WidgetCopyLink[nIndex], false)
            UIHelper.SetVisible(self.WidgetSucceed[nIndex], false)

            UIHelper.SetTouchEnabled(self.BtnMain[nIndex], false)
        elseif self.nPoint[nIndex] == 1 then
            UIHelper.SetVisible(self.WidgetOngoing[nIndex], false)
            UIHelper.SetVisible(self.WidgetFinished[nIndex], true)

            UIHelper.SetVisible(self.BtnSecondary[nIndex], false)
            UIHelper.SetVisible(self.WidgetNotAvailable[nIndex], false)
            UIHelper.SetVisible(self.WidgetCopyLink[nIndex], true)
            UIHelper.SetVisible(self.WidgetSucceed[nIndex], false)

        elseif self.nPoint[nIndex] == 2 then
            UIHelper.SetVisible(self.WidgetOngoing[nIndex], false)
            UIHelper.SetVisible(self.WidgetFinished[nIndex], true)

            UIHelper.SetVisible(self.BtnSecondary[nIndex], false)
            UIHelper.SetVisible(self.WidgetNotAvailable[nIndex], false)
            UIHelper.SetVisible(self.WidgetCopyLink[nIndex], false)
            UIHelper.SetVisible(self.WidgetSucceed[nIndex], true)

            UIHelper.SetTouchEnabled(self.BtnMain[nIndex], false)
        end
    end
end

function UIWidgetTestPassSplit:OpenSharePop(szConditionType)
    if Platform.IsWindows() or Platform.IsMac() then
        local szUid = Login_GetUnionAccount()
        local szAccountName = Login_GetAccount()
        local player = GetClientPlayer()
        local szRoleId = "NoRole"
        if player then
            szRoleId = tostring(player.dwID)
        end
        local szTitle = "番薯小侠！剑网3正在召唤你"
        local szContent = "你的好友为你挖来了一个剑网3无界二测资格！"

        local szUrl = string.format("account=%s&type=%s",szAccountName,szConditionType)
        szUrl = Base64_Encode( szUrl)
        local szShareUrl = "https://jx3.xoyo.com/p/m/2024/04/25/final-test/index.html?params="..szUrl.."#/invite"
        SetClipboard(szShareUrl)
        TipsHelper.ShowNormalTip("已复制分享链接至剪切板")
        XGSDK_TrackEvent("game.share.liebianActivity", "share", {{"conditionType", szConditionType}})
    else
        if not UIMgr.GetView(VIEW_ID.PanelSharePop) then
            UIMgr.Open(VIEW_ID.PanelSharePop , szConditionType)
        end
    end
end

return UIWidgetTestPassSplit