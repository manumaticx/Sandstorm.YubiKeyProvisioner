#!/usr/bin/env bash
set -e

green_echo() {
  printf "\033[0;32m${1}\033[0m\n"
}

green_echo "STEP 1: installing/upgrading opensc"
# The OpenSSH PKCS11 smartcard integration will not work from High Sierra
# onwards. If you need this functionality, unlink this formula, then install
# the OpenSC cask. (https://formulae.brew.sh/formula/opensc)
brew unlink opensc || true
brew reinstall homebrew/cask/opensc
# Disable SmartCard UI otherwise we will get a pairing notification every time we
# insert a YubiKey
currentUser=`who | grep "console" | cut -d" " -f1`
sudo su - "$currentUser" -c "/usr/sbin/sc_auth pairing_ui -s disable"

green_echo "STEP 2: installing/updating YubiKey management tools"
rm '/usr/local/lib/libykcs11.dylib' || true
brew reinstall ykman
brew reinstall yubico-piv-tool && echo "Installed PIV tool" || echo "Failed to install PIV tool"
brew link --overwrite yubico-piv-tool || true

echo ""
green_echo "STEP 3: removing yubikey-agent"
brew services stop yubikey-agent &> /dev/null && echo "Service was stopped" || echo "No service to be stopped"
# we make sure to uninstall the old fork here or an older version
brew uninstall yubikey-agent &> /dev/null && echo "Agent was uninstalled" || echo "Nothing to uninstall"

# Currently still using the fork until the formula is updated
# As most people are using `sandstorm/tap` for the sku-tools. We changed the name
# of the yubikey-agent fork to yubikey-agent-sandstorm as all formulas will be present
# and brew would otherwise fail installing the original yubikey-agent.
brew install sandstorm/tap/yubikey-agent-sandstorm

green_echo "STEP 4: installing yubikey-agent sandstorm fork"
# brew tap filippo.io/yubikey-agent https://filippo.io/yubikey-agent &> /dev/null && echo "filippo.io/yubikey-agent was taped" || echo "Nothing to tap"
# brew install yubikey-agent &> /dev/null && echo "Agent was reinstalled" || echo "Reinstall failed"
echo ""
brew services start yubikey-agent-sandstorm
