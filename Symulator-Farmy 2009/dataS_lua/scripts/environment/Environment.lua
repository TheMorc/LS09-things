Environment = {}
local Environment_mt = Class(Environment)
function Environment:onCreateSunLight(id)
  g_currentMission.environment.sunLightId = id
end
function Environment:onCreateUnderwaterFog(id)
  g_currentMission.environment.underwaterFog = id
end
function Environment:onCreateWater(id)
  g_currentMission.environment.water = id
  local env = g_currentMission.environment
  setShaderParameter(id, "distanceFogInfo", env.waterFogColorR, env.waterFogColorG, env.waterFogColorB, 5.0E-4)
  local profileId = Utils.getProfileClassId()
  if profileId <= 2 then
    setReflectionMapObjectMask(id, 16711680, true)
  end
end
function Environment:new(skyI3DFilename, dayNightCycle, startHour, allowRain, autoRain)
  local instance = {}
  setmetatable(instance, Environment_mt)
  instance.skyRootId = loadI3DFile(skyI3DFilename)
  link(getRootNode(), instance.skyRootId)
  instance.skyId = getChildAt(instance.skyRootId, 0)
  instance.sunLightId = nil
  instance.frameCount = 0
  instance.dayTime = 0
  if startHour ~= nil then
    instance.dayTime = startHour * 60 * 60 * 1000
  end
  instance.waterFogColorR = 0.9294117647058824
  instance.waterFogColorG = 0.9686274509803922
  instance.waterFogColorB = 1
  instance.dayNightCycle = dayNightCycle
  instance.timeScale = 60
  instance.currentDay = 1
  if dayNightCycle then
    instance.ambientCurve = AnimCurve:new(linearInterpolator3)
    instance.ambientCurve:addKeyframe({
      x = 0.2,
      y = 0.2,
      z = 0.3,
      time = 0
    })
    instance.ambientCurve:addKeyframe({
      x = 0.2,
      y = 0.2,
      z = 0.3,
      time = 300
    })
    instance.ambientCurve:addKeyframe({
      x = 0.125,
      y = 0.125,
      z = 0.175,
      time = 360
    })
    instance.ambientCurve:addKeyframe({
      x = 0.225,
      y = 0.225,
      z = 0.225,
      time = 540
    })
    instance.ambientCurve:addKeyframe({
      x = 0.225,
      y = 0.225,
      z = 0.225,
      time = 960
    })
    instance.ambientCurve:addKeyframe({
      x = 0.2,
      y = 0.2,
      z = 0.23,
      time = 1080
    })
    instance.ambientCurve:addKeyframe({
      x = 0.185,
      y = 0.185,
      z = 0.25,
      time = 1260
    })
    instance.ambientCurve:addKeyframe({
      x = 0.2,
      y = 0.2,
      z = 0.3,
      time = 1440
    })
    instance.diffuseCurve = AnimCurve:new(linearInterpolator3)
    instance.diffuseCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 0.05,
      time = 0
    })
    instance.diffuseCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 0.05,
      time = 300
    })
    instance.diffuseCurve:addKeyframe({
      x = 0.2,
      y = 0.15,
      z = 0.05,
      time = 360
    })
    instance.diffuseCurve:addKeyframe({
      x = 0.6,
      y = 0.6,
      z = 0.4,
      time = 420
    })
    instance.diffuseCurve:addKeyframe({
      x = 1,
      y = 1,
      z = 0.95,
      time = 540
    })
    instance.diffuseCurve:addKeyframe({
      x = 1,
      y = 1,
      z = 0.95,
      time = 1020
    })
    instance.diffuseCurve:addKeyframe({
      x = 0.8,
      y = 0.8,
      z = 0.7,
      time = 1080
    })
    instance.diffuseCurve:addKeyframe({
      x = 0.8,
      y = 0.5,
      z = 0.25,
      time = 1140
    })
    instance.diffuseCurve:addKeyframe({
      x = 0.4,
      y = 0.3,
      z = 0.6,
      time = 1200
    })
    instance.diffuseCurve:addKeyframe({
      x = 0.1,
      y = 0.1,
      z = 0.2,
      time = 1260
    })
    instance.diffuseCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 0.05,
      time = 1320
    })
    instance.diffuseCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 0.05,
      time = 1440
    })
    instance.rotCurve = AnimCurve:new(linearInterpolator1)
    instance.rotCurve:addKeyframe({
      v = Utils.degToRad(-15),
      time = 0
    })
    instance.rotCurve:addKeyframe({
      v = Utils.degToRad(-20),
      time = 330
    })
    instance.rotCurve:addKeyframe({
      v = Utils.degToRad(-90),
      time = 720
    })
    instance.rotCurve:addKeyframe({
      v = Utils.degToRad(-170),
      time = 1230
    })
    instance.rotCurve:addKeyframe({
      v = Utils.degToRad(-171),
      time = 1440
    })
    instance.skyCurve = AnimCurve:new(linearInterpolator4)
    instance.skyCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 1,
      w = 0,
      time = 0
    })
    instance.skyCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 1,
      w = 0,
      time = 300
    })
    instance.skyCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 0,
      w = 1,
      time = 360
    })
    instance.skyCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 0,
      w = 1,
      time = 420
    })
    instance.skyCurve:addKeyframe({
      x = 1,
      y = 0,
      z = 0,
      w = 0,
      time = 480
    })
    instance.skyCurve:addKeyframe({
      x = 1,
      y = 0,
      z = 0,
      w = 0,
      time = 1020
    })
    instance.skyCurve:addKeyframe({
      x = 0,
      y = 1,
      z = 0,
      w = 0,
      time = 1140
    })
    instance.skyCurve:addKeyframe({
      x = 0,
      y = 1,
      z = 0,
      w = 0,
      time = 1200
    })
    instance.skyCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 1,
      w = 0,
      time = 1320
    })
    instance.skyCurve:addKeyframe({
      x = 0,
      y = 0,
      z = 1,
      w = 0,
      time = 1440
    })
    instance.skyDayTimeStart = 360
    instance.skyDayTimeEnd = 1140
    instance.volumeFogCurve = AnimCurve:new(linearInterpolator3)
    instance.volumeFogCurve:addKeyframe({
      x = 0.0552942,
      y = 0.0776472,
      z = 0.13490200000000002,
      time = 0
    })
    instance.volumeFogCurve:addKeyframe({
      x = 0.0552942,
      y = 0.0776472,
      z = 0.13490200000000002,
      time = 300
    })
    instance.volumeFogCurve:addKeyframe({
      x = 0.1290198,
      y = 0.1811768,
      z = 0.2360785,
      time = 360
    })
    instance.volumeFogCurve:addKeyframe({
      x = 0.1290198,
      y = 0.1811768,
      z = 0.2360785,
      time = 420
    })
    instance.volumeFogCurve:addKeyframe({
      x = 0.184314,
      y = 0.258824,
      z = 0.337255,
      time = 480
    })
    instance.volumeFogCurve:addKeyframe({
      x = 0.184314,
      y = 0.258824,
      z = 0.337255,
      time = 1020
    })
    instance.volumeFogCurve:addKeyframe({
      x = 0.1290198,
      y = 0.1811768,
      z = 0.26980400000000004,
      time = 1140
    })
    instance.volumeFogCurve:addKeyframe({
      x = 0.1290198,
      y = 0.1811768,
      z = 0.26980400000000004,
      time = 1200
    })
    instance.volumeFogCurve:addKeyframe({
      x = 0.0552942,
      y = 0.0776472,
      z = 0.1686275,
      time = 1320
    })
    instance.volumeFogCurve:addKeyframe({
      x = 0.0552942,
      y = 0.0776472,
      z = 0.13490200000000002,
      time = 1440
    })
    instance.distanceFogCurve = AnimCurve:new(linearInterpolator3)
    instance.distanceFogCurve:addKeyframe({
      x = 0.0196078431372549,
      y = 0.0196078431372549,
      z = 0.0392156862745098,
      time = 0
    })
    instance.distanceFogCurve:addKeyframe({
      x = 0.0196078431372549,
      y = 0.0196078431372549,
      z = 0.0392156862745098,
      time = 300
    })
    instance.distanceFogCurve:addKeyframe({
      x = 0.5607843137254902,
      y = 0.4745098039215686,
      z = 0.4235294117647059,
      time = 360
    })
    instance.distanceFogCurve:addKeyframe({
      x = 0.5607843137254902,
      y = 0.4745098039215686,
      z = 0.4235294117647059,
      time = 420
    })
    instance.distanceFogCurve:addKeyframe({
      x = 0.36470588235294116,
      y = 0.47843137254901963,
      z = 0.6235294117647059,
      time = 480
    })
    instance.distanceFogCurve:addKeyframe({
      x = 0.36470588235294116,
      y = 0.47843137254901963,
      z = 0.6235294117647059,
      time = 1020
    })
    instance.distanceFogCurve:addKeyframe({
      x = 0.23529411764705882,
      y = 0.11764705882352941,
      z = 0.19607843137254902,
      time = 1140
    })
    instance.distanceFogCurve:addKeyframe({
      x = 0.19607843137254902,
      y = 0.0784313725490196,
      z = 0.1568627450980392,
      time = 1200
    })
    instance.distanceFogCurve:addKeyframe({
      x = 0.09803921568627451,
      y = 0.09019607843137255,
      z = 0.11764705882352941,
      time = 1260
    })
    instance.distanceFogCurve:addKeyframe({
      x = 0.0196078431372549,
      y = 0.0196078431372549,
      z = 0.0392156862745098,
      time = 1320
    })
  else
  end
  instance.allowRain = allowRain ~= nil and allowRain == true
  instance.autoRain = instance.allowRain and autoRain ~= nil and autoRain
  instance.rainTypes = {}
  instance.timeSinceLastRain = 9999999
  instance.lastRainScale = 0
  if instance.allowRain then
    instance:loadRainType("data/sky/rain.i3d", "data/maps/sounds/rain.wav")
    instance:loadRainType("data/sky/hail.i3d", "data/maps/sounds/hail.wav")
    instance.minRainInterval = 720
    instance.maxRainInterval = 2880
    instance.minRainDuration = 120
    instance.maxRainDuration = 300
    instance.rainTime = 0
    instance.nextRainType = 0
    instance.rainTypeAfterNext = 0
    if instance.autoRain then
      instance.timeUntilRainAfterNext = math.random(instance.minRainInterval, instance.maxRainInterval)
      instance:setNextRain()
    else
      instance.rainTime = 2 * instance.maxRainDuration
      instance.timeUntilNextRain = 0
      instance.timeUntilRainAfterNext = 0
      instance.nextRainDuration = 0
    end
    instance.rainFadeCurve = AnimCurve:new(linearInterpolator4)
    instance.rainFadeCurve:addKeyframe({
      x = 1,
      y = 0,
      z = 0,
      w = 0,
      time = 0
    })
    instance.rainFadeCurve:addKeyframe({
      x = 0.6,
      y = 0.5,
      z = 0,
      w = 0.35,
      time = 10
    })
    instance.rainFadeCurve:addKeyframe({
      x = 0.55,
      y = 1,
      z = 0,
      w = 0.7,
      time = 20
    })
    instance.rainFadeCurve:addKeyframe({
      x = 0.55,
      y = 1,
      z = 0.5,
      w = 1,
      time = 25
    })
    instance.rainFadeCurve:addKeyframe({
      x = 0.55,
      y = 1,
      z = 1,
      w = 1,
      time = 30
    })
    instance.rainFadeDuration = 30
  end
  instance.isSunOn = true
  return instance
