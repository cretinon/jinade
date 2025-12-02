#!/bin/bash

# shellcheck source=/dev/null disable=SC2294

#
# usage: _install
#
_install_jinade() {
    _func_start "Starting jinade installation"

    local __json_file="$MY_GIT_DIR/jinade/conf/jinade.json"
    local __json
    local __name
    local __driver
    local __network
    local __gw

    if ! _fileexist "$__json_file"; then _warning "jinade configuation file not found... starting configuration process" ; _configure_jinade ; fi

    _verbose "configuration OK, resuming jinade installation"
    __json=$(cat "$__json_file")

    __name=$(_json_get_value_from_key "$__json" "network[0].no_internet_access.name")

    if _network_exist "$__name" ; then
        _verbose "network $__name skipping creation"
    else
        __driver=$(_json_get_value_from_key "$__json" "network[0].no_internet_access.driver")
        __network=$(_json_get_value_from_key "$__json" "network[0].no_internet_access.network")
        __gw=$(_json_get_value_from_key "$__json" "network[0].no_internet_access.gw")

        if ! _network_create "$__name" "$__driver" "$__network" "$__gw" ; then _error "can't create no_internet_acces network (already exist ? network overlap ?)" ; _func_end "1" ; return 1 ; fi
    fi

    __name=$(_json_get_value_from_key "$__json" "network[1].internet_access.name")

    if _network_exist "$__name" ; then
        _verbose "network $__name skipping creation"
    else
        __driver=$(_json_get_value_from_key "$__json" "network[1].internet_access.driver")
        __network=$(_json_get_value_from_key "$__json" "network[1].internet_access.network")
        __gw=$(_json_get_value_from_key "$__json" "network[1].internet_access.gw")

        if ! _network_create "$__name" "$__driver" "$__network" "$__gw" ; then _error "can't create internet_acces network (already exist ? network overlap ?)" ; _func_end "1" ; return 1 ; fi
    fi

    __name=$(_json_get_value_from_key "$__json" "network[2].vpn_access.name")

    if _network_exist "$__name" ; then
        _verbose "network $__name skipping creation"
    else
        __driver=$(_json_get_value_from_key "$__json" "network[2].vpn_access.driver")
        __network=$(_json_get_value_from_key "$__json" "network[2].vpn_access.network")
        __gw=$(_json_get_value_from_key "$__json" "network[2].vpn_access.gw")

        if ! _network_create "$__name" "$__driver" "$__network" "$__gw" ; then _error "can't create vpn_acces network (already exist ? network overlap ?)" ; _func_end "1" ; return 1 ; fi
    fi

    _success "jinade installation OK"

    _func_end "0" ; return 0 # no _shellcheck
}

