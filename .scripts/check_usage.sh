#memcheck = " free | grep Mem | awk '{print $3/$2 * 100.0}' "
last_ram_alert_time=0
last_temp_alert_time=0
last_battery_alert_time=0

while true; do
	total_mem=$(free | grep Mem | awk '{print $2}')
	used_mem=$(free | grep Mem | awk '{print $3}')
	mem_percentage=$((100 * used_mem / total_mem))
	current_time=$(date +%s)
	if [ $mem_percentage -gt 90 ] && [ $((current_time - last_ram_alert_time)) -ge 45 ]; then
		notify-send "󱘤 High RAM usage ($mem_percentage%)" ""
		last_ram_alert_time=$current_time
	fi
	temp=$(sensors | grep 'Package id 0:' | awk '{print $4}' | tr -d '+°C')
	if [ ${temp%.*} -gt 80 ] && [ $((current_time - last_temp_alert_time)) -ge 45 ]; then
		notify-send -u critical "󰸁 High temperature ($temp°C)" ""
		last_temp_alert_time=$current_time
	fi
	battery_percentage=$(upower -i $(upower -e | grep BAT) | grep percentage | awk '{print $2}' | tr -d '%')
	if [ $battery_percentage -lt 10 ] && [ $((current_time - last_battery_alert_time)) -ge 480 ]; then
		notify-send -u normal "󱃍 Low Battery ($battery_percentage% remaining)" ""
		last_battery_alert_time=$current_time
	fi
	sleep 1
done
