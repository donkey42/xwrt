#!/usr/bin/webif-page
<?
. /usr/lib/webif/webif.sh
###################################################################
# Wireless configuration
#
# Description:
#	Wireless configuration.
#
# Author(s) [in order of work date]:
#       Original webif authors.
#	Jeremy Collake <jeremy.collake@gmail.com>
#	Travis Kemen	<kemen04@gmail.com>
# Major revisions:
#
# UCI variables referenced:
#
# Configuration files referenced:
#   wireless
#
header "Network" "Wireless" "@TR<<Wireless Configuration>>" 'onload="modechange()"' "$SCRIPT_NAME"
dmesg_txt="$(dmesg)"
adhoc_count=0
ap_count=0
sta_count=0
validate_wireless() {
	case "$adhoc_count:$sta_count:$ap_count" in
		1*)
			if [ "$sta_count" != "0" ]; then
				append validate_error "string|<h3>@TR<<Error: No other virtual adapters are allowed if one is in adhoc mode.>></h3><br />"
			elif [ "$ap_count" != "0" ]; then
				append validate_error "string|<h3>@TR<<Error: No other virtual adapters are allowed if one is in adhoc mode.>></h3><br />"
			fi
			;;
		0:0:?)
			if [ "$ap_count" -gt "4" ]; then
				append validate_error "string|<h3>@TR<<Error: Only 4 virtual adapters are allowed in ap mode.>></h3><br />"
			fi
			;;
		0:?:?)
			if [ "$sta_count" -gt "1" ]; then
				append validate_error "string|<h3>@TR<<Error: Only 1 adaptor is allowed in client mode.>></h3><br />"
			fi
			if [ "$1"="broadcom" ]; then
				if [ "$ap_count" -gt "3" ]; then
					append validate_error "string|<h3>@TR<<Error: Only 3 virtual adapters are allowed in ap mode with a adapter in client mode.>></h3><br />"
				fi
			elif [ "$1"="atheros" ]; then
				if [ "$ap_count" -gt "4" ]; then
					append validate_error "string|<h3>@TR<<Error: Only 4 virtual adapters are allowed in ap mode.>></h3><br />"
				fi	
			fi
			;;
		*)
			if [ "$adhoc_count" -gt "1" ]; then
				append validate_error "string|<h3>@TR<<Error: Only 1 virtual adapter is allowed to be in adhoc mode.>></h3><br />"
			fi
			;;
	esac
	#reset variables
	adhoc_count=0
	ap_count=0
	sta_count=0
}

###################################################################
# Add Virtual Interface
if ! empty "$FORM_add_vcfg"; then

	uci_add "wireless" "wifi-iface" ""
	uci_set "wireless" "cfg$FORM_add_vcfg_number" "device" "$FORM_add_vcfg"
	uci_set "wireless" "cfg$FORM_add_vcfg_number" "mode" "ap"
	uci_set "wireless" "cfg$FORM_add_vcfg_number" "ssid" "OpenWrt$FORM_add_vcfg_number"
	uci_set "wireless" "cfg$FORM_add_vcfg_number" "hidden" "0"
	uci_set "wireless" "cfg$FORM_add_vcfg_number" "encryption" "none"
	FORM_add_vcfg=""
fi

###################################################################
# Remove Virtual Interface
if ! empty "$FORM_remove_vcfg"; then
	uci_remove "wireless" "$FORM_remove_vcfg"
fi

###################################################################
# Parse Settings, this function is called when doing a config_load
config_cb() {
config_get TYPE "$CONFIG_SECTION" TYPE
case "$TYPE" in
        wifi-device)
                append DEVICES "$CONFIG_SECTION"
        ;;
        wifi-iface)
                append vface "$CONFIG_SECTION" "$N"
        ;;
        interface)
	        append network_devices "$CONFIG_SECTION"
        ;;
esac
}
uci_load network
NETWORK_DEVICES="none $network_devices"
uci_load webif
uci_load wireless

#FIXME: uci_load bug
#uci_load will pass the same config twice when there is a section to be added by using uci_add before a uci_commit happens
#we will use uniq so we don't try to parse the same config section twice.
vface=$(echo "$vface" |uniq)

vcfg_number=$(echo "$DEVICES $N $vface" |wc -l)
let "vcfg_number+=1"

#####################################################################
#setup network device form for vfaces
#
for iface in $NETWORK_DEVICES; do
	network_options="$network_options 
			option|$iface|@TR<<$iface>>"
done

