local M = {}

function M.insert_timestamp()
    -- Format: 2025-07-15T00:00:00+09:00
  -- The %:z format specifier is a GNU extension and may not be available on all systems.
  -- We will calculate the timezone offset manually for better portability.
  local now = os.time()
  local timestamp_part = os.date("%Y-%m-%dT%H:%M:%S", now)
                                                                                          
  local local_t = os.date("*t", now)
  local utc_t = os.date("!*t", now)
  local offset_seconds = os.time(local_t) - os.time(utc_t)
                                                                                          
  local sign = offset_seconds >= 0 and "+" or "-"
  local offset_abs = math.abs(offset_seconds)
  local offset_hours = string.format("%02d", math.floor(offset_abs / 3600))
  local offset_minutes = string.format("%02d", math.floor((offset_abs % 3600) / 60))
  local tz_offset = sign .. offset_hours .. ":" .. offset_minutes
                                                                                          
  local timestamp = "## " .. timestamp_part .. tz_offset
  vim.api.nvim_put({ timestamp }, "c", true, true)
end

return M
