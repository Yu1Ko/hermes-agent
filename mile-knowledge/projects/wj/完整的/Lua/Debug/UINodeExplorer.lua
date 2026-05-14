
-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UINodeExplorer
-- Date: 2022-11-08
-- Desc: 节点浏览器
-- ---------------------------------------------------------------------------------
local UINodeExplorer = class("UINodeExplorer")

s_UINodeExplorer_tNodes = nil -- t[szNodeId] = node : szNodeId = tostring(node)
s_UINodeExplorer_tExpandStatus = s_UINodeExplorer_tExpandStatus or {} -- t[szNodeId] = nStatus : 0为待移除, 1为展开
s_UINodeExplorer_szSelectedNodeId = s_UINodeExplorer_szSelectedNodeId or nil

function UINodeExplorer:OnEnter()
	self.m = {}
	self.m.tCells = {}

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:Init()

	Timer.AddFrameCycle(self, 1, function ()
		self:DrawNode()
	end)
end

function UINodeExplorer:OnExit()
	self.bInit = false

	self:UnRegEvent()
	self:_UnInitScrollList()

	s_UINodeExplorer_tNodes = nil

	self.m = nil
end

function UINodeExplorer:BindUIEvent()
	-- KeyBoard.BindKeyUp(cc.KeyCode.KEY_F9, "刷新节点列表", function()
	-- 	self:UpdateList()
	-- end)
	KeyBoard.BindKeyUp(cc.KeyCode.KEY_LEFT_ARROW, "折叠节点", function()
		if not self.m or self.m.bShift then return end
		self:NavigateCell("left")
	end)
	KeyBoard.BindKeyUp(cc.KeyCode.KEY_UP_ARROW, "移到上一节点", function()
		if not self.m or self.m.bShift then return end
		if self.m.bAlt then
			self:SwitchSelectNodeInCollection("up")
		else
			self:NavigateCell("up")
		end
	end)
	KeyBoard.BindKeyUp(cc.KeyCode.KEY_RIGHT_ARROW, "展开节点", function()
		if not self.m or self.m.bShift then return end
		self:NavigateCell("right")
	end)
	KeyBoard.BindKeyUp(cc.KeyCode.KEY_DOWN_ARROW, "移到下一节点", function()
		if not self.m or self.m.bShift then return end
		if self.m.bAlt then
			self:SwitchSelectNodeInCollection("down")
		else
			self:NavigateCell("down")
		end
	end)
	KeyBoard.BindKeyUp(cc.KeyCode.KEY_SPACE, "展开/折叠子树", function()
		if not self.m then return end
		self:SwitchExpandStatus(nil, true)
	end)
	KeyBoard.BindKeyUp(cc.KeyCode.KEY_TAB, "显示/隐藏节点", function()
		if not self.m then return end
		if self.m.bCtrl then
			self:SwitchVisibleStatus(nil)
		end
	end)
	KeyBoard.BindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F}, "通过名称查找节点", function()
		if not self.m then return end
		if self.m.bCtrl then
			self:ShowDialogToFindNodeByName()
		end
	end)
	KeyBoard.BindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_C}, "复制节点路径", function()
		if not self.m then return end
		self:CopySelectedNodePath()
	end)
	KeyBoard.BindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_UP_ARROW}, "节点上移一像素", function()
		if not self.m then return end
		self:MoveSelectedNode(0, 1)
	end)
	KeyBoard.BindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_DOWN_ARROW}, "节点下移一像素", function()
		if not self.m then return end
		self:MoveSelectedNode(0, -1)
	end)
	KeyBoard.BindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_LEFT_ARROW}, "节点左移一像素", function()
		if not self.m then return end
		self:MoveSelectedNode(-1, 0)
	end)
	KeyBoard.BindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_RIGHT_ARROW}, "节点右移一像素", function()
		if not self.m then return end
		self:MoveSelectedNode(1, 0)
	end)

	KeyBoard.BindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_TAB}, "移动当前节点", function()
		if not self.m then return end
		UIHelper.ShowModifyNamePanel("请输入移动距离", "0,0", function (szText)
			if szText then
				local szX, szY = string.match(szText, "(%-?%d+),(%-?%d+)")
				local nX, nY = tonumber(szX) or 0, tonumber(szY) or 0
				self:MoveSelectedNode(nX, nY)
			end
		end)
	end)
    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
		if not self.m then return end
		if nKeyCode == cc.KeyCode.KEY_CTRL then self.m.bCtrl = true end
		if nKeyCode == cc.KeyCode.KEY_SHIFT then self.m.bShift = true end
		if nKeyCode == cc.KeyCode.KEY_ALT then
			self.m.bAlt = true
			self:OnAltDown()
		end
    end)
    Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szKeyName)
		if not self.m then return end
		if nKeyCode == cc.KeyCode.KEY_CTRL then self.m.bCtrl = false end
		if nKeyCode == cc.KeyCode.KEY_SHIFT then self.m.bShift = false end
		if nKeyCode == cc.KeyCode.KEY_ALT then
			self:OnAltUp()
			self.m.bAlt = false
		end
    end)

	UIHelper.BindUIEvent(self.TouchSelect, EventType.OnTouchBegan, function(node, x, y)
		if not self.m then return end
		self:OnTouchSelect(x, y)
	end)

