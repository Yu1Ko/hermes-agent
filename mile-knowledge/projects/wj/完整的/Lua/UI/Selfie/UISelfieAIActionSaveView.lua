-- ---------------------------------------------------------------------------------
-- Author:
-- Name: UISelfieAIActionSaveView
-- Date: 2026-04-17
-- Desc: AI动作保存界面
-- ---------------------------------------------------------------------------------

local UISelfieAIActionSaveView = class("UISelfieAIActionSaveView")

function UISelfieAIActionSaveView:OnEnter(tSaveType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tSaveType = tSaveType
    self:UpdateInfo()
end

function UISelfieAIActionSaveView:RegEvent()
end

function UISelfieAIActionSaveView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        self:OnSaveHandle()
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UISelfieAIActionSaveView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieAIActionSaveView:UnRegEvent()
end

function UISelfieAIActionSaveView:OnDestroy()
end

function UISelfieAIActionSaveView:UpdateInfo()
    local bShowBody = false
    local bShowFace = false
    for k, v in pairs(self.tSaveType) do
        if v == AI_MOTION_TYPE.BODY then
            bShowBody = true
        elseif v == AI_MOTION_TYPE.FACE then
            bShowFace = true
        end
    end
    UIHelper.SetVisible(self.WidgetActionTitle, bShowBody)
    UIHelper.SetVisible(self.WidgetActionName, bShowBody)

    UIHelper.SetVisible(self.WidgetFaceActionTitle, bShowFace)
    UIHelper.SetVisible(self.WidgetFaceActionName, bShowFace)

    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UISelfieAIActionSaveView:OnSaveHandle()
    local szBodyActName = UIHelper.GetText(self.EditBoxBodyAction)
    local szFaceActName = UIHelper.GetText(self.EditBoxFaceAction)
     -- 转存身体动作文件
     local bAllSuccess = true
     for _, nType in ipairs(self.tSaveType) do
         local szActName
         if nType == AI_MOTION_TYPE.BODY then
             szActName = szBodyActName
         elseif nType == AI_MOTION_TYPE.FACE then
             szActName = szFaceActName
         end
 
         if bAllSuccess then
             local bSuccess = self:SaveCustomAct(nType, szActName)
             if not bSuccess then
                 bAllSuccess = false
             end
         end
     end
     if bAllSuccess then
        UIMgr.Close(self)
     end
end

function UISelfieAIActionSaveView:SaveCustomAct(nType, szActName)
    --判空
    if not szActName or szActName == "" then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_AI_SAVE_NULL1)
        return false
    end

    if string.find(szActName, " ", 1, true) ~= nil then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_AI_SAVE_NULL2)
        return false
    end

    local szTitle = g_tStrings.tSelfieSaveAITitle[nType]

    --过滤文字
    if not TextFilterCheck(UIHelper.UTF8ToGBK(szActName)) then
        local szMsg =  string.format(g_tStrings.STR_SELFIE_AI_SAVE_ILLEGAL, szTitle)
        OutputMessage("MSG_ANNOUNCE_RED", szMsg)
        return false
    end

   local tCustomMotion = AiBodyMotionData.GetAllCustomFile()

    --不允许重名
    local nCount = 0
    for _, v in ipairs(tCustomMotion) do
        if v.nType == nType then
            nCount = nCount + 1

            if v.szName == szActName then
                OutputMessage("MSG_ANNOUNCE_RED", string.format(g_tStrings.STR_SELFIE_AI_SAVE_REPEAT_FAILED, szTitle))
                return false
            end
        end
    end

    if nCount >= 5 then
        OutputMessage("MSG_ANNOUNCE_RED", string.format(g_tStrings.STR_SELFIE_AI_SAVE_MAX_FAILED, szTitle))
        return false
    end

    local szSourcePath, szSavePath
    if nType == AI_MOTION_TYPE.BODY then
        szSourcePath = AiBodyMotionData.GetBodyAniFile()
        szSavePath = AiBodyMotionData.GetSaveBodyActPath(szActName)
    elseif nType == AI_MOTION_TYPE.FACE then
        szSourcePath = AiBodyMotionData.GetFaceAniFile()
        szSavePath = AiBodyMotionData.GetSaveFaceActPath(szActName)
    end
    
    if not szSourcePath or not szSavePath then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_AI_SAVE_FAILED)
        return false
    end

    local tMotion = {
        szMotionFilePath = szSavePath,
        nType = nType,
        szName = szActName,
    }
    AiBodyMotionData.SaveCustomFile(tMotion, szSourcePath, szSavePath)
    OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_AI_SAVE_SUCCESS)
    return true
end

return UISelfieAIActionSaveView
