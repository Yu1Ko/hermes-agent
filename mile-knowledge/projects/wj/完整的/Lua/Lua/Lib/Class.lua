local function createInstance(c, ins, ...)
	if not ins then
		ins = c
	end
	if c.super then
		createInstance(c.super, ins, ...)
	end
	return c
end
local function EmptyFunc() end

function class(super, className)
	if type(super) == "string" then
		className, super = super ,nil
	end
	if not className then
		className = "Unnamed Class"
	end
	local classPrototype = (function ()
		local proxys = {}
		if super then
			proxys.super = super
			setmetatable(proxys, {__index = super})
		end
		proxys.className = className
		return setmetatable({}, {
			__index = proxys,
			__newindex = function(t, k, v)
				if v == nil then
					rawset(t, k, v)
				elseif k == "OnEnter" then
					assert(type(v) == "function")
					proxys[k] = function(self, ...)
						if self._tbOnEnterParams then
							v(self, table.unpack(self._tbOnEnterParams))
							self._tbOnEnterParams = nil
						else
							v(self, ...)
						end

						if not self._bRegSidePageListener then
							UIMutexMgr.RegSidePageListener(self)
							self._bRegSidePageListener = true
						end
					end
				elseif k == "OnExit" then
					assert(type(v) == "function")
					proxys[k] = function(self, ...)
						if not self._donotdestroy then
							UIHelper.StopAllAni(self)
							Event.UnRegAll(self)
							Timer.DelAllTimer(self)
							Timer.DelAllWait(self)

							if self._bRegSidePageListener then
								UIMutexMgr.UnRegSidePageListener(self)
							end

							if not self._keepmt then
								if self._aniMgr then
									self._aniMgr = nil
								end

								if self._widgetMgr then
									self._widgetMgr = nil
								end

								-- 这里不要设置，因为OnExit不是真正的销毁，可以在CCComponentLua的析构里设置
								-- setmetatable(self, nil)
							end
						end

						v(self, ...)
					end
				elseif k == "OnDestroy" then
					assert(type(v) == "function")
					proxys[k] = function(self, ...)
						v(self, ...)
						setmetatable(self, nil)
					end
				else
					rawset(t, k, v)
				end
			end,
			__tostring = function() return className .. " (class prototype)" end,
		})
	end)()

	classPrototype.CreateDataBase = function ()
		return setmetatable({}, {
			__index = classPrototype,
			__tostring = function() return className .. " (class base instance)" end,
		})
	end

	classPrototype.CreateInstance = function (baseClass, ...)
		return createInstance(setmetatable({}, {
			__index = baseClass,
			__tostring = function() return className .. " (class instance)" end,
		}), nil, ...)
	end

	classPrototype.OnEnter = classPrototype.OnEnter or EmptyFunc
	classPrototype.OnExit = classPrototype.OnExit or EmptyFunc
	classPrototype.OnDestroy = classPrototype.OnDestroy or EmptyFunc

	return classPrototype
end

function NewModule(szModuleName)
	local tb = {}
	setmetatable(tb, {
		__index = function (t, k)
			return _G[k]
		end
	})
	_G[szModuleName] = _G[szModuleName] or tb
	setfenv(2, _G[szModuleName])
end