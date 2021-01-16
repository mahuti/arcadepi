Anyone that comes across this: Please note, I wrote this for myself to keep track of all the stuff I need to do when setting up a new Pi or running into problems. It's more of a reference than a walk-through. The first part is a bit of a walk-through, but later sections are useful on a more ad-hoc basis. Some of the information gets out of date now and then, but I keep updating this as I go, so there's a lot of useful information here.         

# Modifications
Plug pi into HDMI & keyboard first before anything else can be done.
To initialize attractmode, you must launch it locally (not over ssh) after installing ($ attract) 

1. Network Setup
2. Boot/config.txt Modifications
3. Installations
4. Transfer and Create Files
5. Look and Feel 
6. Setup optional hardware
7. Joystick testing and calibration
8. Machine specific configurations
9. Index of Commands
10. Optional Software
11. mame tips
12. Troubleshooting

## BEFORE DOING ANYTHING ELSE: 

Change the keyboard configuration otherwise, the pound, tilde and other keys will be weird UK layout

    sudo dpkg-reconfigure keyboard-configuration

or this can be changed via localisation options sudo raspi-config


------------------------------------------------------------------
## 1. Network Setup
------------------------------------------------------------------

### Enable SSH 
Before being able to login to the Pi remotely, you'll have to set up SSH. Once SSH is set up, you can connect remotely via ethernet, or Wifi. 

Use `sudo raspi-config` to set up SSH 
interfacing options >> SSH >> Enable >> reboot your pi

[See article](https://retropie.org.uk/docs/SSH/) for more details

### Configure Wifi
	sudo sh /home/pi/RetroPie-Setup/retropie_setup.sh

### Find IP Address
Once on wifi or ethrnet, the IP address is needed to connect remotely
in the PI's terminal type `ifconfig` and look at `wlan0 > inet` addr

### Change hostname 
Change the host name via an interface, or manually
`sudo raspi-config` to change the hostname via interface 
`sudo pico /etc/hostname` edit hostname file directly

### Install SSHPASS
Install sshpass so that you can run multiple rsync operations without inputting password every time. 

	sudo apt-get install sshpass

Create a password file

	cd /home/pi
	pico sync_pass #add password
	chmod 600 sync_pass


### Test SSH Login
once you have the IP address you can connect from another computer using: 
`ssh pi@[192.168.1.117 etc]` then use *raspberry* as the password


### Install Samba (file sharing)
 
1. `sudo sh /home/pi/RetroPie-Setup/retropie_setup.sh`
2. Go to configuration / tools > samba
3. Install RetroPie Samba shares
4. Manually edit /etc/samba/smb.conf to show new directories when accessing on the network

add the following shares

	[root]
	comment = root
	path = "/"
	writeable = yes
	guest ok = yes
	create mask = 0644
	directory mask = 0755
	force user = pi
	
    [home]
	comment = home
	path = "/home/pi"
	writeable = yes
	guest ok = yes
	create mask = 0644
	directory mask = 0755
	force user = pi
    
	[attractmode]
	comment = attractmode
	path = "/home/pi/.attract"
	writeable = yes
	guest ok = yes
	create mask = 0644
	directory mask = 0755
	force user = pi

------------------------------------------------------------------
#### Install daemon to access pi via hostname

Set up zeroconf to access via ssh pi@hostname.local
	
	sudo apt-get install avahi-daemon
	sudo insserv avahi-daemon
	sudo pico /etc/avahi/services/multiple.service
	

Add this to the multple service: 

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
	
Apply the configuration with: 

	sudo /etc/init.d/avahi-daemon restart

### Add automatic starting of the daemon 
Edit `/opt/retropie/configs/all/autostart.sh` as well as AM-Start.sh & ES-Start.sh

	sudo /etc/init.d/avahi-daemon start &
	attract	# or emulationstation as needed

Now  you can access with ssh pi@HOSTNAME.local
------------------------------------------------------------------

### Find All Raspberry PI's on Network
To find all Raspberry PI's already set up on your network use one of the following commands. 

	arp -a | grep b8:27:eb | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'

or you can also try to use: 

	sudo nmap -sP 192.168.1.0/24 | awk '/^Nmap/{ip=$NF}/B8:27:EB/{print ip}'

If neither works, you'll have to use the method noted in the *Find IP Address* section above

------------------------------------------------------------------
## 2. BOOT/CONFIG.TXT MODIFICATIONS
------------------------------------------------------------------

Adjust overclocking/set machine specific settings in `/boot/config.txt` (add custom settings for specific machine)

### To find machine serial number use: `cat /proc/cpuinfo`

Serial number looks like this: 0000000012345678  when used as a configuration filter, it should look like this: [0x12345678])
Serial number is on last line of cpuinfo and can be used to set up machine specific settings (in this case placed in the bottom of /boot/config.txt)

To quickly grab the specific machine serial number

	cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2

### Set Overscan

Download and install this script to make setting overscan easy, whithout having to guess and reboot each time.

    cd ~/develop
    wget https://github.com/ukscone/set_overscan/archive/master.zip
    unzip master.zip && rm master.zip
    cd set_overscan-master
    sudo make
    sudo sh ./set_overscan.sh



------------------------------------------------------------------
## 3. INSTALLATIONS  
------------------------------------------------------------------

All of the following installations were handled through Retropie-Setup

### install attractmode (attract mode)

AttractMode can be installed as an "experimental" package in RetroPie 3, but It MUST be built manually on Raspberry Pi4 as of 6/28/2020 due to a limitation of the way Raspberry Pi 4's GPU is built (SFML-Pi has DRM problems or something) 

Once installed, run it directly, do not run through a remote terminal

It can be run by calling `attract` or for more robust logging: `attract --loglevel debug`

#### Install Binary if feeling lazy on Raspberry Pi 3
NOTE: Installed version doesn't include hardware acceleration, so follow "install manually" directions below. 

	sudo sh /home/pi/RetroPie-Setup/retropie_setup.sh

manage packages > manage experimental packages install attractmode

#### Build from Source

