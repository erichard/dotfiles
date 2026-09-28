if status is-interactive
    # Commands to run in interactive sessions can go here
end
fish_add_path $HOME/.local/bin
set -gx SSH_AUTH_SOCK ~/.1password/agent.sock
source /home/erwan/.config/op/plugins.sh

# opencode
fish_add_path /home/erwan/.opencode/bin
