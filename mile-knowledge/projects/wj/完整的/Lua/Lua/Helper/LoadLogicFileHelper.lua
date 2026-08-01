-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: LoadLogicFileHelper
-- Date: 2024-06-19 16:07:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

LoadLogicFileHelper = LoadLogicFileHelper or {className = "LoadLogicFileHelper"}
local self = LoadLogicFileHelper
-------------------------------- 消息定义 --------------------------------
LoadLogicFileHelper.Event = {}
LoadLogicFileHelper.Event.XXX = "LoadLogicFileHelper.Msg.XXX"

local _tbMeta	= {};
local tbNodeMark	= {[";"]=1, ["#"]=1};			-- 注释标记表
local tbInvalidChar	= {[" "]=1, ["\t"]=1,["\n"]=1};	-- 开始位置和结束位置的无效字符表

-- 根据文件名，从文件中载入ini数据，并返回数据对象，失败返回nil
-- 返回数据格式：{tbData = {}, __index = _tbMeta};
function LoadLogicFileHelper.LoadFile(szFileName)
	if not szFileName then
		return;
	end
	local tbRet = {};
	local tbData = self._LoadDetail(szFileName);
	if not tbData then
		return;
	end
	tbRet.tbData = tbData;
	setmetatable(tbRet, {__index = _tbMeta});
	return tbRet;
end

-- 载入数据细节
function LoadLogicFileHelper._LoadDetail(szFileName)
    local nStartLoadTime = Timer.RealMStimeSinceStartup()
	local text = Lib.GetStringFromFile(szFileName)
    LOG.INFO("HY, load time = %s", tostring(Timer.RealMStimeSinceStartup() - nStartLoadTime))
	if not text then
		OutputMessage("MSG_ANNOUNCE_NORMAL", "<open file : [" .. UIHelper.GBKToUTF8(szFileName) .. "] failed>")
		return
	end
    
    local nSplitTime = Timer.RealMStimeSinceStartup()
	local strList = string.split(text, "\r\n")
    LOG.INFO("HY, Split Time = %s",  tostring(Timer.RealMStimeSinceStartup() - nSplitTime))

	local tbRet = {}
	local tbSection = {}
	local bEfficientSection = false

    local nCollectTime = Timer.RealMStimeSinceStartup()
	for _, line in ipairs(strList) do
		line = self._ClearInvalid(line)
		if line and "" ~= line and 1 ~= self._IsNodes(line) then
			if 1 == self._IsSection(line) then		-- 是一个有效的节
				local szSection = self._GetSectionName(line)
				if tbRet[szSection] then
					print("[WAR]出现同名的节[".. szSection .. "]，将被覆盖!")
				end
				tbRet[szSection] = {}
				tbSection = tbRet[szSection]
				bEfficientSection = true
			elseif 2 == self._IsSection(line) then
				bEfficientSection = false
			elseif bEfficientSection and 1 == self._IsKeyValue(line) then	-- 是一对key，value
				local szKey, szValue = self._GetKeyValue(line)
				if tbSection[szKey] then
					print("[WAR]出现同名的key[" .. szKey .. "]，将被覆盖!")
				end
				tbSection[szKey] = szValue
			-- else
			-- 	print("[WAR]不可识别的内容[" .. line .. "]")
			end
		end
	end
    LOG.INFO("HY, Collect Time = %s", tostring(Timer.RealMStimeSinceStartup() - nCollectTime))
	return tbRet;
end

-- 清除开始和最后的无效字符
function LoadLogicFileHelper._ClearInvalid(line)
	line = line or ""
	local nBegin = 1
	local nEnd = #line
	for i = nBegin, nEnd do
		if not tbInvalidChar[string.sub(line, i, i)] then
			nBegin = i
			break
		end
	end
	for i = nEnd, nBegin, -1 do
		if not tbInvalidChar[string.sub(line, i, i)] then
			nEnd = i
			break
		end
	end
	return string.sub(line, nBegin, nEnd)
end
-- 是否是注释
function LoadLogicFileHelper._IsNodes(line)
	line = line or "";
	return tbNodeMark[string.sub(line, 1, 1)] or 0;
end
-- 是否是一个节名
function LoadLogicFileHelper._IsSection(line)
	line = line or "";
	if "[" == string.sub(line, 1, 1) and "]" == string.sub(line, #line) then
		if #line >= 4 and string.sub(line, 2, 4) == "NPC" then
			return 1
		elseif #line >= 5 and string.sub(line, 2, 5) == "MAIN" then
			return 1
		else
			return 2--无效的节
		end
	end
	return 0;
end
-- 是否是对于的key，value
function LoadLogicFileHelper._IsKeyValue(line)
	line = line or "";
	local b, e = string.find(line, "=");
	if not b or not e or b == 1 then
		return 0;
	end
	return 1;
end
-- 获取节名
function LoadLogicFileHelper._GetSectionName(line)
	line = line or "";
	return string.sub(line, 2, #line - 1);
end
-- 获取对应的key，value
function LoadLogicFileHelper._GetKeyValue(line)
	local b, e = string.find(line, "=");
	local szKey = "";
	local szValue = "";
	if b and e then
		szKey = string.sub(line, 1, b - 1);
		szValue = string.sub(line, e + 1)
	end
	return szKey, szValue;
end
-- 获取一个节的数据
function _tbMeta.GetSection(self, szSection)
	if not self or not szSection then
		print("[ERROR]参数错误", self, szSection)
	end
	return self.tbData[szSection];
end
-- 根据节名和key值获取相应的值
function _tbMeta.GetValue(self, szSection, szKey)
	if not self or not szSection or not szKey then
		print("[ERROR]参数错误", self, szSection, szKey)
	end
	local tbSection = self.tbData[szSection];
	if tbSection then
		return tbSection[szKey];
	end
end

-- 获取节的迭代器
function _tbMeta.GetItor(self)
	local tbData = self.tbData;
	local tbIndex = {};
	local nPos = 1;
	if not tbData then
		return;
	end
	for szSection in pairs(tbData) do
		table.insert(tbIndex, szSection);
	end
	return function ()
			local szSection = tbIndex[nPos]
			nPos = nPos + 1;
			if not szSection then
				return;
			end
			return szSection, tbData[szSection];
		end
end
-- 打印自身
function _tbMeta.Print(self)
	if not self or not self.tbData then
		print("[WAR]没有数据")
		return;
	end
	for szSection, tbSection in pairs(self.tbData) do
		print(szSection, " = {")
		for szKey, szValue in pairs(tbSection) do
			print("", szKey, " = ", szValue);
		end
		print("}");
	end
end
-- 保存到文件中
function _tbMeta.Save(self, szFileName)
	if not self or not self.tbData then
		print("[WAR]没有数据")
		return;
	end
	szFileName = szFileName or "";
	local file = io.open(szFileName, "w");
	if not file then
		print("<open file : [" .. szFileName .. "] failed>");
		return;
	end

	for szSection, tbSection in pairs(self.tbData) do
		file:write("[" .. szSection .. "]\n");
		for szKey, szValue in pairs(tbSection) do
			file:write(szKey .. "=" .. szValue .. "\n");
		end
		file:write("\n");
	end
	file:close();
end