_configure_jinade () {
    _func_start "Starting jinade configuration"

    local __json_file="$MY_GIT_DIR/jinade/conf/jinade.json"

    local __dns_sever
    local __domain
    local __dns

    local __network_name
    local __network_driver
    local __network_network
    local __network_gw
    local __network

    local __json="{}"

    __dns_server=$(_ask_ip "DNS IP" "192.168.2.53")
    __domain=$(_ask_string "Domain name" "intranet.local")

    __dns="{}"
    __dns=$(_json_add_key_with_value "$__dns" ""                   "server" "$__dns_server")
    __dns=$(_json_add_key_with_value "$__dns" ""                   "domain" "$__domain")

    __network_name=$(_ask_string "Network name for NO internet access" "no_internet_access")
    __network_driver=$(_ask_string " $__network_name driver" "bridge")
    __network_network=$(_ask_network " $__network_name network" "172.22.0.0/16")
    __network_gw=$(_ask_ip " $__network_name gateway" "172.22.0.1")

    __network="{}"
    __network=$(_json_add_key_with_value "$__network" ""                   "no_internet_access" "{\"name\":\"$__network_name\"}")
    __network=$(_json_add_key_with_value "$__network" "no_internet_access" "driver"             "$__network_driver")
    __network=$(_json_add_key_with_value "$__network" "no_internet_access" "network"            "$__network_network")
    __network=$(_json_add_key_with_value "$__network" "no_internet_access" "gw"                 "$__network_gw")

    __json=$(_json_add_value_in_array "$__json" "" "network"               "$__network")


    __network_name=$(_ask_string "Network name for internet access" "internet_access")
    __network_driver=$(_ask_string " $__network_name driver" "bridge")
    __network_network=$(_ask_network " $__network_name network" "172.42.0.0/16")
    __network_gw=$(_ask_ip " $__network_name gateway" "172.42.0.1")

    __network="{}"
    __network=$(_json_add_key_with_value "$__network" ""                "internet_access" "{\"name\":\"$__network_name\"}")
    __network=$(_json_add_key_with_value "$__network" "internet_access" "driver"             "$__network_driver")
    __network=$(_json_add_key_with_value "$__network" "internet_access" "network"            "$__network_network")
    __network=$(_json_add_key_with_value "$__network" "internet_access" "gw"                 "$__network_gw")

    __json=$(_json_add_value_in_array "$__json" "" "network"            "$__network")


    __network_name=$(_ask_string "Network name for vpn access" "vpn_access")
    __network_driver=$(_ask_string " $__network_name driver" "bridge")
    __network_network=$(_ask_network " $__network_name network" "172.94.0.0/16")
    __network_gw=$(_ask_ip " $__network_name gateway" "172.94.0.1")

    __network="{}"
    __network=$(_json_add_key_with_value "$__network" ""           "vpn_access" "{\"name\":\"$__network_name\"}")
    __network=$(_json_add_key_with_value "$__network" "vpn_access" "driver"             "$__network_driver")
    __network=$(_json_add_key_with_value "$__network" "vpn_access" "network"            "$__network_network")
    __network=$(_json_add_key_with_value "$__network" "vpn_access" "gw"                 "$__network_gw")

    __json=$(_json_add_value_in_array "$__json" "" "network"       "$__network")
    __json=$(_json_add_key_with_value "$__json" "" "dns"       "$__dns")

    echo "$__json" > "$__json_file"

    _func_end "0" ; return 0 # no _shellcheck
}

_installed_jinade () {
    _func_start

    local __json_file="$MY_GIT_DIR/jinade/conf/jinade.json"

    if ! _fileexist "$__json_file"; then _func_end "1" ; return 1 ; fi # no _shellcheck

    if ! _network_exist "internet_access"; then _func_end "1" ; return 1 ; fi # no _shellcheck
    if ! _network_exist "no_internet_access"; then _func_end "1" ; return 1 ; fi # no _shellcheck
    if ! _network_exist "vpn_access"; then _func_end "1" ; return 1 ; fi # no _shellcheck

    _func_end "0" ; return 0 # no _shellcheck
}

#
# usage: _install_registry
#
_install_registry() {
    _func_start "Starting registry installation"

    if ! _installed_jinade; then
        _warning "jinade not installed... starting install process"
        if ! _install_jinade ; then _error "something went wrong when installing jinade" ; _func_end "1" ; return 1; fi
    fi

    if ! _fileexist "$MY_GIT_DIR/jinade/stack/registry.yaml"; then
        if ! _configure_registry ; then _error "something went wrong in _configure_registry" ; _func_end "1" ; return 1 ; fi
    else
        _warning "registry stack configuration already exist... skipping configuration process"
    fi

    _verbose "Installing Registry"

    _volume_create "registry"

    if ! _load_conf "$MY_GIT_DIR/portainer/conf/portainer.conf"; then _error "something went wrong when loading portainer conf" ; _usage ; _func_end "1" ; return 1 ; fi
    if ! _stack_create "registry" "$MY_GIT_DIR/jinade/stack/registry.yaml" ; then _error "something went wrong with _stack_create" ; _func_end "1" ; return 1 ; fi

    _warning "can see images here: http://$INTIP:5000/v2/_catalog"

    _func_end "0" ; return 0 # no _shellcheck
}

