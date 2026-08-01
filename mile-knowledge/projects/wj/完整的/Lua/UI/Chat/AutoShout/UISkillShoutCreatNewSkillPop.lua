-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISkillShoutCreatNewSkillPop
-- Date: 2025-03-11 16:45:28
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nMaxInputUtf8Len = 8
local UISkillShoutCreatNewSkillPop = class("UISkillShoutCreatNewSkillPop")

function UISkillShoutCreatNewSkillPop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISkillShoutCreatNewSkillPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISkillShoutCreatNewSkillPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPrint, EventType.OnClick, function(btn)
        self:OnClickSureBtn()
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBox, function (editBox)
        local szInput = UIHelper.GetText(self.EditBox)
        local nLen = UIHelper.GetUtf8Len(szInput)
        if nLen > nMaxInputUtf8Len then
            nLen = nMaxInputUtf8Len
            szInput = UIHelper.LimitUtf8Len(szInput, nMaxInputUtf8Len)
            UIHelper.SetString(editBox, nMaxInputUtf8Len)
        end

        UIHelper.SetString(self.LabelLimit, nLen.."/"..nMaxInputUtf8Len)
    end)
end

function UISkillShoutCreatNewSkillPop:RegEvent()
    Event.Reg(self, EventType.OnSkillShoutSaved, function(szSaveType)
        if self.szType ~= "Skill" then
            return
        end

        if szSaveType == "tbSkillList" then
            UIMgr.Close(self)
        end
    end)
end

function UISkillShoutCreatNewSkillPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISkillShoutCreatNewSkillPop:OnClickSureBtn()
    local szSkillName = UIHelper.GetText(self.EditBox)
    local nLen = UIHelper.GetUtf8Len(szSkillName)
    if nLen > nMaxInputUtf8Len then
        TipsHelper.ShowNormalTip("技能名字过长")
        return
    end

    local bLegal = Table_IsLegalSkillName(szSkillName)
    if string.is_nil(szSkillName) or (not bLegal and not ChatAutoShout.IsSpecialSkill(szSkillName)) then
        TipsHelper.ShowNormalTip("技能名字不合法")
        return
    end

    local nSameSkillIndex = 0
    local tbSkillList = clone(Storage.Chat_SkillShout.tbSkillList) or {}
    local nInsertPos = #tbSkillList + 1
    for index, v in ipairs(tbSkillList) do
        if v.szSkillName == szSkillName then
            nSameSkillIndex = index
            break
        end
    end

    local _doSave = function()
        tbSkillList[nInsertPos] = {szSkillName = szSkillName, bApplied = true}
        ChatAutoShout.SaveSkillShout("tbSkillList", tbSkillList)

        UIMgr.Close(self)

        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelSkillShoutSetting)
        if scriptView then
            scriptView:OnEnter(nInsertPos, {[szSkillName] = true})
        else
            UIMgr.Open(VIEW_ID.PanelSkillShoutSetting, nInsertPos, {[szSkillName] = true})
        end
    end

    if nSameSkillIndex > 0 then
        UIHelper.ShowConfirm("已有相同技能，是否覆盖?", function()
            nInsertPos = nSameSkillIndex
            _doSave()
        end, _doSave)
        return
    else
        _doSave()
    end
end


return UISkillShoutCreatNewSkillPop