source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# opencode
fish_add_path /home/ropali/.opencode/bin

# reload fish shell (re-sources config.fish + conf.d/*)
alias sz "exec fish"
