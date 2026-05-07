local Parser = {}
Parser.__index = Parser

function Parser.new(str)
    local self = setmetatable({}, Parser)
    self.str = str:gsub("^%s+", ""):gsub("%s+$", "")
    self.pos = 1
    self.len = #self.str
    return self
end

-- 词法分析
function Parser:tokenize()
    local tokens = {}

    while self.pos <= self.len do
        local char = self.str:sub(self.pos, self.pos)

		-- 方括号键处理
        if char == '[' then
            local start = self.pos
            self.pos = self.pos + 1
            local keyType = "number"
            local content = ""

            -- 提取方括号内的键值
            while self.pos <= self.len do
                local c = self.str:sub(self.pos, self.pos)
                if c == ']' then break end
                if c:match('["\']') then  -- 处理带引号的字符串键
                    keyType = "string"
                    self.pos = self.pos + 1
                    while self.pos <= self.len do
                        local sc = self.str:sub(self.pos, self.pos)
                        if sc == c then break end
                        if sc == '\\' then self.pos = self.pos + 1 end
                        content = content .. sc
                        self.pos = self.pos + 1
                    end
                    self.pos = self.pos + 1  -- 跳过闭合引号
                else
                    content = content .. c
                    self.pos = self.pos + 1
                end
            end

            -- 生成键值token
            table.insert(tokens, {
                type = "bracket_key",
                value = keyType == "number" and tonumber(content) or content
            })
            self.pos = self.pos + 1  -- 跳过闭合方括号
        -- 处理字符串
        elseif char == '"' or char == "'" then
            local start = self.pos
            self.pos = self.pos + 1
            while self.pos <= self.len do
                local c = self.str:sub(self.pos, self.pos)
                if c == char then break end
                if c == '\\' then self.pos = self.pos + 1 end  -- 跳过转义字符
                self.pos = self.pos + 1
            end
            table.insert(tokens, {
                type = "string",
                value = self.str:sub(start+1, self.pos-1)
            })
            self.pos = self.pos + 1

        -- 处理数字（含负数和小数）
        elseif char:match("%d") or (char == '-' and self.str:sub(self.pos+1, self.pos+1):match("%d")) then
            local start = self.pos
            self.pos = self.pos + 1
            while self.pos <= self.len do
                local c = self.str:sub(self.pos, self.pos)
                if not (c:match("%d") or c == '.' or c == '-') then break end
                self.pos = self.pos + 1
            end
            local num = self.str:sub(start, self.pos-1)
            table.insert(tokens, {
                type = "number",
                value = tonumber(num)
            })

        -- 处理布尔值
        elseif self.str:sub(self.pos, self.pos+3) == "true" then
            table.insert(tokens, {type = "boolean", value = true})
            self.pos = self.pos + 4
        elseif self.str:sub(self.pos, self.pos+4) == "false" then
            table.insert(tokens, {type = "boolean", value = false})
            self.pos = self.pos + 5

        -- 处理表结构
        elseif char == '{' then
            table.insert(tokens, {type = "table_start"})
            self.pos = self.pos + 1
        elseif char == '}' then
            table.insert(tokens, {type = "table_end"})
            self.pos = self.pos + 1

        -- 处理键值分隔符
        elseif char == '=' then
            table.insert(tokens, {type = "assign"})
            self.pos = self.pos + 1
        elseif char == ',' then
            table.insert(tokens, {type = "comma"})
            self.pos = self.pos + 1

        -- 处理标识符
        elseif char:match("[%a_]") then
            local start = self.pos
            while self.pos <= self.len do
                local c = self.str:sub(self.pos, self.pos)
                if not c:match("[%w_]") then break end
                self.pos = self.pos + 1
            end
            table.insert(tokens, {
                type = "identifier",
                value = self.str:sub(start, self.pos-1)
            })

        else
            self.pos = self.pos + 1  -- 跳过空格等无关字符
        end
    end
    return tokens
end

-- 语法解析器
function Parser:parse(tokens)
    local stack = {}
    local current = {}
    local key = nil
    local inBracketKey = false  -- 新增方括号键状态标识

    for _, token in ipairs(tokens) do
		-- 处理方括号键
        if token.type == "bracket_key" then
            key = token.value  -- 直接获取键值
            current.key = key  -- 设置当前键
            --key = nil
        elseif token.type == "table_start" then
            table.insert(stack, current)
            current = {}
        elseif token.type == "table_end" then
            local parent = stack[#stack]
            if parent.key then
                parent[parent.key] = current
                parent.key = nil
            else
                table.insert(parent, current)
            end
            current = table.remove(stack)
        elseif token.type == "identifier" then
            if not key then
                key = token.value
            else
                table.insert(current, token.value)
            end
        elseif token.type == "assign" then
            current.key = key
            key = nil
        elseif token.type == "number" or token.type == "string" or token.type == "boolean" then
            if current.key then
                current[current.key] = token.value
                current.key = nil
            else
                table.insert(current, token.value)
            end
        end
    end

    return current[1] or current
end


function parse_string_to_lua_table(str)
    local parser = Parser.new(str)
    local tokens = parser:tokenize()
    return parser:parse(tokens)
end
