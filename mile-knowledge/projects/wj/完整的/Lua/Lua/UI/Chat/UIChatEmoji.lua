-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatEmoji
-- Date: 2022-12-24 12:54:19
-- Desc: 聊天表情
-- ---------------------------------------------------------------------------------

local UIChatEmoji = class("UIChatEmoji")

----
-- 0 emoji
-- 1 收藏
-- 2 语言
----
function UIChatEmoji:OnEnter()
    self.nCurGroupID = 0

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        JiangHuLanguageData.Init()
    end

    self:UpdateInfo()
end

function UIChatEmoji:OnExit()
    self.bInit = false
    self:UnRegEvent()
    JiangHuLanguageData.UnInit()
end

function UIChatEmoji:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        Event.Dispatch(EventType.OnChatEmojiClosed)
    end)

    UIHelper.BindUIEvent(self.BtnAddCollection, EventType.OnClick, function()
        -- TODO Add collection
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableView, function(tableView, nIndex, script, node, cell)
        local tbGroupInfo = self.tbEmojiGroupList[nIndex]
        if script and tbGroupInfo then
            local bEnable = true
            if self.szUIChannel == UI_Chat_Channel.AINpc and nIndex ~= 1 then
                bEnable = false
            end

            script:OnEnter(tbGroupInfo, nIndex == 1, bEnable)
        end
    end)
end

function UIChatEmoji:RegEvent()
    Event.Reg(self, EventType.OnChatEmojiGroupSelected, function(nGroupID)
        self.nCurGroupID = nGroupID
        self:UpdateInfo_List()
    end)

    Event.Reg(self, "JiangHuWordUpdate", function()
        self:UpdateInfo_LanguageList()
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if self.nCurGroupID == -1 and nViewID == VIEW_ID.PanelCollectEmoticons then
            self:UpdateInfo_EmojiList()
        end
    end)
end

function UIChatEmoji:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatEmoji:UpdateInfo()
    self:UpdateInfo_ToggleList()
end

function UIChatEmoji:UpdateInfo_List()
    if self.nJiangHuLanguageID then
        Timer.DelTimer(self , self.nJiangHuLanguageID)
    end

    if self.nCurGroupID == nil then
        self:UpdateInfo_LanguageList()
    else
        self:UpdateInfo_EmojiList()
    end
end

function UIChatEmoji:UpdateInfo_EmojiList()
    UIHelper.RemoveAllChildren(self.ScrollViewExpression)

    local tbEmojiList = ChatData.GetEmojiOneGroupInfo(self.nCurGroupID)

    local nCount = #tbEmojiList
    for i = 1, nCount do
        local tbEmojiConf = tbEmojiList[i]
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBtnExpression, self.ScrollViewExpression)
        script:OnEnter(tbEmojiConf)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewExpression)
    UIHelper.ScrollToTop(self.ScrollViewExpression)
end

function UIChatEmoji:UpdateInfo_LanguageList()
    UIHelper.RemoveAllChildren(self.ScrollViewExpression)

    local tJiangHuLanguage = JiangHuLanguageData.GetJiangHuData()

    local listIndex = 0
    local listCount = #tJiangHuLanguage
    local setBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetBtnChatTextExpression, self.ScrollViewExpression) assert(setBtn)
    UIHelper.BindUIEvent(setBtn.BtnChatText, EventType.OnClick,function ()
        UIMgr.Open(VIEW_ID.PanelChatTextExpression)
    end)
    if listCount > 0 then
        self.nJiangHuLanguageID = Timer.AddFrameCycle(self , 1 , function ()
            for i = 1, 20, 1 do
                listIndex = listIndex + 1
                local jiangHuData = tJiangHuLanguage[listIndex]
                local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetBtnChatTextExpression, self.ScrollViewExpression) assert(scriptBtn)
                UIHelper.SetVisible(scriptBtn.ImgIcon, false)
                UIHelper.SetString(scriptBtn.LabelContent, jiangHuData[1])
                UIHelper.BindUIEvent(scriptBtn.BtnChatText, EventType.OnClick, function ()
                    JiangHuLanguageData.ProcessJiangHuWord(jiangHuData)
                end)

                if listIndex == listCount then
                    Timer.DelTimer(self , self.nJiangHuLanguageID)
                    break
                end
            end
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewExpression)
        end)
    end
end

function UIChatEmoji:UpdateInfo_ToggleList()
    self.tbEmojiGroupList = ChatData.GetChatEmojiGroupList(true)
    UIHelper.TableView_init(self.TableView, #self.tbEmojiGroupList, PREFAB_ID.WidgetTabExpression)
    UIHelper.TableView_reloadData(self.TableView)
end

function UIChatEmoji:UpdateInfoByUIChannel(szUIChannel)
    self.szUIChannel = szUIChannel

    local bLastIsAINpcChannel = self.szUIChannel == UI_Chat_Channel.AINpc
    if self.bLastIsAINpcChannel ~= bLastIsAINpcChannel then
        self:UpdateInfo_ToggleList()
        self.bLastIsAINpcChannel = bLastIsAINpcChannel
    end
end



return UIChatEmoji