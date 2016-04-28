#!/usr/bin/env bash

function _install_mod_shib {
    if is_ubuntu; then
        install_package libapache2-mod-shib2
        sudo a2enmod shib2
        #TODO(breton): do we really need ssl here?
        sudo a2enmod ssl
    else
        exit_distro_not_supported "apache installation"
    fi
}

function install_federation {
    _install_mod_shib
}

function configure_keystone_federation {
    local here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local keystone_apache_conf=$(apache_site_config_for keystone)

    # insert our Apache federation snippet into the Apache config
    sudo sed -e "0,/<\/VirtualHost>/ {
        /<\/VirtualHost>/ {
            h
            r $here/files/apache-keystone-federation.template
            g
            N
        }
    }" -i $keystone_apache_conf

    # add the federation auth methods
    sudo sed -e "
        /^#methods/s/#\(.*\)$/\1,saml2/
    " -i $KEYSTONE_CONF

    # copy our mod_shib config file into place
    sudo cp $here/files/shibboleth2.xml /etc/shibboleth/

    # generate keys for mod_shib if they don't exist
    # XXX: lets not care about the keys yet
    # if [[ ! -e "/etc/shibboleth/sp-key.pem" ]]; then
    #     sudo shib-keygen -y 10
    # fi
}

function init_federation {
    python $FILES/key-federation-setup.py
}

if is_service_enabled key; then
    if [[ "$1" == "stack" && "$2" == "install" ]]; then
        echo_summary "Configuring keystone for federation"
        install_federation
        configure_keystone_federation
    elif [[ "$1" == "stack" && "$2" == "install" ]]; then
        echo_summary "Initializing Keystone Federation"
        init_federation
    fi
fi
