#!/bin/bash

usage(){
	echo "./run_target.sh -t [TARGET] -r [REPS] -s [SECONDS] -f [FUZZER] -m [MODE] -i [INDEX] -o [OUTPUT]"
	exit 0
}

if [[ -z $PFBENCH ]]; then
	PFBENCH='.'
fi

while [[ $# -gt 0 ]]; do
 	key="$1"

	case $key in
		-t|--target)
			shift
			target="$1" ;;
		-r|--reps)
			shift
			reps="$1" ;;
		-s|--seconds)
			shift
			seconds="$1" ;;
		-f|--fuzzer)
			shift
			Fuzzer="$1" ;;
		-m|--mode)
			shift
			Mode="-$1" ;;
		-i|--index)
			shift
			idx="$1" ;;
		-o|--output)
			shift
			output="$1" ;;
		*)
			echo "Unknown option: $key" ;;
	esac

	shift
done

if [[ -z $target || -z $reps || -z $Fuzzer ]]; then
	usage
fi

if [[ -z $seconds ]]; then
	seconds=86400
fi

if [[ -z $output ]]; then
	output='.'
fi

if [[ -z $Mode ]]; then
	Mode="-all"
elif [ $Fuzzer != "HNPFuzzer" ]; then
	echo "-m option can only be set with HNPFuzzer"
	exit 0
fi

if [[ ${Mode:1} == "persistent" ]]; then
	run_args="-I -Y "
elif [[ ${Mode:1} == "shared" ]]; then
	run_args="-K "
elif [[ ${Mode:1} == "sync" ]]; then
	run_args="-I -K "
elif [[ ${Mode:1} == "all" ]]; then
	run_args=" "
else
	echo "Unknown mode $Mode"
	exit 0
fi

if [[ $Fuzzer != "aflnet" && $Fuzzer != "aflnwe" ]]; then
	image_suffix="-${Fuzzer,,}"
fi