end
function Environment:destroy()
  delete(self.skyRootId)
  for k, v in pairs(self.rainTypes) do
    if v.sample ~= nil then
      delete(v.sample)
    end
    if v.rootNode ~= nil then
      delete(v.rootNode)
    end
  end
  setVolumeFog("none", 0, 0, 0, 0, 0, 0)
end
function Environment:update(dt)
  local speedUp = 1
  local dtMinutes = dt / 60000 * self.timeScale * speedUp
  local sunThreshold = 0.06
  self.dayTime = self.dayTime + dt * self.timeScale * speedUp
  if self.dayTime > 86400000 then
    self.dayTime = 0
    self.currentDay = self.currentDay + 1
    self:calculateNewPrices()
  end
  local lightScale = 1
  local rainSkyScale = 0
  local rainScale = 0
  local fogScale = 0
  local rainParamsChanged = false
  if self.allowRain then
    self.timeSinceLastRain = self.timeSinceLastRain + dtMinutes
    self.timeUntilNextRain = self.timeUntilNextRain - dtMinutes
    if 0 >= self.timeUntilNextRain then
      self.rainTime = self.rainTime + dtMinutes
      if self.rainTime <= self.nextRainDuration then
        if self.rainTime > self.nextRainDuration - self.rainFadeDuration then
          lightScale, rainSkyScale, rainScale, fogScale = self.rainFadeCurve:get(self.nextRainDuration - self.rainTime)
        else
          lightScale, rainSkyScale, rainScale, fogScale = self.rainFadeCurve:get(self.rainTime)
        end
        rainParamsChanged = true
      end
    end
    if 0 < rainScale then
      self.timeSinceLastRain = 0
      local rainType = self:getRainType()
      setVisibility(rainType.rootNode, true)
      for i = 1, table.getn(rainType.geometries) do
        setDropCountScale(rainType.geometries[i], rainScale)
      end
      if rainType.sample == nil then
        rainType.sample = createSample("rainSample")
        loadSample(rainType.sample, rainType.sampleFilename, false)
      end
      if not rainType.sampleRunning then
        playSample(rainType.sample, 0, rainScale, 0)
        rainType.sampleRunning = true
      end
      setSampleVolume(rainType.sample, math.min(1, rainScale))
    else
      self:disableRainEffect()
    end
    if self.rainTime > self.nextRainDuration and self.autoRain then
      self:setNextRain()
    end
  end
  self.lastRainScale = rainScale
  if self.dayNightCycle then
    local dayMinutes = self.dayTime / 60000
    local x, y, z, w = self.skyCurve:get(dayMinutes)
    if self.allowRain then
      x = x * (1 - rainSkyScale)
      y = y * (1 - rainSkyScale)
      z = z * (1 - rainSkyScale)
      w = w * (1 - rainSkyScale)
    end
    setShaderParameter(self.skyId, "partScale", x, y, z, w)
    if self.sunLightId ~= nil then
      local rx = self.rotCurve:get(dayMinutes)
      setRotation(self.sunLightId, rx, Utils.degToRad(75), Utils.degToRad(0))
      local dr, dg, db = self.diffuseCurve:get(dayMinutes)
      dr = dr * lightScale
      dg = dg * lightScale
      db = db * lightScale
      if sunThreshold > dr and sunThreshold > dg and sunThreshold > db then
        self.isSunOn = false
        setVisibility(self.sunLightId, false)
      else
        setLightDiffuseColor(self.sunLightId, dr, dg, db)
        setLightSpecularColor(self.sunLightId, dr, dg, db)
        self.isSunOn = true
        setVisibility(self.sunLightId, true)
      end
      local ar, ag, ab = self.ambientCurve:get(dayMinutes)
      ar = ar * lightScale
      ag = ag * lightScale
      ab = ab * lightScale
      setAmbientColor(ar, ag, ab)
    end
    local fr, fg, fb = self.distanceFogCurve:get(dayMinutes)
    if self.allowRain then
      fr = (1 - fogScale) * fr + fogScale * 0.3
      fg = (1 - fogScale) * fg + fogScale * 0.3
      fb = (1 - fogScale) * fb + fogScale * 0.3
    end
    setFog("exp", 0.0018, 1, fr, fg, fb)
    local vr, vg, vb = self.volumeFogCurve:get(dayMinutes)
    if self.water ~= nil then
      setVolumeFog("exp", 0.5, 0, g_currentMission.waterY, vr, vg, vb)
    end
    if self.underwaterFog ~= nil then
      setShaderParameter(self.underwaterFog, "underwaterColor", vr, vg, vb, 0)
    end
    if self.water ~= nil then
      local fr, fg, fb = self.distanceFogCurve:get(dayMinutes)
    end
    if self.allowRain and rainParamsChanged then
      setShaderParameter(self.skyId, "rainScale", rainSkyScale, 0, 0, 0)
    end
  elseif self.water ~= nil then
    setVolumeFog("exp", 0.5, 0, g_currentMission.waterY, 0.184314, 0.258824, 0.337255)
  end