_configure_registry () {
    _func_start "Starting registry configuration"

    local __json_file="$MY_GIT_DIR/jinade/conf/jinade.json"
    local __json
    local __return
    local __answer
    local __network
    local __volume

    local __service="registry"

    if ! _fileexist "$__json_file"; then _warning "jinade configuation file not found... starting configuration process" ; _configure_jinade ; fi

    __json=$(cat "$__json_file")
    __dns=$(_json_get_value_from_key "$__json" "dns.server")
    __return=$? ; if [ $__return != 0 ] ; then _error "something went wrong in _json_get_value_from_key" ; _func_end "$__return" ; return $__return ; fi # no _shellcheck
    __domain=$(_json_get_value_from_key "$__json" "dns.domain")
    __return=$? ; if [ $__return != 0 ] ; then _error "something went wrong in _json_get_value_from_key" ; _func_end "$__return" ; return $__return ; fi # no _shellcheck

    __cont_name=$(_ask_string "Container name" "registry")
    __host_name=$(_ask_string "Container host name" "registry")
    __volu_name=$(_ask_string "Container volume name" "registry")
    __cont_cmd=$(_ask_string "Container command" "/etc/distribution/config.yml")
    __cont_image=$(_ask_string "Container image" "registry:latest")

    __answer=$(_ask_yes_or_no "Does your container needs internet access ?" "n")

    case "$__answer" in
        y) __network="internet_access"     ; __cont_ip="172.42.0.55";;
        n) __network="no_internet_access"  ; __cont_ip="172.22.0.55" ;;
        *) _error "something's weird"      ; _func_end "1" ; return 1 ;;
    esac

    __cont_ip=$(_ask_ip "Container ip" "$__cont_ip")
    __cont_port=$(_ask_string "Container port" "5000:5000/tcp")
    __cont_expose=$(echo "$__cont_port" | cut -d: -f2)

    local __services_json="{}"
    __services_json=$(_json_add_value_in_array "$__services_json" "$__service" "entrypoint"     "/entrypoint.sh")
    __services_json=$(_json_add_value_in_array "$__services_json" "$__service" "environment"    "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
    __services_json=$(_json_add_value_in_array "$__services_json" "$__service" "environment"    "OTEL_TRACES_EXPORTER=none")
    __services_json=$(_json_add_value_in_array "$__services_json" "$__service" "environment"    "REGISTRY_LOG_LEVEL=info")
    __services_json=$(_json_add_value_in_array "$__services_json" "$__service" "volumes"        "$__volu_name:/var/lib/registry")
    __services_json=$(_json_add_key_with_value "$__services_json" "$__service" "working_dir"    "/")
    __services_json=$(_json_add_key_with_value "$__services_json" "$__service" "image"          "$__cont_image")
    __services_json=$(_json_add_key_with_value "$__services_json" "$__service" "command"        "$__cont_cmd")
    __services_json=$(_json_add_key_with_value "$__services_json" "$__service" "container_name" "$__cont_name")
    __services_json=$(_json_add_key_with_value "$__services_json" "$__service" "hostname"       "$__host_name")
    __services_json=$(_json_add_key_with_value "$__services_json" "$__service" "restart"        "always")
    __services_json=$(_json_add_key_with_value "$__services_json" "$__service.networks.$__network" "ipv4_address" "$__cont_ip")
    __services_json=$(_json_add_value_in_array "$__services_json" "$__service" "dns"            "$__dns")
    __services_json=$(_json_add_key_with_value "$__services_json" "$__service" "dns_search"     "$__domain")
    __services_json=$(_json_add_key_with_value "$__services_json" "$__service" "domainname"     "$__domain")
    __services_json=$(_json_add_value_in_array "$__services_json" "$__service" "expose"         "$__cont_expose")
    __services_json=$(_json_add_value_in_array "$__services_json" "$__service" "ports"          "$__cont_port")

    local __networks_json="{}"
    __networks_json=$(_json_add_key_with_value "$__networks_json" "$__network" "external" "true")
    __networks_json=$(_json_add_key_with_value "$__networks_json" "$__network" "name"     "$__network")

    local __volumes_json="{}"
    __volumes_json=$(_json_add_key_with_value "$__volumes_json" "$__volu_name" "external" "true")
    __volumes_json=$(_json_add_key_with_value "$__volumes_json" "$__volu_name" "name"     "$__volu_name")

    local __main_json="{}"
    __main_json=$(_json_add_key_with_value "$__main_json" "" "services" "$__services_json")
    __main_json=$(_json_add_key_with_value "$__main_json" "" "networks" "$__networks_json")
    __main_json=$(_json_add_key_with_value "$__main_json" "" "volumes"  "$__volumes_json")

    echo "$__main_json" | _json_2_yaml > "$MY_GIT_DIR/jinade/stack/registry.yaml"

    _func_end "0" ; return 0 # no _shellcheck
}

