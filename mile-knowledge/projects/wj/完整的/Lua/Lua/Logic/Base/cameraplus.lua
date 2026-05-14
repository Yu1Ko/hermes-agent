
local function RenderCall(obj, tickFunc)
	if not obj then return end
	if not IsFunction(tickFunc) then return end

	if obj.nTimerCount == nil then
		obj.nTimerCount = 1
	end

	obj.nTimerCount = obj.nTimerCount + 1
	local szKey = string.format("__timerKey_%s", obj.nTimerCount)
	obj[szKey] = Timer.AddFrameCycle(obj, 1, function()
		if IsFunction(tickFunc) then
			local nRet = tickFunc(obj)
			if nRet == 0 then
				Timer.DelTimer(obj, obj[szKey])
				obj[szKey] = nil
			end
		end
	end)
end




local function vector2_len(x1, y1, x2, y2)
	return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

local function vercor3_oo_add(v1, v2)
	return {x = v1.x}
end

local function vector3_len(x1, y1, z1, x2, y2, z2)
	return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2) + (z1 - z2) * (z1 - z2))
end

local function vector3_oo_len(pos1, pos2)
	return math.sqrt((pos1.x - pos2.x) * (pos1.x - pos2.x) +
		(pos1.y - pos2.y) * (pos1.y - pos2.y) + (pos1.z - pos2.z) * (pos1.z - pos2.z))
end

local function coor_init(coor, x, y, z)
	coor.x = x
	coor.y = y
	coor.z = z
end
--[[
      |
   2  |  1
  __________ x
  	  |
   3  |   4
      y
  ]]
local function coor_regionindex(x, y)
	if x >= 0 and y >= 0 then
		return 1
	elseif x < 0 and y >= 0 then
		return 2
	elseif x < 0 and y < 0 then
		return 3
	else
		return 4
	end
end

local function calc_angle(p1, p2)
	local ver_angle, hor_angle
	local radius = vector3_len(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z)
	local xz_len = vector2_len(p1.x, p1.z, p2.x, p2.z)
	local vec = {x=p2.x - p1.x, y=p2.y-p1.y, z=p2.z-p1.z}

	if xz_len == 0 then
		hor_angle = 0
	else
		local x = math.abs(vec.x)
		x = math.min(x, xz_len)
		hor_angle = math.acos( x / xz_len)
	end

	xz_len = math.min(xz_len, radius)
	ver_angle = math.acos(xz_len / radius)
	ver_angle = math.abs(ver_angle)
	if vec.y < 0 then
		ver_angle = -ver_angle
	end

	local index = coor_regionindex(vec.x, vec.z)
	if index == 1 then
	elseif index == 2 then
		hor_angle =  math.pi - hor_angle
	elseif index == 3 then
		hor_angle =  math.pi + hor_angle
	elseif index == 4 then
		hor_angle =  2 * math.pi - hor_angle
	end
	return hor_angle, ver_angle
end

camera_plus = class("camera_plus")

function camera_plus:ctor()
	--旧版class自动调用ctor，新版需class手动调一次
	self.pos 		= {x=0, y=0, z=0}
	self.look 		= {x=0, y=0, z=0}
	self.ver_angle 	= 0
	self.hor_angle 	= 0
	self.radius 	= 0
	self.scene 		= nil
	self.player_pos = nil
end

function camera_plus:regionindex()
	return coor_regionindex(self.look.x - self.pos.x, self.look.z - self.pos.z)
end

function camera_plus:update_view()
	local pos = self.pos
	local look = self.look
	self.scene:SetCameraLookAtPosition(look.x, look.y, look.z)
	self.scene:SetCameraPosition(pos.x, pos.y, pos.z)
	self.scene:SetFocus(look.x, look.y, look.z)

	if self.player_pos then
		self.scene:SetMainPlayerPosition(self.player_pos.x, self.player_pos.y, self.player_pos.z)
	else
		--低配下的影子有点问题，和dongming、zhaoboqiang1讨论之后决定让它卡到地里面去
		self.scene:SetMainPlayerPosition(look.x, look.y - 170, look.z)
	end
