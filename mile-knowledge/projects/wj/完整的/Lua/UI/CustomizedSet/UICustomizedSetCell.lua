-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetCell
-- Date: 2024-07-26 11:38:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetCell = class("UICustomizedSetCell")

function UICustomizedSetCell:OnEnter(nIndex, tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.tData = tData
    self:UpdateInfo()
end

function UICustomizedSetCell:OnExit()
    self.bInit = false
end

function UICustomizedSetCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSet, EventType.OnClick, function(btn)
        if EquipCodeData.CheckCurCustomizedSetIsChanged() then
            UIHelper.SetSelected(self.TogSet, false)
            local dialog = UIHelper.ShowConfirm("当前配装存在修改尚未保存，是否保存修改后继续操作？", function()
                EquipCodeData.SaveCustomizedSet()
            end, function ()
                Event.Dispatch(EventType.OnSelectCustomizedSet, self.nIndex, self.tData)
            end)

            dialog:SetConfirmButtonContent("保存")
            dialog:SetCancelButtonContent("不保存")
        else
            Event.Dispatch(EventType.OnSelectCustomizedSet, self.nIndex, self.tData)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function(btn)
        UIHelper.ShowConfirm(string.format("是否确认删除【%s】配装方案？", self.tData.title), function ()
            EquipCodeData.ReqDelRoleEquip(self.tData.id)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function(btn)
        local scriptView = UIMgr.Open(VIEW_ID.PanelPromptPop, "", "请输入方案名", function (szTitle)
            if not TextFilterCheck(UIHelper.UTF8ToGBK(szTitle)) then --过滤文字
                TipsHelper.ShowNormalTip("您输入的方案名中含有敏感字词。")
                return
            end

            if self.tData then
                EquipCodeData.ReqUpdateRoleEquips(self.tData.id, szTitle, self.tData.kungfu_name, tonumber(self.tData.score), self.tData.equips)
            end
        end)
        scriptView:SetTitle("修改配装方案名")
        scriptView:SetPlaceHolder("字数不能超过4个字")
        scriptView:SetMaxLength(4)
    end)

    UIHelper.BindUIEvent(self.BtnCreate, EventType.OnClick, function(btn)
        EquipCodeData.CreateNewSet()
    end)
end

function UICustomizedSetCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICustomizedSetCell:UpdateInfo()
    if self.tData then
        UIHelper.SetVisible(self.WidgetSet, true)
        UIHelper.SetVisible(self.WidgetEmpty, false)

        UIHelper.SetString(self.LabelLimit, self.tData.title)
    else
        UIHelper.SetVisible(self.WidgetSet, false)
        UIHelper.SetVisible(self.WidgetEmpty, true)
    end
end


return UICustomizedSetCell