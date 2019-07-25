#!/bin/sh
set -e

function print_error() {
  read -r -r line file <<<"$(caller)"
  echo "An error occurred in line $line of file $file:" >&2
  sed "${line}q;d" "$file" >&2
}

connected() {
  if [ "$STATE" == "Connected" ]; then
    echo -e "\e[96malready connected."
    echo -e "\e[96mwe dont need to connect,"
    echo -e "\e[0mdo you want to reconnect? [Y/n]"
    read -r yn
    if [ "$yn" == "y" ]; then
      echo "starting reconnect"
      expressvpn disconnect
      echo -e "\e[92mWaiting 7s for network.."
      sleep 7
      echo -e "\e[0mreconnecting..."
      expressvpn connect
      echo -e "\e[92mSuccessfully reconnected. Thanks for using my script."
      IP=$(curl -s http://whatismyip.akamai.com/)
      echo -e "\e[0mnew ip adresss is: $IP"
    else
      if [ $"yn" == "n" ]; then
        echo -e "\e[0mdo Disconnect now? [Y/n]"
        read -r DCYN
        if [ "$DCYN" == "Y" ]; then
          expressvpn disconnect
        else
          echo -e "\e[0mThere is nothing to do"
          exit
        fi
      fi
      if [ "$yn" == "" ]; then
        echo "starting reconnect"
        expressvpn disconnect
        echo -e "\e[92mWaiting 7s for network.."
        sleep 7
        echo -e "\e[0mreconnecting..."
        expressvpn connect
        echo -e "\e[92mSuccessfully reconnected. Thanks for using my script."
        IP=$(curl -s http://whatismyip.akamai.com/)
        echo -e "\e[0mnew ip adresss is: $IP"
      fi
    fi
    exit
  fi
}

echo -e

# Section 2, if not connected
notconnected() {
  if [ "$STATE" == "Not Connected" ]; then
    echo -e "\e[1:33mYoure not connected.\nDo you want to connect now?\e[0m"
    read -r yn
    if [ "$yn" == "y" ]; then
      echo -e "\e[96mconnecting.."
      expressvpn connect
    elif [[ $yn == "n" ]]; then
      #statements
      echo -e '\e[1:33mThen, heres nothing else to do. Bye!\e[0m'
      exit
    else
      echo -e "\e[31mERROR - Invalid input. Try again.."
      echo -e "Press any key..\e[0m"
      read -r -n 1
      clear
      notconnected
    fi
  fi
  exit
}
# Installl expressvpn from arch/AUR
install_evpn_arch() {
  clear
  sudo pacman -Syu
  sudo pacman -S yay
  yay -Syyuu
  yay -S expressvpn
}

install_evpn_ubuntu() {
  sudo apt update
  sudo apt upgrade
  #  cd ~/
  #  wget https://download.expressvpn.xyz/clients/linux/expressvpn_2.1.0-1_amd64.deb
  sudo apt install ./expressvpn.deb -y
  #  sudo rm -r ./expressvpn*.deb
  echo -e "\e[92msuccessfully installed expressvpn"
  echo -e "Please insert your activationcode from expressvpn\e[0m"
  expressvpn activate
}

# Check if expressvpn is installed
chkdep() {
  clear
  echo "checking dependencies.."
  if ! [ -x "$(command -v expressvpn)" ]; then
    echo -e "\e[31mCritical Error. Expressvpn not installed. Do you want to install it now? [yes/no]\e[0m"
    read -r -n 3 yn
    if [ "$yn" == "yes" ]; then
      # Install for arch
      if [ -x "$(command -v pacman)" ]; then
        install_evpn_arch
      elif [[ -x "$(command -v apt)" ]]; then
        install_evpn_ubuntu
      else
        echo "cant continue without installing expressvpn."
        exit
      fi
      clear
      chkdep
    elif [ $"[yes/no]" = "no" ]; then
      exit
    fi
  else
    echo "expressvpn seems to been installed. Continuing script in 2s.."
    sleep 2
    chkconn
  fi
}

# Check connection State
chkconn() {
  STATE=$(expressvpn status | head -n 1 | awk '{print $1}')

  if [ "$STATE" == "[1;32;49mConnected" ]; then
    STATE="Connected"
    connected
  else
    STATE="Not Connected"
    notconnected
  fi

  echo -e "actually your connection state is: $STATE\e[0m"
}

chkdep
trap print_error ERR
