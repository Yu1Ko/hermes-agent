-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIWebView
-- Date: 2022-11-16 17:34:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWebView = class("UIWebView")

function UIWebView:OnEnter(szURL)
    self.szURL = szURL

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWebView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    -- 关闭内置浏览器的时候 要设置一下PC的焦点，不然响应不了键盘事件
    WindowsSetFocus()
end

function UIWebView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReload, EventType.OnClick, function(btn)
        if self.webview then
            self.webview:reload()
        end
    end)

    UIHelper.BindUIEvent(self.BtnGoBack, EventType.OnClick, function(btn)
        if self.webview then
            self.webview:goBack()
        end
    end)

    UIHelper.BindUIEvent(self.GoForward, EventType.OnClick, function(btn)
        if self.webview then
            self.webview:goForward()
        end
    end)
end

function UIWebView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWebView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWebView:UpdateInfo()
    if Device.IsAndroid10() then
        local nHeight = UIHelper.GetHeight(self.webview)
        UIHelper.SetHeight(self.webview, nHeight - 80)
    end

    if self.webview and not string.is_nil(self.szURL) then
        self.webview:loadURL(self.szURL)
        self.webview:setScalesPageToFit(true)

        -- UIHelper.SetString(self.LabelLoading, "正在努力加载中...")
        -- UIHelper.SetVisible(self.LabelLoading, true)
        -- UIHelper.SetVisible(self.webview, false)

        -- self.webview:setOnShouldStartLoading(function(_, url)
        --     LOG.INFO("UIWebView, setOnShouldStartLoading, url = "..tostring(url))
        -- end)

        -- self.webview:setOnDidFinishLoading(function(_, url)
        --     LOG.INFO("UIWebView, setOnDidFinishLoading, url = "..tostring(url))
        --     UIHelper.SetVisible(self.LabelLoading, false)
        --     UIHelper.SetVisible(self.webview, true)
        -- end)

        -- self.webview:setOnDidFailLoading(function(_, url)
        --     LOG.INFO("UIWebView, setOnDidFailLoading, url = "..tostring(url))
        --     UIHelper.SetString(self.LabelLoading, "加载失败，请刷新重试")
        -- end)


    end



    -- canGoBack
    -- canGoForward
    -- self.webview:loadFile 还有这个接口，以后可以看手机上的日志？
end


return UIWebView



