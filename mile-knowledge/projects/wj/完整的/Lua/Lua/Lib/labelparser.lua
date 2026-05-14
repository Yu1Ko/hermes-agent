--[[
	示例：
	local labelparser = require("labelparser")
	local text1 = "hello worldd   <div>hello world</div> 你好 <div fontName='nihao' fontSize=#123456>hello,world</div><div></div>"
	local parsedtable = labelparser.parse(text1)
	-- output:
	<parsedtable> = {
		{
			content = "hello worldd   ",
			labelname = "div",
		},
		{
			content = "hello world",
			labelname = "div",
		},
		{
			content = " 你好 ",
			labelname = "div",
		},
		{
			content = "hello,world",
			fontname = "nihao",
			fontsize = "#123456",
			labelname = "div",
		},
	}
]]--

local print = print
local table = table
local string = string

local _M = {}

local LABEL_DIV_BEGIN = "<div>"
local LABEL_DIV_END = "</div>"
local BOOLEAN_TRUE = "true"
local BOOLEAN_FALSE = "false"

function _M.parse(text, bDontClear)
	-- 用于存储解析结果
	local parsedtable = {}
	local treenode = {}

	-- 检测开头和结尾是否为标签 <xxx>即为标签
	if not string.find(text, "^%b<>.+%b<>$") then
		-- 在最外层包装一个标签，便于解析时的统一处理，不用处理没有包装标签的情况
		text = table.concat({LABEL_DIV_BEGIN, text, LABEL_DIV_END})
	end
	-- 标签头栈，用于存储标签头(<div>是标签头，</div>是标签尾)
	-- 标签头存储了格式信息，碰到标签时可以直接使用当前栈顶的标签头格式信息，应用到标签之间的内容上
	local labelheadstack = {}
	-- 迭代所有格式为<xxx>的标签(包含了标签头和标签尾巴)
	local index = 0
	for beginindex, endindex in function() return string.find(text, "%b<>", index) end do
		local label = string.sub(text, beginindex, endindex)
		--排除<!--注释-->、<!doctype html>、<meta=...>
		if not (string.find(label, "^<!") or string.find(label, "^<meta")) then
			-- 检测字符串是否以"</"开头
			if string.find(label, "^</") then
				-- 标签尾
				treenode = _M.disposeLabelTail(labelheadstack, parsedtable, treenode, text, label, beginindex, endindex)
			elseif string.find(label, "/>$") then -- 检测以'/>'结尾
				-- 自闭合标签
				treenode = _M.disposeLabelSelfClosing(labelheadstack, parsedtable, treenode, text, label, beginindex, endindex)
			else-- 检测到标签头
				treenode = _M.disposeLabelHead(labelheadstack, parsedtable, treenode, text, label, beginindex, endindex)
			end
		end

		index = endindex + 1
	end

	--清理没有content的contenttable
	if not bDontClear then
		for i = #parsedtable, 1, -1 do
			local content = parsedtable[i].content
			if content == nil then
				table.remove(parsedtable, i)
			end
		end
	end

	return parsedtable
end

-- 处理标签头
function _M.disposeLabelHead(labelheadstack, parsedtable, treenode, text, labelhead, beginindex, endindex)
	if not treenode.children then
		treenode.children = {}
	end

	local childnode = {}

	-- 获得标签名称
	local labelname = _M.parseLabelname(labelhead)

	-- 解析标签属性
	childnode.labelname = labelname
	childnode.parent = treenode
	childnode.labelparams = _M.parseLabelHead(labelhead)

	-- 取出当前栈顶位置的标签信息
	local labelinfo = _M.peekstack(labelheadstack)
	if labelinfo then
		-- 获得当前标签头和上一个标签头之间内容(标签嵌套造成)
		local content = string.sub(text, labelinfo.endindex+1, beginindex-1)
		-- 解析两个标签头之间的内容
		if content ~= nil and content ~= "" then
			_M.insertContentTable(parsedtable, treenode, content)
		end
	end

	-- 将当前标签头和位置信息，放入栈顶位置
	_M.pushstack(labelheadstack, {["labelhead"]=labelhead, ["beginindex"]=beginindex, ["endindex"]=endindex})

	-- 将内容表插入到总表中
	local contenttable = _M.insertContentTable(parsedtable, childnode)
	childnode.contenttable = contenttable

	table.insert(treenode.children, childnode)

	return childnode
end