#####################################################################
# generate nas package field
#
if ! empty "$FORM_install_nas"; then
	echo "Installing NAS package ...<pre>"
	install_package "nas"
	echo "</pre>"
fi
if ! empty "$FORM_install_hostapd"; then
	echo "Installing HostAPD package ...<pre>"
	install_package "hostapd"
	echo "</pre>"
fi
if ! empty "$FORM_install_wpa_supplicant"; then
	echo "Installing wpa-supplicant package ...<pre>"
	install_package "wpa-supplicant"
	echo "</pre>"
fi
nas_installed="0"
is_package_installed nas
equal "$?" "0" && nas_installed="1"

hostapd_installed="0"
is_package_installed hostapd
equal "$?" "0" && hostapd_installed="1"

wpa_supplicant_installed="0"
is_package_installed wpa-supplicant
equal "$?" "0" && wpa_supplicant_installed="1"

#####################################################################
# This is looped for every physical wireless card (wifi-device)
#
for device in $DEVICES; do
	if empty "$FORM_submit"; then
		config_get FORM_ap_mode $device mode
		config_get iftype "$device" type
	        config_get country $device country
	        config_get FORM_channel $device channel
	        config_get FORM_maxassoc $device maxassoc
	        config_get FORM_distance $device distance
	        config_get FORM_diversity $device diversity
	        config_get FORM_txantenna $device txantenna
	        config_get FORM_rxantenna $device rxantenna
	        config_get FORM_disabled $device disabled
	else
		config_get country $device country
		config_get iftype "$device" type
		eval FORM_ap_mode="\$FORM_ap_mode_$device"
		eval FORM_channel="\$FORM_bgchannel_$device"
		[ -z "$FORM_channel" ] && eval FORM_channel="\$FORM_achannel_$device"
		eval FORM_maxassoc="\$FORM_maxassoc_$device"
		eval FORM_distance="\$FORM_distance_$device"
		eval FORM_diversity="\$FORM_diversity_$device"
		eval FORM_txantenna="\$FORM_txantenna_$device"
		eval FORM_rxantenna="\$FORM_rxantenna_$device"
		eval FORM_disabled="\$FORM_disabled_$device"
	fi
	
        append forms "start_form|@TR<<Wireless Adapter>> $device @TR<< Configuration>>" "$N"
        if [ "$iftype" = "broadcom" ]; then
        	append forms "helpitem|Broadcom Wireless Configuration" "$N"
		append forms "helptext|Helptext Broadcom Wireless Configuration#The router can be configured to handle multiple virtual interfaces which can be set to different modes and encryptions. Limitations are 1x sta, 0-3x ap or 1-4x ap or 1x adhoc" "$N"
	elif [ "$iftype" = "atheros" ]; then
        	append forms "helpitem|Atheros Wireless Configuration" "$N"
		append forms "helptext|Helptext Atheros Wireless Configuration#The router can be configured to handle multiple virtual interfaces which can be set to different modes and encryptions. Limitations are 1x sta, 0-4x ap or 1-4x ap or 1x adhoc" "$N"
	fi
	
        mode_disabled="field|@TR<<Radio>>
		select|disabled_$device|$FORM_disabled
		option|1|@TR<<Off>>
        	option|0|@TR<<On>>"
        append forms "$mode_disabled" "$N"
        	
        if [ "$iftype" = "atheros" ]; then
        	mode_fields="field|@TR<<Mode>>
			select|mode_ap_$device|$FORM_ap_mode"
		echo "$dmesg_txt" |grep -q "${device}: 11g"
		if [ "$?" = "0" ]; then
			mode_fields="$mode_fields
				option|11bg|@TR<<802.11B/G>>
				option|11g|@TR<<802.11G>>"
		fi
		echo "$dmesg_txt" |grep -q "${device}: 11b"
		if [ "$?" = "0" ]; then
			mode_fields="$mode_fields
				option|11b|@TR<<802.11B>>"
		fi
		echo "$dmesg_txt" |grep -q "${device}: 11a"
		if [ "$?" = "0" ]; then
			mode_fields="$mode_fields
				option|11a|@TR<<802.11A>>"
		fi
        append forms "$mode_fields" "$N"
        fi
        
        # Initialize channels based on country code
        # (--- hardly a switch here ---)
        case "$country" in
                All|all|ALL) 
                	    BGCHANNELS="1 2 3 4 5 6 7 8 9 10 11 12 13 14"; CHANNEL_MAX=14
                	    ACHANNELS="36 40 42 44 48 50 52 56 58 60 64 149 152 153 157 160 161 156";;
                *) 
                   BGCHANNELS="1 2 3 4 5 6 7 8 9 10 11"; CHANNEL_MAX=11
                   ACHANNELS="36 40 42 44 48 50 52 56 58 60 64 149 152 153 157 160 161 156";;
        esac
        
        BG_CHANNELS="field|@TR<<Channel>>|bgchannelform_$device|hidden
                select|bgchannel_$device|$FORM_channel
                option|0|@TR<<Auto>>"
        for ch in $BGCHANNELS; do
                BG_CHANNELS="$BG_CHANNELS
                        option|$ch"
        done
        
        A_CHANNELS="field|@TR<<Channel>>|achannelform_$device|hidden
                select|achannel_$device|$FORM_channel"
        for ch in $ACHANNELS; do
                A_CHANNELS="$A_CHANNELS
                        option|$ch"
        done
	append forms "$BG_CHANNELS" "$N"
	append forms "$A_CHANNELS" "$N"
	
	if [ "$iftype" = "atheros" ]; then
        	mode_diversity="field|@TR<<Diversity>>
			select|diversity_$device|$FORM_diversity
			option|1|@TR<<On>>
        		option|0|@TR<<Off>>"        	
        	append forms "$mode_diversity" "$N"
        	append forms "helpitem|Diversity" "$N"
		append forms "helptext|Helptext Diversity#Used on systems with multiple antennas to help improve reception. Disable if you only have one antenna." "$N"
		append forms "helplink|http://madwifi.org/wiki/UserDocs/AntennaDiversity" "$N"

        	form_txant="field|@TR<<TX Antenna>>
			select|txantenna_$device|$FORM_txantenna
			option|0|@TR<<Auto>>
        		option|1|@TR<<Antenna 1>>
        		option|2|@TR<<Antenna 2>>"
        	append forms "$form_txant" "$N"

        	form_rxant="field|@TR<<RX Antenna>>
			select|rxantenna_$device|$FORM_rxantenna
			option|0|@TR<<Auto>>
        		option|1|@TR<<Antenna 1>>
        		option|2|@TR<<Antenna 2>>"
        	append forms "$form_rxant" "$N"
        fi
        
	
	#Currently broadcom only.
	if [ "$iftype" = "broadcom" ]; then
        maxassoc="field|@TR<<Max Associated Clients (Default 128)>>
                text|maxassoc_${device}|$FORM_maxassoc"
	append forms "$maxassoc" "$N"
	fi
	
        distance="field|@TR<<Wireless Distance (In Meters)>>
                text|distance_${device}|$FORM_distance"

	append forms "$distance" "$N"
	append forms "helpitem|Wireless Distance" "$N"
        append forms "helptext|Helptext Wireless Distance#You must enter a number that is the distance of your longest link." "$N"

	add_vcfg="string|<tr><td><a href=$SCRIPT_NAME?add_vcfg=$device&amp;add_vcfg_number=$vcfg_number>@TR<<Add Virtual Interface>></a>"
        append forms "$add_vcfg" "$N"
        append forms "end_form" "$N"

	#####################################################################
	# This is looped for every virtual wireless interface (wifi-iface)
	#
        for vcfg in $vface; do
       		config_get FORM_device $vcfg device
       		if [ "$FORM_device" = "$device" ]; then
       			if empty "$FORM_submit"; then
	        		config_get FORM_network $vcfg network
	        		config_get FORM_mode $vcfg mode
	        		config_get FORM_ssid $vcfg ssid
	        		config_get FORM_encryption $vcfg encryption
	        		config_get FORM_key $vcfg key
	        		case "$FORM_key" in
	        			1|2|3|4) FORM_wep_key="$FORM_key"
	        				FORM_key="";;
	        		esac
	        		config_get FORM_key1 $vcfg key1
	        		config_get FORM_key2 $vcfg key2
	        		config_get FORM_key3 $vcfg key3
	        		config_get FORM_key4 $vcfg key4
	        		config_get FORM_server $vcfg server
	        		config_get FORM_radius_port $vcfg port
	        		config_get FORM_hidden $vcfg hidden
	        		config_get FORM_isolate $vcfg isolate
	        		config_get FORM_txpower $vcfg txpower
	        		config_get FORM_bgscan $vcfg bgscan
	        		config_get FORM_isolate $vcfg isolate
	        		config_get FORM_frag $vcfg frag
	        		config_get FORM_rts $vcfg rts
			else
				eval FORM_key="\$FORM_radius_key_$vcfg"
				eval FORM_radius_ipaddr="\$FORM_radius_ipaddr_$vcfg"
				
				eval FORM_encryption="\$FORM_encryption_$vcfg"
				case "$FORM_encryption" in
					psk|psk2) eval FORM_key="\$FORM_wpa_psk_$vcfg";;
					wpa|wpa2) eval FORM_key="\$FORM_radius_key_$vcfg";;
				esac
				eval FORM_mode="\$FORM_mode_$vcfg"
				eval FORM_server="\$FORM_server_$vcfg"
				eval FORM_radius_port="\$FORM_radius_port_$vcfg"
				eval FORM_hidden="\$FORM_broadcast_$vcfg"
				eval FORM_isolate="\$FORM_isolate_$vcfg"
				eval FORM_wep_key="\$FORM_wep_key_$vcfg"
				eval FORM_key1="\$FORM_key1_$vcfg"
				eval FORM_key2="\$FORM_key2_$vcfg"
				eval FORM_key3="\$FORM_key3_$vcfg"
				eval FORM_key4="\$FORM_key4_$vcfg"
				eval FORM_broadcast="\$FORM_broadcast_$vcfg"
				eval FORM_ssid="\$FORM_ssid_$vcfg"
				eval FORM_network="\$FORM_network_$vcfg"
				eval FORM_txpower="\$FORM_txpower_$vcfg"
				eval FORM_bgscan="\$FORM_bgscan_$vcfg"
				eval FORM_isolate="\$FORM_isolate_$vcfg"
				eval FORM_frag="\$FORM_frag_$vcfg"
				eval FORM_rts="\$FORM_rts_$vcfg"
			fi
			
			case "$FORM_mode" in
				ap) let "ap_count+=1";;
				sta) let "sta_count+=1";;
				adhoc) let "adhoc_count+=1";;
			esac
			
			append forms "start_form|@TR<<Wireless Virtual Adaptor Configuration for Wireless Card>> $FORM_device" "$N"
			network="field|@TR<<Network>>
	        	        select|network_$vcfg|$FORM_network
	        	        $network_options"
			append forms "$network" "$N"

			mode_fields="field|@TR<<WLAN Mode#Mode>>
			select|mode_$vcfg|$FORM_mode
			option|ap|@TR<<Access Point>>
			option|wds|@TR<<WDS>>
			option|sta|@TR<<Client>>
			option|adhoc|@TR<<Ad-Hoc>>"
			append forms "$mode_fields" "$N"
			append forms "helpitem|WDS Connections" "$N"
			append forms "helptext|Helptext WDS Connections#Enter the MAC address of the router on your network that should be wirelessly connected to. The other router must also support wds and have the mac address of this router entered." "$N"

			hidden="field|@TR<<ESSID Broadcast>>|broadcast_form_$vcfg|hidden
				select|broadcast_$vcfg|$FORM_hidden
				option|0|@TR<<Show>>
				option|1|@TR<<Hide>>"
			append forms "$hidden" "$N"
			
			if [ "$iftype" = "atheros" ]; then
			eval txpowers="\$CONFIG_wireless_${device}_txpower"
			if [ "$txpowers" = "" ]; then
				txpowers='1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16'
			fi
			txpower_field="field|@TR<<Tx Power>>
					select|txpower_$vcfg|$FORM_txpower"
			for txpower in $txpowers; do
				txpower_field="$txpower_field
						option|$txpower|$txpower dbm"
			done
			append forms "$txpower_field" "$N"
			
			bgscan_field="field|@TR<<Backround Client Scanning>>|bgscan_form_$vcfg|hidden
					select|bgscan_$vcfg|$FORM_bgscan
					option|1|@TR<<On>>
					option|0|@TR<<Off>>"
			append forms "$bgscan_field" "$N"
			append forms "helpitem|Backround Client Scanning" "$N"
			append forms "helptext|Helptext Backround Client Scanning#Enables or disables the ablility of a virtual interface to scan for other access points while in client mode. Disabling this allows for higher throughput but keeps your card from roaming to other access points with a higher signal strength." "$N"
			append forms "helplink|http://madwifi.org/wiki/UserDocs/PerformanceTuning" "$N"
			
			rts="field|@TR<<RTS (Default off)>>
				text|rts_$vcfg|$FORM_rts"
			append forms "$rts" "$N"

			frag="field|@TR<<Fragmentation (Default off)>>
				text|frag_$vcfg|$FORM_frag"
			append forms "$frag" "$N"
			fi

			isolate_field="field|@TR<<AP Isolation>>|isolate_form_$vcfg|hidden
					select|isolate_$vcfg|$FORM_isolate
					option|0|@TR<<Off>>
					option|1|@TR<<On>>"
			append forms "$isolate_field" "$N"

			ssid="field|@TR<<ESSID>>|ssid_form_$vcfg|hidden
				text|ssid_$vcfg|$FORM_ssid"
			append forms "$ssid" "$N"
			
			bssid="field|@TR<<BSSID>>|bssid_form_$vcfg|hidden
				text|bssid_$vcfg|$FORM_bssid"
			append forms "$bssid" "$N"

			###################################################################
			# Generate 4 40-bit WEP keys or 1 128-bit WEP Key
			eval FORM_wep_passphrase="\$FORM_wep_passphrase_$vcfg"
			eval FORM_generate_wep_128="\$FORM_generate_wep_128_$vcfg"
			eval FORM_generate_wep_40="\$FORM_generate_wep_40_$vcfg"
			! empty "$FORM_generate_wep_128" &&
			{
				FORM_wep_key="1"
				FORM_key1=""
				FORM_key2=""
				FORM_key3=""
				FORM_key4=""
				# generate a single 128(104)bit key
				if empty "$FORM_wep_passphrase"; then
					echo "<div class=warning>$EMPTY_passphrase_error</div>"
				else
					textkeys=$(wepkeygen -s "$FORM_wep_passphrase"  |
					 awk 'BEGIN { count=0 };
						{ total[count]=$1, count+=1; }
						END { print total[0] ":" total[1] ":" total[2] ":" total[3]}')
					FORM_key1=$(echo "$textkeys" | cut -d ':' -f 0-13 | sed s/':'//g)
					FORM_key2=""
					FORM_key3=""
					FORM_key4=""
					FORM_encryption="wep"
				fi
			}

			! empty "$FORM_generate_wep_40" &&
			{
				FORM_wep_key="1"
				FORM_key1=""
				FORM_key2=""
				FORM_key3=""
				FORM_key4=""
				# generate a single 128(104)bit key
				if empty "$FORM_wep_passphrase"; then
					echo "<div class=warning>$EMPTY_passphrase_error</div>"
				else
					textkeys=$(wepkeygen "$FORM_wep_passphrase" | sed s/':'//g)
					keycount=1
					for curkey in $textkeys; do
					case $keycount in
						1) FORM_key1=$curkey;;
						2) FORM_key2=$curkey;;
						3) FORM_key3=$curkey;;
						4) FORM_key4=$curkey
							break;;
					esac
					let "keycount+=1"
					done
					FORM_encryption="wep"
				fi
			
			}

			encryption_forms="field|@TR<<Encryption Type>>
				select|encryption_$vcfg|$FORM_encryption
				option|none|@TR<<Disabled>>
				option|wep|WEP
				option|psk|WPA (@TR<<PSK>>)
				option|psk2|WPA2 (@TR<<PSK>>)
				option|wpa|WPA (RADIUS)
				option|wpa2|WPA2 (RADIUS)"
			append forms "$encryption_forms" "$N"

			wep="field|@TR<<Passphrase>>|wep_keyphrase_$vcfg|hidden
				text|wep_passphrase_$vcfg|$FORM_wep_passphrase
				string|<br />
				field|&nbsp;|wep_generate_keys_$vcfg|hidden
				submit|generate_wep_40_$vcfg|@TR<<Generate 40bit Keys>>
				submit|generate_wep_128_$vcfg|@TR<<Generate 128bit Key>>
				string|<br />
				field|@TR<<WEP Key 1>>|wep_key_1_$vcfg|hidden
				radio|wep_key_$vcfg|$FORM_wep_key|1
				text|key1_$vcfg|$FORM_key1|<br />
				field|@TR<<WEP Key 2>>|wep_key_2_$vcfg|hidden
				radio|wep_key_$vcfg|$FORM_wep_key|2
				text|key2_$vcfg|$FORM_key2|<br />
				field|@TR<<WEP Key 3>>|wep_key_3_$vcfg|hidden
				radio|wep_key_$vcfg|$FORM_wep_key|3
				text|key3_$vcfg|$FORM_key3|<br />
				field|@TR<<WEP Key 4>>|wep_key_4_$vcfg|hidden
				radio|wep_key_$vcfg|$FORM_wep_key|4
				text|key4_$vcfg|$FORM_key4|<br />"
			append forms "$wep" "$N"

			wpa="field|WPA @TR<<PSK>>|wpapsk_$vcfg|hidden
				password|wpa_psk_$vcfg|$FORM_key
				field|@TR<<RADIUS IP Address>>|radius_ip_$vcfg|hidden
				text|server_$vcfg|$FORM_server
				field|@TR<<RADIUS Port>>|radius_port_form_$vcfg|hidden
				text|radius_port_$vcfg|$FORM_radius_port
				field|@TR<<RADIUS Server Key>>|radiuskey_$vcfg|hidden
				text|radius_key_$vcfg|$FORM_key"
			append forms "$wpa" "$N"
			
			if [ "$iftype" = "broadcom" ]; then
				install_nas_button="field|@TR<<NAS Package>>|install_nas_$vcfg|hidden"
				if ! equal "$nas_installed" "1"; then
					install_nas_button="$install_nas_button
						string|<div class=\"warning\">WPA and WPA2 will not work until you install the NAS package. </div>
						submit|install_nas| Install NAS Package |"
				else
					install_nas_button="$install_nas_button
					string|@TR<<Installed>>."
				fi
				append forms "$install_nas_button" "$N"
			elif [ "$iftype" = "atheros" ]; then
				install_hostapd_button="field|@TR<<HostAPD Package>>|install_hostapd_$vcfg|hidden"
				if ! equal "$hostapd_installed" "1"; then
					install_hostapd_button="$install_hostapd_button
						string|<div class=\"warning\">WPA and WPA2 will not work until you install the HostAPD package. </div>
						submit|install_hostapd| Install HostAPD Package |"
				else
					install_hostapd_button="$install_hostapd_button
						string|@TR<<Installed>>."
				fi

				install_wpa_supplicant_button="field|@TR<<wpa-supplicant Package>>|install_wpa_supplicant_$vcfg|hidden"
				if ! equal "$wpa_supplicant_installed" "1"; then
					install_wpa_supplicant_button="$install_wpa_supplicant_button
						string|<div class=\"warning\">WPA and WPA2 will not work until you install the wpa-supplicant package. </div>
						submit|install_wpa_supplicant| Install wpa-supplicant Package |"
				else
					install_wpa_supplicant_button="$install_wpa_supplicant_button
						string|@TR<<Installed>>."
				fi
				append forms "$install_hostapd_button" "$N"
				append forms "$install_wpa_supplicant_button" "$N"
			fi

			###################################################################
			# set JavaScript
			javascript_forms="
				v = isset('encryption_$vcfg','wep');
				set_visible('wep_key_1_$vcfg', v);
				set_visible('wep_key_2_$vcfg', v);
				set_visible('wep_key_3_$vcfg', v);
				set_visible('wep_key_4_$vcfg', v);
				set_visible('wep_generate_keys_$vcfg', v);
				set_visible('wep_keyphrase_$vcfg', v);
				set_visible('wep_keys_$vcfg', v);
				//
				// force encryption listbox to no selection if user tries
				// to set WPA (PSK) with Ad-hoc mode.
				//
				if (isset('mode_$vcfg','adhoc'))
				{
					if (isset('encryption_$vcfg','psk'))
					{
						document.getElementById('encryption_$vcfg').value = 'off';
					}
				}
				//
				// force encryption listbox to no selection if user tries
				// to set WPA (Radius) with anything but AP mode.
				//
				if (!isset('mode_$vcfg','ap'))
				{
					if (isset('encryption_$vcfg','wpa') || isset('encryption_$vcfg','wpa2'))
					{
						document.getElementById('encryption_$vcfg').value = 'off';
					}
				}
				v = (isset('mode_ap_$device','11b') || isset('mode_ap_$device','11bg') || isset('mode_ap_$device','11g'));
				set_visible('bgchannelform_$device', v);
				v = (isset('mode_ap_$device','11a'));
				set_visible('achannelform_$device', v);
				v = (!isset('mode_$vcfg','wds'));
				set_visible('ssid_form_$vcfg', v);
				set_visible('broadcast_form_$vcfg', v);
				v = (isset('mode_$vcfg','wds'));
				set_visible('bssid_form_$vcfg', v);
				v = (isset('mode_$vcfg','sta'));
				set_visible('bgscan_form_$vcfg', v);
				v = (isset('mode_$vcfg','ap'));
				set_visible('isolate_form_$vcfg', v);
				v = (isset('encryption_$vcfg','psk') || isset('encryption_$vcfg','psk2'));
				set_visible('wpapsk_$vcfg', v);
				v = (('$iftype'=='broadcom') && (isset('encryption_$vcfg','psk')) && (isset('encryption_$vcfg','psk2') || isset('encryption_$vcfg','wpa') || isset('encryption_$vcfg','wpa2')));
				set_visible('install_nas_$vcfg', v);
				v = (('$iftype'=='atheros') && (!isset('mode_$vcfg','sta')) && (isset('encryption_$vcfg','psk') || isset('encryption_$vcfg','psk2') || isset('encryption_$vcfg','wpa') || isset('encryption_$vcfg','wpa2')));
				set_visible('install_hostapd_$vcfg', v);
				v = (('$iftype'=='atheros') && (isset('mode_$vcfg','sta')) && (isset('encryption_$vcfg','psk') || isset('encryption_$vcfg','psk2') || isset('encryption_$vcfg','wpa') || isset('encryption_$vcfg','wpa2')));
				set_visible('install_wpa_supplicant_$vcfg', v);
				v = (isset('encryption_$vcfg','wpa') || isset('encryption_$vcfg','wpa2'));
				set_visible('radiuskey_$vcfg', v);
				set_visible('radius_ip_$vcfg', v);
				set_visible('radius_port_form_$vcfg', v);"
			append js "$javascript_forms" "$N"
			remove_vcfg="string|<tr><td><a href="$SCRIPT_NAME?remove_vcfg=$vcfg">@TR<<Remove Virtual Interface>></a>"
			append forms "helpitem|Encryption Type" "$N"
			append forms "helptext|HelpText Encryption Type#WPA (RADIUS) is only supported in Access Point mode. WPA (PSK) does not work in Ad-Hoc mode." "$N"
			append forms "$remove_vcfg" "$N"
			append forms "end_form" "$N"
			
			###################################################################
			# set validate forms
			case "$FORM_encryption" in
				psk|psk2) append validate_forms "wpapsk|FORM_wpa_psk_$vcfg|@TR<<WPA PSK#WPA Pre-Shared Key>>|required|$FORM_key" "$N";;
				wpa|wpa2) append validate_forms "string|FORM_radius_key_$vcfg|@TR<<RADIUS Server Key>>|min=4 max=63 required|$FORM_key" "$N"
					append validate_forms "ip|FORM_server_$vcfg|@TR<<RADIUS IP Address>>|required|$FORM_server" "$N"
					append validate_forms "port|FORM_radius_port_$vcfg|@TR<<RADIUS Port>>|required|$FORM_radius_port" "$N";;
				wep)
					append validate_forms "int|FORM_wep_key_$vcfg|@TR<<Selected WEP Key>>|min=1 max=4|$FORM_wep_key" "$N"
					append validate_forms "wep|FORM_key1_$vcfg|@TR<<WEP Key>> 1||$FORM_key1" "$N"
					append validate_forms "wep|FORM_key2_$vcfg|@TR<<WEP Key>> 2||$FORM_key2" "$N"
					append validate_forms "wep|FORM_key3_$vcfg|@TR<<WEP Key>> 3||$FORM_key3" "$N"
					append validate_forms "wep|FORM_key4_$vcfg|@TR<<WEP Key>> 4||$FORM_key4" "$N";;
			esac
			append validate_forms "string|FORM_ssid_$vcfg|@TR<<ESSID>>|required|$FORM_ssid" "$N"
			append validate_forms "int|FORM_frag_$vcfg|@TR<<Fragmentation Threshold>>|min=0 max=2346|$FORM_frag" "$N"
			append validate_forms "int|FORM_rts_$vcfg|@TR<<RTS Threshold>>|min=0 max=2347|$FORM_rts" "$N"
		fi
	done
	validate_wireless $iftype
