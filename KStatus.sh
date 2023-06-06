#!/bin/bash
YEL=$'\e[1;33m'     # Yellow
RED=$'\033[0;31m'   # Red
NC=$'\033[0m'       # No Color
PRPL=$'\033[1;35m'  # Purple
GRN=$'\e[1;32m'     # Green
BLUE=$'\e[3;49;34m' # Blue

#script logo with copyrights
printf "${BLUE}\n"
echo "██╗  ██╗███████╗████████╗ █████╗ ████████╗██╗   ██╗███████╗"
echo "██║ ██╔╝██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║   ██║██╔════╝"
echo "█████╔╝ ███████╗   ██║   ███████║   ██║   ██║   ██║███████╗"
echo "██╔═██╗ ╚════██║   ██║   ██╔══██║   ██║   ██║   ██║╚════██║"
echo "██║  ██╗███████║   ██║   ██║  ██║   ██║   ╚██████╔╝███████║"
echo "╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝"
printf "\nPowered by KeepSec Technologies Inc.™\n"
printf "${NC}\n"

#check if root or not
if [ $(id -u) -ne 0 ]; then
  printf "${RED}\nThis script can only be executed as root\n\n${NC}"
  sleep 0.5
  exit
fi
sleep 1
printf "\n"

#make directories and variables for it
mkdir /etc/KStatus &>/dev/null
mkdir /etc/KStatus/logs &>/dev/null
mkdir /etc/KStatus/configs &>/dev/null
dirConf="/etc/KStatus/configs"
dirLogs="/etc/KStatus/logs"

#variables for number of questions
num=1

#variables of quotes to output secondary scripts well
sqt="'"
dqt='"'

#where configs are localted
config=($dirConf/KStatus-*)

#function to ask if you want to delete previous configs
function delConf {
  read -n 1 -p "${YEL}Delete${NC} previous KSatus configurations? (Y/N) " ynDEL
  printf "\n\nThose configurations will be ${RED}deleted${NC}:\n\n"
  ls -A1 $dirConf | awk -F 'KStatus-|-job' {'print $2'}
  case $ynDEL in
  [yY])
    printf "\n"
    read -n 1 -p "${RED}Are you ${RED}sure?${NC} (Y/N) " ynDEL2
    printf "\n"
    ;;
  [nN])
    printf "\n"
    ;;
  *)
    printf "${RED}\n\nAnswer 'Y' or 'N', try again\n\n${NC}"
    sleep 0.5
    delConf
    ;;
  esac
  case $ynDEL2 in
  [yY])
    printf "\n"
    ;;
  [nN])
    printf "\n"
    delConf
    ;;
  *)
    printf "${RED}\nAnswer 'Y' or 'N', try again\n\n${NC}"
    sleep 0.5
    delConf
    ;;
  esac
}
#function to ask frequence of checking the hosts (min 1 minute, max 60 minutes)
function askFreq {
  read -n 2 -p "How often in ${YEL}minutes${NC} do you want the cron job to run (1-60) : " cron
  case $cron in
  *)
    if [[ $cron -gt 0 && $cron -lt 61 ]]; then
      printf "\n"
    else
      printf "${RED}\nOnly numbers between 1 and 60, try again\n\n${NC}"
      sleep 0.5
      askFreq
    fi
    ;;
  esac
}
#function to ask for another monitor or not
function askMonit {
  read -n 1 -p "Do you want another service (${YEL}${num}${NC})? (Y/N) " yn
  case $yn in
  [yY])
    printf "\n\n"
    ;;
  [nN])
    printf "\n\n"
    return 1
    ;;
  *)
    printf "${RED}\nAnswer 'Y' or 'N', try again\n\n${NC}"
    sleep 0.5
    askMonit
    ;;
  esac
}

#check to see if configuration already present and run delConf function if it is
if [ -f "${config[0]}" ]; then
  delConf
  if [[ $ynDEL2 == Y || $ynDEL2 == y ]]; then
    rm -f /etc/cron.d/KStatus-*
    rm -f $dirConf/KStatus-*
  fi