end

function UINodeExplorer:RegEvent()
	Event.Reg(self, "LocateNodeByName", function (szName)
		self:CollectNodeByName(szName)
		self:SwitchSelectNodeInCollection("")
	end)
end
function UINodeExplorer:UnRegEvent()
	Event.UnRegAll(self)
	-- KeyBoard.UnBindKeyUp(cc.KeyCode.KEY_F9)
	KeyBoard.UnBindKeyUp(cc.KeyCode.KEY_LEFT_ARROW)
	KeyBoard.UnBindKeyUp(cc.KeyCode.KEY_UP_ARROW)
	KeyBoard.UnBindKeyUp(cc.KeyCode.KEY_RIGHT_ARROW)
	KeyBoard.UnBindKeyUp(cc.KeyCode.KEY_DOWN_ARROW)
	KeyBoard.UnBindKeyUp(cc.KeyCode.KEY_SPACE)
	KeyBoard.UnBindKeyUp(cc.KeyCode.KEY_TAB)
	KeyBoard.UnBindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_F})
	KeyBoard.UnBindKeyDown({cc.KeyCode.KEY_CTRL, cc.KeyCode.KEY_C})
	KeyBoard.UnBindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_UP_ARROW})
	KeyBoard.UnBindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_DOWN_ARROW})
	KeyBoard.UnBindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_LEFT_ARROW})
	KeyBoard.UnBindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_RIGHT_ARROW})
	KeyBoard.UnBindKeyDown({cc.KeyCode.KEY_SHIFT, cc.KeyCode.KEY_TAB})
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local Def = {
	szSpaceChar = "   ",
	nCellHeight = 30,
	nFontSize = 24,
	tNormalColor = cc.c3b(255, 255, 255),
	tSelectedColor = cc.c3b(0, 255, 0),
	tNullColor = cc.c3b(255, 0, 0),
	tDrawNormalColor = cc.c4f(0, 1, 0, 1),
	tDrawHideColor = cc.c4f(0, 0, 1, 1),
}

local _nDepth = 0
local _Traversal
_Traversal = function (node, fnVisit, bForce)
	assert(node)
	assert(fnVisit)
	local bBreak = false

	if node:getName() == "PanelNodeExplorer" then return false end

	-- return true to break
	bBreak = fnVisit(node)
	if bBreak then return true end

	if not bForce then
		if not s_UINodeExplorer_tExpandStatus[tostring(node)] then return false end
	end

	if node:getChildrenCount() > 0 then
		_nDepth = _nDepth + 1
		for _, child in ipairs(node:getChildren()) do
			bBreak = _Traversal(child, fnVisit, bForce)
			if bBreak then break end
		end
		assert(_nDepth > 0)
		_nDepth = _nDepth - 1
	end

	return bBreak
end


local _IsValidNode = function (szNodeId, bForce)
	if not szNodeId then return false end

	local scene = cc.Director:getInstance():getRunningScene()
	local bValid = false
	local bBreak = false
	local targetNode
	_nDepth = 0
	for _, child in ipairs(scene:getChildren()) do
		bBreak = _Traversal(child, function (node)
			if tostring(node) == szNodeId then
				bValid = true
				targetNode = node
				return true
			end
		end, bForce)
		if bBreak then break end
	end
	return bValid, targetNode