-- 处理标签尾
function _M.disposeLabelTail(labelheadstack, parsedtable, treenode, text, labeltail, beginindex, endindex)
	-- 检测到标签尾，可以解析当前标签范围内的串，标签头在栈顶位置
	-- 将与标签尾对应的标签头出栈(栈顶)
	local labelinfo = _M.popstack(labelheadstack)
	-- 解析栈顶标签头和当前标签尾之间的内容
	if labelinfo then
		-- 检测标签是否匹配
		if not _M.checkLabelMatch(labelinfo.labelhead, labeltail) then
			return print(string.format("labelparser # error: label can not match(%s, %s)",
										labelinfo.labelhead, labeltail))
		end
		-- 获得当前标签尾和对应标签头之间内容
		local content = string.sub(text, labelinfo.endindex+1, beginindex-1)
		if content ~= nil and content ~= "" then
			if treenode.contenttable then
				local contenttable = clone(treenode.contenttable)
				contenttable.content = content
				table.insert(parsedtable, contenttable)
			end
		end
		-- 因为此前内容都解析过了，所以修改栈顶标签头信息，让其修饰范围改变为正确的
		-- 修改当前栈顶标签头位置到当前标签尾的范围
		local labelinfo_unused = _M.peekstack(labelheadstack)
		if labelinfo_unused then
			labelinfo_unused.beginindex = beginindex
			labelinfo_unused.endindex = endindex
		end
		return treenode.parent
	end
	return treenode
end

-- 处理自闭合标签
function _M.disposeLabelSelfClosing(labelheadstack, parsedtable, treenode, text, label, beginindex, endindex)
	treenode = _M.disposeLabelHead(labelheadstack, parsedtable, treenode, text, label, beginindex, endindex)
	treenode = _M.disposeLabelTail(labelheadstack, parsedtable, treenode, text, label, beginindex, endindex)
	return treenode
end

-- 检测标签头和标签尾是否配对，即标签名是否相同
function _M.checkLabelMatch(labelhead, labeltail)
	local labelheadname = _M.parseLabelname(labelhead)
	local labeltailname = _M.parseLabelname(labeltail)
	return labeltailname == labelheadname
end

-- 从标签头或者标签尾解析出标签名称
function _M.parseLabelname(label)
	-- 解析标签名
	local labelnameindex1, labelnameindex2 = string.find(label, "%w+")
	if not labelnameindex1 then
		return print ("labelparser # error: label name not found") and nil
	end
	-- 获得标签名称
	local labelname = string.sub(label, labelnameindex1, labelnameindex2)
	local labelname = string.lower(labelname)
	return labelname
end

-- 解析标签头属性
function _M.parseLabelHead(labelhead)
	local labelparams = {}

	local function match(property)
		local equalmarkpos = string.find(property, "=")
		-- 分离属性名和属性值
		local propertyname = string.sub(property, 1, equalmarkpos-1)
		local propertyvalue = string.sub(property, equalmarkpos+1, string.len(property))
		-- 属性名转为小写
		propertyname = string.lower(propertyname)
		-- 属性值处理
		local continue = false
		-- 1.检测是否为字符串(单引号或者双引号括起来)
		local beginindex, endindex = string.find(propertyvalue, "['\"].+['\"]")
		if beginindex then
			propertyvalue = string.sub(propertyvalue, beginindex+1, endindex-1)
			continue = true
		end
		-- 2.检测是否为布尔值
		if not continue then
			local propertyvalue_lower = string.lower(propertyvalue)
			if propertyvalue_lower == BOOLEAN_TRUE then
				propertyvalue = true
				continue = true
			elseif propertyvalue_lower == BOOLEAN_FALSE then
				propertyvalue = false
				continue = true
			end
		end
		-- 3.检测是否为数字
		if not continue then
			local propertyvalue_number = tonumber(propertyvalue)
			if propertyvalue_number then
				propertyvalue = propertyvalue_number
				continue = true
			end
		end
		-- 若以上都不是，则默认直接为字符串
		labelparams[propertyname] = propertyvalue
	end

	-- 匹配格式：property=value
	-- value要求无"且非空白字符并且不含有‘>’
	for property in string.gmatch(labelhead, "[%w%_]+%=[^%s%>\"]+") do
		match(property)
	end
	-- value要求有"且可有空白字符并且不含有‘>’
	for property in string.gmatch(labelhead, "[%w%_]+%=\"[^%>]+") do
		match(property)
	end
	return labelparams
end

function _M.insertContentTable(parsedtable, treenode, content)
	local contenttable = {}
	local labelnames = {}
	contenttable.content = content
	contenttable.labelname = ""
	--将所有父级节点的labelparam和labelname加上
	while treenode do
		for propertyname, propertyvalue in pairs(treenode.labelparams) do
			if contenttable[propertyname] then
				contenttable[propertyname] = contenttable[propertyname] .. propertyvalue
			else
				contenttable[propertyname] = propertyvalue
			end
		end
		if treenode.labelname and not table.contain_value(labelnames, treenode.labelname) then
			table.insert(labelnames, 1, treenode.labelname)
		end
		treenode = treenode.parent
	end
	for _, labelname in pairs(labelnames) do
		contenttable.labelname = contenttable.labelname .. "<" .. labelname .. ">"
	end
	table.insert(parsedtable, contenttable)
	return contenttable
end

--
-- utils-stack
--

function _M.peekstack(stacktable)
	return stacktable[#stacktable]
end

function _M.pushstack(stacktable, elem)
	table.insert(stacktable, elem)
end

function _M.popstack(stacktable)
	local elem = stacktable[#stacktable]
	stacktable[#stacktable] = nil
	return elem
end

labelparser = _M