fi
#start of series of questions
askFreq
#email address to receive the notifs
read -p "What is the ${YEL}email${NC} address that you want to receive your notifications : " to
echo""
#internet domain pointing to your server to send emails
read -p "What is the ${YEL}domain${NC} that will be used to send emails : " domain
echo""
printf "${GRN}Assure yourself that the domain is pointing to the IP of your server with preferably a SPF/DMARC${NC}\n"
echo""
sleep 1
#loop for infinite questions to add as many services as you want
while :; do
  read -p "What is the (${YEL}${num}${NC}) service you want notifications for : " statusloop
  echo""
  echo -e "#!/bin/bash
  HOST=\$(hostname)
  subject=${dqt}SERVICE DOWN: $statusloop | \$HOST ${dqt}
  status=${dqt}\$(sudo systemctl show $statusloop --no-page)${dqt}
  status_text=\$(echo ${dqt}\${status}${dqt} | grep 'ActiveState=' | cut -f2 -d=)
  if [[ ${dqt}\${status_text}${dqt} == ${dqt}inactive${dqt} ]]; then
  printf ${dqt}The service ${sqt}$statusloop${sqt} is currently down for \$HOST!\n\n Please check it out as soon as possible.${dqt} | mail -r ${dqt}notification${dqt} -s ${dqt}\$subject${dqt} ${dqt}$to${dqt}
  fi" >$dirConf/KStatus-$statusloop-job.sh
  croncmd="root /usr/bin/bash $dirConf/KStatus-$statusloop-job.sh >> $dirLogs/KStatus-$statusloop.log"
  cronjob="*/$cron * * * * $croncmd"

  printf "$cronjob\n" >"/etc/cron.d/KStatus-$statusloop-job"
  num=$((num + 1))
  askMonit || break
done

#function for the installing wheel
function installing {
  tput civis
  spinner="⣾⣽⣻⢿⡿⣟⣯⣷"
  while :; do
    for i in $(seq 0 7); do
      printf "${PRPL}${spinner:$i:1}"
      printf "\010${NC}"
      sleep 0.2
    done
  done
}

#executes function above
installing &
SPIN_PID=$!
disown
printf "${PRPL}\nInstalling utilities ➜ ${NC}"

#add notification user
sudo adduser --disabled-password --gecos "" notification &>/dev/null

#checks package manager and then install postfix with your right package manager + puts the right configuration in the config file for you if you don't already have postfix installed
if [ -n "$(command -v apt-get)" ] && [ -z "$(command -v postfix)" ]; then
  sudo apt-get -y install postfix >/dev/null
  sudo echo "postfix postfix/mailname string $domain" | debconf-set-selections
  sudo echo "postfix postfix/protocols select  all" | debconf-set-selections
  sudo echo "postfix postfix/mynetworks string  127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" | debconf-set-selections
  sudo echo "postfix postfix/mailbox_limit string  0" | debconf-set-selections
  sudo echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
  sudo echo "postfix postfix/compat_conversion_warning   boolean true" | debconf-set-selections
  sudo echo "postfix postfix/protocols select all" | debconf-set-selections
  sudo echo "postfix postfix/procmail boolean false" | debconf-set-selections
  sudo echo "postfix postfix/relayhost string" | debconf-set-selections
  sudo echo "postfix postfix/chattr boolean false" | debconf-set-selections
  sudo echo "postfix postfix/destinations string $domain" | debconf-set-selections
elif [ -n "$(command -v yum)" ] && [ -z "$(command -v postfix)" ]; then
  sudo yum install -y postfix >/dev/null
  sudo sed -i -e "s/inet_interfaces = localhost/inet_interfaces = all/g" /etc/postfix/main.cf &>/dev/null
  sudo sed -i -e "s/#mydomain =.*/mydomain = $domain/g" /etc/postfix/main.cf &>/dev/null
  sudo sed -i -e "s/#mynetworks =.*/mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128/g" /etc/postfix/main.cf &>/dev/null
  sudo sed -i -e "s/mydestination =.*/mydestination = mail."'$mydomain'", "'$mydomain'"/g" /etc/postfix/main.cf &>/dev/null
  sudo sed -i -e "117d" /etc/postfix/main.cf &>/dev/null
fi

#install mailx a CLI tool to send emails
if [ -n "$(command -v apt-get)" ]; then
  sudo apt-get -y install bsd-mailx >/dev/null
elif [ -n "$(command -v yum)" ]; then
  sudo yum install -y mailx >/dev/null
fi

#enable postfix mail services
sudo systemctl enable postfix &>/dev/null
sudo systemctl start postfix &>/dev/null
sudo systemctl reload postfix &>/dev/null

#kills spinning wheel
kill -9 $SPIN_PID &>/dev/null
tput cnorm
echo ""
#bye bye message :)
printf "${GRN}\n\nWe're done!${NC}"
echo ""

exit 1
