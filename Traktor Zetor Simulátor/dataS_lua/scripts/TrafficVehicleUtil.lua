TrafficVehicleUtil = {}
TrafficVehicleUtil.trafficVehicles = {}
TrafficVehicleUtil.highestProbability = 0
function TrafficVehicleUtil.registerTrafficVehicle(filename, probability)
  TrafficVehicleUtil.highestProbability = TrafficVehicleUtil.highestProbability + probability
  table.insert(TrafficVehicleUtil.trafficVehicles, {filename = filename, probability = probability})
end
function TrafficVehicleUtil.getRandomTrafficVehicle()
  local prob = math.random(0, TrafficVehicleUtil.highestProbability)
  local num = table.getn(TrafficVehicleUtil.trafficVehicles)
  local tempSum = 0
  for i = 1, num do
    if prob >= tempSum and prob <= TrafficVehicleUtil.trafficVehicles[i].probability + tempSum then
      return TrafficVehicleUtil.trafficVehicles[i].filename
    end
    tempSum = tempSum + TrafficVehicleUtil.trafficVehicles[i].probability
  end
  return TrafficVehicleUtil.trafficVehicles[num].filename
end