_process_lib_jinade () {
    _func_start

    eval set -- "$@"

    local __return

    while true ; do
        case "$1" in
            -- ) shift ; break ;;
            * )  shift ;;
        esac
    done

    while true ; do
        case "$1" in
            install_registry )	       _install_registry        ; __return=$? ; break ;;
            install_squid )	       _install_squid           ; __return=$? ; break ;;
            install_openvpn-client )   _install_openvpn_client  ; __return=$? ; break ;;
            install_tor-privoxy )      _install_tor_privoxy     ; __return=$? ; break ;;
            install_sonarr )	       _install_sonarr          ; __return=$? ; break ;;
            install_nzbhydra2 )	       _install_nzbhydra2       ; __return=$? ; break ;;
            install_flaresolverr )     _install_flaresolverr    ; __return=$? ; break ;;
            install_jackett )	       _install_jackett         ; __return=$? ; break ;;
            install_transmission )     _install_transmission    ; __return=$? ; break ;;
            install_sabnzbd )	       _install_sabnzbd         ; __return=$? ; break ;;
            install )	               _install_jinade          ; __return=$? ; break ;;
            -- ) shift ;;
            *)   _error "command $1 not found" ; __return=1 ; break ;;
        esac
    done

    _func_end "$__return" ; return "$__return"
}


#
# usage: _install_openvpn-client
#
_install_openvpn_client() {
    _func_start

    local __ip
    local __user
    local __pass

    _verbose "Installing openvpn-client"


    _volume_create "vpn"

    read -r -p "VPN remote IP ? " __ip
    read -r -p "VPN username ? " __user
    read -r -p "VPN password ? " __pass

    cat <<EOF > /var/lib/docker/volumes/vpn/_data/vpn.conf
client
dev tun
proto udp
remote $__ip 1198
resolv-retry infinite
keepalive 10 60
nobind
persist-key
persist-tun
tls-client
remote-cert-tls server
auth-user-pass /vpn/vpn.cert_auth
verb 1
reneg-sec 0
redirect-gateway def1
disable-occ
fast-io
ca /vpn/ca.crt
EOF

    echo "$__user" > /var/lib/docker/volumes/vpn/_data/vpn.cert_auth
    echo "$__pass" >> /var/lib/docker/volumes/vpn/_data/vpn.cert_auth

    echo "192.168.2.0/24" > /var/lib/docker/volumes/vpn/_data/.firewall

    _stack_create "openvpn-client" "$DOCKER_DIR/stack/stack.openvpn-client.yaml"

    _func_end "0" ; return 0 # no _shellcheck
}

#
# usage: _install_tor-privoxy
#
_install_tor_privoxy() {
    _func_start

    _verbose "Installing tor-privoxy"

    _network_create "internet_access" "bridge" "172.42.0.0/16" "172.42.0.1"
    _network_create "vpn_access" "bridge" "172.94.0.0/16" "172.94.0.1"
    _volume_create "tor-privoxy"

    echo "192.168.2.0/24" > /var/lib/docker/volumes/tor-privoxy/_data/.route
    echo "172.94.0.94" > /var/lib/docker/volumes/tor-privoxy/_data/.vpn
    echo "172.42.0.1" > /var/lib/docker/volumes/tor-privoxy/_data/.gw

    _stack_create "tor-privoxy" "$DOCKER_DIR/stack/stack.tor-privoxy.yaml"

    _func_end "0" ; return 0 # no _shellcheck
}

#
# usage: _install_sonarr
#
_install_sonarr() {
    _func_start

    _verbose "Installing sonarr"

    _network_create "internet_access" "bridge" "172.42.0.0/16" "172.42.0.1"
    _volume_create "sonarr"

    cat <<EOF > /var/lib/docker/volumes/sonarr/auto.mntnfs
Films        -fstype=nfs,rw   192.168.2.36:/volume1/Films
Download     -fstype=nfs,rw   192.168.2.36:/volume1/Download
EOF

    _stack_create "sonarr" "$DOCKER_DIR/stack/stack.sonarr.yaml"

    _warning "sonarr is : http://$INTIP:8989/"

    _func_end "0" ; return 0 # no _shellcheck
}

