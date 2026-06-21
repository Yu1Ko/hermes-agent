-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ServiceCenterFeedback
-- Date: 2023-06-20 14:59:12
-- Desc: 客服中心 - 反馈BUG
-- ---------------------------------------------------------------------------------

local ServiceCenterFeedback = class("ServiceCenterFeedback")
local ToggleType =
{
    Quest = 1,
    NPC = 2,
    Scene = 3,
    Craft = 4,
    Other = 5,
    Item = 6,
    Char = 7,
    Skill = 8 ,
    Tip = 9,
}

local LifeToggleName =
{
    g_tStrings.CRAFT_HERBALISM,
    g_tStrings.CRAFT_MINING,
    g_tStrings.CRAFT_DISSECTING,
    g_tStrings.CRAFT_CUILIAN,
    g_tStrings.CRAFT_READING,
    g_tStrings.CRAFT_COOKING,
    g_tStrings.CRAFT_SMITHING,
    g_tStrings.CRAFT_TAILORING,
    g_tStrings.CRAFT_LEECHCRAFT,
}

local CURL_REQUEST_TAG = "Bug"

function ServiceCenterFeedback:OnEnter(tbFeeInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbFeeInfo = tbFeeInfo or self.tbFeeInfo
    self:UpdateInfo()
end

function ServiceCenterFeedback:OnExit()
    self.bInit = false
    self.tbFeeInfo = nil
    self:UnRegEvent()
end

function ServiceCenterFeedback:BindUIEvent()
    for i, v in ipairs(self.tbTypeToggle) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
            UIHelper.SetSelected(self.tbTypeToggle[self.nCurSelectType] , false)
            self.nCurSelectType = i
            UIHelper.SetSelected(self.tbTypeToggle[self.nCurSelectType] , true)
            self:UpdateEditState()
        end)
    end

    for i, v in ipairs(self.tbLifeToggle) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
           self.nSelectLiftType = i
        end)
    end

    UIHelper.BindUIEvent(self.BtnSubmit , EventType.OnClick , function ()
       self:OnSubmit()
    end)
end

function ServiceCenterFeedback:RegEvent()
    Event.Reg(self, "CURL_REQUEST_RESULT", function ()
        local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3
        if szKey == CURL_REQUEST_TAG then
            local confirmView = UIHelper.ShowConfirm(g_tStrings.MSG_QUEST_SEND_SUCCEED)
            confirmView:HideCancelButton()
        end
    end)
end

function ServiceCenterFeedback:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceCenterFeedback:UpdateInfo()
    UIHelper.SetText(self.NameEdit  , "")
    UIHelper.SetText(self.SceneEdit  , "")
    UIHelper.SetText(self.DescribeEdit  , "")
    self.nCurSelectType = 1
    if  self.tbFeeInfo then
        self.nCurSelectType = self.tbFeeInfo.nSelectIndex
    end
    UIHelper.SetSelected(self.tbTypeToggle[self.nCurSelectType] , true)
    self:UpdateEditState()
end

