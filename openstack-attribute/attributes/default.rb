# mysql setting
default[:mysql][:access_network]  = "192.168.128.%"
default[:mysql][:listening_ip]    = "192.168.128.50"

default[:mysql][:pass][:keystone] = "keystone"
default[:mysql][:pass][:glance]   = "glance"
default[:mysql][:pass][:nova]     = "nova"
default[:mysql][:pass][:cinder]   = "cinder"
default[:mysql][:pass][:quantum]  = "quantum"


# qpid
default[:qpid][:listening_ip] = "192.168.128.50"


# keystone access endpoint
default[:keystone][:identity_api_address][:publicURL]   = "172.26.0.51"
default[:keystone][:identity_api_address][:adminURL]    = "192.168.128.51"
default[:keystone][:identity_api_address][:internalURL] = "192.168.128.51"

default[:keystone][:comupte_api_address][:publicURL]    = "172.26.0.51"
default[:keystone][:comupte_api_address][:adminURL]     = "192.168.128.51"
default[:keystone][:comupte_api_address][:internalURL]  = "192.168.128.51"

default[:keystone][:ec2_api_address][:publicURL]        = "172.26.0.51"
default[:keystone][:ec2_api_address][:adminURL]         = "192.168.128.51"
default[:keystone][:ec2_api_address][:internalURL]      = "192.168.128.51"

default[:keystone][:cinder_api_address][:publicURL]     = "172.26.0.51"
default[:keystone][:cinder_api_address][:adminURL]      = "192.168.128.51"
default[:keystone][:cinder_api_address][:internalURL]   = "192.168.128.51"

default[:keystone][:glance_api_address][:publicURL]     = "172.26.0.51"
default[:keystone][:glance_api_address][:adminURL]      = "192.168.128.51"
default[:keystone][:glance_api_address][:internalURL]   = "192.168.128.51"

default[:keystone][:quantum_api_address][:publicURL]    = "172.26.0.51"
default[:keystone][:quantum_api_address][:adminURL]     = "192.168.128.51"
default[:keystone][:quantum_api_address][:internalURL]  = "192.168.128.51"

default[:keystone][:swift_api_address][:publicURL]      = "172.26.0.51"
default[:keystone][:swift_api_address][:adminURL]       = "192.168.128.51"
default[:keystone][:swift_api_address][:internalURL]    = "192.168.128.51"
default[:keystone][:swift_api_address][:port]           = "8080"


# keystone admin token
default[:keystone][:admin_token]    = "ADMINTOKEN"


# keystone user & password

default[:keystone][:user][:admin][:name]   = "admin"
default[:keystone][:user][:admin][:pass]   = "admin"
default[:keystone][:user][:nova][:name]    = "nova"
default[:keystone][:user][:nova][:pass]    = "nova"
default[:keystone][:user][:glance][:name]  = "glance"
default[:keystone][:user][:glance][:pass]  = "glance"
default[:keystone][:user][:swift][:name]   = "swift"
default[:keystone][:user][:swift][:pass]   = "swift"
default[:keystone][:user][:cinder][:name]  = "cinder"
default[:keystone][:user][:cinder][:pass]  = "cinder"
default[:keystone][:user][:quantum][:name] = "quantum"
default[:keystone][:user][:quantum][:pass] = "quantum"
default[:keystone][:user][:demo][:name]    = "demo"
default[:keystone][:user][:demo][:pass]    = "demo"

default[:keystone][:tenant][:admin][:name]   = "admin"
default[:keystone][:tenant][:service][:name] = "service"
default[:keystone][:tenant][:demo][:name]    = "demo"


# glance
default[:glance][:store_type] = "file"
default[:glance][:reg_host]   = "192.168.128.51"
