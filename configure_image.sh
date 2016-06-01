#!/bin/bash

# This sets up clockers on a Raspbian Jessie (Lite) image.

if [ -z "$1" ]; then
  echo "Need destination root"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f image_settings.sh ]; then
  source image_settings.sh
else
  echo -n "Name of device (eg. clockers, clockbot, myclock, clock): "
  read NAME
  echo "NAME=$NAME" >> image_settings.sh

  echo -n "WiFi SSID: "
  read WIFI_SSID
  echo "WIFI_SSID=$WIFI_SSID" >> image_settings.sh

  echo -n "WiFi PSK: "
  read WIFI_PSK
  echo "WIFI_PSK=$WIFI_PSK" >> image_settings.sh

  echo -n "Ngrok binary (if you want ngrok installed): "
  read NGROK_BIN
  echo "NGROK_BIN=$NGROK_BIN" >> image_settings.sh

  echo -n "Ngrok host: "
  read NGROK_HOST
  echo "NGROK_HOST=$NGROK_HOST" >> image_settings.sh

  echo -n "Ngrok ssh port: "
  read NGROK_PORT
  echo "NGROK_PORT=$NGROK_PORT" >> image_settings.sh

  echo "Thanks! Wrote image_settings.sh"
fi

cat >$1/home/pi/bootstrap.sh <<EOL
#!/bin/bash

# This should be run when the system is connected to the internet

apt-get update -y && apt-get upgrade -y

EOL
chmod 755 $1/home/pi/bootstrap.sh

echo -n "Setting hostname to ${2}.. "
echo $2 > $1/etc/hostname
sed -i "s/raspberrypi/${2}/" $1/etc/hosts
echo "Done."

echo -n "Configuring Avahi.. "
SERVICEPATH=/etc/avahi/services/multiple.service
cat >$1/etc/avahi/services/multiple.service <<EOL
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
                <type>_device-info._tcp</type>
                <port>0</port>
                <txt-record>model=RackMac</txt-record>
        </service>
        <service>
                <type>_ssh._tcp</type>
                <port>22</port>
        </service>
</service-group>
EOL
echo "Done."

if [ -z "$WIFI_SSID" -o -z "$WIFI_PSK" ]; then
  echo "No wifi configured.."
else
  echo -n "Configuring wifi.. "
  cat >$1/etc/wpa_supplicant/wpa_supplicant.conf <<EOL
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
  ssid="$WIFI_SSID"
  psk="$WIFI_PSK"
}
EOL
  echo "Done."
fi

echo -n "Installing node.. "
NODE=https://nodejs.org/dist/v6.5.0/node-v6.5.0-linux-armv6l.tar.xz
NODEPATH=$1/opt/node

mkdir -p $NODEPATH
curl -s $NODE | tar Jx -C $NODEPATH --strip-components=1
cat >$1/etc/profile.d/nodepath.sh <<EOL
export PATH="/opt/node/bin:\$PATH"
EOL

cat $1/etc/profile.d/nodepath.sh >>  $1/home/pi/bootstrap.sh

echo "Done."

echo -n "Installing clockers.. "
cp -a $DIR/server $1/home/pi/clockers
echo >> $1/etc/rc.local
echo "/home/pi/clockers/daemon_start.sh &" >> $1/etc/rc.local

# bootstrap
echo "cd /home/pi/clockers" >> $1/home/pi/bootstrap.sh
echo "apt-get install -y wiringpi" >> $1/home/pi/bootstrap.sh
echo "npm update" >> $1/home/pi/bootstrap.sh
echo "make clean && make" >> $1/home/pi/bootstrap.sh

echo "Done."

echo -n "Installing raspberry-wifi-conf.. "
cat >$1/home/pi/rpi-wifi-conf.sh <<EOL
export PATH=/opt/node/bin:\$PATH

cd /home/pi/raspberry-wifi-conf

npm start &> /var/log/rpi-wifi-conf.log
EOL
chmod 755 $1/home/pi/rpi-wifi-conf.sh

git clone https://github.com/eeejay/raspberry-wifi-conf.git $1/home/pi/raspberry-wifi-conf
sed -i "s/rpi-config-ap/${2}-ap/" $1/home/pi/raspberry-wifi-conf/config.json

echo "/home/pi/rpi-wifi-conf.sh &" >> $1/etc/rc.local

# bootstrap
echo "cd /home/pi/raspberry-wifi-conf" >> $1/home/pi/bootstrap.sh
echo "npm update" >> $1/home/pi/bootstrap.sh
echo "npm install bower" >> $1/home/pi/bootstrap.sh
echo "apt-get install -y git" >> $1/home/pi/bootstrap.sh
echo "./node_modules/.bin/bower --allow-root install" >> $1/home/pi/bootstrap.sh
echo "npm run-script provision" >> $1/home/pi/bootstrap.sh

echo "Done."

if [ -z "$NGROK_BIN" -o -z "$NGROK_HOST" -o -z "$NGROK_PORT" ]; then
  echo "ngrok not configured"
else
  echo -n "Installing ngrok.. "
  cp $NGROK_BIN $1/home/pi/ngrok || echo failed to copy $NGROK_BIN
  cat >$1/home/pi/ngrok.cfg <<EOL
server_addr: $NGROK_HOST:4443
trust_host_root_certs: false
tunnels:
  webapp:
    proto:
      http: 3000
    subdomain: $2
    inspect: false
  ssh:
    proto:
      tcp: 22
    remote_port: $NGROK_PORT
EOL

  echo "/home/pi/ngrok -log=stdout -config=/home/pi/ngrok.cfg start webapp ssh > /var/log/ngrok.log &" >> $1/etc/rc.local
  echo "Done"
fi

sed -i "s/exit 0//" $1/etc/rc.local
echo >> $1/etc/rc.local
echo "exit 0" >> $1/etc/rc.local

echo "= All done. ="
echo "Run the bootstrap.sh script as root on first boot of the pi."
echo "If you want to use the wifi configuration interface, make sure you remove"
echo "the 'network' field in wpa_supplicant.conf"