#
# usage: _install_nzbhydra2
#
_install_nzbhydra2() {
    _func_start

    _verbose "Installing nzbhydra2"

    _network_create "internet_access" "bridge" "172.42.0.0/16" "172.42.0.1"
    _network_create "vpn_access" "bridge" "172.94.0.0/16" "172.94.0.1"
    _volume_create "nzbhydra2"

    echo "192.168.2.0/24" > /var/lib/docker/volumes/nzbhydra2/_data/.route
    echo "172.94.0.94" > /var/lib/docker/volumes/nzbhydra2/_data/.vpn
    echo "172.42.0.1" > /var/lib/docker/volumes/nzbhydra2/_data/.gw

    _stack_create "nzbhydra2" "$DOCKER_DIR/stack/stack.nzbhydra2.yaml"

    _warning "nzbhydra2 is : http://$INTIP:5076/"

    _func_end "0" ; return 0 # no _shellcheck
}

#
# usage: _install_flaresolverr
#
_install_flaresolverr() {
    _func_start

    _verbose "Installing flaresolverr"

    _network_create "internet_access" "bridge" "172.42.0.0/16" "172.42.0.1"
    _network_create "vpn_access" "bridge" "172.94.0.0/16" "172.94.0.1"
    _volume_create "flaresolverr"

    echo "192.168.2.0/24" > /var/lib/docker/volumes/flaresolverr/_data/.route
    echo "172.94.0.94" > /var/lib/docker/volumes/flaresolverr/_data/.vpn
    echo "172.42.0.1" > /var/lib/docker/volumes/flaresolverr/_data/.gw

    _stack_create "flaresolverr" "$DOCKER_DIR/stack/stack.flaresolverr.yaml"

    _warning "flaresolverr is : http://$INTIP:8191/"

    _func_end "0" ; return 0 # no _shellcheck
}

#
# usage: _install_jackett
#
_install_jackett() {
    _func_start

    _verbose "Installing jackett"

    _network_create "internet_access" "bridge" "172.42.0.0/16" "172.42.0.1"
    _network_create "vpn_access" "bridge" "172.94.0.0/16" "172.94.0.1"
    _volume_create "jackett"

    echo "192.168.2.0/24" > /var/lib/docker/volumes/jackett/_data/.route
    echo "172.94.0.94" > /var/lib/docker/volumes/jackett/_data/.vpn
    echo "172.42.0.1" > /var/lib/docker/volumes/jackett/_data/.gw

    _stack_create "jackett" "$DOCKER_DIR/stack/stack.jackett.yaml"

    _warning "jackett is : http://$INTIP:9117/"

    _func_end "0" ; return 0 # no _shellcheck
}

#
# usage: _install_transmission
#
_install_transmission() {
    _func_start

    _verbose "Installing transmission"

    _network_create "internet_access" "bridge" "172.42.0.0/16" "172.42.0.1"
    _network_create "vpn_access" "bridge" "172.94.0.0/16" "172.94.0.1"
    _volume_create "transmission"

    echo "192.168.2.0/24" > /var/lib/docker/volumes/transmission/_data/.route
    echo "172.94.0.94" > /var/lib/docker/volumes/transmission/_data/.vpn
    echo "172.42.0.1" > /var/lib/docker/volumes/transmission/_data/.gw

    _stack_create "transmission" "$DOCKER_DIR/stack/stack.transmission.yaml"

    _warning "transmission is : http://$INTIP:9091/"

    _func_end "0" ; return 0 # no _shellcheck
}

#
# usage: _install_sabnzbd
#
_install_sabnzbd() {
    _func_start

    _verbose "Installing sabnzbd"

    _network_create "internet_access" "bridge" "172.42.0.0/16" "172.42.0.1"
    _network_create "vpn_access" "bridge" "172.94.0.0/16" "172.94.0.1"
    _volume_create "sabnzbd"

    echo "192.168.2.0/24" > /var/lib/docker/volumes/sabnzbd/_data/.route
    echo "172.94.0.94" > /var/lib/docker/volumes/sabnzbd/_data/.vpn
    echo "172.42.0.1" > /var/lib/docker/volumes/sabnzbd/_data/.gw

    _stack_create "sabnzbd" "$DOCKER_DIR/stack/stack.sabnzbd.yaml"

    _warning "sabnzbd is : http://$INTIP:8080/"

    _func_end "0" ; return 0 # no _shellcheck
}

#
# usage: _install_squid
#
_install_squid() {
    _func_start

    _verbose "Installing Squid"

    _network_create "internet_access" "bridge" "172.42.0.0/16" "172.42.0.1"
    _stack_create "squid" "$DOCKER_DIR/stack/stack.squid.yaml"

    _warning "your proxy is now: http://$INTIP:3128/"

    _func_end "0" ; return 0 # no _shellcheck
}