case $target in
	"dnsmasq" )
		if [[ ${Mode:1} == "shared" ]]; then
			echo "Shared Mode is equivalent to All Mode on protocols based on UDP"
			Mode="-all"
		fi
		if [[ ${Mode:1} == "sync" || ${Mode:1} == "all" ]]; then
			if [[ ${Mode:1} == "all" ]]; then
				run_args+="-K"
			fi
			if [[ $Fuzzer == "HNPFuzzer" ]]; then
				options="-P DNS -t 1000 -m none -D 10000 -q 3 -s 3 -E ${run_args}"
			elif [[ $Fuzzer == "aflnet" ]]; then
				options="-P DNS -D 10000 -K"
			elif [[ $Fuzzer == "aflnwe" ]]; then
				options="-D 10000 -K"
			elif [[ $Fuzzer == "stateafl" ]]; then
				options="-P DNS -t 5000 -m none -D 10000 -q 3 -s 3 -E -K"
			else
				echo "Unknown fuzzer $Fuzzer"
				exit 0
			fi
			if [[ $Fuzzer != "HNPFuzzer" ]]; then
				unset Mode
			fi
			$PFBENCH/scripts/execution/profuzzbench_exec_common.sh dnsmasq${image_suffix} $reps ${output}/results-dnsmasq-${Fuzzer}${Mode}${idx} ${Fuzzer} out-dnsmasq-${Fuzzer} "${options}" ${seconds} 5 &
		else
			echo "Persistent Mode does not support protocols based on UDP"
			exit 0
		fi ;;
	
	"dcmtk" )
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-P DICOM -t 5000 -m none -D 10000 -q 3 -s 3 -E ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-P DICOM -t 5000 -m none -D 10000 -q 3 -s 3 -E -K"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-D 10000 -K"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-P DICOM -t 5000+ -m none -D 10000 -q 3 -s 3 -E -K"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh dcmtk${image_suffix} $reps ${output}/results-dcmtk-${Fuzzer}${Mode}${idx} ${Fuzzer} out-dcmtk-${Fuzzer} "${options}" ${seconds} 5 &
		;;

	"tinydtls" )
		if [[ ${Mode:1} == "shared" ]]; then
			echo "Shared Mode is equivalent to All Mode on protocols based on UDP"
			Mode="-all"
		fi
		if [[ ${Mode:1} == "sync" || ${Mode:1} == "all" ]]; then
			if [[ ${Mode:1} == "all" ]]; then
				run_args+="-K"
			fi
			if [[ $Fuzzer == "HNPFuzzer" ]]; then
				options="-P DTLS12 -m none -D 10000 -q 3 -s 3 -E -W 30 ${run_args}"
			elif [[ $Fuzzer == "aflnet" ]]; then
				options="-P DTLS12 -m none -D 10000 -q 3 -s 3 -E -K -W 30"
			elif [[ $Fuzzer == "aflnwe" ]]; then
				options="-D 10000 -K -W 30"
			elif [[ $Fuzzer == "stateafl" ]]; then
				options="-P DTLS12 -t 1000 -m none -D 10000 -q 3 -s 3 -E -K -W 30"
			else
				echo "Unknown fuzzer $Fuzzer"
				exit 0
			fi
			if [[ $Fuzzer != "HNPFuzzer" ]]; then
				unset Mode
			fi
			$PFBENCH/scripts/execution/profuzzbench_exec_common.sh tinydtls${image_suffix} $reps ${output}/results-tinydtls-${Fuzzer}${Mode}${idx} ${Fuzzer} out-tinydtls-${Fuzzer} "${options}" ${seconds} 5 &
		else
			echo "Persistent Mode does not support protocols based on UDP"
			exit 0
		fi ;;

	"forked-daapd" )
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-P HTTP -D 200000 -m none -t 5000+ -q 3 -s 3 ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-P HTTP -D 200000 -m none -t 5000+ -q 3 -s 3 -E -K -W 15"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-D 200000 -m 1000 -t 3000+ -K"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-P HTTP -D 200000 -m none -t 6000+ -q 3 -s 3 -E -K -W 30"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh forked-daapd${image_suffix} $reps ${output}/results-forked-daapd-${Fuzzer}${Mode}${idx} ${Fuzzer} out-forked-daapd-${Fuzzer} "${options}" ${seconds} 5 &
		;;
	
	"lightftp" )
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-P FTP -t 1000 -m none -D 10000 -q 3 -s 3 -E ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-P FTP -t 1000 -m none -D 10000 -q 3 -s 3 -E -K"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-D 10000 -K"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-P FTP -t 1000 -m none -D 10000 -q 3 -s 3 -E"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh lightftp${image_suffix} $reps ${output}/results-lightftp-${Fuzzer}${Mode}${idx} ${Fuzzer} out-lightftp-${Fuzzer} "${options}" ${seconds} 5 &
		;;

	"pureftpd" )
		if [[ ${Mode:1} != "persistent" && ${Mode:1} != "all" ]]; then
			image_suffix+="-nofork"
		fi
		if [[ ${Mode:1} == "shared" || ${Mode:1} == "all" ]]; then
			run_args+="-t 1000"
		else
			run_args+="-t 1000+"
		fi
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-m none -P FTP -D 10000 -q 3 -s 3 -E ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-t 1000+ -m none -P FTP -D 10000 -q 3 -s 3 -E -K"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-t 1000+ -m none -D 10000 -K"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-t 1000+ -m none -P FTP -D 10000 -q 3 -s 3 -E -K"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh pureftpd${image_suffix} $reps ${output}/results-pure-ftpd-${Fuzzer}${Mode}${idx} ${Fuzzer} out-pure-ftpd-${Fuzzer} "${options}" ${seconds} 5 &
		;;

	"proftpd" )
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-t 1000+ -m none -P FTP -D 10000 -q 3 -s 3 -E ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-t 1000+ -m none -P FTP -D 10000 -q 3 -s 3 -E -K"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-t 1000+ -m none -D 10000 -K"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-t 1000+ -m none -P FTP -D 10000 -q 3 -s 3 -E -K"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh proftpd${image_suffix} $reps ${output}/results-proftpd-${Fuzzer}${Mode}${idx} ${Fuzzer} out-proftpd-${Fuzzer} "${options}" ${seconds} 5 &
		;;

	"bftpd" )
		if [[ ${Mode:1} != "persistent" && ${Mode:1} != "all" ]]; then
			image_suffix+="-nofork"
		fi
		if [[ ${Mode:1} == "shared" || ${Mode:1} == "all" ]]; then
			run_args+="-t 500"
		else
			run_args+="-t 1000+"
		fi
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-m none -P FTP -D 10000 -q 3 -s 3 -E ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-t 1000+ -m none -P FTP -D 10000 -q 3 -s 3 -E -K"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-t 1000+ -m none -D 10000 -K"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-t 1000+ -m none -P FTP -D 10000 -q 3 -s 3 -E -K"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh bftpd${image_suffix} $reps ${output}/results-bftpd-${Fuzzer}${Mode}${idx} ${Fuzzer} out-bftpd-${Fuzzer} "${options}" ${seconds} 5 &
		;;
	
	"live555" )
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-P RTSP -m none -D 10000 -q 3 -s 3 -E -R ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-P RTSP -D 10000 -q 3 -s 3 -E -K -R"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-D 10000 -K"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-P RTSP -t 1000 -m none -D 10000 -q 3 -s 3 -E -K -R"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh live555${image_suffix} $reps ${output}/results-live555-${Fuzzer}${Mode}${idx} ${Fuzzer} out-live555-${Fuzzer} "${options}" ${seconds} 5 &
		;;

	"kamailio" )
		if [[ ${Mode:1} == "sync" ]]; then
			run_args+="-l 5061"
		fi
		if [[ ${Mode:1} == "shared" ]]; then
			echo "Shared Mode is equivalent to All Mode on protocols based on UDP"
			Mode="-all"
		fi
		if [[ ${Mode:1} == "sync" || ${Mode:1} == "all" ]]; then
			if [[ ${Mode:1} == "all" ]]; then
				run_args+="-K"
			fi
			if [[ $Fuzzer == "HNPFuzzer" ]]; then
				options="-m none -t 3000+ -P SIP -D 50000 -q 3 -s 3 -E ${run_args}"
			elif [[ $Fuzzer == "aflnet" ]]; then
				options="-m none -t 3000+ -P SIP -l 5061 -D 50000 -q 3 -s 3 -E -K"
			elif [[ $Fuzzer == "aflnwe" ]]; then
				options="-m none -t 3000+ -D 50000 -K"
			elif [[ $Fuzzer == "stateafl" ]]; then
				options="-m none -t 3000+ -P SIP -D 70000 -l 5061 -q 3 -s 3 -E -K"
			else
				echo "Unknown fuzzer $Fuzzer"
				exit 0
			fi
			if [[ $Fuzzer != "HNPFuzzer" ]]; then
				unset Mode
			fi
			$PFBENCH/scripts/execution/profuzzbench_exec_common.sh kamailio${image_suffix} $reps ${output}/results-kamailio-${Fuzzer}${Mode}${idx} ${Fuzzer} out-kamailio-${Fuzzer} "${options}" ${seconds} 5 &
		else
			echo "Persistent Mode does not support protocols based on UDP"
			exit 0
		fi ;;

	"exim" )
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-P SMTP -D 10000 -m none -q 3 -s 3 -E -W 100 ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-P SMTP -D 10000 -q 3 -s 3 -E -K -W 100"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-D 10000 -K -W 100"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-P SMTP -D 10000 -t 5000 -m none -q 3 -s 3 -E -K -W 100"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh exim${image_suffix} $reps ${output}/results-exim-${Fuzzer}${Mode}${idx} ${Fuzzer} out-exim-${Fuzzer} "${options}" ${seconds} 5 &
		;;

	"openssh" )
		if [[ ${Mode:1} == "persistent" || ${Mode:1} == "sync" ]]; then
			run_args+="-t 3000"
		else
			run_args+="-t 500"
		fi
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-P SSH -m none -D 10000 -q 3 -s 3 -E -W 10 ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-P SSH -t 3000 -m none -D 10000 -q 3 -s 3 -E -K -W 10"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-D 10000 -K -W 10 -m none"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-P SSH -t 3000 -m none -D 10000 -q 3 -s 3 -E -K -W 10"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh openssh${image_suffix} $reps ${output}/results-openssh-${Fuzzer}${Mode}${idx} ${Fuzzer} out-openssh-${Fuzzer} "${options}" ${seconds} 5 &
		;;

	"openssl" )
		if [[ $Fuzzer == "HNPFuzzer" ]]; then
			options="-P TLS -D 10000 -m none -q 3 -s 3 -E -R -W 100 ${run_args}"
		elif [[ $Fuzzer == "aflnet" ]]; then
			options="-P TLS -D 10000 -q 3 -s 3 -E -K -R -W 100"
		elif [[ $Fuzzer == "aflnwe" ]]; then
			options="-D 10000 -K -W 100"
		elif [[ $Fuzzer == "stateafl" ]]; then
			options="-P TLS -t 1000+ -D 10000 -m none -q 3 -s 3 -E -K -R -W 100"
		else
			echo "Unknown fuzzer $Fuzzer"
			exit 0
		fi
		if [[ $Fuzzer != "HNPFuzzer" ]]; then
			unset Mode
		fi
		$PFBENCH/scripts/execution/profuzzbench_exec_common.sh openssl${image_suffix} $reps ${output}/results-openssl-${Fuzzer}${Mode}${idx} ${Fuzzer} out-openssl-${Fuzzer} "${options}" ${seconds} 5 &
		;;

	* )
		echo "Unknown target: $target" ;;
esac
