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
InputBinding.mouseButtons = {}
InputBinding.buttonKeys = {}
InputBinding.buttonKeys2 = {}
InputBinding.axes = {}
InputBinding.axesKeys = {}
InputBinding.mouseButtonState = {}
InputBinding.NUM_BUTTONS = 0
InputBinding.version = 0.11
function InputBinding.getButton(button)
  return InputBinding.buttons[button]
end
function InputBinding.getMouseButton(button)
  return InputBinding.mouseButtons[button]
end
function InputBinding.getButtonKey(button)
  if InputBinding.buttonKeys[button] ~= nil then
    return InputBinding.buttonKeys[button]
  end
  if InputBinding.buttonKeys2[button] ~= nil then
    return InputBinding.buttonKeys2[button]
  end
  return 0
end
function InputBinding.hasEvent(button)
  return g_inputButtonEvent[button]
end
function InputBinding.isPressed(button)
  return g_inputButtonLast[button]
end
function InputBinding.getButtonKeyName(button)
  local key = InputBinding.getButtonKey(button)
  if key >= Input.KEY_f1 and key <= Input.KEY_f15 then
    return "F" .. button - Input.KEY_f1 + 1
  end
  if key == Input.KEY_shift then
    return "Shift"
  end
  if key >= Input.KEY_KP_0 and key <= Input.KEY_KP_9 then
    return "Numpad" .. key - Input.KEY_KP_0
  end
  if key == Input.KEY_KP_period then
    return "Numpad ."
  end
  if key == Input.KEY_KP_divide then
    return "Numpad /"
  end
  if key == Input.KEY_KP_multiply then
    return "Numpad *"
  end
  if key == Input.KEY_KP_minus then
    return "Numpad -"
  end
  if key == Input.KEY_KP_plus then
    return "Numpad +"
  end
  if key == Input.KEY_KP_enter then
    return "Numpad Enter"
  end
  if key == Input.KEY_KP_equals then
    return "Numpad ="
  end
  if key == Input.KEY_return then
    return "Enter"
  end
  if key == Input.KEY_space then
    return "Space"
  end
  return string.upper(string.char(key))
end
function InputBinding.getButtonName(button)
  local hardwareButton = InputBinding.getButton(button)
  if hardwareButton == -1 then
    return nil
  end
  return string.format("%d", hardwareButton + 1)
end
function InputBinding.isAxisZero(value)
  return value == nil or math.abs(value) < 1.0E-4
end
function InputBinding.getDigitalInputAxis(axis)
  local input = Utils.getNoNil(InputBinding.digitalAxes[axis], 0)
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
  local input = Utils.getNoNil(InputBinding.analogAxes[axis], 0)
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
function InputBinding.checkFormat()
  local isNewFormat = true
  local xmlFile = loadXMLFile("InputBindings", g_inputBindingPath)
  local i = 0
  while true do
    local baseName = string.format("inputBinding.input(%d)", i)
    local inputName = getXMLString(xmlFile, baseName .. "#name")
    if inputName == nil then
      break
    end
    local inputKey1 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key1"), "INVALID")
    if inputKey1 == "INVALID" then
      isNewFormat = false
      break
    end
    i = i + 1
  end
  delete(xmlFile)
  return isNewFormat
end
function InputBinding.checkVersion(inputBindingPath, inputBindingPathTemplate)
  local xmlFile1 = loadXMLFile("InputBindings1", inputBindingPath)
  local xmlFile2 = loadXMLFile("InputBindings2", inputBindingPathTemplate)
  local version1 = Utils.getNoNil(getXMLFloat(xmlFile1, "inputBinding#version"), 0.1)
  local version2 = Utils.getNoNil(getXMLFloat(xmlFile2, "inputBinding#version"), 0.1)
  if version1 ~= version2 then
    return false
  end
  return true
