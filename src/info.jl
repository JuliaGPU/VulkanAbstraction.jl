print_info(message, info) = println(join([message, string.(info)...], "\n    "))

function print_app_info()
    print_info("Available instance layers:", enumerate_instance_layer_properties())
    print_info("Available extensions:", enumerate_instance_extension_properties())
end

function print_devices(instance::InstanceSetup)
    pdevices = print_available_devices(instance)
    print_device_info.(pdevices)
end

function print_available_devices(instance::InstanceSetup)
    pdevices = enumerate_physical_devices(instance)
    print_info("Available devices:", get_physical_device_properties.(pdevices))
    pdevices
end

function print_device_info(physical_device)
    print_info("Available device layers:", enumerate_device_layer_properties(physical_device))
    print_info("Available device extensions:", enumerate_device_extension_properties(physical_device))
end