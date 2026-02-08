local launch = {}

local thread = require("thread")
local event = require("event")

local smart_require = require("util.smart_require")
local smart_event = smart_require.reload("util.smart_event")

local main_thread_finished_event = "main_thread_finished"

function launch.launch(func, onExit)
    local t = thread.create(function()
            local threadOk, threadErr = pcall(func)
            event.push(main_thread_finished_event, threadOk, threadErr)
        end
    )

    while true do
        local eventName, threadOk, threadErr = event.pullMultiple(
                    main_thread_finished_event, smart_event.event_listener_event_type, smart_event.main_thread_interrupted, "interrupted")

        if eventName == smart_event.event_listener_event_type then
            smart_event.drain()
        else
            t:kill()
            smart_event.unregister()
            onExit()
            if eventName == "interrupted" then
                if threadErr then
                    error(threadErr)
                end
            end
            if not threadOk then
                error(threadErr)
            end
            break
        end
    end
end

return launch