done
if ! empty "$FORM_submit"; then
	empty "$FORM_generate_wep_128" && empty "$FORM_generate_wep_40" &&
	{
		SAVED=1
		validate <<EOF
$validate_forms
EOF
		equal "$?" 0 && {
			for device in $DEVICES; do
				eval FORM_ap_mode="\$FORM_ap_mode_$device"
				eval FORM_channel="\$FORM_bgchannel_$device"
				[ -z "$FORM_channel" ] && eval FORM_channel="\$FORM_achannel_$device"
				eval FORM_maxassoc="\$FORM_maxassoc_$device"
				eval FORM_distance="\$FORM_distance_$device"
				eval FORM_diversity="\$FORM_diversity_$device"
				eval FORM_txantenna="\$FORM_txantenna_$device"
				eval FORM_rxantenna="\$FORM_rxantenna_$device"
				eval FORM_disabled="\$FORM_disabled_$device"
				
				uci_set "wireless" "$device" "mode" "$FORM_ap_mode"
				uci_set "wireless" "$device" "channel" "$FORM_channel"
				uci_set "wireless" "$device" "maxassoc" "$FORM_maxassoc"
				uci_set "wireless" "$device" "distance" "$FORM_distance"
				uci_set "wireless" "$device" "diversity" "$FORM_diversity"
				uci_set "wireless" "$device" "txantenna" "$FORM_txantenna"
				uci_set "wireless" "$device" "rxantenna" "$FORM_rxantenna"
				uci_set "wireless" "$device" "disabled" "$FORM_disabled"

				for vcfg in $vface; do
     		  			config_get FORM_device $vcfg device
     		  			if [ "$FORM_device" = "$device" ]; then
						eval FORM_radius_key="\$FORM_radius_key_$vcfg"
						eval FORM_radius_ipaddr="\$FORM_radius_ipaddr_$vcfg"
						eval FORM_wpa_psk="\$FORM_wpa_psk_$vcfg"
						eval FORM_encryption="\$FORM_encryption_$vcfg"
						eval FORM_mode="\$FORM_mode_$vcfg"
						eval FORM_server="\$FORM_server_$vcfg"
						eval FORM_radius_port="\$FORM_radius_port_$vcfg"
						eval FORM_hidden="\$FORM_broadcast_$vcfg"
						eval FORM_isolate="\$FORM_isolate_$vcfg"
						eval FORM_wep_key="\$FORM_wep_key_$vcfg"
						eval FORM_key1="\$FORM_key1_$vcfg"
						eval FORM_key2="\$FORM_key2_$vcfg"
						eval FORM_key3="\$FORM_key3_$vcfg"
						eval FORM_key4="\$FORM_key4_$vcfg"
						eval FORM_broadcast="\$FORM_broadcast_$vcfg"
						eval FORM_ssid="\$FORM_ssid_$vcfg"
						eval FORM_bssid="\$FORM_bssid_$vcfg"
						eval FORM_network="\$FORM_network_$vcfg"
						eval FORM_txpower="\$FORM_txpower_$vcfg"
						eval FORM_bgscan="\$FORM_bgscan_$vcfg"
						eval FORM_isolate="\$FORM_isolate_$vcfg"
						eval FORM_isolate="\$FORM_rts_$vcfg"
						eval FORM_isolate="\$FORM_frag_$vcfg"

						uci_set "wireless" "$vcfg" "network" "$FORM_network"
						uci_set "wireless" "$vcfg" "ssid" "$FORM_ssid"
						uci_set "wireless" "$vcfg" "bssid" "$FORM_bssid"
						uci_set "wireless" "$vcfg" "mode" "$FORM_mode"
						uci_set "wireless" "$vcfg" "encryption" "$FORM_encryption"
						uci_set "wireless" "$vcfg" "server" "$FORM_server"
						uci_set "wireless" "$vcfg" "port" "$FORM_radius_port"
						uci_set "wireless" "$vcfg" "hidden" "$FORM_hidden"
						uci_set "wireless" "$vcfg" "isolate" "$FORM_isolate"
						uci_set "wireless" "$vcfg" "txpower" "$FORM_txpower"
						uci_set "wireless" "$vcfg" "bgscan" "$FORM_bgscan"
						uci_set "wireless" "$vcfg" "frag" "$FORM_frag"
						uci_set "wireless" "$vcfg" "rts" "$FORM_rts"
						
						case "$FORM_encryption" in
							wep) uci_set "wireless" "$vcfg" "key" "$FORM_wep_key";;
							psk|psk2) uci_set "wireless" "$vcfg" "key" "$FORM_wpa_psk";;
							wpa|wpa2) uci_set "wireless" "$vcfg" "key" "$FORM_radius_key";;
						esac
						uci_set "wireless" "$vcfg" "key1" "$FORM_key1"
						uci_set "wireless" "$vcfg" "key2" "$FORM_key2"
						uci_set "wireless" "$vcfg" "key3" "$FORM_key3"
						uci_set "wireless" "$vcfg" "key4" "$FORM_key4"
					fi
				done
			done
		}
	}
fi



#####################################################################
# modechange script
#
cat <<EOF
<script type="text/javascript" src="/webif.js"></script>
<script type="text/javascript">
<!--
function modechange()
{
	var v;
	$js

	hide('save');
	show('save');
}
-->
</script>

EOF


display_form <<EOF
onchange|modechange
$validate_error
$forms
EOF

footer ?>
<!--
##WEBIF:name:Network:300:Wireless
-->
