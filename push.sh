#!/bin/bash
# Käännä koodi, kopsaa heksa inboksiin ja lähetä laitteelle.
avra main.asm
if [ $? -eq 0 ]; then
    mv main.hex "/home/taira/inbox/hex_out.hex"
    bash /home/taira/skriptit/puske.sh
fi
