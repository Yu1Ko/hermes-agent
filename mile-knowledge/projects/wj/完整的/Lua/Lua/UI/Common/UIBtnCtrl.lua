-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIBtnCtrl
-- Date: 2023-08-16 10:52:17
-- Desc: 挂在按钮上的脚本，用于按钮的快速跳转等
-- ---------------------------------------------------------------------------------

local UIBtnCtrl = class("UIBtnCtrl")

function UIBtnCtrl:OnEnter(nID, callback)
    self.nID = nID or tonumber(self.nID)
    self.callback = callback

    if not self.nID or self.nID == 0 then
        return
    end

    self.tbInfo = UIBtnCtrlTab[self.nID]
	if not self.tbInfo then
		LOG.ERROR("UIBtnCtrl nID = %s not find ", tostring(self.nID))
		return
	end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIBtnCtrl:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBtnCtrl:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        UIHelper.DoBtnCtrl(self.nID)
        if self.callback then
            self.callback()
        end
    end)
end

function UIBtnCtrl:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    --- 福袋返场
    if self.nID == 47 then
        Event.Reg(self, "XGSDK_OnPayResult", function(szResultType, nCode, szMsg, szChannelCode, szChannelMsg)
            self:UpdateInfo()
        end)

        Event.Reg(self, "ON_UPDATE_BUY_ITEM_ORDER_SN", function(szOrder, bAddFlag, bDelFlag)
            self:UpdateInfo()
        end)
    end
end

function UIBtnCtrl:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBtnCtrl:UpdateInfo()
    if self.tbInfo.szBtnDes ~= "" then
        UIHelper.SetString(self.LabelShop, self.tbInfo.szBtnDes)
    end

    if not self.btnState then
        local szShowTip = self.tbInfo.szShowTip
        local szFuncTip = self.tbInfo.szFuncTip
        if UIHelper.CheckBtnCtrl(self.nID) then
            UIHelper.SetButtonState(self._rootNode, BTN_STATE.Normal)
        elseif not string.is_nil(szFuncTip) then
            UIHelper.SetButtonState(self._rootNode, BTN_STATE.Disable, function()
                string.execute(szFuncTip)
            end)
        else
            UIHelper.SetButtonState(self._rootNode, BTN_STATE.Disable, szShowTip)
        end
    end
end

function UIBtnCtrl:UpdateBtnDes(szBtnDes)
    UIHelper.SetString(self.LabelShop, szBtnDes)
end

function UIBtnCtrl:UpdateBtnState(btnState)
    self.btnState = btnState
    UIHelper.SetButtonState(self._rootNode, btnState)
end

return UIBtnCtrl