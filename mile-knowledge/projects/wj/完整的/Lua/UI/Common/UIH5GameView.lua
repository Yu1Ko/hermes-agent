-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIH5GameView
-- Date: 2026-04-15 14:43:01
-- Desc: H5小游戏界面
-- ---------------------------------------------------------------------------------

local UIH5GameView = class("UIH5GameView")

function UIH5GameView:OnEnter(szGameName)
    self.szGameName = szGameName

    self.szPath = H5Mgr.GetRootPath() .. szGameName .. "/index.html"
    self.szFullPath = GetFullPath(self.szPath)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIH5GameView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIH5GameView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIH5GameView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIH5GameView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIH5GameView:UpdateInfo()
    self.Webview:loadFile(self.szFullPath)
    self.Webview:setScalesPageToFit(true)

    self.Webview:setOnShouldStartLoading(function(_, url)
        LOG.INFO("UIH5GameView, setOnShouldStartLoading, url = "..tostring(url))

        if string.find(url, "https://callcplusfunc") == 1 then
            if self:extractAfterEquals(url) == "submit_score" then
                UIMgr.Close(self)

            end

            return false
        end



        return true
    end)
end

function UIH5GameView:callJS()
    -- 调用一个无参的JS函数
    -- self.webview:evaluateJS("showMessage();");

    -- 调用一个带参的JS函数，并传递数据
    local jsCode = "window.JX3H5Host(‘{\"action\": \"onNativeMessage\"， \"value\": 100}’);"
    -- 或者直接调用： jsCode = “updateScore(100);“;
    local szCode = "window.JX3H5Host.onNativeMessage(123);"
    self.Webview:evaluateJS(szCode)
end

function UIH5GameView:extractAfterEquals(text)
    -- 找到等号位置
    local pos = text:find("=")

    if not pos then
        return nil, "未找到等号"
    end

    -- 提取等号后的所有内容
    local result = text:sub(pos + 1)

    -- 去除可能的空格
    result = result:match("^%s*(.-)%s*$")

    return result
end


return UIH5GameView