-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CustomTipsSizeData
-- Date: 2024-06-19 14:35:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

CustomTipsSizeData = CustomTipsSizeData or {className = "CustomTipsSizeData"}
local self = CustomTipsSizeData
-------------------------------- 消息定义 --------------------------------
CustomTipsSizeData.Event = {}
CustomTipsSizeData.Event.XXX = "CustomTipsSizeData.Msg.XXX"

function CustomTipsSizeData.Init()
	self.RegEvent()
end

function CustomTipsSizeData.UnInit()
	Event.UnRegAll(self)
end


function CustomTipsSizeData.RegEvent()
	Event.Reg(self, EventType.OnPrefabAdd, function(nPrefabID, scriptView)	--修改整个预制的大小
		local conf = TabHelper.GetUIPrefabTab(nPrefabID)
		if not conf then
			return
		end
		local tbScaleInfo = TabHelper.GetTipsScaleTab(conf.szPrefabName, false)
		if (Platform.IsWindows() or Platform.IsMac()) and not table.is_empty(tbScaleInfo) then
			UIHelper.SetScale(scriptView._rootNode, tbScaleInfo.nScale, tbScaleInfo.nScale)
		end
    end)

	Event.Reg(self, EventType.OnViewOpen, function(nViewID)	--修改panel内某个节点的大小
		local conf = TabHelper.GetUIViewTab(nViewID)
		if not conf then
			return
		end
		local tbScaleInfo = TabHelper.GetTipsScaleTab(conf.szViewName, true)
		if (Platform.IsWindows() or Platform.IsMac()) and not table.is_empty(tbScaleInfo) then
			local scriptView = UIMgr.GetViewScript(nViewID)
			local node = UIHelper.GetChildByPath(scriptView._rootNode, tbScaleInfo.szPrefabName)
			UIHelper.SetScale(node, tbScaleInfo.nScale, tbScaleInfo.nScale)
		end
    end)
end