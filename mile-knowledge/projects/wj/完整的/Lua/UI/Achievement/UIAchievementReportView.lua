-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementReportView
-- Date: 2023-02-15 16:47:38
-- Desc: 隐元秘鉴 - 隐元秘档
-- Prefab: PanelAchievementReport
-- ---------------------------------------------------------------------------------

local UIAchievementReportView = class("UIAchievementReportView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementReportView:_LuaBindList()
    self.BtnClose                 = self.BtnClose --- 关闭界面
    self.LabelRoleName            = self.LabelRoleName --- 角色名称（标题）
    self.ScrollViewReportItemList = self.ScrollViewReportItemList --- 报告条目列表的 scroll view
    self.LayoutReportItemList     = self.LayoutReportItemList --- 报告条目列表的 layout
end

function UIAchievementReportView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementReportView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementReportView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIAchievementReportView:RegEvent()
    Event.Reg(self, "ON_GET_DOCUMENT", function(dwPlayerID, tInfo)
        -- 把数据保存起来，这样后面打开不需要再请求了。避免频繁请求时服务器提示需要1分钟间隔
        AchievementData.tReportInfo = tInfo
        
        self:UpdateReportItemList(dwPlayerID, tInfo)
    end)
end

function UIAchievementReportView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementReportView:UpdateInfo()
    local player = g_pClientPlayer

    UIHelper.SetString(self.LabelRoleName, GBKToUTF8(player.szName))

    -- 在请求到数据之前，先显示个等待信息
    self:AddReportItem(g_tStrings.STR_ACHIEVEMENT_APPLYING)
    self:UpdateScrollView()

    if not AchievementData.tReportInfo then
        RemoteCallToServer("On_Achievement_GetDocumentInfo", g_pClientPlayer.dwID)
    else
        self:UpdateReportItemList(g_pClientPlayer.dwID, AchievementData.tReportInfo)
    end
    
end

local function AddAItemMsg(szInfo, bNormal)
    -- fixme: 手游目前这个函数不支持font参数，这里先临时修改下颜色
    if bNormal then
        --return GetFormatText(szInfo, 225, nil, nil, nil, nil, nil, nil, nil, nil, 200)
        return GetFormatText(szInfo, 225, 29, 71, 95, nil, nil, nil, nil, nil, 200)
    else
        --return GetFormatText(szInfo, 240, nil, nil, nil, nil, nil, nil, nil, nil, 200)
        return GetFormatText(szInfo, 240, 187, 135, 60, nil, nil, nil, nil, nil, 200)
    end
end

local function AddMsg(szSelf, szInfo, szBefore, szAfter)
    local szMsg = szSelf
    if szInfo then
        if szBefore then
            szMsg = szMsg .. AddAItemMsg(szBefore, true)
        end
        szMsg = szMsg .. AddAItemMsg(szInfo, false)
        if szAfter then
            szMsg = szMsg .. AddAItemMsg(szAfter, true)
        end
    end
    return szMsg
end

function UIAchievementReportView:UpdateReportItemList(dwPlayerID, tInfo)
    ---- 先清空数据
    UIHelper.RemoveAllChildren(self.ScrollViewReportItemList)

    local szMsg                     = ""
    local szCreateTime              = ""
    local szJoinTongTime            = ""

    if tInfo.nCreateTime then
        local tStartTime = TimeToDate(tInfo.nCreateTime)
        szCreateTime     = g_tStrings.STR_TIME_7 .. FormatString(g_tStrings.STR_TIME_3, tStartTime.year, tStartTime.month, tStartTime.day)
    end
    if tInfo.nJoinTongTime then
        local tInTongTime = TimeToDate(tInfo.nJoinTongTime)
        szJoinTongTime    = g_tStrings.STR_TIME_7 .. FormatString(g_tStrings.STR_TIME_3, tInTongTime.year, tInTongTime.month, tInTongTime.day)
    end

    -- 创建账号
    szMsg = AddMsg(szMsg, szCreateTime, nil, g_tStrings.STR_DOCUMENT_BUILD_ACCOUNT_TIME)

    -- 门派
    if tInfo.dwForceID and tInfo.dwForceID ~= 0 then
        szMsg                  = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_FORCE_1, true)
        local szGenerationName = Table_GetDesignationGeneration(tInfo.dwForceID, tInfo.nForceGeneration)
        if tInfo.dwForceID == FORCE_TYPE.SHAO_LIN then
            szGenerationName = szGenerationName .. g_tStrings.STR_WORD
        end
        szMsg = szMsg .. AddAItemMsg(Table_GetForceName(tInfo.dwForceID) .. szGenerationName, false)
        szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_FORCE_2, true)
    end

    -- 固定的一个条目
    szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_VERSION_DESC, true)

    -- 收徒
    if tInfo.nApprenticeCount and tInfo.nApprenticeCount ~= 0 then
        szMsg = szMsg .. AddAItemMsg("；\n", true)
        szMsg = AddMsg(szMsg, tInfo.nApprenticeCount, g_tStrings.STR_DOCUMENT_APPRENTICE_1, g_tStrings.STR_DOCUMENT_APPRENTICE_2)
    end

    -- 击败秘境boss数目
    if tInfo.nBossCount and tInfo.nBossCount ~= 0 then
        szMsg = szMsg .. AddAItemMsg("；\n", true)
        szMsg = AddMsg(szMsg, tInfo.nBossCount, g_tStrings.STR_DOCUMENT_KILL_1, g_tStrings.STR_DOCUMENT_KILL_2)
    end

    -- 阵营
    if tInfo.nCamp and (tInfo.nCamp == CAMP.GOOD or tInfo.nCamp == CAMP.EVIL) then
        szMsg = szMsg .. AddAItemMsg("；\n", true)
        szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_CAMP_1, true)
        if tInfo.nCamp == CAMP.GOOD then
            szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_CAMP_2, false)
        elseif tInfo.nCamp == CAMP.EVIL then
            szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_CAMP_3, false)
        end
        szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_CAMP_4, true)
        szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_CAMP_TITLE[tInfo.nCamp], false)

        if tInfo.nKilledCount and tInfo.nKilledCount ~= 0 then
            szMsg = AddMsg(szMsg, tInfo.nKilledCount, g_tStrings.STR_DOCUMENT_CAMP_5, g_tStrings.STR_DOCUMENT_CAMP_6)
        end
    end

    -- 帮会
    if tInfo.nTongID and tInfo.nTongID ~= 0 then
        szMsg            = szMsg .. AddAItemMsg("；\n", true)
        szMsg            = szMsg .. AddAItemMsg(szJoinTongTime, false)
        szMsg            = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_TONG_1, true)
        local szTongName = GetTongClient().ApplyGetTongName(tInfo.nTongID, APPLY_TONG_NAME_NUM)
        szMsg            = szMsg .. AddAItemMsg(szTongName, false)
        if tInfo.szCastleName and tInfo.szCastleName ~= 0 then
            szMsg = AddMsg(szMsg, UIHelper.GBKToUTF8(tInfo.szCastleName), g_tStrings.STR_DOCUMENT_TONG_2, nil)
        else
            szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_TONG_3, true)
        end
    end

    -- 完成的任务和奇遇
    if tInfo.nQuestCount and tInfo.nQuestCount ~= 0 then
        szMsg = szMsg .. AddAItemMsg("；\n", true)
        szMsg = AddMsg(szMsg, tInfo.nQuestCount, g_tStrings.STR_DOCUMENT_QUEST_1, g_tStrings.STR_DOCUMENT_QUEST_2)
        if tInfo.nAdventureCount and tInfo.nAdventureCount ~= 0 then
            szMsg = AddMsg(szMsg, tInfo.nAdventureCount, g_tStrings.STR_DOCUMENT_QUEST_3, g_tStrings.STR_DOCUMENT_QUEST_4)
        end
    end

    -- 社交
    local szPlayerDesignation = GetPlayerDesignation(dwPlayerID)
    if (tInfo.nReputeCount and tInfo.nReputeCount ~= 0) or (szPlayerDesignation ~= "") or (tInfo.nCloseFellowship and tInfo.nCloseFellowship ~= 0) then
        szMsg        = szMsg .. AddAItemMsg("；\n", true)
        local bComma = false
        if tInfo.nReputeCount and tInfo.nReputeCount ~= 0 then
            bComma = true
            szMsg  = AddMsg(szMsg, tInfo.nReputeCount, g_tStrings.STR_DOCUMENT_REPUTATION_1, g_tStrings.STR_DOCUMENT_REPUTATION_2)
        end
        if tInfo.nCloseFellowship and tInfo.nCloseFellowship ~= 0 then
            if bComma then
                szMsg = szMsg .. AddAItemMsg("，", true)
            end
            bComma = true
            szMsg  = AddMsg(szMsg, tInfo.nCloseFellowship, g_tStrings.STR_DOCUMENT_REPUTATION_3, g_tStrings.STR_DOCUMENT_REPUTATION_4)
        end
        if szPlayerDesignation and szPlayerDesignation ~= "" then
            if bComma then
                szMsg = szMsg .. AddAItemMsg("，", true)
            end
            szMsg = AddMsg(szMsg, szPlayerDesignation, g_tStrings.STR_DOCUMENT_REPUTATION_5, nil)
        end
    end

    -- 装备分数
    if tInfo.nEquipScore and tInfo.nEquipScore ~= 0 then
        szMsg = szMsg .. AddAItemMsg("；\n", true)
        szMsg = AddMsg(szMsg, tInfo.nEquipScore, g_tStrings.STR_DOCUMENT_EQUIPMENT_1, g_tStrings.STR_DOCUMENT_EQUIPMENT_2)
    end

    -- 挂件与宠物
    if tInfo.nPendentCount and tInfo.nPendentCount ~= 0 then
        szMsg                 = szMsg .. AddAItemMsg("；\n", true)
        szMsg                 = AddMsg(szMsg, tInfo.nPendentCount, g_tStrings.STR_DOCUMENT_PENDANT_1, g_tStrings.STR_DOCUMENT_PENDANT_2)
        tInfo.nFellowPetCount = tInfo.nFellowPetCount or 0
        szMsg                 = AddMsg(szMsg, tInfo.nFellowPetCount, nil, g_tStrings.STR_DOCUMENT_PENDANT_3)
    end

    -- 书籍
    if tInfo.nBookCount and tInfo.nBookCount ~= 0 then
        szMsg = szMsg .. AddAItemMsg("；\n", true)
        szMsg = AddMsg(szMsg, tInfo.nBookCount, g_tStrings.STR_DOCUMENT_BOOK_1, g_tStrings.STR_DOCUMENT_BOOK_2)
    end

    -- 技艺
    if tInfo.nMaxProfessionLevelCount and tInfo.nMaxProfessionLevelCount ~= 0 then
        szMsg = szMsg .. AddAItemMsg("；\n", true)
        szMsg = AddMsg(szMsg, tInfo.nMaxProfessionLevelCount, g_tStrings.STR_DOCUMENT_LIFE_SKILL_1, g_tStrings.STR_DOCUMENT_LIFE_SKILL_2)
        if tInfo.szProfessionExpertiseName and tInfo.szProfessionExpertiseName ~= 0 then
            szMsg = AddMsg(szMsg, UIHelper.GBKToUTF8(tInfo.szProfessionExpertiseName), g_tStrings.STR_DOCUMENT_LIFE_SKILL_3, g_tStrings.STR_DOCUMENT_LIFE_SKILL_4)
        end
    end

    -- 外装
    if tInfo.nExteriorCount and tInfo.nExteriorCount ~= 0 then
        szMsg = szMsg .. AddAItemMsg("；\n", true)
        szMsg = AddMsg(szMsg, tInfo.nExteriorCount, g_tStrings.STR_DOCUMENT_EXTERIOR_1, g_tStrings.STR_DOCUMENT_EXTERIOR_2)
        szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_EXTERIOR_ROLETYPE[tInfo.nRoleType], true)
    end

    -- 资历（成就点数）
    if tInfo.nAchievementPoint and tInfo.nAchievementPoint ~= 0 then
        szMsg = szMsg .. AddAItemMsg("；\n", true)
        szMsg = AddMsg(szMsg, tInfo.nAchievementPoint, g_tStrings.STR_DOCUMENT_ACHIEVEMENT_1, nil)
        szMsg = AddMsg(szMsg, UIHelper.GBKToUTF8(tInfo.szAchievementStage), g_tStrings.STR_DOCUMENT_ACHIEVEMENT_2, nil)
    end

    -- 马匹和武器
    if (tInfo.szHorseName and tInfo.szHorseName ~= 0) or (tInfo.szWeaponName and tInfo.szWeaponName ~= 0) then
        szMsg        = szMsg .. AddAItemMsg("；\n", true)
        local bComma = false
        if tInfo.szHorseName and tInfo.szHorseName ~= 0 then
            bComma = true
            szMsg  = AddMsg(szMsg, UIHelper.GBKToUTF8(tInfo.szHorseName), g_tStrings.STR_DOCUMENT_RIDE_1, nil)
        end
        if tInfo.szWeaponName and tInfo.szWeaponName ~= 0 then
            if bComma then
                szMsg = szMsg .. AddAItemMsg("，", true)
            end
            bComma = true
            szMsg  = AddMsg(szMsg, UIHelper.GBKToUTF8(tInfo.szWeaponName), g_tStrings.STR_DOCUMENT_RIDE_2, nil)
        end
        if bComma then
            szMsg = szMsg .. AddAItemMsg("，", true)
        end
        szMsg = szMsg .. AddAItemMsg(g_tStrings.STR_DOCUMENT_RIDE_3, true)
    end
    szMsg           = szMsg .. AddAItemMsg("。", true)

    -- 端游中最终拼成的报告中，会使用 \n 来分隔每一行，所以这里可以split一下，然后转换为我们需要的格式
    -- hack: 同时由于手游的颜色是通过BB码来表示的，上面每个条目为之前条目添加的 ；\n 前后也会添加颜色BB码。
    -- hack: 直接利用\n分隔时，会导致BB码的结尾部分被分割到下一部分，所以这里特殊处理下，将\n挪到bb码结尾后面
    szMsg           = string.gsub(szMsg, "\n</c>", "</c>\n")

    tReportItemList = string.split(szMsg, "\n")
    for _, szReportItem in ipairs(tReportItemList) do
        self:AddReportItem(szReportItem)
    end

    self:UpdateScrollView()
end

function UIAchievementReportView:AddReportItem(szRichTextReportItem)
    UIHelper.AddPrefab(PREFAB_ID.WidgetAchievementReportContent, self.ScrollViewReportItemList, szRichTextReportItem)
end

function UIAchievementReportView:UpdateScrollView()
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewReportItemList, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewReportItemList)
    UIHelper.ScrollToLeft(self.ScrollViewReportItemList, 0)
end

return UIAchievementReportView