end

local _CanSee = function (node)
	assert(node)
	while node do
		if not node:isVisible() then
			return false
		end
		node = node:getParent()
	end
	return true
end

UINodeExplorer_GetSelectedNode = function()
	if s_UINodeExplorer_tNodes and _IsValidNode(s_UINodeExplorer_szSelectedNodeId) then
		local tNode = s_UINodeExplorer_tNodes[s_UINodeExplorer_szSelectedNodeId]
		if tNode then
			return tNode.node
		end
	end
end

function UINodeExplorer:Init()
	local node

	-- 初始绘图节点
	node = cc.DrawNode:create()
	self.m.drawNode = node
	self._rootNode:addChild(node, -1)

	-- 信息显示
	self.Label:setString("")
	self.Label:enableShadow()

	-- list
	self:_InitScrollList()
	self:UpdateList()

	-- touch select
	UIHelper.SetContentSize(self.TouchSelect, UIHelper.GetContentSize(self._rootNode))
	UIHelper.SetPosition(self.TouchSelect, 0, 0)
	UIHelper.SetTouchDownHideTips(self.TouchSelect, false)
	self:EnableTouchSelect(false)
end

function UINodeExplorer:_InitScrollList()
	local list = self.ScrollList
	assert(list)
	self:_UnInitScrollList()
	local tScrollList = UIScrollList.Create({
		listNode = self.ScrollList,
		fnGetCellType = function() return "cell" end,
		fnUpdateCell = function(cell, nIndex)
			self:_UpdateCell(cell, nIndex)
		end,
		fnCreateCell = function(szCellType)
			return self:_CreateCell(szCellType)
		end,
	})
	assert(tScrollList)
	self.m.tScrollList = tScrollList
	self.m.tListSize = list:getContentSize()
end
function UINodeExplorer:_UnInitScrollList()
	if self.m.tScrollList then
		self.m.tScrollList:Destroy()
		self.m.tScrollList = nil
	end
end

function UINodeExplorer:_CreateCell(szCellType)
	local cell = ccui.Button:create()
	cell:ignoreContentAdaptWithSize(false)
	cell:setContentSize(self.m.tListSize.width, Def.nCellHeight)
	cell:setAnchorPoint(0, 0)
	cell:setCascadeOpacityEnabled(true)

	local label = cc.Label:create()
	label:enableShadow()
	label:setSystemFontSize(Def.nFontSize)
	label:setContentSize(self.m.tListSize.width, Def.nCellHeight)
	label:setAnchorPoint(0,0)
	label:setPosition(0, 0)
	label:setCascadeOpacityEnabled(true)
	label:setLineHeight(Def.nFontSize)
	cell:addChild(label)
	cell.label = label

	cell.OnEnter = function(nIndex)
		self.m.tCells[tostring(cell)] = cell
	end
	cell.OnExit = function(nIndex)
		self.m.tCells[tostring(cell)] = nil
	end

	-- 事件绑定
	UIHelper.BindUIEvent(cell, EventType.OnClick, function(cell)
		self:OnClickCell(cell)
	end)
	return cell
end

function UINodeExplorer:_UpdateCell(cell, nIndex)
	assert(cell)
	assert(nIndex)
	local szNodeId = self.m.tNodeIdArr[nIndex]
	local tNode = s_UINodeExplorer_tNodes[szNodeId]

	local node = tNode.node
	local bExpand = s_UINodeExplorer_tExpandStatus[szNodeId] ~= nil

	cell.szNodeId = szNodeId
	cell:setVisible(true)
	UIHelper.SetEnable(cell, not self.m.bTouchSelectEnabled)

	-- label
	local label = cell.label
	assert(label)
	local szText
	local bValid = _IsValidNode(szNodeId)
	if bValid then
		local szName = node:getName()
		local szFlag = node:getChildrenCount() > 0 and (bExpand and "v" or ">") or "- "
		szText = string.format("%s%s %s", string.rep(Def.szSpaceChar, tNode.nDepth), szFlag, szName)
	else
		szText = string.format("%s%s", string.rep(Def.szSpaceChar, tNode.nDepth), "X")
	end
	label:setString(szText)
	local tColor = bValid
		and (s_UINodeExplorer_szSelectedNodeId == szNodeId and Def.tSelectedColor or Def.tNormalColor)
		or Def.tNullColor
	label:setTextColor(tColor)

