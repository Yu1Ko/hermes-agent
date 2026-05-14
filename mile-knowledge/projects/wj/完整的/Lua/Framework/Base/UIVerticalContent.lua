-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIVerticalContent
-- Date: 2023-04-21 17:50:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIVerticalContent = class("UIVerticalContent")

function UIVerticalContent:OnEnter(szContent)
    if not szContent then return end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szContent)
end

function UIVerticalContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIVerticalContent:BindUIEvent()
    
end

function UIVerticalContent:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIVerticalContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIVerticalContent:UpdateInfo(szContent)
    UIHelper.RemoveAllChildren(self.LayoutContent)
    local szContentList = string.split(szContent, "\n")
    local nPosY = UIHelper.GetWorldPositionY(self.ScrollViewVertical)
    for nIndex, szWord in ipairs(szContentList) do
        szWord = CraftData.BookNameOptimize(szWord)
        szWord = string.gsub(szWord, g_tStrings.STR_ONE_CHINESE_SPACE, "\n")
        szWord = string.gsub(szWord, " ", "\n")
        local tSubStringList = GetUTF8SubStringList(szWord, 16)
        for _, szSubString in ipairs(tSubStringList) do
            --szSubString = string.gsub(szSubString, g_tStrings.STR_ONE_CHINESE_SPACE, "\n")            
            local scriptLabel = UIHelper.AddPrefab(PREFAB_ID.WidgetVerticalLabel, self.ScrollViewVertical, szSubString)
            UIHelper.SetString(scriptLabel._rootNode, szSubString)
            UIHelper.SetTextColor(scriptLabel._rootNode, cc.c3b(0xAE, 0xD9, 0xE0))
            local nPosX = UIHelper.GetWorldPositionX(scriptLabel._rootNode)
            UIHelper.SetWorldPosition(scriptLabel._rootNode, nPosX, nPosY)
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewVertical)
    UIHelper.ScrollToLeft(self.ScrollViewVertical, 0)
end


return UIVerticalContent