function ServiceCenterFeedback:UpdateEditState()
    local bShowEditor1 =  self:CheckEditShow(1)
    local bShowEditor2 =  self:CheckEditShow(2)
    UIHelper.SetVisible(self.LayoutNameEdit ,bShowEditor1)
    UIHelper.SetVisible(self.LayoutSceneEdit ,bShowEditor2)
    UIHelper.SetString(self.LabelName , self:GetEditTitleName(1))
    UIHelper.SetString(self.LabelScene , self:GetEditTitleName(2))
    UIHelper.SetText(self.NameEdit , "")
    UIHelper.SetText(self.SceneEdit , "")

    if  self.tbFeeInfo then
        if self.tbFeeInfo.nSelectIndex == self.nCurSelectType then
            if self.tbFeeInfo.tbParams then
                if self.tbFeeInfo.tbParams[1] then
                    UIHelper.SetText(self.NameEdit  , UIHelper.GBKToUTF8(self.tbFeeInfo.tbParams[1]))
                end
                if self.tbFeeInfo.tbParams[2] then
                    UIHelper.SetText(self.SceneEdit  , self.tbFeeInfo.tbParams[2])
                end
            end
        end
    end


    if self.nCurSelectType == ToggleType.Scene then
        local player = GetClientPlayer()
		local szName = Table_GetMapName(player.GetMapID())
        UIHelper.SetText(self.NameEdit , UIHelper.GBKToUTF8(szName))
        UIHelper.SetText(self.SceneEdit , player.nX..","..player.nY..","..player.nZ)
    end

    UIHelper.SetVisible(self.WidgetEditorContent ,bShowEditor1 or bShowEditor2)
    UIHelper.SetVisible(self.WidgetLife , self.nCurSelectType == ToggleType.Craft)
    self.nSelectLiftType = 1
    UIHelper.SetToggleGroupSelected(self.WidgetLifeChoose, 0)
    UIHelper.LayoutDoLayout(self.WidgetContent , true)
end

function ServiceCenterFeedback:OnSubmit()
	local szEdit1 = UIHelper.GetText(self.NameEdit)
	local szEdit2 = UIHelper.GetText(self.SceneEdit)
    local szMessage = UIHelper.GetText(self.DescribeEdit)
    local confirmView
    if szEdit1 == "" and not self:CheckEditEmpty(1) then
        confirmView = UIHelper.ShowConfirm(self:GetEditEmptyTip(1))
    elseif szEdit2 == "" and not self:CheckEditEmpty(2) then
            confirmView = UIHelper.ShowConfirm(self:GetEditEmptyTip(2))
	elseif string.len(szMessage) < 10 then
        confirmView = UIHelper.ShowConfirm(g_tStrings.MSG_DESCRIBE_TOO_FEW)
	else
        local UrlParam =  self:GetFillData(szEdit1 , szEdit2 , szMessage)
        if Platform.IsAndroid() or bIsAndroid then
            UrlParam["Platform"] = "Android"
        elseif Platform.IsIos() or bIsIos then
            UrlParam["Platform"] = "Ios"
        else
            UrlParam["Platform"] = "VKWin"
        end
		ServiceCenterData.SendDataToGMWEB(CURL_REQUEST_TAG,UrlParam)
        CURL_HttpPost(CURL_REQUEST_TAG, ServiceCenterData.GetGameMasterReportUrl(), UrlParam)
        UIHelper.SetText(self.NameEdit  , "")
        UIHelper.SetText(self.SceneEdit  , "")
        UIHelper.SetText(self.DescribeEdit  , "")
        if self.nCurSelectType == ToggleType.Scene then
            local player = GetClientPlayer()
            local szName = Table_GetMapName(player.GetMapID())
            UIHelper.SetText(self.NameEdit , UIHelper.GBKToUTF8(szName))
            UIHelper.SetText(self.SceneEdit , player.nX..","..player.nY..","..player.nZ)
        end
        self.tbFeeInfo = nil
	end
    if confirmView then
        confirmView:HideCancelButton()
    end
end

function ServiceCenterFeedback:GetEditEmptyTip(nEditIndex)
    if not self.tbNameConfirmContent then
        self.tbNameConfirmContent = {}
        self.tbNameConfirmContent[ToggleType.Quest] = {g_tStrings.MSG_INPUT_QUEST_NAME , ""}
        self.tbNameConfirmContent[ToggleType.Char] =  {g_tStrings.MSG_INPUT_QUEST_NAME , ""}
        self.tbNameConfirmContent[ToggleType.Craft] = {"" , ""}
        self.tbNameConfirmContent[ToggleType.Item] = {g_tStrings.MSG_INPUT_QUEST_NAME , ""}
        self.tbNameConfirmContent[ToggleType.NPC] = {g_tStrings.MSG_INPUT_NPC_NAME , ""}
        self.tbNameConfirmContent[ToggleType.Other] = {"" , ""}
        self.tbNameConfirmContent[ToggleType.Scene] = {g_tStrings.MSG_INPUT_MAP_NAME , ""}
        self.tbNameConfirmContent[ToggleType.Skill] = {g_tStrings.MSG_INPUT_SCHOOL_NAME ,g_tStrings.MSG_INPUT_SKILL_NAME}
        self.tbNameConfirmContent[ToggleType.Tip] = {"" , ""}
    end
    return self.tbNameConfirmContent[self.nCurSelectType][nEditIndex]