end

function UINodeExplorer:UpdateList()
	-- 维护展开状态
	local tExpandStatus = s_UINodeExplorer_tExpandStatus
	for k, _ in pairs(tExpandStatus) do
		tExpandStatus[k] = 0
	end

	-- 遍历节点
	local tNodes = {} s_UINodeExplorer_tNodes = tNodes
	local tNodeIdArr = {} self.m.tNodeIdArr = tNodeIdArr
	local scene = cc.Director:getInstance():getRunningScene()
	local bBreak = false
	_nDepth = 0
	for _, child in ipairs(scene:getChildren()) do
		bBreak = _Traversal(child, function (node)
			local szNodeId = tostring(node)
			table.insert(tNodeIdArr, szNodeId)
			-- 收集数据
			tNodes[szNodeId] = {
				node = node,
				nDepth = _nDepth,
			}
			-- 维护展开状态
			local bExpand = false
			if tExpandStatus[szNodeId] then
				tExpandStatus[szNodeId] = 1
				bExpand = true
			end
		end)
		if bBreak then break end
	end

	-- 维护展开状态
	local tRemoveStatus = {}
	for k, v in pairs(tExpandStatus) do
		if v == 0 then
			table.insert(tRemoveStatus, k)
		end
	end
	for k, v in pairs(tRemoveStatus) do tExpandStatus[v] = nil end


	local nStartIndex = self.m.nReloadStartIndex or 1
	self.m.tScrollList:ReloadWithStartIndex(#tNodeIdArr, nStartIndex)

	self:UpdateInfo()
end

function UINodeExplorer:OnClickCell(cell)
	local szNodeId = cell.szNodeId

	-- 按住ctrl会切换展开状态
	if self.m.bCtrl then
		self:SetExpandStatus(szNodeId, not s_UINodeExplorer_tExpandStatus[szNodeId])
	else
		self:SelectNode(szNodeId)
	end

end

function UINodeExplorer:Test()
	local root = self._rootNode

	if not root:getChildByName("Cell") then
		local cell = ccui.Button:create()
		root:addChild(cell)
		cell:setName("Cell")
		cell:ignoreContentAdaptWithSize(false)
		UIHelper.SetContentSize(cell, 600, 900)
		UIHelper.SetAnchorPoint(cell, 0.5, 0.5)
		UIHelper.SetPosition(cell, 0, 0)

		UIHelper.BindUIEvent(cell, EventType.OnClick, function(cell, x, y)
			print("----> on click")
		end)
		UIHelper.BindUIEvent(cell, EventType.OnTouchBegan, function(cell, x, y)
			print("----> on OnTouchBegan")
		end)
	end
end

function UINodeExplorer:SetExpandStatus(szNodeId, bExpand)
	szNodeId = szNodeId or s_UINodeExplorer_szSelectedNodeId
	if not szNodeId then return end
	if (s_UINodeExplorer_tExpandStatus[szNodeId] ~= nil) == (bExpand == true) then return end

	s_UINodeExplorer_tExpandStatus[szNodeId] = nil
	if bExpand then
		local tNode = s_UINodeExplorer_tNodes[szNodeId]
		if tNode then
			local node = tNode.node
			if node and _IsValidNode(szNodeId) and node:getChildrenCount() > 0 then
				s_UINodeExplorer_tExpandStatus[szNodeId] = 1
			end
		end
	end

	self.m.nReloadStartIndex = self:GetIndexByNodeId(szNodeId)
	self:UpdateList()
end

function UINodeExplorer:NodeId2CellId(szNodeId)
	for szCellId, cell in pairs(self.m.tCells) do
		if cell.szNodeId == szNodeId then
			return szCellId
		end
	end
end


function UINodeExplorer:SelectNode(szNodeId)

	if Platform.IsMobile() then
		local bExpand = s_UINodeExplorer_tExpandStatus[szNodeId]
		self:SetExpandStatus(szNodeId, not bExpand)
	end

	local szLastId = s_UINodeExplorer_szSelectedNodeId
	if szLastId == szNodeId then return end

	-- 处理旧选中节点
	if szLastId then
		s_UINodeExplorer_szSelectedNodeId = nil
		local nIndex = self:GetIndexByNodeId(szLastId) if nIndex then
			self.m.tScrollList:UpdateCell(nIndex)
		end
	end

	-- 处理新选中节点
	if szNodeId then
		s_UINodeExplorer_szSelectedNodeId = szNodeId
		local nIndex = self:GetIndexByNodeId(szNodeId) if nIndex then
			self.m.tScrollList:UpdateCell(nIndex)
			self.m.tScrollList:ScrollToIndex(nIndex)
			self:UpdateInfo(szNodeId)
		end
	end
end

function UINodeExplorer:DrawNode(szNodeId, tColor)
	local draw = self.m and self.m.drawNode
	if not draw then return end
	draw:clear()

	szNodeId = szNodeId or s_UINodeExplorer_szSelectedNodeId
	if not szNodeId then return end
	local tNode = s_UINodeExplorer_tNodes[szNodeId]
	if not tNode then return end
	local node = tNode.node
	assert(node)
	if not _IsValidNode(szNodeId) then return end

	if not tColor then
		tColor = _CanSee(node) and Def.tDrawNormalColor or Def.tDrawHideColor
	end

	-- 连接线
	local szCellId = self:NodeId2CellId(szNodeId)
	if szCellId then
		local cell = self.m.tCells[szCellId]
		local label = cell.label
		assert(label)
		local nSrcX, nSrcY = 0, 0
		local tSrcSize = label:getContentSize()
		nSrcX = nSrcX + tSrcSize.width + 10
		nSrcY = nSrcY + tSrcSize.height * 0.5 -- cell锚点在左下角

		local tSrcWorldPos = label:convertToWorldSpaceAR(cc.p(nSrcX, nSrcY))
		local tSrcDrawPos = draw:convertToNodeSpaceAR(tSrcWorldPos)
		local tDstWorldPos = node:convertToWorldSpaceAR(cc.p(0, 0))
		local tDstDrawPos = draw:convertToNodeSpaceAR(tDstWorldPos)

		draw:drawLine(tSrcDrawPos, tDstDrawPos, tColor)
	end

	-- 节点rect
	local tAnchor = node:getAnchorPoint()
	local tNodeSize = node:getContentSize()
	local tLB = cc.p(tNodeSize.width * (0 - tAnchor.x), tNodeSize.height * (0 - tAnchor.y))
	local tRT = cc.p(tNodeSize.width * (1 - tAnchor.x), tNodeSize.height * (1 - tAnchor.y))
	local tDrawLB = draw:convertToNodeSpaceAR(node:convertToWorldSpaceAR(tLB))
	local tDrawRT = draw:convertToNodeSpaceAR(node:convertToWorldSpaceAR(tRT))
	draw:drawRect(tDrawLB, tDrawRT, tColor)

end

function UINodeExplorer:UpdateInfo(szNodeId, bSafe)
	local bShowNodeCount = false
	-- update bottom info
	UIHelper.SetVisible(self.BtnOpenScript, false)
	UIHelper.SetVisible(self.BtnCloseUI, false)
	local label = self.Label
	assert(label)
	local szInfo = ""
	local szSelectedInfo = ""
	szNodeId = szNodeId or s_UINodeExplorer_szSelectedNodeId
	if szNodeId then
		local tNode = s_UINodeExplorer_tNodes[szNodeId]
		if tNode then
			local node = tNode.node
			if node and (bSafe or _IsValidNode(szNodeId)) then
				local szName = node:getName()
				local x, y = UIHelper.GetPosition(node)
				local tAnchor = node:getAnchorPoint()
				local tSize = node:getContentSize()
				local bVisible = node:isVisible()
				local nOpacity = node:getOpacity()
				local nRotation = node:getRotation()
				local nLocalZOrder = node:getLocalZOrder()
				local scaleX, scaleY = node:getScaleX(), node:getScaleY()
				local nFontSize = node.getFontSize and node:getFontSize() or (node.getTTFConfig and node:getTTFConfig().fontSize or 0)
				local tInfoArr = {
					string.format("name=%s", szName),
					string.format("pos=(%.2f, %.2f)", x, y),
					string.format("anchor=(%.2f, %.2f)", tAnchor.x, tAnchor.y),
					string.format("size=(%.2f, %.2f)", tSize.width, tSize.height),
					string.format("scale=(%.2f, %.2f)", scaleX, scaleY),
					string.format("visible=%s",tostring(bVisible)),
					string.format("opacity=%s",tostring(nOpacity)),
					string.format("rotation=%s",tostring(nRotation)),
					string.format("Z=%s",tostring(nLocalZOrder)),
					string.format("FontSize=%s",tostring(nFontSize))
				}

				local szImgPath = UIHelper.GetTextureResourceName(node)
				if szImgPath then
					table.insert(tInfoArr, string.format("ImgPath=%s", UIHelper.GBKToUTF8(szImgPath)))
				end

				szInfo = table.concat(tInfoArr, "  ")

				-- LuaBind信息
				local compLuaBind = node:getComponent("LuaBind")
				local scriptView = compLuaBind and compLuaBind:getScriptObject()
				if scriptView then
					local nViewID = scriptView._nViewID
					local nPrefabID = scriptView._nPrefabID
					local szScriptPath = scriptView._scriptPath
					local szPrefaName = ""
					if nViewID then
						szPrefaName = "ViewName: " .. TabHelper.GetUIViewTab(nViewID).szViewName
					elseif nPrefabID then
						szPrefaName = "PrefabName: " .. TabHelper.GetUIPrefabTab(nPrefabID).szPrefabName
					end
					szInfo = szInfo .. "\r\n" .. "ScriptPath: " .. szScriptPath .. ", " .. szPrefaName

					-- 按钮
					UIHelper.SetVisible(self.BtnOpenScript, true)
					UIHelper.BindUIEvent(self.BtnOpenScript, EventType.OnClick, function()
						if string.is_nil(szScriptPath) then
							return
						end

						local szPrefix = io.popen("cd"):read()
						local szPath = szPrefix.."/"..cc.FileUtils:getInstance():fullPathForFilename(szScriptPath)
						os.execute(string.format("start \"\" \"vscode://file/%s\"", szPath))
					end)

					UIHelper.SetVisible(self.BtnCloseUI, true)
					UIHelper.BindUIEvent(self.BtnCloseUI, EventType.OnClick, function()
						UIMgr.Close(nViewID)
					end)
				end

				if bShowNodeCount then
					local nCount, nProtCount = UIHelper.GetNodeCount(node)
					szSelectedInfo = string.format("<outline=#0B3E18&1><color=#2ED259>(%d, %d)</c></u>", nCount, nProtCount)
				end
			end
		end
	end

	label:setString(szInfo)

	-- update top info
	if bShowNodeCount then
		local nCount, nProtCount = UIHelper.GetNodeCount(cc.Director:getInstance():getRunningScene())
		UIHelper.SetRichText(self.RichLabelTop, string.format("<outline=#0B3E18&1><color=#FFFFFF>(%d, %d) %s</c></u>", nCount, nProtCount, szSelectedInfo))
	else
		UIHelper.SetRichText(self.RichLabelTop, string.format("<outline=#0B3E18&1><color=#FFFFFF>%s</c></u>", "NodeExplorer"))
	end
end

function UINodeExplorer:NavigateCell(szDir)
	local szNodeId = s_UINodeExplorer_szSelectedNodeId
	local tNodeIdArr = self.m.tNodeIdArr

	-- 取默认
	if not szNodeId then
		szNodeId = tNodeIdArr[1]
	end
	if not szNodeId then return end

	-- 节点已失效
	local nIndex = self:GetIndexByNodeId(szNodeId)
	if not nIndex then
		szNodeId = tNodeIdArr[1]
		nIndex = 1
	end
	if not szNodeId then return end
	-- 找到有效节点
	local bUpdate = false
	while not _IsValidNode(szNodeId) do
		bUpdate = true
		if nIndex > 1 then
			nIndex = nIndex - 1
			szNodeId = tNodeIdArr[nIndex]
		else
			s_UINodeExplorer_szSelectedNodeId = nil
			return
		end
	end
	s_UINodeExplorer_szSelectedNodeId = szNodeId
	if bUpdate then
		self.m.nReloadStartIndex = nil
		self:UpdateList()
		return
	end


	if szDir == "up" then
		nIndex = nIndex - 1
		if nIndex >= 1 then
			szNodeId = tNodeIdArr[nIndex] if szNodeId then
				self:SelectNode(szNodeId)
			end
		end

	elseif szDir == "down" then
		nIndex = nIndex + 1
		if nIndex <= #tNodeIdArr then
			szNodeId = tNodeIdArr[nIndex] if szNodeId then
				self:SelectNode(szNodeId)
			end
		end

	elseif szDir == "left" then
		self:SetExpandStatus(szNodeId, false)
	elseif szDir == "right" then
		self:SetExpandStatus(szNodeId, true)
	end
end

function UINodeExplorer:SwitchExpandStatus(szNodeId, bSubTree)
	szNodeId = szNodeId or s_UINodeExplorer_szSelectedNodeId
	if not szNodeId then return end
	local bExpand = not s_UINodeExplorer_tExpandStatus[szNodeId]

	if bSubTree then
		local tNode = s_UINodeExplorer_tNodes[szNodeId]
		if tNode then
			local node = tNode.node
			if not node or not _IsValidNode(szNodeId) then return end

			_nDepth = 0
			_Traversal(node, function (node)
				if node:getChildrenCount() > 0 then
					s_UINodeExplorer_tExpandStatus[tostring(node)] = bExpand and 1 or nil
				end
			end, true)

			self:UpdateList()
		end
	else
		self:SetExpandStatus(szNodeId, bExpand)
	end

end

function UINodeExplorer:RefreshSelectedNode()
	local szNodeId = s_UINodeExplorer_szSelectedNodeId
	if szNodeId then
		s_UINodeExplorer_szSelectedNodeId = nil
		self:SelectNode(szNodeId)
	end
end

function UINodeExplorer:SwitchVisibleStatus(szNodeId)
	szNodeId = szNodeId or s_UINodeExplorer_szSelectedNodeId
	if not szNodeId then return end
	local tNode = s_UINodeExplorer_tNodes[szNodeId]
	if tNode then
		local node = tNode.node
		if node and _IsValidNode(szNodeId) then
			node:setVisible(not node:isVisible())
			self:UpdateInfo(szNodeId, true)
		end
	end

end

function UINodeExplorer:GetIndexByNodeId(szNodeId)
	for i, v in ipairs(self.m.tNodeIdArr) do
		if v == szNodeId then
			return i
		end
	end
end

function UINodeExplorer:ExpandParentChain(node, bClean)
	if bClean then
		s_UINodeExplorer_tExpandStatus = {}
	end
	node = node and node:getParent()
	while node do
		s_UINodeExplorer_tExpandStatus[tostring(node)] = 1
		node = node:getParent()
	end
end

function UINodeExplorer:LocateNode(node)
	self:ExpandParentChain(node, true)
	self.m.nReloadStartIndex = nil
	self:UpdateList()
	self:SelectNode(tostring(node))
end

function UINodeExplorer:OnAltDown()
	self:EnableTouchSelect(true)
end
function UINodeExplorer:OnAltUp()
	self:EnableTouchSelect(false)
end

function UINodeExplorer:EnableTouchSelect(bEnable)
	if self.m.bTouchSelectEnabled == bEnable then
		return
	end
	self.m.bTouchSelectEnabled = bEnable

	self.TouchSelect:setTouchEnabled(bEnable)

	UIHelper.SetSwallowTouches(self.TouchSelect, bEnable)
	for szCellId, cell in pairs(self.m.tCells or {}) do
		UIHelper.SetEnable(cell, not bEnable)
	end

	UIHelper.SetSwallowTouches(self.ScrollList, not bEnable)
	UIHelper.SetEnable(self.BtnBg, not bEnable)
end

function UINodeExplorer:OnTouchSelect(x, y)
	-- 收集
	self:CollectNodeByPoint(x, y)
	-- 在结果中切换
	self:SwitchSelectNodeInCollection("")
end

function UINodeExplorer:CollectNodeByName(szName)
	-- 遍历收集
	local tNodeIdArr = {}
	local scene = cc.Director:getInstance():getRunningScene()
	_nDepth = 0
	for _, child in ipairs(scene:getChildren()) do
		_Traversal(child, function (node)
			if string.find(string.lower(node:getName()), string.lower(szName)) then
				table.insert(tNodeIdArr, tostring(node))
			end
		end, true)
	end
	self.m.tCollectNodeIdArr = tNodeIdArr

	self.m.nSwithSelectNodeIndex = nil
end

function UINodeExplorer:CollectNodeByPoint(x, y)
	-- 世界坐标
	local tPosInWorld = cc.p(x, y)

	-- 遍历收集
	local tNodeIdArr = {}
	local scene = cc.Director:getInstance():getRunningScene()
	_nDepth = 0
	for _, child in ipairs(scene:getChildren()) do
		_Traversal(child, function (node)
			-- 不要看不见的
			if not _CanSee(node) then return end
			-- 不要非交互的(文本图片除外)
			if not node.setString
			and not node.setFontSize
			and not node.setSpriteFrame
			and (not node.isTouchEnabled or not node:isTouchEnabled())
			then return end
			-- 不要layer层
			if string.find(node:getName(), "UI.+Layer") then return end
			-- 点击范围
			local size = node:getContentSize()
			local tPosInNode = node:convertToNodeSpace(tPosInWorld)
			if tPosInNode.x > 0 and tPosInNode.y > 0 and tPosInNode.x < size.width and tPosInNode.y < size.height then
				table.insert(tNodeIdArr, tostring(node))
			end
		end, true)
	end
	self.m.tCollectNodeIdArr = tNodeIdArr

	self.m.nSwithSelectNodeIndex = nil
end

function UINodeExplorer:SwitchSelectNodeInCollection(szDir)
	local tNodeIdArr = self.m.tCollectNodeIdArr
	-- 无集合
	if not tNodeIdArr or #tNodeIdArr == 0 then
		self.m.nSwithSelectNodeIndex = nil
		return
	end

	local nIndex = self.m.nSwithSelectNodeIndex
	if not nIndex then
		nIndex = #tNodeIdArr
	elseif "up" == szDir then
		if nIndex > 1 then
			nIndex = nIndex - 1
		end
	elseif "down" == szDir then
		if nIndex < #tNodeIdArr then
			nIndex = nIndex + 1
		end
	end
	self.m.nSwithSelectNodeIndex = nIndex
	local szNodeId = tNodeIdArr[nIndex]

	local bValid, node = _IsValidNode(szNodeId, true)
	if not bValid then
		-- 若节点失效, 跳过
		table.remove(tNodeIdArr, nIndex)
		self:SwitchSelectNodeInCollection(szDir == "up" and szDir or "")
	else
		-- 定位
		self:LocateNode(node)
	end
end

function UINodeExplorer:ShowDialogToFindNodeByName()
	UIHelper.ShowModifyNamePanel("请输入要查找节点的名称", "", function (szText)
		if szText then
			Event.Dispatch("LocateNodeByName", szText)
		end
	end)
end

function UINodeExplorer:CopySelectedNodePath()
	local szNodeId = s_UINodeExplorer_szSelectedNodeId
	if not szNodeId then return end

	local szNodePath = ""
	local tNode = s_UINodeExplorer_tNodes[szNodeId]
	if tNode then
		local node = tNode.node
		while node and node:getParent() do
			if not szNodePath or #szNodePath <= 0 then
				szNodePath = node:getName()
			else
				szNodePath = node:getName() .. "/" .. szNodePath
			end
			node = node:getParent()
		end
	end
	SetClipboard(szNodePath)
	print("Copy node path success: " .. szNodePath)
end

function UINodeExplorer:MoveSelectedNode(x, y)
	local szNodeId = s_UINodeExplorer_szSelectedNodeId
	if not szNodeId then return end

	local szNodePath = ""
	local tNode = s_UINodeExplorer_tNodes[szNodeId]
	if tNode then
		local node = tNode.node
		local curX, curY = UIHelper.GetPosition(node)
		UIHelper.SetPosition(node, curX + x, curY +  y)
	end
end

return UINodeExplorer