AnimCurve = {}
function linearInterpolator1(first, second, alpha)
  return first.v * alpha + second.v * (1 - alpha)
end
function linearInterpolator2(first, second, alpha)
  local oneMinusAlpha = 1 - alpha
  return first.x * alpha + second.x * oneMinusAlpha, first.y * alpha + second.y * oneMinusAlpha
end
function linearInterpolator3(first, second, alpha)
  local oneMinusAlpha = 1 - alpha
  return first.x * alpha + second.x * oneMinusAlpha, first.y * alpha + second.y * oneMinusAlpha, first.z * alpha + second.z * oneMinusAlpha
end
function linearInterpolator4(first, second, alpha)
  local oneMinusAlpha = 1 - alpha
  return first.x * alpha + second.x * oneMinusAlpha, first.y * alpha + second.y * oneMinusAlpha, first.z * alpha + second.z * oneMinusAlpha, first.w * alpha + second.w * oneMinusAlpha
end
function linearInterpolatorN(first, second, alpha)
  local oneMinusAlpha = 1 - alpha
  local ret = {}
  for i = 1, table.getn(first.v) do
    table.insert(ret, first.v[i] * alpha + second.v[i] * oneMinusAlpha)
  end
  return ret
end
local AnimCurve_mt = Class(AnimCurve)
function AnimCurve:new(interpolator)
  local instance = {}
  setmetatable(instance, AnimCurve_mt)
  instance.keyframes = {}
  instance.interpolator = interpolator
  instance.currentTime = 0
  instance.maxTime = 0
  return instance
end
function AnimCurve:delete()
end
function AnimCurve:addKeyframe(keyframe)
  local numKeys = table.getn(self.keyframes)
  if 0 < numKeys and keyframe.time < self.keyframes[numKeys].time then
    print("Error: keyframes not strictly monotonic increasing")
    return
  end
  table.insert(self.keyframes, keyframe)
  self.maxTime = keyframe.time
end
function AnimCurve:get(time)
  local numKeys = table.getn(self.keyframes)
  if numKeys == 0 then
    return
  end
  local first, second
  if 2 <= numKeys and time >= self.keyframes[1].time then
    if time < self.maxTime then
      for i = 2, numKeys do
        second = self.keyframes[i]
        if time <= second.time then
          first = self.keyframes[i - 1]
          break
        end
      end
    else
      first = self.keyframes[numKeys]
      second = first
    end
  else
    first = self.keyframes[1]
    second = first
  end
  local time0 = first.time
  local time1 = second.time
  local alpha
  if time0 < time1 then
    alpha = (time1 - time) / (time1 - time0)
  else
    alpha = time0
  end
  return self.interpolator(first, second, alpha)
end
