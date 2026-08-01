-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: TeachBoxData
-- Date: 2023-11-20 20:31:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

TeachBoxData = TeachBoxData or {className = "TeachBoxData"}
local self = TeachBoxData

self.tbKungFuQuest = {	--门派入门任务ID（万灵后续新门派无需维护，这个判角色老稻香村任务有没有完成的，判断玩家是否是老玩家，VK上的时候用来做教学的，现在段氏默认为全部都是新手，所以不用加了
	[FORCE_TYPE.SHAO_LIN] = 12198,	-- 少林
    [FORCE_TYPE.WAN_HUA] = 12151,	-- 万花
    [FORCE_TYPE.TIAN_CE] = 12160,	-- 天策
    [FORCE_TYPE.CHUN_YANG] = 12161,	-- 纯阳
    [FORCE_TYPE.QI_XIU] = 12162,	-- 七秀
    [FORCE_TYPE.WU_DU] = 12163,	-- 五毒
    [FORCE_TYPE.TANG_MEN] = 12164,	-- 唐门
    [FORCE_TYPE.CANG_JIAN] = 12165,	-- 藏剑
    [FORCE_TYPE.GAI_BANG] = 12166,	-- 丐帮
    [FORCE_TYPE.MING_JIAO] = 12167,	-- 明教
    [FORCE_TYPE.CANG_YUN] = 12338,	-- 苍云
    [FORCE_TYPE.CHANG_GE] = 14417,	-- 长歌
    [FORCE_TYPE.BA_DAO] = 15977,	-- 霸刀
    [FORCE_TYPE.PENG_LAI] = 18948,	-- 蓬莱
    [FORCE_TYPE.LING_XUE] = 20517,	-- 凌雪
    [FORCE_TYPE.YAN_TIAN] = 21922,	-- 衍天
    [FORCE_TYPE.YAO_ZONG] = 23718,	-- 药宗
    [FORCE_TYPE.DAO_ZONG] = 25058,	-- 刀宗
    [FORCE_TYPE.WAN_LING] = 26288,	--万灵
}

self.nLevel = 110 	--nil表示不检测等级

self.tbDescList = {}	--当前教程描述列表，与图片对应
self.tbImgList = {}		--当前教程图片列表，与描述对应

self.tbDescIDList = {}


function TeachBoxData.Init()
	TeachBoxData.RegEvent()

	self.GetTeachBoxList()
end

function TeachBoxData.UnInit()

end

function TeachBoxData.RegEvent()
	Event.Reg(TeachBoxData, "LOADING_END", function ()
		local player = GetClientPlayer()
		local nForceID = player.dwForceID
		local bQuestFinished = QuestData.IsFinished(self.tbKungFuQuest[nForceID])	--门派指定任务是否已完成
		if Storage.TeachBox.bIsOldPlayer == nil then
			if self.nLevel then
				Storage.TeachBox.bIsOldPlayer = bQuestFinished or player.nLevel > self.nLevel
			else
				Storage.TeachBox.bIsOldPlayer = bQuestFinished
			end
			Storage.TeachBox.Flush()
		end
	end)
end

function TeachBoxData.UpdateTeachInfo(nIndex)	--获取单条教程图片与描述信息
	local tbConfig = TabHelper.GetUITeachBoxTab(nIndex)
	if not tbConfig then
		return
	end
	local nFirst = 1
	self.tbDescList = {}
	self.tbImgList = {}
	self.UpdateSingleTeachInfo(tbConfig, nFirst)
end

function TeachBoxData.UpdateSingleTeachInfo(tbConfig , nIndex)
	if tbConfig["szDesc"..nIndex] and tbConfig["szImage"..nIndex] then
		if tbConfig["szDesc"..nIndex] ~= "" and tbConfig["szImage"..nIndex] ~= "" then --图片与描述一一对应
			table.insert(self.tbDescList, tbConfig["szDesc"..nIndex])
			table.insert(self.tbImgList, tbConfig["szImage"..nIndex])
		elseif tbConfig["szDesc"..nIndex] == "" and tbConfig["szImage"..nIndex] ~= "" then --一段描述对应多张图片
			table.insert(self.tbDescList, tbConfig["szDesc1"])
			table.insert(self.tbImgList, tbConfig["szImage"..nIndex])
		end
		TeachBoxData.UpdateSingleTeachInfo(tbConfig , nIndex+1)
	end
end

function TeachBoxData.DeletePlayerMark()
	Storage.TeachBox.bIsOldPlayer = nil
	Storage.TeachBox.Flush()
	LOG.INFO("清除新老玩家判断标记")
end

