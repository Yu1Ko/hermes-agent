QuestionnaireData   = QuestionnaireData or {className = "QuestionnaireData"}

local self          = QuestionnaireData

--- 是否有新的问卷
self.bHasNew        = false

--- 当前问卷数据
self.tQuestionnaire = {
    --- 问卷链接
    szAddr = "",
    --- 答完问卷后，预期跳转的链接，用于判断是否答完
    szSubmiURL = "",
    --- 问卷ID
    szSurveyID = "",
    --- 问卷道具奖励，用于展示，最多会有4个
    tRewards = {
        { ItemType = 1, ItemIndex = 1, ItemStackNum = 10 },
        { ItemType = 1, ItemIndex = 2, ItemStackNum = 20 },
        { ItemType = 1, ItemIndex = 3, ItemStackNum = 30 },
        { ItemType = 1, ItemIndex = 4, ItemStackNum = 40 },
    },
}

function QuestionnaireData.Init()
    self.InitData()
    self.RegEvent()
end

function QuestionnaireData.UnInit()
    Event.UnRegAll(self)
end

function QuestionnaireData.InitData()
    self.bHasNew = false
end

function QuestionnaireData.RegEvent()
    Event.Reg(self, "POP_SURVEY", function(szAddr, szSubmiURL, szSurveyID, tRewards)
        self.UpdateQuestionnaire(true, szAddr, szSubmiURL, szSurveyID, tRewards)
    end)

    Event.Reg(self, EventType.OnRoleLogin, function()
        self.InitData()
    end)
end

function QuestionnaireData.UpdateQuestionnaire(bHasNew, szAddr, szSubmiURL, szSurveyID, tRewards)
    self.bHasNew                   = bHasNew

    if Channel.Is_WLColud() then
        -- WLCloud 端不显示问卷
        self.bHasNew = false
    end

    self.tQuestionnaire.szAddr     = szAddr
    self.tQuestionnaire.szSubmiURL = szSubmiURL
    self.tQuestionnaire.szSurveyID = szSurveyID
    self.tQuestionnaire.tRewards   = tRewards

    Event.Dispatch(EventType.OnQuestionnaireInfoChanged)

    -- 刷新下红点
    Event.Dispatch("OnUpdateHuaELouRedPoint")

    if bHasNew then
        LOG.DEBUG("收到新问卷 %s %s %s", szAddr, szSubmiURL, szSurveyID)
        LOG.TABLE(tRewards)
    end
end

function QuestionnaireData.OpenQuestionnaire()
    if not self.bHasNew then
        return
    end

    local tInfo = self.tQuestionnaire

    -- 打开问卷
    -- note: 手游上如果打开很慢，可以试试把 https:// 或 http:// 前缀给去掉，可以会好很多
    -- note: 好像之前打开白屏是预制脚本那边的问题，那边修复后，这个处理反而会导致部分情况无法打开，这里注释掉
    --tInfo.szAddr = string.gsub(tInfo.szAddr, "^https?://", "")
    --tInfo.szSubmiURL = string.gsub(tInfo.szSubmiURL, "^https?://", "")

    LOG.DEBUG("打开问卷 %s", tInfo.szAddr)
    local script  = UIHelper.OpenWeb(tInfo.szAddr, true)

    local bSubmit = false

    script.webview:setOnShouldStartLoading(function(_, newUrl)
        LOG.DEBUG("实际跳转 %s", newUrl)
        LOG.DEBUG("预期跳转 %s", tInfo.szSubmiURL)
        if string.find(newUrl, tInfo.szSubmiURL) and self.bHasNew then
            -- 若跳转到对应目标页面，则认为已提交，通知服务器
            LOG.DEBUG("上报问卷已提交 %s", tInfo.szSurveyID)
            RemoteCallToServer("OnSurveySubmit", tInfo.szSurveyID)

            bSubmit = true
            self.UpdateQuestionnaire(false)

            LOG.DEBUG("上报完后自动关闭浏览器")
            UIMgr.Close(VIEW_ID.PanelEmbeddedWebPages)
        end

        return true
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelEmbeddedWebPages then
            Event.UnReg(self, EventType.OnViewClose)

            if bSubmit then
                TipsHelper.ShowImportantYellowTip("感谢参与问卷调研，请至信使处查收邮件", false, 4)
            end
        end
    end)
end