end

function camera_plus:on_pos(obj)
	obj = self
	obj._interval = GetTickCount() - (obj._starttime or 0)
	if not obj._totaltime or obj._interval >= obj._totaltime then
		if obj._dst_x and obj._dst_y and obj._dst_z then
			obj.pos.x, obj.pos.y, obj.pos.z = obj._dst_x, obj._dst_y, obj._dst_z
		end

		obj._dst_x, obj._dst_y, obj._dst_z = nil, nil, nil
		obj._delta_x, obj._delta_y, obj._delta_z = nil, nil, nil
		obj._totaltime = nil
		obj._starttime = nil
		obj._interval = nil
		obj._action = nil
		obj:update_radius()
		obj:update_view()
		obj:update_angle()
		if obj._action then
			obj._action()
		end
		obj._action = nil
		return 0
	else
		local pos = obj.pos
		local per = (1 - obj._interval / obj._totaltime)
		pos.x = obj._dst_x - obj._delta_x * per
		pos.y = obj._dst_y - obj._delta_y * per
		pos.z = obj._dst_z - obj._delta_z * per

		obj:update_radius()
		obj:update_view()
		obj:update_angle()
		if obj._action then
			obj._action()
		end
	end
end

function camera_plus:setpos(x, y, z, frame_num, on_action)
	local pos = self.pos

	x = x or pos.x
	y = y or pos.y
	z = z or pos.z

	if not frame_num or frame_num < 2 then
		self.pos.x, self.pos.y, self.pos.z = x, y, z
		if self._totaltime then
			self._totaltime = nil
			self._dst_x, self._dst_y, self._dst_z = nil, nil, nil
			self._action = nil
		end
		self:update_radius()
		self:update_view()
		self:update_angle()
		if on_action then
			on_action()
		end
		return
	end

	if not self._totaltime  then
		RenderCall(self, self.on_pos)
	end

	self._dst_x, self._dst_y, self._dst_z = x, y, z
	self._delta_x =  (x - pos.x)
	self._delta_y =  (y - pos.y)
	self._delta_z =  (z - pos.z)
	self._totaltime = frame_num * 16
	self._starttime = GetTickCount()
	self._action = on_action
end

function camera_plus:getpos(bPoint)
	if bPoint then
		return self.pos
	end
	return self.pos.x, self.pos.y, self.pos.z
end


function camera_plus:on_look(obj)
	obj = self
	obj._l_interval = GetTickCount() - (obj._l_starttime or 0)
	if not obj._l_totaltime or obj._l_interval >= obj._l_totaltime then
		if obj._l_dst_x and obj._l_dst_y and obj._l_dst_z then
			obj.look.x, obj.look.y, obj.look.z = obj._l_dst_x, obj._l_dst_y, obj._l_dst_z
		end

		obj._l_dst_x, obj._l_dst_y, obj._l_dst_z = nil, nil, nil
		obj._l_delta_x, obj._l_delta_y, obj._l_delta_z = nil, nil, nil
		obj._l_totaltime = nil
		obj._l_starttime = nil
		obj._l_interval = nil
		obj:update_center_r()
		obj:update_radius()
		obj:update_view()
		obj:update_angle()
		if obj._l_action then
			obj._l_action()
		end
		obj._l_action = nil
		return 0
	else
		local look = obj.look
		local per = (1 - obj._l_interval / obj._l_totaltime)
		look.x = obj._l_dst_x - obj._l_delta_x * per
		look.y = obj._l_dst_y - obj._l_delta_y * per
		look.z = obj._l_dst_z - obj._l_delta_z * per

		obj:update_center_r()
		obj:update_radius()
		obj:update_view()
		obj:update_angle()
		if obj._l_action then
			obj._l_action()
		end
	end
end