end
function Environment:setWaterFogColor(r, g, b)
  self.waterFogColorR = r
  self.waterFogColorG = g
  self.waterFogColorB = b
end
function Environment:setNextRain()
  self:disableRainEffect()
  self.rainTime = 0
  self.nextRainType = self.rainTypeAfterNext
  self.rainTypeAfterNext = 0
  if math.random() > 0.7 then
    self.rainTypeAfterNext = 1
  end
  self.timeUntilNextRain = self.timeUntilRainAfterNext
  self.timeUntilRainAfterNext = math.random(self.minRainInterval, self.maxRainInterval)
  self.nextRainDuration = math.random(self.minRainDuration, self.maxRainDuration)
  if self.dayNightCycle then
    self.timeUntilNextRain = self:getNextDayStartTime(self.timeUntilNextRain) + math.random(0, self.skyDayTimeEnd - self.skyDayTimeStart - self.nextRainDuration)
  end
end
function Environment:getNextDayStartTime(time)
  if self.dayNightCycle then
    local dayTimeMinutes = self.dayTime / 60000
    local absolutTime = time + dayTimeMinutes
    local days, minutesOfDay = math.modf(absolutTime / 1440)
    if minutesOfDay < self.skyDayTimeStart then
      return days * 24 * 60 - dayTimeMinutes + self.skyDayTimeStart
    else
      return (days + 1) * 24 * 60 - dayTimeMinutes + self.skyDayTimeStart
    end
  else
    return time
  end
