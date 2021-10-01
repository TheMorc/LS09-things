FruitUtil = {}
FruitUtil.FRUITTYPE_UNKNOWN = 0
FruitUtil.NUM_FRUITTYPES = 0
FruitUtil.fruitTypes = {}
FruitUtil.fruitIndexToDesc = {}
function FruitUtil.registerFruitType(name, needsSeeding, allowsSeeding, hasStraw, minHarvestingGrowthState, pricePerLiter, literPerQm, seedUsagePerQm, seedPricePerLiter, hudFruitOverlayFilename)
  local key = "FRUITTYPE_" .. string.upper(name)
  if FruitUtil[key] == nil then
    FruitUtil.NUM_FRUITTYPES = FruitUtil.NUM_FRUITTYPES + 1
    FruitUtil[key] = FruitUtil.NUM_FRUITTYPES
    local desc = {
      name = name,
      index = FruitUtil.NUM_FRUITTYPES
    }
    desc.needsSeeding = needsSeeding
    desc.allowsSeeding = allowsSeeding
    desc.hasStraw = hasStraw
    desc.minHarvestingGrowthState = minHarvestingGrowthState
    desc.pricePerLiter = pricePerLiter
    desc.yesterdaysPrice = pricePerLiter
    desc.literPerQm = literPerQm
    desc.seedUsagePerQm = seedUsagePerQm
    desc.seedPricePerLiter = seedPricePerLiter
    desc.hudFruitOverlayFilename = hudFruitOverlayFilename
    FruitUtil.fruitTypes[name] = desc
    FruitUtil.fruitIndexToDesc[FruitUtil.NUM_FRUITTYPES] = desc
    g_startPrices[FruitUtil.NUM_FRUITTYPES] = pricePerLiter
    g_startPriceSum = g_startPriceSum + pricePerLiter
  end
end