end

-- 检测编辑框是否可以为空
function ServiceCenterFeedback:CheckEditEmpty(nEditIndex)
    if not self.tbCheckInputName then
        self.tbCheckInputName = {}
        self.tbCheckInputName[ToggleType.Quest] = {false , true}
        self.tbCheckInputName[ToggleType.Char] = {false , true}
        self.tbCheckInputName[ToggleType.Craft] = {true , true}
        self.tbCheckInputName[ToggleType.Item] = {false , true}
        self.tbCheckInputName[ToggleType.NPC] = {false , true}
        self.tbCheckInputName[ToggleType.Other] = {true , true}
        self.tbCheckInputName[ToggleType.Scene] = {false , true}
        self.tbCheckInputName[ToggleType.Skill] = {false , false}
        self.tbCheckInputName[ToggleType.Tip] = {true , true}
    end
    return self.tbCheckInputName[self.nCurSelectType][nEditIndex]
end

function ServiceCenterFeedback:CheckEditShow(nEditIndex)
    if not self.tbCheckInputShow then
        self.tbCheckInputShow = {}
        self.tbCheckInputShow[ToggleType.Quest] = {true , true}
        self.tbCheckInputShow[ToggleType.Char] = {true , true}
        self.tbCheckInputShow[ToggleType.Craft] = {false , false}
        self.tbCheckInputShow[ToggleType.Item] = {true , true}
        self.tbCheckInputShow[ToggleType.NPC] = {true , true}
        self.tbCheckInputShow[ToggleType.Other] = {false , false}
        self.tbCheckInputShow[ToggleType.Scene] = {true , true}
        self.tbCheckInputShow[ToggleType.Skill] = {true , true}
        self.tbCheckInputShow[ToggleType.Tip] = {false , false}
    end

    if self.tbCheckInputShow[self.nCurSelectType] then
        return self.tbCheckInputShow[self.nCurSelectType][nEditIndex]
    end

    return false
end

function ServiceCenterFeedback:GetEditTitleName(nEditIndex)
    if not self.tbEditTitleName then
        self.tbEditTitleName = {}
        self.tbEditTitleName[ToggleType.Quest] = {"任务名称" , "场景名" }
        self.tbEditTitleName[ToggleType.Char] = {"角色名" , "性别" }
        self.tbEditTitleName[ToggleType.Craft] = {"" , ""}
        self.tbEditTitleName[ToggleType.Item] = {"物品名" , "来源" }
        self.tbEditTitleName[ToggleType.NPC] = {"NPC名" , "场景名" }
        self.tbEditTitleName[ToggleType.Other] = {"" , ""}
        self.tbEditTitleName[ToggleType.Scene] = {"场景名" , "坐标" }
        self.tbEditTitleName[ToggleType.Skill] = {"门派名" , "技能名" }
        self.tbEditTitleName[ToggleType.Tip] = {"" , ""}
    end

    if self.tbEditTitleName[self.nCurSelectType] then
        return self.tbEditTitleName[self.nCurSelectType][nEditIndex]
    end

    return false
end