function camera_plus:setlook(x, y, z, frame_num, on_action)
	local look = self.look

	x = x or look.x
	y = y or look.y
	z = z or look.z

	if not frame_num or frame_num < 2 then
		self.look.x, self.look.y, self.look.z = x, y, z
		if self._l_totaltime then
			self._l_totaltime = nil
			self._l_dst_x, self._l_dst_y, self._l_dst_z = nil, nil, nil
			self._l_action = nil
		end
		self:update_radius()
		self:update_view()
		self:update_angle()
		self:update_center_r()
		if on_action then
			on_action()
		end
		return
	end

	if not self._l_totaltime  then
		RenderCall(self, self.on_look)
	end

	self._l_dst_x, self._l_dst_y, self._l_dst_z = x, y, z
	self._l_delta_x =  (x - look.x)
	self._l_delta_y =  (y - look.y)
	self._l_delta_z =  (z - look.z)
	self._l_totaltime = frame_num * 16
	self._l_starttime = GetTickCount()
	self._l_action = on_action
end

function camera_plus:getlook(bPoint)
	if bPoint then
		return self.look
	end
	return self.look.x, self.look.y, self.look.z
end

-- function camera_plus:getcameraposition()
-- 	return self.scene:GetCameraPosition()
-- end

-- function camera_plus:getcameralookposition()
-- 	return self.scene:GetCameraLookAtPosition()
-- end

-- function camera_plus:updatelook(x, y, z)
-- 	self.look.x, self.look.y, self.look.z = x, y, z
-- end

-- function camera_plus:updatepos(x, y, z)
-- 	self.pos.x, self.pos.y, self.pos.z = x, y, z
-- end

function camera_plus:set_center_pos(x, y, z)
	self.center_pos = {}
	coor_init(self.center_pos, x, y, z)
end

function camera_plus:get_center_pos(bPoint)
	if bPoint then
		return self.center_pos
	end

	return self.center_pos.x, self.center_pos.y, self.center_pos.z
end

function camera_plus:on_center_r(obj)
	obj = self
	obj._c_interval = GetTickCount() - (obj._c_starttime or 0)
	if not obj._c_totaltime or obj._c_interval >= obj._c_totaltime then
		if obj._dst_center_r then
			obj.center_r = obj._dst_center_r
		end

		obj._dst_center_r = nil
		obj._delta_center_r = nil
		obj._c_totaltime = nil
		obj._c_starttime = nil
		obj._c_interval = nil

		self:set_angle(self.ver_angle, self.hor_angle)

		return 0
	else
		local per = (1 - obj._c_interval / obj._c_totaltime)
		obj.center_r = obj._dst_center_r - obj._delta_center_r * per

		self:set_angle(self.ver_angle, self.hor_angle)
	end
end

function camera_plus:set_center_r(center_r, frame_num)
	if not frame_num or frame_num < 2 then
		self.center_r = center_r
		if self._c_totaltime then
			self._c_totaltime = nil
			self._dst_center_r = nil
		end
		self:set_angle(self.ver_angle, self.hor_angle)
		return
	end

	if not self._c_totaltime  then
		RenderCall(self, self.on_center_r)
	end

	self._dst_center_r = center_r
	self._delta_center_r =  (center_r - self.center_r)
	self._c_totaltime = frame_num * 16
	self._c_starttime = GetTickCount()

	--self:set_angle(self.ver_angle, self.hor_angle)
end

function camera_plus:get_center_r()
	return self.center_r
end

function camera_plus:setperspective(fovy, aspect, z_near, z_far, perspective)
	--fAspect  = w/h
	if fovy then
		self.fovy 	= fovy
	end

	if aspect then
		self.aspect = aspect
	end

	if z_near then
		self.z_near = z_near
	end

	if z_far then
		self.z_far 	= z_far
	end

	if not fovy and not aspect and not z_near and not z_far then
		return
	end

	--if perspective then
		self.scene:SetCameraPerspective(fovy, aspect, z_near, z_far)
	--else
	--	self.scene:SetCameraOrthogonal(fovy, aspect, z_near, z_far)
	--end
end