end
function InputBinding.load()
  local path = g_inputBindingPath
  local xmlFile = loadXMLFile("InputBindings", path)
  InputBinding.version = Utils.getNoNil(getXMLFloat(xmlFile, "inputBinding#version"), 0.1)
  local i = 0
  while true do
    local baseName = string.format("inputBinding.input(%d)", i)
    local inputName = getXMLString(xmlFile, baseName .. "#name")
    if inputName == nil then
      break
    end
    local inputKey1 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key1"), "no")
    local inputKey2 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key2"), "")
    local inputButton = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#button"), "")
    local inputMouseButton = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#mouse"), "")
    if inputKey1 == "no" then
      inputKey1 = ""
      local inputKeyOld = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key"), "")
      if inputKeyOld ~= "" then
        inputKey1 = inputKeyOld
      end
    end
    local inputButtonNumber = -1
    if inputButton ~= "" and inputButton ~= "--" then
      if Input[inputButton] == nil then
        print("Error: invalid button '" .. inputButton .. "'  for input event '" .. inputName .. "'")
        break
      else
        inputButtonNumber = Input[inputButton]
      end
    end
    local buttonIndex = i + 1
    if inputMouseButton ~= "" and inputMouseButton ~= "--" then
      if Input[inputMouseButton] == nil then
        print("Error: invalid mouse button '" .. inputMouseButton .. "'  for input event '" .. inputName .. "'")
        break
      else
        InputBinding.mouseButtons[buttonIndex] = Input[inputMouseButton]
      end
    else
      InputBinding.mouseButtons[buttonIndex] = 0
    end
    if inputKey1 ~= "" and inputKey1 ~= "--" then
      if Input[inputKey1] == nil then
        print("Error: invalid key1 '" .. inputKey1 .. "'  for input event '" .. inputName .. "'")
        break
      else
        InputBinding.buttonKeys[buttonIndex] = Input[inputKey1]
      end
    else
      InputBinding.buttonKeys[buttonIndex] = 0
    end
    if inputKey2 ~= "" and inputKey2 ~= "--" then
      if Input[inputKey2] == nil then
        print("Error: invalid key2 '" .. inputKey2 .. "'  for input event '" .. inputName .. "'")
        break
      else
        InputBinding.buttonKeys2[buttonIndex] = Input[inputKey2]
      end
    else
      InputBinding.buttonKeys2[buttonIndex] = 0
    end
    InputBinding[inputName] = buttonIndex
    InputBinding.buttons[buttonIndex] = inputButtonNumber
    g_inputButtonEvent[buttonIndex] = false
    g_inputButtonLast[buttonIndex] = false
    i = i + 1
  end
  InputBinding.NUM_BUTTONS = i
  local i = 0
  while true do
    local baseName = string.format("inputBinding.axis(%d)", i)
    local axisActionName = getXMLString(xmlFile, baseName .. "#name")
    if axisActionName == nil then
      break
    end
    local axisKey1 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key1"), "")
    local axisKey2 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key2"), "")
    local axisKey3 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key3"), "")
    local axisKey4 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key4"), "")
    local axisAxis = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#axis"), "")
    local invert = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#invert"), false)
    if axisKey1 == nil or axisKey2 == nil or axisAxis == nil then
      print("Error: no gamepad axis or key specified for input axis '" .. axisActionName .. "'")
      break
    end
    local key1 = -1
    local key2 = -1
    local key3 = -1
    local key4 = -1
    local axis = -1
    if axisKey1 ~= "" then
      key1 = Input[axisKey1]
    end
    if axisKey2 ~= "" then
      key2 = Input[axisKey2]
    end
    if axisKey3 ~= "" then
      key3 = Input[axisKey3]
    end
    if axisKey4 ~= "" then
      key4 = Input[axisKey4]
    end
    if axisAxis ~= "" then
      axis = Input[axisAxis]
    end
    if key1 == nil then
      print("Error: invalid key '" .. axisKey1 .. "'  for input axis '" .. axisActionName .. "'")
      break
    end
    if key2 == nil then
      print("Error: invalid key '" .. axisKey2 .. "'  for input axis '" .. axisActionName .. "'")
      break
    end
    if key3 == nil then
      print("Error: invalid key '" .. axisKey3 .. "'  for input axis '" .. axisActionName .. "'")
      break
    end
    if key4 == nil then
      print("Error: invalid key '" .. axisKey4 .. "'  for input axis '" .. axisActionName .. "'")
      break
    end
    if axis == nil then
      print("Error: invalid axis '" .. axisAxis .. "'  for input axis '" .. axisActionName .. "'")
      break
    end
    local index = i + 1
    InputBinding[axisActionName] = index
    local entry = {}
    entry.key1 = key1
    entry.key2 = key2
    entry.key3 = key3
    entry.key4 = key4
    entry.axis = axis
    entry.invert = invert
    entry.axisName = axisAxis
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
    if v.key3 == sym then
      if isDown then
        InputBinding.digitalAxes[k] = 1
      elseif InputBinding.digitalAxes[k] == 1 then
        InputBinding.digitalAxes[k] = 0
      end
    end
    if v.key4 == sym then
      if isDown then
        InputBinding.digitalAxes[k] = -1
      elseif InputBinding.digitalAxes[k] == -1 then
        InputBinding.digitalAxes[k] = 0
      end
    end
  end
end
function InputBinding.mouseEvent(posX, posY, isDown, isUp, button)
  if isDown then
    InputBinding.mouseButtonState[button] = true
  elseif button ~= Input.MOUSE_BUTTON_WHEEL_UP and button ~= Input.MOUSE_BUTTON_WHEEL_DOWN then
    InputBinding.mouseButtonState[button] = false
  end
end
function InputBinding.update(dt)
  for k, v in pairs(InputBinding.axes) do
    if v.axis ~= -1 then
      if v.invert then
        InputBinding.analogAxes[k] = -getInputAxis(v.axis)
      else
        InputBinding.analogAxes[k] = getInputAxis(v.axis)
      end
    end
  end
  local inputButtons = {}
  for i = 1, 16 do
    local isDown = getInputButton(i - 1) > 0 or 0 < InputBinding.externalInputButtons[i]
    inputButtons[i] = isDown
  end
  for i = 1, InputBinding.NUM_BUTTONS do
    local isDown = false
    if InputBinding.buttonKeys[i] ~= nil and not isDown then
      isDown = Utils.getNoNil(Input.isKeyPressed(InputBinding.buttonKeys[i]), false)
    end
    if InputBinding.buttonKeys2[i] ~= nil and not isDown then
      isDown = Utils.getNoNil(Input.isKeyPressed(InputBinding.buttonKeys2[i]), false)
    end
    if InputBinding.buttons[i] ~= -1 and not isDown then
      isDown = inputButtons[InputBinding.buttons[i] + 1]
    end
    if InputBinding.mouseButtons[i] ~= nil and not isDown then
      isDown = Utils.getNoNil(InputBinding.mouseButtonState[InputBinding.mouseButtons[i]], false)
    end
    g_inputButtonEvent[i] = isDown and not g_inputButtonLast[i]
    g_inputButtonLast[i] = isDown
  end
  InputBinding.mouseButtonState[Input.MOUSE_BUTTON_WHEEL_UP] = false
  InputBinding.mouseButtonState[Input.MOUSE_BUTTON_WHEEL_DOWN] = false
end