function TeachBoxData.GetPlayerMark()
	if Storage.TeachBox.bIsOldPlayer == nil then
		LOG.INFO("玩家未被标记")
	else
		local szDesc = Storage.TeachBox.bIsOldPlayer and "老玩家" or "新玩家"
		LOG.INFO("当前玩家为:%s", szDesc)
	end
end

function TeachBoxData.SetPlayerMark(bOldPlayer)
	Storage.TeachBox.bIsOldPlayer = bOldPlayer
	Storage.TeachBox.Flush()
	local szDesc = Storage.TeachBox.bIsOldPlayer and "老玩家" or "新玩家"
	LOG.INFO("当前玩家为已标记为:%s", szDesc)
end

function TeachBoxData.OpenTutorialPanel(...)
	UIMgr.Open(VIEW_ID.PanelTutorialLite, ...)
end

function TeachBoxData.OpenTutorialCollectionPanel(nTab)
	-- 游戏教学合集
	UIMgr.Open(VIEW_ID.PanelTutorialCollection, nil, nil, nTab)
end

function TeachBoxData.OpenTeachBoxPanelWithSearch(szName)
	UIMgr.Open(VIEW_ID.PanelTutorialCollection, nil, nil, TutorialPageIndex.TEACH_BOX)

	if string.is_nil(szName) then
		return
	end

	Timer.AddFrame(self, 1, function ()
		Event.Dispatch(EventType.OnSearchTeachBox, szName)
	end)
end

function TeachBoxData.GetAllTeachCells()
	local tbAllTeachData = {}
	for k, v in pairs(UITeachBoxTab) do
		local nID = v["nID"]
        local szName = v["szName"]
        local szGroup = v["szGroup"]
        local szGroupDesc = v["szGroupDesc"]
		local tbNameList = string.split(szGroupDesc, ",")
        local nSortID, nSubSortID, nContentSortID = string.match(szGroup, "(%d+),(%d+),(%d+)")
        nSortID, nSubSortID, nContentSortID = tonumber(nSortID), tonumber(nSubSortID), tonumber(nContentSortID)
		v.nSortID = nSortID
		v.nSubSortID = nSubSortID
		v.nContentSortID = nContentSortID
		table.insert(tbAllTeachData, v)
	end

	table.sort(tbAllTeachData, function (a, b)
		if a.nSortID ~= b.nSortID then
			return a.nSortID < b.nSortID
		elseif a.nSubSortID ~= b.nSubSortID then
			return a.nSubSortID < b.nSubSortID
		elseif a.nContentSortID ~= b.nContentSortID then
			return a.nContentSortID < b.nContentSortID
		end
	end)

	return tbAllTeachData
end

function TeachBoxData.GetTeachBoxList()
    self.tbTeachBoxList = {}
	local tbAllTeachCell = self:GetAllTeachCells()
    for _, v in pairs(UITeachBoxTab) do
        local nID = v["nID"]
        local szName = v["szName"]
        local szGroup = v["szGroup"]
        local szGroupDesc = v["szGroupDesc"]
		local tbNameList = string.split(szGroupDesc, ",")
        local nSortID, nSubSortID, nContentSortID = string.match(szGroup, "(%d+),(%d+),(%d+)")
        nSortID, nSubSortID, nContentSortID = tonumber(nSortID), tonumber(nSubSortID), tonumber(nContentSortID)

        if not self.tbTeachBoxList[nSortID] then
            self.tbTeachBoxList[nSortID] = {
                nSortID = nSortID,
                szName = "",
                tbSub = {}
            }
        end

        local sortItem = self.tbTeachBoxList[nSortID]

        if sortItem.szName == "" then
            sortItem.szName = tbNameList[1]
        end

        if not sortItem.tbSub[nSubSortID] then
            sortItem.tbSub[nSubSortID] = {
                nSubSortID = nSubSortID,
                szSubName = "",
                tbContent = {}
            }
        end

        local subSortItem = sortItem.tbSub[nSubSortID]

        if subSortItem.szSubName == "" then
            subSortItem.szSubName = tbNameList[2]
        end

        table.insert(subSortItem.tbContent, { nContentSortID = nContentSortID, szName = szName, tbData = v, nID = nID })
    end

    for k,v in pairs(self.tbTeachBoxList) do
		if v.tbSub then
			table.sort(v.tbSub, function(a, b) return a.nSubSortID < b.nSubSortID end)
			for k2,v2 in pairs(v.tbSub) do
				table.sort(v2.tbContent, function(a, b) return a.nContentSortID < b.nContentSortID end)
			end
		end
    end
	table.insert(self.tbTeachBoxList, 1, {
		nSortID = 0,
		szName = "全部",
		tbSub = nil,
		tbContent = tbAllTeachCell
	})
end