function camera_plus:getperspective()
	return self.fovy, self.aspect, self.z_near, self.z_far
end

function camera_plus:update_angle()
	local pos = self.pos
	local look = self.look
	local xz_len = vector2_len(pos.x, pos.z, look.x, look.z)
	local vec = {x=look.x - pos.x, y=look.y-pos.y, z=look.z-pos.z}

	if xz_len == 0 then
		self.hor_angle = 0
	else
		local x = math.abs(vec.x)
		x = math.min(x, xz_len)
		self.hor_angle = math.acos( x / xz_len)
	end

	xz_len = math.min(xz_len, self.radius)
	self.ver_angle = math.acos(xz_len / self.radius)
	self.ver_angle = math.abs(self.ver_angle)
	if vec.y < 0 then
		self.ver_angle = -self.ver_angle
	end

	local index = coor_regionindex(vec.x, vec.z)
	if index == 1 then
	elseif index == 2 then
		self.hor_angle =  math.pi - self.hor_angle
	elseif index == 3 then
		self.hor_angle =  math.pi + self.hor_angle
	elseif index == 4 then
		self.hor_angle =  2 * math.pi - self.hor_angle
	end
end

function camera_plus:update_radius()
	local pos = self.pos
	local look = self.look
	self.radius = vector3_len(pos.x, pos.y, pos.z, look.x, look.y, look.z)
end

function camera_plus:update_center_r()
	local center_pos = self.center_pos
	local look = self.look
	self.center_r = vector2_len(center_pos.x, center_pos.z, look.x, look.z)
	self.center_vect = {x = center_pos.x - look.x, z = center_pos.z - look.z}
	self:normalize(self.center_vect)
end

function camera_plus:normalize(v)
	local l = math.sqrt(v.x * v.x + v.z * v.z)
	if l ~= 0 then
		v.x = v.x / l
		v.z = v.z / l
	end
end

function camera_plus:init(scene, pos_x, pos_y, pos_z, look_x, look_y, look_z, fovy, aspect, z_near, z_far, perspective, center_pos)
	-- cos(angle ) = x / radius

	self.scene = scene
	self.center_pos = {}
	self.bHaveCenter = false
	if center_pos then
		coor_init(self.center_pos, center_pos[1], center_pos[2], center_pos[3])
		self.bHaveCenter = true
	else
		coor_init(self.center_pos, look_x, look_y, look_z)
	end
	center_pos = self.center_pos

	coor_init(self.pos, pos_x, pos_y, pos_z)
	coor_init(self.look, look_x, look_y, look_z)
	--self.center_r = vector2_len(center_pos.x, center_pos.z, look_x, look_z)
	self:update_center_r()
	--self.center_angle = calc_angle(center_pos, self.look)

	self:update_radius()
	self:setperspective(fovy, aspect, z_near, z_far, perspective)

	self:update_angle()
	self:update_view()
end

function camera_plus:destroyrenderCall()
	Timer.DelAllTimer(self)
end

function camera_plus:calc_pos(ver_angle, hor_angle)
	local xz_len = math.cos(ver_angle) * self.radius
	xz_len = math.abs(xz_len)

	local y = math.sin(ver_angle) * self.radius
	local x = math.cos(hor_angle) * xz_len
	local z = math.sin(hor_angle) * xz_len


	local look = self.center_pos
	return look.x - x, look.y - y, look.z - z
end

function camera_plus:set_angle(ver_angle, hor_angle)
	ver_angle = math.max(ver_angle, -math.pi/2 + 0.05)
	ver_angle = math.min(ver_angle,  math.pi/2 - 0.05)

	local x, y, z = self:calc_pos(ver_angle, hor_angle)
	local center_pos = self.center_pos

	--local xz_len = math.cos(ver_angle) * self.center_r
	--xz_len = math.abs(xz_len)

	--local y = math.sin(ver_angle) * self.center_r
	--local center_angle = hor_angle - math.pi / 2
	--local center_angle = hor_angle - self.center_angle

	local center_angle = hor_angle - math.pi / 2
	local c_x = math.cos(center_angle) * self.center_r
	local c_z = math.sin(center_angle) * self.center_r

	if self.center_vect then
		c_x = self.center_vect.x * self.center_r
		c_z = self.center_vect.z * self.center_r
	end

	coor_init(self.look, center_pos.x - c_x, center_pos.y, center_pos.z - c_z)
	coor_init(self.pos, x - c_x, y, z - c_z)

	self:update_angle()
	self:update_view()
