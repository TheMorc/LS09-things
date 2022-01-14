g_inputButtonEvent = {}
g_inputButtonLast = {}
InputBinding = {}
InputBinding.externalInputButtons = {
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
}
InputBinding.externalAnalogAxes = {}
InputBinding.externalDigitalAxes = {}
InputBinding.analogAxes = {
  0,
  0,
  0,
  0
}
InputBinding.digitalAxes = {
  0,
  0,
  0,
  0
}
InputBinding.buttons = {}
InputBinding.buttonKeys = {}
InputBinding.axes = {}
InputBinding.axesKeys = {}
function InputBinding.getButton(button)
  return InputBinding.buttons[button]
end
function InputBinding.getButtonKey(button)
  return InputBinding.buttonKeys[button]
end
function InputBinding.hasEvent(button)
  return g_inputButtonEvent[button]
end
function InputBinding.isPressed(button)
  return g_inputButtonLast[button]
end
function InputBinding.getButtonKeyName(button)
  return string.upper(string.char(InputBinding.getButtonKey(button)))
end
function InputBinding.getButtonName(button)
  local hardwareButton = InputBinding.getButton(button)
  if hardwareButton == -1 then
    return nil
  end
  return string.format("%d", hardwareButton + 1)
end
function InputBinding.isAxisZero(value)
  return math.abs(value) < 1.0E-4
end
function InputBinding.getDigitalInputAxis(axis)
  local input = InputBinding.digitalAxes[axis]
  if InputBinding.isAxisZero(input) then
    for i = 1, table.getn(InputBinding.externalDigitalAxes) do
      input = Utils.getNoNil(InputBinding.externalDigitalAxes[i][axis], 0)
      if not InputBinding.isAxisZero(input) then
        break
      end
    end
  end
  return input
end
function InputBinding.getAnalogInputAxis(axis)
  local input = InputBinding.analogAxes[axis]
  if InputBinding.isAxisZero(input) then
    for i = 1, table.getn(InputBinding.externalAnalogAxes) do
      input = Utils.getNoNil(InputBinding.externalAnalogAxes[i][axis], 0)
      if not InputBinding.isAxisZero(input) then
        break
      end
    end
  end
  return input
end
function InputBinding.registerDigitalInputAxis()
  table.insert(InputBinding.externalDigitalAxes, {
    0,
    0,
    0,
    0
  })
  return table.getn(InputBinding.externalDigitalAxes)
end
function InputBinding.registerAnalogInputAxis()
  table.insert(InputBinding.externalAnalogAxes, {
    0,
    0,
    0,
    0
  })
  return table.getn(InputBinding.externalAnalogAxes)
end
function InputBinding.setDigitalInputAxis(id, axis, value)
  for k, v in pairs(InputBinding.axes) do
    if v.axis == axis then
      if v.invert then
        InputBinding.externalDigitalAxes[id][k] = -value
      else
        InputBinding.externalDigitalAxes[id][k] = value
      end
    end
  end
end
function InputBinding.setAnalogInputAxis(id, axis, value)
  for k, v in pairs(InputBinding.axes) do
    if v.axis == axis then
      if v.invert then
        InputBinding.externalAnalogAxes[id][k] = -value
      else
        InputBinding.externalAnalogAxes[id][k] = value
      end
    end
  end
end
function InputBinding.addDownButton(button)
  if 1 <= button and button <= 16 then
    InputBinding.externalInputButtons[button] = InputBinding.externalInputButtons[button] + 1
  end
end
function InputBinding.removeDownButton(button)
  if 1 <= button and button <= 16 then
    InputBinding.externalInputButtons[button] = math.max(InputBinding.externalInputButtons[button] - 1, 0)
  end
