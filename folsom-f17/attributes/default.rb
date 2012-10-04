# mysql setting
default[:mysql][:listening_ip]    = "192.168.128.31"
default[:mysql][:access_network]  = "192.168.128.%"
default[:mysql][:pass][:keystone] = "keystone"
default[:mysql][:pass][:glance]   = "glance"
default[:mysql][:pass][:nova]     = "nova"
default[:mysql][:pass][:cinder]   = "cinder"
default[:mysql][:pass][:horizon]  = "horizon"
default[:mysql][:pass][:quantum]  = "quantum"

# keystone access endpoint
default[:keystone][:identity_api_address][:publicURL]   = "localhost"
default[:keystone][:identity_api_address][:adminURL]    = "localhost"
default[:keystone][:identity_api_address][:internalURL] = "localhost"
default[:keystone][:comupte_api_address][:publicURL]    = "localhost"
default[:keystone][:comupte_api_address][:adminURL]     = "localhost"
default[:keystone][:comupte_api_address][:internalURL]  = "localhost"
default[:keystone][:ec2_api_address][:publicURL]        = "localhost"
default[:keystone][:ec2_api_address][:adminURL]         = "localhost"
default[:keystone][:ec2_api_address][:internalURL]      = "localhost"
default[:keystone][:cinder_api_address][:publicURL]     = "localhost"
default[:keystone][:cinder_api_address][:adminURL]      = "localhost"
default[:keystone][:cinder_api_address][:internalURL]   = "localhost"
default[:keystone][:glance_api_address][:publicURL]     = "localhost"
default[:keystone][:glance_api_address][:adminURL]      = "localhost"
default[:keystone][:glance_api_address][:internalURL]   = "localhost"
default[:keystone][:quantum_api_address][:publicURL]    = "localhost"
default[:keystone][:quantum_api_address][:adminURL]     = "localhost"
default[:keystone][:quantum_api_address][:internalURL]  = "localhost"
default[:keystone][:swift_api_address][:publicURL]      = "localhost"
default[:keystone][:swift_api_address][:adminURL]       = "localhost"
default[:keystone][:swift_api_address][:internalURL]    = "localhost"
default[:keystone][:swift_api_address][:port]           = "8080"

# keystone password
default[:keystone][:password][:admin]   = "password"
default[:keystone][:password][:service] = "password"
default[:keystone][:password][:demo]    = "password"

# swift
default[:swift][:data_image_path]  = "/images"   # this dir need 11GB+
default[:swift][:device_mount_dir] = "/swift"
default[:swift][:hash_str]         = "swift-12345"
