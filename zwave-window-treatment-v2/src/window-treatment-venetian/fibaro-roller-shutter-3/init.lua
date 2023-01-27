-- Copyright 2021 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--- @type st.zwave.CommandClass
local cc = (require "st.zwave.CommandClass")
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({version=1})

local FIBARO_ROLLER_SHUTTER_FINGERPRINTS = {
  {mfr = 0x010F, prod = 0x0303, model = 0x1000}, -- Fibaro Roller shutter_3 EU version
  {mfr = 0x010F, prod = 0x0303, model = 0x2000}, -- Fibaro Roller shutter_3 US version
  {mfr = 0x010F, prod = 0x0303, model = 0x3000}, -- Fibaro Roller shutter_3 AU version
}

-- configuration parameters
local CALIBRATION_CONFIGURATION = 150
local OPERATING_MODE_CONFIGURATION = 151

-- fieldnames
local CALIBRATION = "calibration"
local OPERATING_MODE = "operating_mode"

-- calibration statuses
local CLB_NOT_STARTED = "not_started"
local CLB_DONE = "done"
local CLB_PENDING = "pending"

local function can_handle_fibaro_roller_shutter_3(opts, driver, device, ...)
  for _, fingerprint in ipairs(FIBARO_ROLLER_SHUTTER_FINGERPRINTS) do
    if device:id_match( fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

local function configuration_report(driver, device, cmd)
  local parameter_number = cmd.args.parameter_number
  local configuration_value = cmd.args.configuration_value

  if parameter_number == CALIBRATION_CONFIGURATION then
    local calibration_status
    if configuration_value == 0 then
      calibration_status = CLB_NOT_STARTED
    elseif configuration_value == 1 then
      calibration_status = CLB_DONE
    elseif configuration_value == 2 then
      if device:get_field(CALIBRATION) == CLB_NOT_STARTED then
        calibration_status = CLB_PENDING
      end
    end
    device:set_field(CALIBRATION, calibration_status, {persist = true})
  elseif parameter_number == OPERATING_MODE_CONFIGURATION then
    if configuration_value == 2 then
      device:try_update_metadata({profile = "fibaro-roller-shutter-3-venetian"})
    else
      device:try_update_metadata({profile = "fibaro-roller-shutter-3"})
    end
  end
end

local function device_added(self, device)
  device:set_field(CALIBRATION, CLB_NOT_STARTED)
  device:do_refresh()
end

local fibaro_roller_shutter_3 = {
  zwave_handlers = {
    [cc.CONFIGURATION] = {
      [Configuration.REPORT] = configuration_report
    }
  },
  NAME = "fibaro roller shutter 3",
  can_handle = can_handle_fibaro_roller_shutter_3,
  lifecycle_handlers = {
    add = device_added
  }
}

return fibaro_roller_shutter_3