end
function InputBinding.load()
  local xmlFile = loadXMLFile("VehicleTypes", "data/inputBinding.xml")
  local i = 0
  while true do
    local baseName = string.format("inputBinding.input(%d)", i)
    local inputName = getXMLString(xmlFile, baseName .. "#name")
    if inputName == nil then
      break
    end
    local inputKey = getXMLString(xmlFile, baseName .. "#key")
    local inputButton = getXMLString(xmlFile, baseName .. "#button")
    if inputKey == nil or inputButton == nil then
      print("Error: no button or key specified for input event '" .. inputName .. "'")
      break
    end
    local inputButtonNumber = -1
    if inputButton ~= "" then
      if Input[inputButton] == nil then
        print("Error: invalid button '" .. inputButton .. "'  for input event '" .. inputName .. "'")
        break
      else
        inputButtonNumber = Input[inputButton]
      end
    end
    if Input[inputKey] == nil then
      print("Error: invalid key '" .. inputKey .. "'  for input event '" .. inputName .. "'")
      break
    end
    local buttonIndex = i + 1
    InputBinding[inputName] = buttonIndex
    InputBinding.buttons[buttonIndex] = inputButtonNumber
    InputBinding.buttonKeys[buttonIndex] = Input[inputKey]
    g_inputButtonEvent[buttonIndex] = false
    g_inputButtonLast[buttonIndex] = false
    i = i + 1
  end
  InputBinding.NUM_BUTTONS = i
  i = 0
  while true do
    local baseName = string.format("inputBinding.axis(%d)", i)
    local axisName = getXMLString(xmlFile, baseName .. "#name")
    if axisName == nil then
      break
    end
    local axisKey1 = getXMLString(xmlFile, baseName .. "#key1")
    local axisKey2 = getXMLString(xmlFile, baseName .. "#key2")
    local axisAxis = getXMLString(xmlFile, baseName .. "#axis")
    local invert = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#invert"), false)
    if axisKey1 == nil or axisKey2 == nil or axisAxis == nil then
      print("Error: no button or key specified for input axis '" .. axisName .. "'")
      break
    end
    local key1 = -1
    local key2 = -1
    local axis = -1
    if axisKey1 ~= "" then
      key1 = Input[axisKey1]
    end
    if axisKey1 ~= "" then
      key2 = Input[axisKey2]
    end
    if axisAxis ~= "" then
      axis = Input[axisAxis]
    end
    if key1 == nil then
      print("Error: invalid key '" .. axisKey1 .. "'  for input axis '" .. axisName .. "'")
      break
    end
    if key2 == nil then
      print("Error: invalid key '" .. axisKey2 .. "'  for input axis '" .. axisName .. "'")
      break
    end
    if axis == nil then
      print("Error: invalid axis '" .. axisAxis .. "'  for input axis '" .. axisName .. "'")
      break
    end
    local index = i + 1
    InputBinding[axisName] = index
    local entry = {}
    entry.key1 = key1
    entry.key2 = key2
    entry.axis = axis
    entry.invert = invert
    InputBinding.axes[index] = entry
    i = i + 1
  end
  delete(xmlFile)
  for i = 1, 16 do
    setKeyboardButtonMapping(i, -1)
  end
  for k, v in pairs(InputBinding.axes) do
    if v.axis ~= -1 then
      setKeyboardAxisMapping(v.axis, -1, -1)
    end
  end
end
function InputBinding.keyEvent(unicode, sym, modifier, isDown)
  for k, v in pairs(InputBinding.axes) do
    if v.key1 == sym then
      if isDown then
        InputBinding.digitalAxes[k] = 1
      elseif InputBinding.digitalAxes[k] == 1 then
        InputBinding.digitalAxes[k] = 0
      end
    end
    if v.key2 == sym then
      if isDown then
        InputBinding.digitalAxes[k] = -1
      elseif InputBinding.digitalAxes[k] == -1 then
        InputBinding.digitalAxes[k] = 0
      end
    end
  end
end
function InputBinding.update(dt)
  for k, v in pairs(InputBinding.axes) do
    if v.invert then
      InputBinding.analogAxes[k] = -getInputAxis(v.axis)
    else
      InputBinding.analogAxes[k] = getInputAxis(v.axis)
    end
  end
  local inputButtons = {}
  for i = 1, 16 do
    local isDown = getInputButton(i - 1) > 0 or 0 < InputBinding.externalInputButtons[i]
    inputButtons[i] = isDown
  end
  for i = 1, InputBinding.NUM_BUTTONS do
    local isDown = Input.isKeyPressed(InputBinding.buttonKeys[i]) == true
    if InputBinding.buttons[i] ~= -1 and not isDown then
      isDown = inputButtons[i]
    end
    g_inputButtonEvent[i] = isDown and not g_inputButtonLast[i]
    g_inputButtonLast[i] = isDown
  end
end