end

function camera_plus:rotate(ver_angle, hor_angle, min_ver_angle, max_ver_angle, min_hor_angle, max_hor_angle)
	local cur_hor_angle = self.hor_angle
	local cur_ver_angle = self.ver_angle

	cur_ver_angle = cur_ver_angle - ver_angle
	cur_hor_angle = cur_hor_angle + hor_angle

	min_ver_angle = min_ver_angle or - math.pi / 2
	max_ver_angle = max_ver_angle or math.pi / 2

	cur_ver_angle = math.max(cur_ver_angle, min_ver_angle)
	cur_ver_angle = math.min(cur_ver_angle, max_ver_angle)

	if min_hor_angle and max_hor_angle then
		if min_hor_angle < max_hor_angle then
			cur_hor_angle = math.max(cur_hor_angle, min_hor_angle)
			cur_hor_angle = math.min(cur_hor_angle, max_hor_angle)
		else
			 --hor_angle范围是0～2pi，当角度限制在A~B,而A，B正好跨过0度的临界点的时候，角度hor_angle会从0变成2pi，最大最小值的判断就需要特殊处理
			if cur_hor_angle >= max_hor_angle and cur_hor_angle < max_hor_angle + (min_hor_angle - max_hor_angle) / 4 then
				cur_hor_angle = max_hor_angle
			end
			if cur_hor_angle <= min_hor_angle and cur_hor_angle > min_hor_angle - (min_hor_angle - max_hor_angle) / 4 then
				cur_hor_angle = min_hor_angle
			end
		end
	end

	self:set_angle(cur_ver_angle, cur_hor_angle)
end

function camera_plus:move(delta_x, delta_y, delta_z)
	local pos = self.pos
	local look = self.look
	local center = self.center_pos

	pos.x = pos.x + delta_x
	pos.y = pos.y + delta_y
	pos.z = pos.z + delta_z

	look.x = look.x + delta_x
	look.y = look.y + delta_y
	look.z = look.z + delta_z

	center.x = center.x + delta_x
	center.y = center.y + delta_y
	center.z = center.z + delta_z

	self:update_view()
end

function camera_plus:move_ver(delta_y)
	self:move(0, delta_y, 0)
end

function camera_plus:move_Z(delta)
	local cur_hor_angle = self.hor_angle
	local delta_z = math.sin(cur_hor_angle) * math.abs(delta)
	local delta_x = math.cos(cur_hor_angle) * math.abs(delta)
	--local index   = self:regionindex()

	delta_z = math.abs(delta_z)
	delta_x = math.abs(delta_x)
	if delta > 0 then
		delta_z = delta_z
		delta_x = delta_x
	else
		delta_z = -delta_z
		delta_x = -delta_x
	end

	-- if index == 1 then
	-- 	delta_z = delta_z
	-- 	delta_x = -delta_x
	-- elseif index == 2 then
	-- 	delta_z = -delta_z
	-- 	delta_x = -delta_x
	-- elseif index == 3 then
	-- 	delta_z = -delta_z
	-- 	delta_x = delta_x
	-- elseif index == 4 then
	-- 	delta_z = delta_z
	-- 	delta_x = delta_x
	-- end

	self:move(delta_x, 0, delta_z)
end

