-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISmallNumInsertPop
-- Date: 2024-05-14 22:37:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISmallNumInsertPop = class("UISmallNumInsertPop")

function UISmallNumInsertPop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISmallNumInsertPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISmallNumInsertPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function ()
        local nCount = tonumber(UIHelper.GetString(self.EditPaginate))
        if nCount > self.nMin then
            nCount = nCount - 1
        else
            nCount = self.nMin
        end

        UIHelper.SetString(self.EditPaginate, nCount)
    end)

    UIHelper.BindUIEvent(self.BtnPlus, EventType.OnClick, function ()
        local nCount = tonumber(UIHelper.GetString(self.EditPaginate))
        if nCount < self.nMax then
            nCount = nCount + 1
        else
            nCount = self.nMax
        end

        UIHelper.SetString(self.EditPaginate, nCount)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditPaginate, function ()
        local szCount = UIHelper.GetString(self.EditPaginate)
        local bNum = self:isNumber(szCount)
        if not bNum then
            UIHelper.SetString(self.EditPaginate, "")
            return
        end

        local nCount = tonumber(szCount)
        if nCount < self.nMin then
            nCount = self.nMin
        end

        if nCount > self.nMax then
            nCount = self.nMax
        end
        UIHelper.SetString(self.EditPaginate, nCount)
    end)

    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function ()
        local nCount = tonumber(UIHelper.GetString(self.EditPaginate))
        if self.funcConfirm then
            self.funcConfirm(nCount)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        UIHelper.SetVisible(self._rootNode, false)
    end)
end

function UISmallNumInsertPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISmallNumInsertPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISmallNumInsertPop:UpdateInfo()

end

function UISmallNumInsertPop:UpdataInputNumber(szInput, nDefault, nMin, nMax, szSource, funcConfirm, funcCancel)
    UIHelper.SetString(self.EditPaginate, nDefault)
    self.szInput = szInput
    self.nMin = nMin
    self.nMax = nMax
    self.funcConfirm = funcConfirm
    self.funcCancel = funcCancel
    UIHelper.SetVisible(self._rootNode, true)
end

function UISmallNumInsertPop:isNumber(str)
    for i=1,string.len(str) do
        if string.byte(string.sub(str,i,i)) < 48 or string.byte(string.sub(str,i,i)) > 57 then
          return false
        end
    end
    return true
end

return UISmallNumInsertPop