-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICMDEditorView
-- Date: 2022-11-10 10:05:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICMDEditorView = class("UICMDEditorView")

--为了少改动原有代码，新增全局缓存以及标记来进行判断
UICMDEditorView.tCMDCache = {}
UICMDEditorView.CountVersion = 0
UICMDEditorView.CountCheck = 0
UICMDEditorView.CurrentCMD = ''

function UICMDEditorView:OnEnter(tbGMView, tCMD)
    self.tCMD = tCMD
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self:BindKeyBoardEvent()
        self.bInit = true
    end
    self.tbGMView = tbGMView
    self.tbGMView.tbLastData.CMDEditorView = false
    self:UpdateInfo()
end

function UICMDEditorView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:UnBindKeyBoardEvent()
end

function UICMDEditorView:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnCarryout, EventType.OnClick, function(btn)
        self:UpdateCMDCache(self.tCMD.CMD)
        local szCMD = self.CurrentCMD~="" and self.CurrentCMD or (self.tCMD.CMD or "")
        GMMgr.ExecuteGMCommand(self.tCMD.text, string.gsub(szCMD,"\\", "/"), self.tCMD.CMDType)
        self.CountVersion = #self.tCMDCache
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        self.tbGMView.tbLastData.CMDEditorView = self.tCMD
        self:UpdateCMDCache(self.tCMD.CMD)
        local szCMD = self.CurrentCMD~="" and self.CurrentCMD or (self.tCMD.CMD or "")
        GMMgr.ExecuteGMCommand(self.tCMD.text, string.gsub(szCMD,"\\", "/"), self.tCMD.CMDType)
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelGM)
    end)

    UIHelper.BindUIEvent(self.BtnClear, EventType.OnClick, function(btn)
        UIHelper.SetString(self.EditCMD, "")
    end)

    UIHelper.BindUIEvent(self.BtnCloseView, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditCMD, function()
            local szCMD = UIHelper.GetString(self.EditCMD)
            self.tCMD.CMD = szCMD
            -- self:UpdateInfo_Left(szSearchkey)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditCMD, function()
            local szCMD = UIHelper.GetString(self.EditCMD)
            self.tCMD.CMD = szCMD
            -- self:UpdateInfo_Left(szSearchkey)
        end)
    end
end

function UICMDEditorView:BindKeyBoardEvent()
    local count = #self.tCMDCache
    KeyBoard.BindKeyUp(cc.KeyCode.KEY_UP_ARROW, "切换到上一指令", function()
        --如果计数版本不匹配，则强行更新count
        if self.CountVersion ~= self.CountCheck then
            count = #self.tCMDCache - 1
            self.CountCheck = self.CountVersion
        else
            if count > 1 then
                count = count - 1
            end
        end
        self:ShowCMDCache(count)
    end)

    KeyBoard.BindKeyUp(cc.KeyCode.KEY_DOWN_ARROW, "切换到下一指令", function()
        if count < #self.tCMDCache then
            count = count + 1
        end
        self:ShowCMDCache(count)
    end)
end

function UICMDEditorView:UnBindKeyBoardEvent()
    KeyBoard.UnBindKeyUp(cc.KeyCode.KEY_UP_ARROW)
    KeyBoard.UnBindKeyUp(cc.KeyCode.KEY_DOWN_ARROW)
end

function UICMDEditorView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICMDEditorView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICMDEditorView:UpdateInfo()
    local szCMD = tostring(self.tCMD.CMD)
    if not string.find(szCMD, "\r\n") then
        szCMD = tostring(self.tCMD.CMD):gsub(";",";\r\n")
    end
    UIHelper.SetString(self.LabelTitle, tostring(self.tCMD.text))
    UIHelper.SetString(self.EditCMD, szCMD)
end

function UICMDEditorView:UpdateCMDCache(szCMD)
    szCMD = tostring(szCMD)
    if szCMD and szCMD ~= '' then
        local foundIndex = nil
        for i, value in ipairs(self.tCMDCache) do
            if value == szCMD then
                foundIndex = i
                break
            end
        end
        if foundIndex then
            table.remove(self.tCMDCache, foundIndex)
        end
        table.insert(self.tCMDCache, szCMD)
        self.CountVersion = self.CountVersion + 1
    end
end

function UICMDEditorView:ShowCMDCache(nIndex)
    local szCMD = self.tCMDCache[nIndex]
    self.CurrentCMD = szCMD
    if szCMD and not string.find(szCMD, "\r\n") then
        szCMD = szCMD:gsub(";", ";\r\n")
    end
    UIHelper.SetString(self.EditCMD, szCMD or "")
end

return UICMDEditorView