function camera_plus:move_hor(delta)
	local cur_hor_angle = self.hor_angle
	local delta_z = math.cos(cur_hor_angle) * math.abs(delta)
	local delta_x = math.sin(cur_hor_angle) * math.abs(delta)
	local index   = self:regionindex()

	delta_z = math.abs(delta_z)
	delta_x = math.abs(delta_x)
	if delta > 0 then
		delta_z = -delta_z
		delta_x = -delta_x
	end

	if index == 1 then
		delta_z = delta_z
		delta_x = -delta_x
	elseif index == 2 then
		delta_z = -delta_z
		delta_x = -delta_x
	elseif index == 3 then
		delta_z = -delta_z
		delta_x = delta_x
	elseif index == 4 then
		delta_z = delta_z
		delta_x = delta_x
	end

	self:move(delta_x, 0, delta_z)
end


function camera_plus:zoom(delta, min_radius, max_radius)
	local org_radius = self.radius
	self.radius = math.max(self.radius + delta, 10)
	if min_radius then
		self.radius = math.max(self.radius, min_radius)
	end

	if max_radius then
		self.radius = math.min(self.radius, max_radius)
	end

	self.center_r =  self.radius / org_radius  * self.center_r
	self:update_camera()
end

function camera_plus:get_radius()
	return self.radius
end

function camera_plus:on_radius(obj)
	obj = self
	obj._interval = GetTickCount() - (obj._r_starttime or 0)
	if not obj._r_totaltime or obj._interval >= obj._r_totaltime then
		if obj._dst_r then
			obj.radius = obj._dst_r
		end

		obj._dst_r = nil
		obj._delta_r = nil
		obj._r_totaltime = nil
		obj._interval = nil
		obj._r_starttime = nil
		obj:update_camera()
		return 0
	else
		obj.radius = obj._dst_r - obj._delta_r * (1 - obj._interval / obj._r_totaltime)
		obj:update_camera()
	end
end

function camera_plus:set_radius(radius, frame_num)
	if not radius then
		return
	end

	if not frame_num or frame_num < 2 then
		self.radius = radius
		if self._r_totaltime then
			self._r_totaltime = nil
			self._dst_r = nil
		end

		self:update_camera()
		return
	end

	if not self._r_totaltime then
		RenderCall(self, self.on_radius)
	end

	self._dst_r = radius
	self._delta_r = (radius - self.radius)
	self._r_totaltime = frame_num * 16
	self._r_starttime = GetTickCount()
end

function camera_plus:update_camera()
	local look = self.look
	local cur_hor_angle = self.hor_angle
	local cur_ver_angle = self.ver_angle

	local x, y, z = self:calc_pos(cur_ver_angle, cur_hor_angle)
	local center_pos = self.center_pos

	local center_angle = calc_angle(center_pos, look)
	local c_x = math.cos(center_angle) * self.center_r
	local c_z = math.sin(center_angle) * self.center_r

	coor_init(self.look, center_pos.x + c_x, center_pos.y, center_pos.z + c_z)
	coor_init(self.pos, x + c_x, y, z + c_z)

	self:update_view()
end

function camera_plus:set_mainplayer_pos(x, y, z)
	if not x then
		self.player_pos = nil
		return
	end

	if not self.player_pos then
		self.player_pos = {}
	end

	coor_init(self.player_pos, x, y, z)
	self:update_view()
end

function camera_plus:dump()
	local out_pos = string.format("ca_pos(%0.1f, %0.1f, %0.1f)", self.pos.x, self.pos.y, self.pos.z)
	local out_look = string.format("ca_look(%0.1f, %0.1f, %0.1f)", self.look.x, self.look.y, self.look.z)
	local out_fovy = ""

	if self.fovy then
		out_fovy = out_fovy .. string.format("ca_fovy(%.3f)\n", self.fovy)
	end

	if self.aspect then
		out_fovy = out_fovy .. string.format("ca_aspect(%.2f)\n", self.aspect)
	end

	if self.z_near then
		out_fovy = out_fovy .. string.format("ca_z_near(%.1f)\n", self.z_near)
	end

	if self.z_far then
		out_fovy = out_fovy .. string.format("ca_z_far(%.1f)\n", self.z_far)
	end
	return out_pos.."\n"..out_look.."\n"..out_fovy
end
