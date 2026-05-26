
--[[
uft8

| bits | U+first   | U+last     | bytes | Byte_1   | Byte_2   | Byte_3   | Byte_4   | Byte_5   | Byte_6   |
+------+-----------+------------+-------+----------+----------+----------+----------+----------+----------+
|   7  | U+0000    | U+007F     |   1   | 0xxxxxxx |          |          |          |          |          |
|  11  | U+0080    | U+07FF     |   2   | 110xxxxx | 10xxxxxx |          |          |          |          |
|  16  | U+0800    | U+FFFF     |   3   | 1110xxxx | 10xxxxxx | 10xxxxxx |          |          |          |
|  21  | U+10000   | U+1FFFFF   |   4   | 11110xxx | 10xxxxxx | 10xxxxxx | 10xxxxxx |          |          |
|  26  | U+200000  | U+3FFFFFF  |   5   | 111110xx | 10xxxxxx | 10xxxxxx | 10xxxxxx | 10xxxxxx |          |
|  31  | U+4000000 | U+7FFFFFFF |   6   | 1111110x | 10xxxxxx | 10xxxxxx | 10xxxxxx | 10xxxxxx | 10xxxxxx |

10xxxxxx : (\128 - \193)
--]]

utf8 = {}
function utf8.charbytes (s, i)
   -- argument defaults
   i = i or 1
   local c = string.byte(s, i)
   
   -- determine bytes needed for character, based on RFC 3629
   if c > 0 and c <= 127 then
      -- UTF8-1
      return 1
   elseif c >= 194 and c <= 223 then
      -- UTF8-2
     -- local c2 = string.byte(s, i + 1)
      return 2
   elseif c >= 224 and c <= 239 then
      -- UTF8-3
      --local c2 = s:byte(i + 1)
      --local c3 = s:byte(i + 2)
      return 3
   elseif c >= 240 and c <= 244 then
      -- UTF8-4
      --local c2 = s:byte(i + 1)
      --local c3 = s:byte(i + 2)
      --local c4 = s:byte(i + 3)
      return 4
   end
end

function utf8.len (s)
   local _, count = string.gsub(s, "[^\128-\193]", "")
   return count
end


function utf8.sub (s, i, j)
   if i <= 0 or i > j then
      return
   end
   
   local pos = 1
   local bytes = string.len(s)
   local len = 0
   local startChar = i
   local endChar = j
   local startByte, endByte = 1, bytes
   
   while pos <= bytes do
      len = len + 1
      
      if len == startChar then
         startByte = pos
      end
      
      pos = pos + utf8.charbytes(s, pos)
      
      if len == endChar then
         endByte = pos - 1
         break
      end
   end
   
   return string.sub(s, startByte, endByte)
end

-- replace UTF-8 characters based on a mapping table
function utf8.replace (s, mapping)
   local pos = 1
   local bytes = string.len(s)
   local charbytes
   local newstr = ""

   while pos <= bytes do
      charbytes = utf8.charbytes(s, pos)
      local c = string.sub(s, pos, pos + charbytes - 1)
      newstr = newstr .. (mapping[c] or c)
      pos = pos + charbytes
   end

   return newstr
end

function utf8.char_task (str, func)
   for s in string.gfind(str, "([%z\1-\127\194-\244][\128-\191]*)") do
      func(s)
   end
end

function utf8.split(s, num)
   local total_chars    = utf8.len(s)
   local line_cnt       = math.ceil(total_chars / num)
   local byte_cnt       = s:len()
   local count          = 0
   local dst_chars      = num
   local st_index       = 1
   local res            = {}

   if total_chars <= num then
      table.insert(res, string.sub(s, 1, byte_cnt))
      return res
   end
   
   local i = 1
   while i <= byte_cnt do
      count = count + 1

      i = i + utf8.charbytes(s, i)
      
      if count == dst_chars then
         table.insert(res, string.sub(s, st_index, i - 1))

         st_index = i
         dst_chars = dst_chars + num
         if dst_chars >= total_chars then
            table.insert(res, string.sub(s, i, byte_cnt))
            break
         end
      end
   end
   return res
end

--[[
function utf8.truncate(s, n)
   local dropping = string.byte(s, n+1)

   if not dropping then
      return s
   end
   
   if dropping >= 128 and dropping < 192 then
      return truncate(s, n-1)
   end
   return string.sub(s, 1, n)
end
]]

function utf8.find(s, f)
    return string.find(s, f, nil, true)
end