##### Install manually for Raspberry Pi 3 (rules for RPi4 are shown after this)
[Manual compile instructions on GitHub](https://github.com/mickelson/attract/wiki/Compiling-on-the-Raspberry-Pi-%28Raspbian-Jessie%29)
This works on Raspbian Stretch as well as Jessie.

*update*

	sudo apt-get update; sudo apt-get upgrade

*make development folder*

	cd ~; mkdir develop

*Install "sfml-pi" and Attract-Mode dependencies*

    sudo apt-get install cmake libflac-dev libogg-dev libvorbis-dev libopenal-dev libjpeg8-dev libfreetype6-dev libudev-dev libraspberrypi-dev
    
    # or try 
    # sudo apt-get install cmake libflac-dev libogg-dev libvorbis-dev libopenal-dev libfreetype6-dev libudev-dev libjpeg-dev libudev-dev libfontconfig1-dev


*Download and build sfml-pi*
Install and make 

	cd ~/develop
	git clone --depth 1 https://github.com/mickelson/sfml-pi sfml-pi
	mkdir sfml-pi/build; cd sfml-pi/build
	cmake .. -DSFML_RPI=1 -DEGL_INCLUDE_DIR=/opt/vc/include -DEGL_LIBRARY=/opt/vc/lib/libbrcmEGL.so -DGLES_INCLUDE_DIR=/opt/vc/include -DGLES_LIBRARY=/opt/vc/lib/libbrcmGLESv2.so
    make -j4
	sudo make install
	sudo ldconfig

Note: if you are using a Pi firmware older than 1.20160921-1, please replace "libbrcmEGL.so" and "libbrcmGLESv2" with the old names, "libEGL.so" and "libGLESv2". This mode uses OpenGL ES


*Build FFmpeg with mmal support for Attract mode(hardware accelerated video decoding)*
Install & make. When getting to the .configure step... wait. It takes awhile and doesn't look like it's working. Go get coffee. "Make" takes a really long time too
	
	cd ~/develop
	git clone --depth 1 git://source.ffmpeg.org/ffmpeg.git
	cd ffmpeg
	./configure --enable-mmal --disable-debug --enable-shared --extra-ldflags="-latomic"    # <-- this last bit is probably only needed on buster
	make  #Potentially add the parameter "-j4" when you run make on a pi2 or pi3 to speed the build significantly. In my experience it causes fatal errors in compiling
	sudo make install
	sudo ldconfig

*Download and build Attract-Mode*
Install and make
	
	cd ~/develop
	git clone --depth 1 https://github.com/mickelson/attract attract
	cd attract
	make USE_MMAL=1 USE_GLES=1 
	sudo make install USE_MMAL=1 USE_GLES=1

*Delete build files*

	cd ~; rm -r -f ./develop	

*Check to see that it was installed correctly.*

	attract -v

*It's important to load AttractMode the first time so that it creates configuration files. Run `attract` or `attract --loglevel debug` at the commmand line*

To launch attract mode with logging in the terminal, and saved to a log as well: 
    
    attract --loglevel debug 2>&1 | tee ~/.attract/log.txt

##### Install manually for Raspberry Pi 4 / buster
[Manual compile instructions on GitHub](https://github.com/mickelson/attract/wiki/Compiling-on-the-Raspberry-Pi-4-%28Raspbian-Buster%29)
[Related post](https://github.com/mickelson/attract/issues/576)


This works on Raspbian Buster on Pi 4

Start with a CLEAN RetroPie install or this likely won't work. 

*update*

	sudo apt-get update; sudo apt-get upgrade

*make development folder*

	cd ~; mkdir develop

*Install "sfml-pi" dependencies*

	sudo apt-get install -y cmake libflac-dev libogg-dev libvorbis-dev libopenal-dev libjpeg8-dev libfreetype6-dev libudev-dev libdrm-dev libgbm-dev libegl1-mesa-dev
	
    
*Download and build sfml-pi*
Install and make 

	git clone --depth 1 https://github.com/mickelson/sfml-pi sfml-pi
	mkdir sfml-pi/build; cd sfml-pi/build
	cmake .. -DSFML_DRM=1 -DSFML_OPENGL_ES=1
    make -j4
	sudo make install
	sudo ldconfig

*Install attractmode dependencies 

	sudo apt-get install -y cmake libflac-dev libogg-dev libvorbis-dev libavutil-dev libavcodec-dev libavformat-dev libavfilter-dev libswscale-dev libavresample-dev libopenal-dev libfreetype6-dev libudev-dev libjpeg-dev libudev-dev libfontconfig1-dev libglu1-mesa-dev libxinerama-dev libcurl4-openssl-dev

*Download and build Attract-Mode*
Install and make
	
	git clone --depth 1 https://github.com/mickelson/attract attract
	cd attract
	make USE_DRM=1 USE_MMAL=1  # this doesn't work -> USE_GLES=1
	sudo make install USE_DRM=1 USE_MMAL=1

*Delete build files*

	cd ~; rm -rf ./develop	

*Check to see that it was installed correctly.*

	attract -v

Before the next reboot, make sure you go into the autostart and change the autostart to `attract`

	sudo pico /opt/retropie/configs/all/autostart.sh 

------------------------------------------------------------------

### Install emulators
Most emulators are installed automatically, a few must be installed from the optional or experimental packages

	sudo sh /home/pi/RetroPie-Setup/retropie_setup.sh

#### Optional Packages
	
	manage packages > manage optional packages

- advmame-0.94 (not available on pi4)
- advmame-1.4 (not available on pi4)
- 102 advmame #advmame doesn't support RetroArch overlays
- 109 daphne (lr-daphne likely doesnt' work)
- 113 dosbox
- 125 lr-freeintv
- 144 scummvm  (there's now an experimental/optional libretro scummvm installation)
- 315 kodi
- 833 scraper 

#### Compile Mame 189

This requires a version of SDL2 without X11. So we'll need to remove SDL2 & install. Any program that uses SDL2 to draw to the framebuffer should now be doing it in hardware on the raspberry pis videocore4 using opengles2.

    # remove SDL2
    sudo apt-get remove -y --force-yes libsdl2-dev
    sudo apt-get autoremove -y
    
    # install dependencies 
    sudo apt-get -y install libfontconfig-dev qt5-default automake mercurial libtool libfreeimage-dev libopenal-dev libpango1.0-dev libsndfile-dev libudev-dev libtiff5-dev libwebp-dev libasound2-dev libaudio-dev libxrandr-dev libxcursor-dev libxi-dev libxinerama-dev libxss-dev libesd0-dev freeglut3-dev libmodplug-dev libsmpeg-dev libjpeg-dev
    
    # build
    hg clone http://hg.libsdl.org/SDL
    cd SDL
    ./autogen.sh
    ./configure --disable-pulseaudio --disable-esd --disable-video-mirror --disable-video-wayland --disable-video-opengl --host=arm-raspberry-linux-gnueabihf
    make
    sudo make install
    
    # get all the libraries
    cd ~/develop
    wget http://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.2.tar.gz
    wget http://www.li
    bsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.2.tar.gz
    wget http://www.libsdl.org/projects/SDL_net/release/SDL2_net-2.0.1.tar.gz
    wget http://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.14.tar.gz

    #Uncompress them all
    tar zxvf SDL2_image-2.0.2.tar.gz 
    tar zxvf SDL2_mixer-2.0.2.tar.gz 
    tar zxvf SDL2_net-2.0.1.tar.gz 
    tar zxvf SDL2_ttf-2.0.14.tar.gz
    
    # Build the Image file loading library
    cd SDL2_image-2.0.2 
    ./autogen.sh 
    ./configure 
    make 
    sudo make install
    cd ..

    # Build the Audio mixer library
    cd SDL2_mixer-2.0.2 
    ./autogen.sh 
    ./configure 
    make 
    sudo make install
    cd ..

    # Build the Networking library
    cd SDL2_net-2.0.1 
    ./autogen.sh 
    ./configure 
    make 
    sudo make install
    cd ..

    #install freetype-config (required by truetype font library)
     wget -c https://download.savannah.gnu.org/releases/freetype/freetype-2.9.1.tar.bz2
     tar xvfz freetype-2.9.1.tar.bz2
     cd freetype-2.9.1.tar.bz2
     ./configure --prefix=/usr/local/freetype2 --enable-freetype-config
     make
     sudo make install
     cd ..
    
    # add this location (/usr/local/freetype2/) to
    sudo pico /etc/ld.so.conf
    
    
    # Build the Truetype font library
    cd SDL2_ttf-2.0.14
    ./autogen.sh
    ./configure --with-freetype-prefix=/usr/local/freetype2
    make
    sudo make install
    cd ..

Create a larger swap file

    sudo nano /etc/dphys-swapfile

Find the line that says CONF_SWAPSIZE=100 and change the value so that it reads CONF_SWAPSIZE=2048. Save, exit & reboot. Then start to work on MAME

    wget https://github.com/mamedev/mame/releases/download/mame0189/mame0189s.zip 
    unzip mame0189s.zip -d mame
    cd mame
    unzip mame.zip

    sudo pico makefile
    
Comment out all of the existing options in the makefile and add these options to the makefile

    REGENIE =1
    NOWERROR =1
    TARGET =mame
    SUBTARGET =arcade
    USE_QTDEBUG =0
    #NO_X11 =1
    NO_OPENGL=1
    NO_USE_XINPUT =1
    NO_BGFX=1
    FORCE_DRC_C_BACKEND =1
    DEBUG =0
    ARCHOPTS =-mcpu=cortex-a72 -mtune=cortex-a72  -mfloat-abi=hard -funsafe-math-optimizations -fexpensive-optimizations -fprefetch-loop-arrays

Then make the app

    make -j5
    
    cd ~/develop/mame
    ./mamearcade -cc #create config
    mkdir roms

Don’t forget to turn the swap file back to 100mb.

    sudo nano /etc/dphys-swapfile

Find the line that says CONF_SWAPSIZE=2048 and change the value so that it reads
CONF_SWAPSIZE=100. Save and exit, reboot. 

    /home/pi/.mame/mamearcade -inipath /home/pi/.mame/mame.ini /home/pi/.mame/roms/digdug.zip
#### Experimental Packages
	
manage packages > manage optional packages

- lr-mame2003-plus (Pi 4. On the pi3 this will be in optional packages )

- lr-Daphne, by June 2020 has ceased to be developed and doesn't work. 

To install Daphne [review this youtube video](https://www.youtube.com/watch?v=WKkkwk74Arc)

### Install Pixel Desktop

Pixel desktop may not work when installed this way, due to a known bug. 

	sudo sh /home/pi/RetroPie-Setup/retropie_setup.sh

configuration / tools > raspbiantools
install Pixel desktop environment

------------------------------------------------------------------
## 4. TRANSFER AND CREATE FILES
------------------------------------------------------------------

### Add shortcuts folder 
------------------------------------------------------------------
To simplify adding files and finding files add a shortcuts folder. Add `/home/pi/shortcuts/` with paths to commonly used folders 

	mkdir /home/pi/shortcuts
	mkdir /home/pi/shortcuts/roms
	mkdir /home/pi/shortcuts/configs
	mkdir /home/pi/shortcuts/input

Create aliases

    mkdir ~/shortcuts
    mkdir ~/shortcuts/configs
    mkdir ~/shortcuts/ledspicer
    mkdir ~/shortcuts/inputs
    
	ln -s /boot 						                /home/pi/shortcuts/configs/boot
	ln -s /opt/retropie/configs/all/emulationstation 	/home/pi/shortcuts/configs/emulationstation
	ln -s /opt/retropie/configs 				        /home/pi/shortcuts/configs/retropieconfigs
    ln -s /opt/retropie/configs/all/attract             /home/pi/shortcuts/configs/attractmode
	ln -s /etc/init.d 					                /home/pi/shortcuts/configs/initd
	ln -s /dev/input 					                /home/pi/shortcuts/inputs/input
	ln -s /proc/bus/input/devices 				        /home/pi/shortcuts/inputs/input_devices 
	ln -s /home/pi/.kodi/userdata/playlists 		    /home/pi/shortcuts/kodi_playlists 
    ln -s /usr/local/share/ledspicer                    /home/pi/shortcuts/ledspicer/configs
    ln -s /usr/local/etc/ledspicer.conf                 /home/pi/shortcuts/ledspicer/ledspicer.conf


### Copy Files
------------------------------------------------------------------

	#Load up a backup containing all of the needed roms/files, then pull them using rsync
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/home/pi/RetroPie/roms /home/pi/RetroPie/

	#Copy configuration files
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/all /opt/retropie/configs

	#Copy attract files
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/home/pi/.attract /home/pi/ #this might be a symlink to /opt/etc...
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/all/attractmode /opt/retropie/configs/all/

	#Copy fonts
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/home/pi/.fonts /home/pi/

	#Copy splashscreens
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/home/pi/RetroPie/splashscreens /home/pi/RetroPie

	#Copy BIOS
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/home/pi/RetroPie/BIOS /home/pi/RetroPie

	#Copy Retropie Menu
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/home/pi/RetroPie/retropiemenu /home/pi/RetroPie

	#Copy Daphne input file
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/daphne/dapinput.ini /opt/retropie/configs/daphne/

	#Copy Kodi files
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/ports/kodi/userdata  /opt/retropie/configs/ports/kodi 

	#Copy Intellivision ROM files
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/usr/local/share/jzintv/rom  /usr/local/share/jzintv/

	#Copy Launch Screens
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/arcade/launching.png  /opt/retropie/configs/arcade/ 
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/atari2600/launching.png  /opt/retropie/configs/atari2600/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/daphne/launching.png  /opt/retropie/configs/daphne/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/fba/launching.png  /opt/retropie/configs/fba/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/gba/launching.png  /opt/retropie/configs/gba/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/gb/launching.png  /opt/retropie/configs/gb/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/intellivision/launching.png  /opt/retropie/configs/intellivision/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/mame-advmame/launching.png  /opt/retropie/configs/mame-advmame/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/mame-libretro/launching.png  /opt/retropie/configs/mame-libretro/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/mame-mame4all/launching.png  /opt/retropie/configs/mame-mame4all/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/mastersystem/launching.png  /opt/retropie/configs/mastersystem/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/megadrive/launching.png  /opt/retropie/configs/megadrive/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/n64/launching.png  /opt/retropie/configs/n64/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/neogeo/launching.png  /opt/retropie/configs/neogeo/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/nes/launching.png  /opt/retropie/configs/nes/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/ngp/launching.png  /opt/retropie/configs/ngp/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/ngpc/launching.png  /opt/retropie/configs/ngpc/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/pc/launching.png  /opt/retropie/configs/pc/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/ports/launching.png  /opt/retropie/configs/ports/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/psx/launching.png  /opt/retropie/configs/psx/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/scummvm/launching.png  /opt/retropie/configs/scummvm/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/sega32x/launching.png  /opt/retropie/configs/sega32x/
	sshpass -p$(cat /home/pi/sync_pass) rsync -avz mahuti@192.168.1.93:/Volumes/retropie/opt/retropie/configs/snes/launching.png  /opt/retropie/configs/snes/
 
### Manage Roms

To manipulate roms into different set types: 

https://recalbox.gitbook.io/tutorials/utility/rom-management/clrmamepro-tutorial

To make Full Non-Merged Roms (Non-Merged Roms that contain their BIOSes), make sure that "Non-Merged" is selected and "Separate Bios Sets" is not checked in the Advanced rebuild settings.

------------------------------------------------------------------
## 5. LOOK AND FEEL
------------------------------------------------------------------
### Hide Content

#### To hide the end messaging

    sudo pico /etc/rc.local
    
add `dmesg --console-off` right before `exit 0`

#### To hide the opening content

    sudo pico /boot/cmdline.txt

add 
    
    console=tty3 loglevel=3 logo.nologo quiet splash vt.global_cursor_default=0 systemd.show_status=0

#### To hide splash

    sudo pico /boot/config.txt
    
add `disable_splash=1`

#### hide auto-login text

    touch ~/.hushlogin

#### Hide/modify message of the day (superseded by .hushlogin if used):

    sudo nano /etc/motd
    
#### Hide Autologin Text

    sudo nano /etc/systemd/system/getty@tty1.service.d/autologin.conf

change `ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM` to 
`ExecStart=-/sbin/agetty --skip-login --noclear --noissue --login-options "-f pi" %I $TERM`

#### Hide bootloader screen

    sudo -E rpi-eeprom-config --edit
    
add 

    DISABLE_HDMI=1 
    
reboot

### Configure Retroarch
https://github.com/RetroPie/RetroPie-Setup/wiki/Configuration-Editor

	sudo ~/RetroPie-Setup/retropie-setup.sh

C Configuration/Tools > 805 configedit - Edit RetroPie/RetroArch Configurations


### Add Splashscreens 
`sudo sh /home/pi/RetroPie-Setup/retropie_setup.sh`
Then **configuration/tools option 833 or 834 (pi4 839)** then enable splash screen randomizer (option 3)

### Reduce System Volume
Enter `alsamixer` in terminal and change volume (may not work without audio output initialized)
 
### Autostart Scripts 

#### Add front end startup scripts
_If you already copied the configs in the "Copy Files" section you can skip this._

Add custom startup scripts to `/opt/retropie/configs/all/` to simplify starting up in AttractMode or EmulationStation. 

1. `AM-Start.sh`
2. `ES-Start.sh`

Autostart.sh script is overwritten by the contents of one or the other of these when using _"restart in.."_ commands in emulationstation or attractmode front-end (those commands will be set up later)


#### LAUNCH SCREENS  
_If you already copied the Launch Screens in the "Copy Files" section you can skip this._

1. Launch screens added to each emulator config folder `/opt/retropie/configs/[SYSTEM]`
2. Retropie-setup modified to use launch screens for each emulator
[More about launch screens](https://github.com/retropie/retropie-setup/wiki/runcommand#adding-custom-launching-images)

#### RETROARCH

##### Overlays

###### Arcade Overlays
https://github.com/biscuits99/rp-video-manager

    wget https://github.com/biscuits99/rp-video-manager/releases/download/{release-number}/rp-video-manager.zip
    unzip -o rp-video-manager.zip
    rm rp-video-manager.zip
    cd /home/pi/rp-video-manager
    chmod 755 videomanager.sh
    ./videomanager.sh

###### Console Overlays
For a crap-ton of cheesy overlays, download and install the bezelproject (search on google)

To setup a standard overlay here's an example: 

1. Add the top 2 lines at a minimum to the system retrorarch file `/opt/retropie/configs/atari2600/retroarch.cfg`
The rest of the lines are examples of setting positioning. Aspect_ratio_index=22 means "use custom aspect ratio" 

    input_overlay = "/opt/retropie/configs/all/retroarch/overlay/Atari-2600.cfg"
    input_overlay_opacity = "1.000000"
    custom_viewport_width = 994
    custom_viewport_height = 758
    custom_viewport_x = 318
    custom_viewport_y = 136
    aspect_ratio_index = 22
    video_force_aspect = true
    video_shader = /opt/retropie/configs/all/retroarch/shaders/crt-pi-curvature.glslp
    video_shader_enable = true

2. the Atari-2600.cfg file mentioned in the RA config should contain something like the following. The png file can be relative to the location of the cfg file if a folder path is not specified.    
 
    overlays = 1

    overlay0_overlay = Atari-2600.png

    overlay0_full_screen = true

    overlay0_descs = 0

3. An individual game file can also be created in the folder for the emulator `/opt/retropie/configs/all/retroarch/config/Stella/Zaxxon (USA).cfg`  
The file should contain somethng like this: 

    input_overlay = "/opt/retropie/configs/all/retroarch/overlay/GameBezels/Atari2600/Zaxxon (USA).cfg"


##### Exiting For arcade machines: 
To exit using only escape key

Configure keyboard hotkey behaviour for RetroArch. By setting it to use NO hotkey, it will remove hotkey default and set the "escape" key to automatically launch RGUI menu. Because "escape" is the normally the default emulator exit key, you will likely need to remap the exit key to something besides "escape" uless you've already done so. In my case, I use the "space" key. 
 
1. sudo sh ~/RetroPie-Setup/retropie_setup.sh
2. Open Configuration/Tools -> RetroArch
3. Configure Hotkey behavior
4. Set it to no hotkey
5. Edit the following files: `/opt/retropie/configs/all/retroarch.cfg`, `/opt/retropie/configs/EACH_OF_YOUR_CONFIGURED_EMULATORs/retroarch.cfg`, `/opt/retropie/configs/all/retroarch-joypads/YOUR_CONFIGURED_JOYPADS.cfg` and change any occurrence of `inpux_exit_emulator`, `input_exit_emulator_btn` to use a new escape key. I use `inpux_exit_emulator="space"`. Make sure to remove any variation of `input_exit_emulator`, `input_exit_emulator_btn`, `input_enable_hotkey`, `input_enable_hotkey_btn`. There may be options for a few different versions of these, make sure to remove all of them except those that you've added. 
7. if using picade x-hat, configure your new key to be the "esc" key in the boot/config: I use dtparam=escape=57  

Might want to change this as well: input_menu_toggle = "tilde" (close to the tab command... like mame.) 

MAKE SURE YOU ALSO MAKE THIS CHANGE HERE: `/opt/retropie/configs/arcade/retroarch.cfg`

After removing hotkeys, you may have to change some things like: 
input_state_slot_increase = "right"
input_state_slot_decrease = "left"

If you removed the hotkey, but have ever configured any hotkey+ buttons in your gamepads, make sure you remove the configured buttons from the gamepad-specific cfg files or things will go haywire. 

##### Default Configurations for arcade machines
Stick as close as you can to these default controls and you'll have to do less configuration later

RETRO_DEVICE_ID_JOYPAD_START        MAME: KEY_START
RETRO_DEVICE_ID_JOYPAD_SELECT       MAME: KEY_COIN
RETRO_DEVICE_ID_JOYPAD_A            MAME: KEY_BUTTON_1
RETRO_DEVICE_ID_JOYPAD_B            MAME: KEY_BUTTON_2
RETRO_DEVICE_ID_JOYPAD_X            MAME: KEY_BUTTON_3
RETRO_DEVICE_ID_JOYPAD_Y            MAME: KEY_BUTTON_4
RETRO_DEVICE_ID_JOYPAD_L            MAME: KEY_BUTTON_5
RETRO_DEVICE_ID_JOYPAD_R            MAME: KEY_BUTTON_6
RETRO_DEVICE_ID_JOYPAD_L2           MAME: KEY_BUTTON_7
RETRO_DEVICE_ID_JOYPAD_UP           MAME: KEY_JOYSTICK_U
RETRO_DEVICE_ID_JOYPAD_DOWN         MAME: KEY_JOYSTICK_D
RETRO_DEVICE_ID_JOYPAD_LEFT         MAME: KEY_JOYSTICK_L
RETRO_DEVICE_ID_JOYPAD_RIGHT        MAME: KEY_JOYSTICK_R
RETRO_DEVICE_ID_JOYPAD_R2           Turbo Button

##### Clearing controller configuration in RA
How to reset controllers on RetroPie

1. Choose Manage Packages.
1. Choose Manage Core Packages.
1. Choose emulationstation (Installed)
1. Choose Configurations / Options (it may also be named Configurations Tools)
1. Choose the option to Clear/Reset Emulation Station input configuration.
1. Choose Yes to proceed to clear the controller settings.

##### Enable Keyboard input in MAME

Launch a rom from AttractMode or EmulationStation. Open the menu (hotkey plus the xbutton (not the x key... the configured button)

The latest builds of mame2003-plus have a new core option called "Input interface" which allows you to select between retropad, mame_keyboard, and simultaneous.

*retropad* only reads input through the retropad abstraction. With default RetroArch settings, as has been mentioned, the retropad abstraction includes a mapping for player one on the keyboard.
*mame_keyboard* this only uses the libretro keyboard api to pass keyboard input directly to the MAME keyboard input system.
*simultaneous* is the 'classic' mame2003 behavior. both input systems simultaneously, including when they overlap.

#### ATTRACTMODE  
_If you already copied the configs in the "Copy Files" section you can skip this.

	/opt/retropie/configs/all/attractmode (pi3... pi4 version is in ~/.attract)

1. add Attract Mode setup folder with custom scripts
2. modify attract.cfg
3. add emulators
4. add intro movie
5. add layouts
6. add Catver.ini, controls.ini, nplayers.ini to mame-config
7. add modules debug, helpers, shader
8. add romlists (all automatically generated except Scummvm and Attract Mode Setup)
9. add "Attract Mode Setup" graphics to scraper
10. add screensaver.nut and related assets to screensaver
11. add Arcade Ambience 1983.mp3 to sounds
12. add custom script to launch "tab" menu in management screen if tab isn't available


#### EMULATIONSTATION  
_If you already copied the configs & retropiemenu in the "Copy Files" section you can skip this._

1. add es_systems.cfg `/opt/retropie/configs/all/emulationstation/es_systems.cfg`
2. add custom game list `/home/pi/RetroPie/retropiemenu/gamelist.xml`
3. add custom icons to `/home/pi/RetroPie/retropiemenu/icons`
4. add Attract-Mode.sh script to `/home/pi/RetroPie/retropiemenu/Attract-Mode.sh`
5. turn off SplashScreen in Emulationstation. Add to es_settings.cfg in `/opt/retropie/configs/all/emulationstation/ ` `<bool name="SplashScreen" value="false" />`

To launch EmulationStation in a rotated mode add this to autostart
emulationstation --screenrotate 1 --screensize 480 640 --screenoffset 0 0 #counter clockwise, 480x640 and 0,0 offset
this may crash the scraper UI when using "scrape now" 

#### MAME 
1. Modify advmame keymap to additionally use C key to enter coins
2. Modify mame keymap to additionally use C key to enter coins
3. Modify qbert keymap to use diagonals. (unless using an ultimarc stick)

#### Other emulators
_If you already copied the DAPHNE input file and Intellivision files in the "Copy Files" section you can skip this._

1. Add intellivision roms exec.bin and grom.bin to `/usr/local/share/jzintv/rom` (console only.. not in Arcade-pi setup)
2. Modify Daphne's default joystick codes `/opt/retropie/configs/daphne/dapinput.ini` [More...](https://github.com/retropie/RetroPie-Setup/wiki/Daphne)
3. Modify advance-mame's default joystick codes to use select+enter to exit, and select to enter coins

#### KODI 
_If you already copied the Kodi userdata files in the "Copy Files" section you can skip this._

KODI is set to autoplay /home/pi/Videos folder using autoexec.py file
[More on kodi forums...](https://forum.kodi.tv/showthread.php?tid=280300&pid=2361411#pid2361411)

Add autoexec.py to Kodi userdata folder 
`/opt/retropie/configs/ports/kodi/userdata/autoexec.py`
[More on the kodi wiki...](http://kodi.wiki/view/Autoexec.py)

Kodi keymaps added Joystick.xml and Keymap.xml to create single-key exit function 
`/opt/retropie/configs/ports/kodi/userdata/keymaps/joystick.xml`
`/opt/retropie/configs/ports/kodi/userdata/keymaps/keyboard.xml`
[More on the kodi wiki...](https://github.com/RetroPie/RetroPie-Setup/wiki/KODI)


------------------------------------------------------------------
## 6. SETUP OPTIONAL HARDWARE 
------------------------------------------------------------------
### Zero Delay Encoders

To use more than one and have them seen as seperate controllers, add a HID quirk 

1. Add a hid quirk to the boot script: 

	`sudo pico /boot/cmdline.txt`

Add this (with a space after existing items) 

	`usbhid.quirks=0x0079:0x0006:0x40`
    
### GGG 49Way GPWiz49 
By default this is a badpad in Linux, sending all kinds of batshit-bad data. HID Quirks need to be added to handle it. 

1. Create file /etc/modprobe.d/usbhid.conf with the following: 

	`options usbhid quirks=0xFAFA:0x0007:0x00000020,0xFAFA:0x0008:0x00000020`

2. Add the hid quirk to the boot script: 

	`sudo pico /boot/cmdline.txt`

Add this (with a space after existing items) 

	`usbhid.quirks=0xFAFA:0x0007:0x00000020,0xFAFA:0x0008:0x00000020`

Once the HID Quirks have been added, it just needs to get configured in Emulationstation controller set up. 

Add UDEV rules to allow access to this device without ROOT privileges
https://github.com/LairdCP/UwTerminalX/wiki/Granting-non-root-USB-device-access-(Linux)

3. Add a UDEV rule sudo pico :/etc/udev/rules.d/50-set49mode.rules 
 
    `ACTION=="add", SUBSYSTEMS=="usb", ATTRS{idVendor}=="fafa", ATTRS{idProduct}=="0007", MODE:="666"`

4. Reload UDEV `sudo udevadm control --reload`

5. Install set49mode


### Picade X-Hat

#### Version 1
1. [Picade Hat hardware](https://github.com/pimoroni/picade-hat) and related sofware added (for version 1, not sure if the current version will work with older picade hats)


2. Modified [picadehat-custom](https://github.com/pimoroni/picade-hat/tree/master/gamepads) by changing `KEY_C` to `KEY_6` (which is actually '5') and `KEY_ENTER` to `KEY_TAB`

`cd /home/pi/Pimoroni/picade/picade-hat/gamepads` 

3. run `sudo ./configload picadehat-custom` to use the above custom mapping
run `sudo ./configload picadehat-default` to change back to default

#### Version 2
https://github.com/pimoroni/picade-hat
https://github.com/pimoroni/picade-hat/blob/master/picade.txt
Linux Keycodes/keyboard bindings: 
https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h
https://github.com/libretro/RetroArch/issues/358 you can search in the  /opt/retropie/configs/all/retroarch.cfg  file for "tilde" and you will find the list of acceptable names of inputs in there

1. Review documentation for [Picade Hat hardware](https://github.com/pimoroni/picade-hat)  

2. Run `curl -sS https://get.pimoroni.com/picadehat | bash` for one line installation and reboot

3. Edit /boot/config.txt as needed. Without adding the overlay the default keys will be used. Example: 

REMOVE (probably) hdmi_force_hotplug, as this software enables it for some odd reason. 

    dtoverlay=picade
    dtparam=up=12
    dtparam=down=6
    dtparam=left=20
    dtparam=right=16

    dtparam=button1=5
    dtparam=button2=11
    dtparam=button3=8
    dtparam=button4=25
    dtparam=button5=9
    dtparam=button6=10

    dtparam=enter=27
    dtparam=escape=57 # 57 is space bar, 1 is escape key
    dtparam=coin=6 #the number 6 means the number 5. Weird, I know. 
    dtparam=start=24

### Pimoroni Plasma Button
https://github.com/pimoroni/plasma
curl https://get.pimoroni.com/plasma | bash

------------------------------------------------------------------
### RGBCommander / GGG / Ultimarc LED and Dynamic joysticks

Install and configure RGBCommander from http://users.telenet.be/rgbcommander/
**NOTE:** RGBCommander will fail if it finds ._ files. There is a script in the index to clean those files from the entire system.

To restart, stop, start, check status: 

	sudo systemctl [restart,stop,start,status] rgbcommander

Create shortcut

	ln -s /usr/sbin/rgbcommander /home/pi/shortcuts/configs/rgbcommander
                    
Testing utility

    sudo systemctl stop rgbcommander
    rgbcmdcon
    (type ? <enter>)

------------------------------------------------------------------

### LedSpicer
Install and configure from https://sourceforge.net/p/ledspicer/wiki/Deployment/

Update Retropie to the latest version. On 4.3(ish) Stretch I was unable to get tinyxml2 to work due to missing dependencies

Load prerequisites & get tinyxml2

    sudo apt install build-essential pkg-config libtool libtinyxml2-dev libusb-1.0-0-dev libpthread-stubs0-dev -y
    sudo apt install libpulse-dev -y

Download to development folder

    cd /develop 
    git clone https://github.com/meduzapat/LEDSpicer.git
    cd LEDSpicer
   
Compile

    sudo sh autogen.sh
    ./configure --enable-ultimateio --enable-ledwiz32 --enable-pacdrive --enable-alsaaudio  --enable-develop CPPFLAGS='-DSHOW_OUTPUT=1'
    (for production use this: ./configure --enable-ultimateio --enable-ledwiz32 --enable-pacdrive --enable-alsaaudio )    
    make clean
    make -j5
    sudo make install
    

Copy & edit basic configuration 

    sudo cp /usr/local/share/doc/ledspicer/examples/ledspicer.conf /usr/local/etc/ledspicer.conf
    
Configure 
    
    sudo pico /usr/local/etc/ledspicer.conf
    
Install UDEV Rules
    
    sudo cp /usr/local/share/doc/ledspicer/examples/21-ledspicer.rules /etc/udev/rules.d/
    sudo chmod 744 /etc/udev/rules.d/21-ledspicer.rules
    sudo udevadm control --reload-rules && sudo udevadm trigger
    
Add default profile

    sudo pico /usr/local/share/ledspicer/profiles/default.xml

Set up to run as root on startup
    
    sudo cp /usr/local/share/doc/ledspicer/examples/ledspicerd.service /etc/systemd/system
    sudo systemctl enable ledspicerd.service
    
or... 

Run LEDSpicer daemon

    ledspicerd  
    
Test Individual Leds

    ledspicerd -l
    
Test Configured Elements
    
    ledspicerd -e
    
Test profile

    ledspicerd -p default
    
if this errors out, it's likely due to an XML configuration issue.

Look at logs

    cat /var/log/syslog | grep ledspicer
    cat /var/log/syslog | grep LEDSpicer

example use of Emitter to launch a profile

    emitter LoadProfileByEmulator digdug arcade
    
To capture inputs of gamepads

    inputseeker
    
To scan for events in MAME games
    
    nc -v localhost 8000

To update: git pull from the development folder, then compile 

------------------------------------------------------------------

### GamePadBlock
GamePadBlock is a piece of hardware that allows you to switch between controllers dynamically and use 2 of each controller. 
Repository for this script is available here: https://github.com/mahuti/GamePadBlock

For more: https://blog.petrockblock.com/gamepadblock/

Install USB Hid Quirks so that two gamepads can be shown for one Gamepadblock
`wget -O - https://raw.githubusercontent.com/petrockblog/GamepadBlockScripts/master/gamepadblockRaspbian.sh | sudo bash`

[Update firmware for GamePadBlock to 1.2+](https://github.com/petrockblog/petrockutil)

Add Pyserial, etc to [run custom script for GamePadBlock](https://blog.petrockblock.com/2017/11/11/using-virtual-com-port-gamepadblock/)

	sudo apt-get install -y python-pip
	sudo pip install pyserial

Download and copy BINARY	to /home/pi
Just [download the binaries](https://blog.petrockblock.com/gamepadblock-downloads/) from here and copy it to a folder named "gamepadblock" in /home/pi/: 
NOTE: Don't bother doing this: git clone --depth 1 https://github.com/petrockblog/petrockutil/ petrockutil-linux-arm #you'll have to make/compile it. not worth it. 

	cd /home/pi/gamepadblock
	./petrockutil-linux-arm scan serial #this gets location of device (/dev/ttyACM0, etc)

Add the script found [here](https://github.com/mahuti/GamePadBlock): 

Modify runcommand-onstart.sh to launch controller switcher
This file can be found here. Instructions available at the repository linked above. 

	/opt/retropie/configs/all/runcommand-onstart.sh

------------------------------------------------------------------
## 7. JOYSTICK/MOUSE TESTING SETUP AND CALIBRATION
------------------------------------------------------------------
### Reset

In case the inputs get jacked up and need to be reset, the entire input configuration can be reset from the setup script. 

    sudo ~/RetroPie-Setup/retropie_setup.sh

Select Manage Packages --> Core Packages --> EmulationStation --> Configuration --> EmulationStation
Select Clear/Reset Emulation Station Input Configuration
Reboot

You can also remove libretro's configs for mame `rm ~/RetroPie/roms/arcade/mame2003-plus/cfg/default.cfg` They aren't editable by hand. 


### Keyboard/Keyboard Encoder Setup

This is a helpful guide for getting an encoder set up to work with retropie out of the box without any mapping. 

https://retropie.org.uk/docs/Keyboard-Controllers/
https://docs.libretro.com/guides/input-and-controls/#default-retroarch-keyboard-bindings

### Joystick Testing

To find out information about USB devices. Use -vvv to make it verbose and show interface details

    lsusb  
    
To test a joystick button code, or to make sure it's working use Jstest. Go to the dev input folder and find the joystick in question. There will be js0 and maybe additional js numbers if you have multiple joysticks plugged in. 

	cd /dev/input
	jstest js[joystick number]

### Mouse Testing

This may produce random crazy visual garbage that requires a sudo reboot to clear up

    cat /dev/input/mice


### Joystick Calibration

#### Jscal Utility

Calibrate using jscal

	jscal -c /dev/input/js0 (calibrates)

#### Preview

Then preview what needs to be stored

	jscal -p /dev/input/js0

will output something like this: `jscal -s 4,1,0,127,127,4227201,4194176,1,0,127,127,4227201,4194176,1,0,127,127,4227201,4194176,1,0,127,127,4227201,4194176 /dev/input/by-id/usb-GGG_GP-Wiz40-joystick`

#### Store it 
Store it (temporarily)

	jscal -s /dev/input/js0 (saves)

#### Test it
Outside bounds of the stick should now be something more like -32,000-32,000

	jstest /dev/input/js0

#### Store it Permanently
Then store it permanently. The joystick.state file saved will automatically include the joystick id rather than "js0"

	sudo jscal-store /dev/input/js0

#### Update the Joystick Input Type
you'll need to edit this file manually to add the input type of linuxraw rather than udev

	/opt/retropie/configs/all/retroarch-joypads

------------------------------------------------------------------
## 8. MACHINE SPECIFIC MODIFICATIONS
------------------------------------------------------------------
### Pi3 Options

    # Additional overlays and parameters are documented /boot/overlays/README

    # Enable audio (loads snd_bcm2835)
    dtparam=audio=on
    gpu_mem_256=128
    gpu_mem_512=256
    gpu_mem_1024=256
    overscan_scale=1

    ## General Overscan
    disable_overscan=0

    [pi3]
    ## Overclocking
    arm_freq=1300
    gpu_freq=500
    core_freq=500
    sdram_freq=500
    over_voltage=6
    v3d_freq=525
    sdram_schmoo=0x02000020
    over_voltage_sdram_p=6
    over_voltage_sdram_i=4
    over_voltage_sdram_c=4
    h264_freq=333
    gpu_mem=256

### Terra Cresta (terra cresta)

Modified /boot/config.txt to show display vertically display_rotate=1 
https://www.raspberrypi.org/documentation/configuration/config-txt/video.md

Removed configurations from here "/opt/retropie/configs/all/retroarch/config/MAME 2003"


    ## TERRA CRESTA [0x932d6bd2]
    [0x932d6bd2]

    ## PiCade Hat (pimoroni)
    dtparam=audio=off # disabled for picade
    # Enable audio (loads snd_bcm2835)
    dtoverlay=hifiberry-dac
    dtoverlay=i2s-mmap #sound amp support

    ## Vertical Monitor
    display_rotate=1

    ## Machine Specific Overscan
    #disable_overscan=1
    #overscan_scale=1
    overscan_left=-20
    overscan_right=-15
    overscan_top=110
    overscan_bottom=-200

    framebuffer_width=550  #1100
    framebuffer_height=619  #720

    hdmi_group=2
    hdmi_mode=87
    hdmi_cvt=550 619 60

### Defender 

    ## DEFENDER [0xb9739f82]
    [0xb9739f82]

    ## PiCade Hat (pimoroni)
    dtparam=audio=off # disabled for picade
    # Enable audio (loads snd_bcm2835)
    dtoverlay=hifiberry-dac
    dtoverlay=i2s-mmap #sound amp support
    
### Space Encounters

    ## SPACE ENCOUNTERS [0x3d3f1c0f]
    [0x3d3f1c0f]

    ## PiCade Hat (pimoroni)
    dtparam=audio=off # disabled for picade
    # Enable audio (loads snd_bcm2835)
    dtoverlay=hifiberry-dac
    dtoverlay=i2s-mmap #sound amp support

    ## Machine Specific Overscan
    disable_overscan=0
    overscan_left=28
    overscan_right=13
    overscan_top=-11
    overscan_bottom=-5


------------------------------------------------------------------
## 9. INDEX OF COMMANDS
------------------------------------------------------------------
 
### Copying/syncing files across network using _rsync_
_sync/copy from one volume/directory to another_
`sudo rsync -va --progress "/Volumes/retropie 1/home/pi/Videos" "/Volumes/retropie/home/pi"`

_pull from remote location(use -n modifier for dry run test, use -z for compression, use -a to preserve permissions & symlinks)_
`rsync -avz username@remote_host:/home/username/dir1 place_to_sync_on_local_machine`

_push to remote location_
`rsync -a ~/dir1 username@remote_host:destination_directory`

### make app executable 

     chmod +x filename
     
### Checking folder sizes
    
    sudo du -h / | sort -h -r | head -n 10

### Shortenging and Resetting Log Rotation

Shorten number of weeks of logs to keep

    sudo pico /etc/logrotate.conf
    
Delete the status file and run logrotate

    sudo rm /var/lib/logrotate/status 
    sudo logrotate -f /etc/logrotate.conf 

### USB Drives

[Partitioning Drives](https://thepihut.com/blogs/raspberry-pi-tutorials/17699796-formatting-and-mounting-a-usb-drive-from-a-terminal-window)

[Formatting Drives](https://devtidbits.com/2013/03/21/using-usb-external-hard-disk-flash-drives-with-to-your-raspberry-pi/)

### Common key commands needed in linux
_list folder contentsc

	ls [folder name]

_list folder contents with permissions_

	ls -l [folder]

_list folder contents with invisibles_

	ls -al [folder]

_change directory_

	cd [directory name]

_edit file_

	sudo pico [file]

(control+x to exit/save control+x to search)

_remove all files in a folder_

	sudo rm -R [folder]

_Make a directory_

	mkdir [directory name]

_change permissions on one file_


	sudo chmod 777 [filename]

_change permissions on all files in folder_

	sudo chmod 777 -R [foldername]

_change ownership of a file/folder_

	sudo chown [user] [file]

_change group of a file/folder_

	sudo chgrp [group] [file]

_open current directory shown in console in finder (works on a Mac... ymmv)_

	open .

_view real path after changing directory into a symlinked folder_

	realpath .

_create symlink alias_

	ln -s [/path/to/file] [/path/to/symlink]

_stop attract mode remotely_

	killall -9 attract

_rename directory_

	mv /home/pi/.attract /home/pi/.attractbak

_duplicate directory_

	cp -a src target

_remove all mac dot files_
go to the root of the system (or whatever folder to be recursively cleaned) 

	cd /
	sudo find ./ -name "._*" -exec rm -rf {} \;
	sudo find ./ -name ".DS_Store" -exec rm -rf {} \;

_untar/ungz unzip file_

	tar -xvzf filename.tar.gz

_view log file as it's running_

	tail -f /usr/sbin/rgbcommander/rgbcmdd.log

_list free disk space_

	df -h

_show keys being pressed

    showkey
    
When trying to test for keys being pressed don't run this through a terminal. Run it directly on the machine. 
    
_watch processor speed

    watch -n 1 vcgencmd measure_clock arm
    
------------------------------------------------------------------
## 10. Optional Software
------------------------------------------------------------------

### VNC
Server install instructions: https://www.raspberrypi.org/documentation/remote-access/vnc/
Viewer download: https://www.realvnc.com/en/connect/download/viewer/

This will not allow one to see another command-line. It's really pretty useless for a RetroPie

### RetroPie Manager

	sudo ~/RetroPie-Setup/retropie_setup.sh

manage packages > manage experimental packages >> 829 RetroPie Manager

### Virtual Gamepad
https://retropie.org.uk/docs/Virtual-Gamepad/

	sudo ~/RetroPie-Setup/retropie_setup.sh

manage packages > manage experimental packages >> 842 Virtual GamePad

This can be set up to make a phone work as a gamepad. Handy for testing without a keyboard handy. 


### PYUSB

Install this software to use python as a system language

    sudo apt-get install python libusb-1.0
    sudo apt-get install python-pip
    sudo pip install --upgrade pyusb
    

------------------------------------------------------------------
## 10. MAME TIPS
------------------------------------------------------------------

### Mame 2003 Plus

To clear a configured field, don't hit "esc" twice, double tap the "delete" key

    mame2003-plus_skip_disclaimer = "enabled"
mame2003-plus_skip_warnings = "enabled"

### RetroPie Readonly Mode

If you click "x" and RetroPie says it's readonly mode, try the player1 button or return or something else. 

------------------------------------------------------------------
## 10. TROUBLESHOOTING
------------------------------------------------------------------

### RetroPie won't save cfg overrides

One can almost guarantee the option to "save core overrides" was selected at some point. Delete the folder (or move it instead of deleting it) at `/opt/retropie/configs/all/retroarch/confgis/EMULATORNAME`

You can also try setting permissions on the `/opt/retropie/configs/SYSTEMNAME/retroarch.cfg` file, but it's likely the former problem. 

Always save the current retroarch.cfg file configuration, never save core overrides. If you don't see the name of the .cfg file on the screen, you're not in the right place