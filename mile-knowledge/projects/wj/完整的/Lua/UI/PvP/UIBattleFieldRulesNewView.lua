-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIBattleFieldRulesViewNew
-- Date: 2023-03-28 15:57:34
-- Desc: 战场规则界面 PanelBattleFieldRulesNew
-- ---------------------------------------------------------------------------------

local UIBattleFieldRulesViewNew = class("UIBattleFieldRulesViewNew")

local tMapIDsList = {
    BATTLE_FIELD_MAP_ID.YUN_HU_TIAN_DI,
    BATTLE_FIELD_MAP_ID.FU_XIANG_QIU,
    BATTLE_FIELD_MAP_ID.SHEN_NONG_YIN,
    BATTLE_FIELD_MAP_ID.SAN_GUO_GU_ZHAN_CHANG,
    BATTLE_FIELD_MAP_ID.XI_FENG_GU_DAO,
    BATTLE_FIELD_MAP_ID.JIU_GONG_QI_GU,
    BATTLE_FIELD_MAP_ID.XUE_YU_GUAN_CHENG,
}

--绝境战场的地图
local tDesertStormMapIDsList = {
    BATTLE_FIELD_MAP_ID.LONG_MEN_JUE_JING,
    BATTLE_FIELD_MAP_ID.CANG_MING_JUE_JING,
    BATTLE_FIELD_MAP_ID.BAI_LONG_JUE_JING,
    BATTLE_FIELD_MAP_ID.TIAN_YUAN_JUE_JING,
}

local tTitleList = {
    "胜利目标",
    "开启时间",
    "得分方法",
    "战场背景",
}

function UIBattleFieldRulesViewNew:OnEnter(dwMapID, bDesertStorm)
    self.dwMapID = dwMapID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tMapIDs = bDesertStorm and tDesertStormMapIDsList or tMapIDsList
    local szViewTitle = "战场规则"
    if bDesertStorm and TreasureBattleFieldData.IsSingleMatchMap(self.dwMapID) then
        tMapIDs = {self.dwMapID}
    end
    if bDesertStorm and TreasureBattleFieldData.IsSkillMatchMap(self.dwMapID) then
        tMapIDs = {self.dwMapID}
    end
    if bDesertStorm and TreasureBattleFieldData.IsExtractMatchMap(self.dwMapID) then
        tMapIDs = {self.dwMapID}
    end
    if dwMapID == BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN then
        tMapIDs = {self.dwMapID}
        szViewTitle = "玩法规则"
    end
    -- 测试用，所有地图
    -- tMapIDs = {}
    -- local nCount = g_tTable.BattleField:GetRowCount()
    -- for i = 2, nCount do
    --     local tLine = g_tTable.BattleField:GetRow(i)
    --     table.insert(tMapIDs, tLine.dwMapID)
    -- end
    self:InitUI(tMapIDs, szViewTitle)
    self:UpdateInfo()
end

function UIBattleFieldRulesViewNew:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBattleFieldRulesViewNew:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMenuChange, EventType.OnClick, function()
        print("BtnMenuChange")
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIBattleFieldRulesViewNew:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBattleFieldRulesViewNew:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIBattleFieldRulesViewNew:InitUI(tMapIDs, szViewTitle)
    if not string.is_nil(szViewTitle) then
        UIHelper.SetString(self.LabelTitle, szViewTitle)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewContent)
    for _, v in ipairs(tMapIDs) do
        local dwMapID = v
        local scriptTog = UIMgr.AddPrefab(PREFAB_ID.WidgetBattleFieldRulesTog, self.ScrollViewContent)

        local szName = UIHelper.GBKToUTF8(Table_GetBattleFieldName(dwMapID))
        scriptTog:SetText(szName)
        scriptTog:RegisterToggleGroup(self.ToggleGroupTab)
        scriptTog:SetSelected(dwMapID == self.dwMapID, true)
        scriptTog:SetSelectedCallback(function(bSelected)
            if bSelected and dwMapID ~= self.dwMapID then
                self.dwMapID = dwMapID
                self:UpdateInfo()
            end
        end)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    Timer.AddFrame(self, 1, function()
        UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewBattleRules, true, true)
        UIHelper.ScrollViewDoLayout(self.ScrollViewBattleRules)
        UIHelper.ScrollToTop(self.ScrollViewBattleRules)
    end)
