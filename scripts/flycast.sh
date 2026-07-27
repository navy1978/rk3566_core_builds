#!/bin/bash

##################################################################
# Created by Christian Haitian for use to easily update          #
# various standalone emulators, libretro cores, and other        #
# various programs for the RK3566 platform for various Linux     #
# based distributions.                                           #
# See the LICENSE.md file at the top-level directory of this     #
# repository.                                                    #
##################################################################

cur_wd="$PWD"
bitness="$(getconf LONG_BIT)"

	# Libretro Flycast build
	if [[ "$var" == "flycast" || "$var" == "all" ]]; then
	 cd $cur_wd
	  if [ ! -d "flycast/" ]; then
		git clone https://github.com/navy1978/flycast2022-lowend.git flycast
		if [[ $? != "0" ]]; then
		  echo " "
		  echo "There was an error while cloning the Flycast 2022 Low-End git.  Is Internet active or did the git location change?  Stopping here."
		  exit 1
		fi
	  else
		git -C flycast remote set-url origin https://github.com/navy1978/flycast2022-lowend.git
		git -C flycast pull --ff-only origin master
		if [[ $? != "0" ]]; then
		  echo " "
		  echo "There was an error while updating Flycast 2022 Low-End.  Stopping here."
		  exit 1
		fi
	  fi

	 cd flycast/

	  if [[ "$bitness" == "64" ]]; then
		# The bundled GCC 9.x AICA profile is trained and validated on RK3566.
		# The wrapper verifies the profile and always starts from a clean tree.
		make rk3566-pgo JOBS="$(nproc)"
	  else
		make clean
		make FORCE_GLES=1 platform=classic_armv8_a35 -j$(nproc)
	  fi

	  if [[ $? != "0" ]]; then
		echo " "
		echo "There was an error while building the newest lr-flycast core.  Stopping here."
		exit 1
	  fi

	  strip flycast_libretro.so

	  if [ ! -d "../cores$bitness/" ]; then
		mkdir -v ../cores$bitness
	  fi

	  cp flycast_libretro.so ../cores$bitness/.

	  # This fork uses the standard libretro rumble interface.  Keep the
	  # historical dArkOS filenames without applying the old direct-PWM patch.
	  if [[ "$bitness" == "64" ]]; then
		cp flycast_libretro.so ../cores$bitness/flycast_rumble_libretro.so
	  else
		cp flycast_libretro.so ../cores$bitness/flycast32_rumble_libretro.so
	  fi

	  gitcommit=$(git rev-parse --short HEAD)
	  echo "$gitcommit" > ../cores$bitness/flycast_libretro.so.commit
	  if [[ "$bitness" == "64" ]]; then
		echo "$gitcommit" > ../cores$bitness/flycast_rumble_libretro.so.commit
	  else
		echo "$gitcommit" > ../cores$bitness/flycast32_rumble_libretro.so.commit
	  fi

	  echo " "
	  echo "Flycast 2022 Low-End cores have been placed in the rk3566_core_builds/cores$bitness subfolder"
	fi
