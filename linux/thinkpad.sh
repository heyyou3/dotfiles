while true; do
  if [ "$(synclient -l | grep 'Touchpad' | perl -anlE 'say $F[2]')" == 0 ]; then
    synclient TouchPadOff=1
  fi
  sleep 1
done