function ServiceCenterFeedback:GetTypeName()
    if not self.tbTypeName then
        self.tbTypeName = {}
        self.tbTypeName[ToggleType.Quest] = "QuestBug"
        self.tbTypeName[ToggleType.Char] = "PlayerBug"
        self.tbTypeName[ToggleType.Craft] = "CraftBug"
        self.tbTypeName[ToggleType.Item] = "ItemBug"
        self.tbTypeName[ToggleType.NPC] = "NpcBug"
        self.tbTypeName[ToggleType.Other] = "OtherBug"
        self.tbTypeName[ToggleType.Scene] = "MapBug"
        self.tbTypeName[ToggleType.Skill] = "SkillBug"
        self.tbTypeName[ToggleType.Tip] = "Textbug"
    end
    return self.tbTypeName[self.nCurSelectType]
end

function ServiceCenterFeedback:GetFillData(szEdit1 , szEdit2 , szMessage)
    local UrlParam = {}
    ServiceCenterData.FillBasicInfo(self:GetTypeName(), UrlParam)
    szEdit1 = UIHelper.UTF8ToGBK(szEdit1) or ""
    szEdit2 = UIHelper.UTF8ToGBK(szEdit2) or ""
    szMessage = UIHelper.UTF8ToGBK(szMessage) or ""
    szMessage = (szMessage == "") and "unInput" or szMessage
    szEdit2 = (szEdit2 == "") and "unInput" or szEdit2
    szEdit1 = (szEdit2 == "") and "unInput" or szEdit2
    if  self.nCurSelectType == ToggleType.Quest then
        if szEdit2 == "" then
            szEdit2 =  UIHelper.UTF8ToGBK(g_tStrings.UNKNOWN_MAP)
        end
        UrlParam["QuestName"] = szEdit1
        UrlParam["QuestID"] = 0
		UrlParam["InputMapName"] = szEdit2
		UrlParam["Detail"] = szMessage
    elseif self.nCurSelectType == ToggleType.Tip then
        UrlParam["Detail"] = szMessage
    elseif self.nCurSelectType == ToggleType.Other then
        UrlParam["Detail"] = szMessage
    elseif self.nCurSelectType == ToggleType.Craft then
        UrlParam["CraftType"] = UIHelper.UTF8ToGBK(LifeToggleName[self.nSelectLiftType])
		UrlParam["Detail"] = szMessage
    elseif self.nCurSelectType == ToggleType.NPC then
        UrlParam["NpcName"] = szEdit1
		UrlParam["InputMapName"] = szEdit2
		UrlParam["Detail"] = szMessage
        UrlParam["NpcTemplateID"] = 0
    elseif self.nCurSelectType == ToggleType.Scene then
        if szEdit2 == "" then
            szEdit2 =  UIHelper.UTF8ToGBK(g_tStrings.MSG_UNKNOW_POS)
        end
        UrlParam["InputMapName"] = szEdit1
		UrlParam["Position"] = szEdit2
		UrlParam["Detail"] = szMessage
    elseif self.nCurSelectType == ToggleType.Item then
        if szEdit2 == "" then
            szEdit2 =  UIHelper.UTF8ToGBK(g_tStrings.MSG_UNKNOW_SOURCE)
        end
        UrlParam["ItemName"] = szEdit1
		UrlParam["From"] = szEdit2
		UrlParam["ItemVersion"] = 0
		UrlParam["ItemTableType"] = 0
		UrlParam["ItemTableIndex"] = 0
		UrlParam["Detail"] = szMessage
    elseif self.nCurSelectType == ToggleType.Char then
        if szEdit2 == "" then
            szEdit2 =  UIHelper.UTF8ToGBK(g_tStrings.MSG_UNKNOW_SEX)
        end
        UrlParam["PlayerName"]	= szEdit1
		UrlParam["Sex"] = szEdit2
		UrlParam["Detail"] = szMessage
    elseif self.nCurSelectType == ToggleType.Skill then
        UrlParam["SchoolName"] = szEdit1
		UrlParam["SkillName"] = szEdit2
		UrlParam["SkillID"] = 0
		UrlParam["SkillLevel"] = 0
		UrlParam["Detail"] = szMessage
    end
    return UrlParam
end


return ServiceCenterFeedback