end

function UIBattleFieldRulesViewNew:UpdateInfo()
    local dwMapID = BattleFieldData.GetBattleFieldFatherID(self.dwMapID)
    local szHelpImage, szHelpText = Table_GetBattleFieldHelpInfo(dwMapID)

    self:ClearRuleItem()

    -- szHelpText = string.pure_text(szHelpText)
    -- szHelpText = string.gsub(szHelpText, "\\", "\n") or szHelpText
    -- szHelpText = UIHelper.GBKToUTF8(szHelpText)

    -- for i = 1, #tTitleList do
    --     local szTitle = tTitleList[i]
    --     local szContent
    --     for j = 1, #tTitleList do
    --         if  i ~= j then
    --             local szNextTitle = tTitleList[j]
    --             --例：取“胜利目标：\n\n”到“\n\n得分方法：”之间的内容
    --             string.gsub(szHelpText, szTitle .. "：?[%s]*(.-)[%s]*" .. szNextTitle .. "：?", function(szText)
    --                 if not szContent or #szText < #szContent then
    --                     szContent = szText
    --                 end
    --             end)
    --             --有些地图战场背景字符中间缺少'：'
    --             string.gsub(szHelpText, szTitle .. "?[%s]*(.-)[%s]*" .. szNextTitle .. "：?", function(szText)
    --                 if not szContent or #szText < #szContent then
    --                     szContent = szText
    --                 end
    --             end)
    --         end
    --     end

    --     if not szContent then
    --         string.gsub(szHelpText, szTitle .. "：?[%s]*(.*)", function(szText)
    --             szContent = szText
    --         end)
    --     end

    --     if szContent and #szContent > 0 then
    --         --查了battlefield.txt表之后发现结尾有些神秘字符“　”又不是换行又不是空格反正很坑
    --         szContent = string.gsub(szContent, "[%s　]*$", "")
    --         self:AddRuleItem(szTitle, szContent)
    --     end
    -- end

    if szHelpText and string.find(szHelpText, "text=") then
        local szTitle, szTitleFontID
        szHelpText = UIHelper.GBKToUTF8(szHelpText)
        szHelpText = string.gsub(szHelpText, "\\\n", "\n")
        szHelpText = string.gsub(szHelpText, "text=.-</text>", function(szTarget)
            local szContent = string.match(szTarget, "text=\"(.-)\"")
            local szFontID = string.match(szTarget, "font=(%d+)")
            if not szTitleFontID then
                szTitleFontID = szFontID
            end
            if szFontID == szTitleFontID then
                szContent = string.gsub(szContent, "\n", "")
                szContent = string.gsub(szContent, "：", "")
                szTitle = szContent
            else
                szContent = string.gsub(szContent, "^[\n\r]+", "")
                self:AddRuleItem(szTitle, szContent)
                szTitle = nil
            end
        end)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewBattleRules, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewBattleRules)
    UIHelper.ScrollToTop(self.ScrollViewBattleRules)

    --图片
    if szHelpImage and #szHelpImage > 0 then
        --\ui\Image\BattleField\shennongyin.tga DX路径
        --Resource\BattleField\shennongyin.png VK路径
        szHelpImage = string.gsub(szHelpImage, "\\ui\\Image", "Resource")
        szHelpImage = string.gsub(szHelpImage, ".tga", ".png")

        UIHelper.SetTexture(self.ImgRules, szHelpImage)
        UIHelper.SetVisible(self.WidgetBattleMap, true)
    else
        UIHelper.SetVisible(self.WidgetBattleMap, false)
    end
end

function UIBattleFieldRulesViewNew:ClearRuleItem()
    UIHelper.RemoveAllChildren(self.ScrollViewBattleRules)
end

function UIBattleFieldRulesViewNew:AddRuleItem(szTitle, szContent)
    UIMgr.AddPrefab(PREFAB_ID.WidgetBattleFieldRules, self.ScrollViewBattleRules, szTitle, szContent)
end


return UIBattleFieldRulesViewNew