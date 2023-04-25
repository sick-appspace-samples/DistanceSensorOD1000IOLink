--[[----------------------------------------------------------------------------

  Application Name:
  DistanceSensorOD1000IOLink

  Summary:
  Connecting and communicating to IO-Link device OD1000 distance sensor

  Description:
  This sample shows how to connect to the IO-Link device OD1000 and how to
  receive distance measurement data.

  How to run:
  This sample can be run on any AppSpace device which can act as an IO-Link master,
  e.g. SIM family. The IO-Link device OD1000 must be properly connected to a port
  which supports IO-Link. If the port is configured as IO-Link master, see script,
  the power LED blinks slowly. When a IO-Link device is successfully connected the
  LED blinks rapidly.

  More Information:
  See device manual of IO-Link master for according ports. See manual of IO-Link
  device OD1000 for further IO-Link specific description and device specific commands.

------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------

-- Enable power on S1 port, must be adapted if another port is used
-- luacheck: globals gPwr gIoLinkDevice gTmr
gPwr = Connector.Power.create('S1')
gPwr:enable(true)

-- Creating IO-Link device handle for S1 port, must be adapted if another port is used
-- Now S1 port is configured as an IO-Link master.
gIoLinkDevice = IOLink.RemoteDevice.create('S1')

-- Creating timer to cyclicly read process data of OD1000 device
gTmr = Timer.create()
gTmr:setExpirationTime(1000)
gTmr:setPeriodic(true)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

--@handleOnConnected()
local function handleOnConnected()
  print('IO-Link device OD1000 connected')

  -- Reading product name and other product related data
  local productName = gIoLinkDevice:getProductName()
  print('Product Name: ' .. productName)
  local firmwareVersion = gIoLinkDevice:readData(23, 0) -- index 23, subindex 0,  Firmware Version
  print('Firmware Version: ' .. firmwareVersion)

  -- Changing and checking the switching point of Q2, index 62, subindex 1
  -- The new switching point is 300 mm
  local newSwitchingPoint = string.pack('i2', 3000)
  local returnWrite = gIoLinkDevice:writeData(62, 1, newSwitchingPoint)
  local switchingPoint,
    returnReadSP = gIoLinkDevice:readData(62, 1)
  local appliedSwitchingPoint = string.unpack('i2', switchingPoint)
  print('Switching Point of Q2: ' .. appliedSwitchingPoint)
  print('Write Message: ' .. returnWrite .. '; Read Message: ' .. returnReadSP)

  --Starting timer after successfull connection
  gTmr:start()
end
IOLink.RemoteDevice.register(gIoLinkDevice, 'OnConnected', handleOnConnected)

-- Stopping timer when IO-Link device gets disconnected
--@handleOnDisconnected()
local function handleOnDisconnected()
  gTmr:stop()
  print('IO-Link device OD1000 disconnected')
end
IOLink.RemoteDevice.register( gIoLinkDevice, 'OnDisconnected', handleOnDisconnected )

--@handleOnPowerFault()
local function handleOnPowerFault()
  print('Power fault at IO-Link device OD1000')
  gTmr:stop()
end
IOLink.RemoteDevice.register(gIoLinkDevice, 'OnPowerFault', handleOnPowerFault)

-- On every expiration of the timer, the process data of IO-Link device OD1000 is read
--@handleOnExpired()
local function handleOnExpired()
  -- Reading process data
  local data,
    dataValid = gIoLinkDevice:readProcessData()
  print('Valid: ' .. dataValid .. '  Length: ' .. #data)

  -- Extracting distance value out of process data
  local distance = string.unpack('i2', data)
  print('distance: ' .. distance)
end
Timer.register(gTmr, 'OnExpired', handleOnExpired)

--End of Function and Event Scope-----------------------------------------------