end
function Environment:startRain(duration, rainType, timeUntilStart)
  self:disableRainEffect()
  if timeUntilStart ~= nil then
    self.timeUntilNextRain = timeUntilStart
  else
    self.timeUntilNextRain = 0
  end
  self.rainTime = 0
  self.nextRainDuration = duration
  self.nextRainType = 0
  if rainType ~= nil and rainType == 1 then
    self.nextRainType = 1
  end
end
function Environment:disableRainEffect()
  local rainType = self:getRainType()
  setVisibility(rainType.rootNode, false)
  if rainType.sampleRunning then
    stopSample(rainType.sample)
    rainType.sampleRunning = false
  end
end
function Environment:loadRainType(i3d, sampleFilename)
  local rainType = {}
  rainType.rootNode = loadI3DFile(i3d)
  link(getRootNode(), rainType.rootNode)
  setCullOverride(rainType.rootNode, true)
  setVisibility(rainType.rootNode, false)
  rainType.geometries = {}
  for i = 1, getNumOfChildren(rainType.rootNode) do
    local child = getChildAt(rainType.rootNode, i - 1)
    if getClassName(child) == "Shape" then
      local geometry = getGeometry(child)
      if geometry ~= 0 and getClassName(geometry) == "Precipitation" then
        table.insert(rainType.geometries, geometry)
      end
    end
  end
  rainType.sampleFilename = sampleFilename
  rainType.sample = nil
  rainType.sampleRunning = false
  table.insert(self.rainTypes, rainType)
end
function Environment:getRainType()
  if self.nextRainType == 1 then
    return self.rainTypes[2]
  else
    return self.rainTypes[1]
  end
end
function Environment:calculateNewPrices()
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    local price = FruitUtil.fruitIndexToDesc[i].pricePerLiter
    local maxDiff = 0.5
    local minDiff = 0.05
    local delta = 0.2 * math.random() - 0.1
    if minDiff >= math.abs(delta) then
      delta = 0
    end
    FruitUtil.fruitIndexToDesc[i].yesterdaysPrice = price
    if price + delta < g_startPrices[i] - g_startPrices[i] * maxDiff and delta < 0 then
      delta = -delta
    end
    if price + delta > g_startPrices[i] + g_startPrices[i] * maxDiff and 0 < delta then
      delta = -delta
    end
    price = price + delta
    price = math.floor(1000 * price) / 1000
    FruitUtil.fruitIndexToDesc[i].pricePerLiter = price
  end
end
