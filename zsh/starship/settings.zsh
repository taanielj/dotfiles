# What is tuned by hand: the options, and the lists the other files read.

# What each STARSHIP_<NAME> can be, the default first. Set them in ~/.zshrc.local,
# for one shell as `STARSHIP_LOOK=segments exec zsh`, or with prompt-style.
#   look       coloured text, as p10k's lean style, or coloured blocks
#   colors     a palette in base.toml
#   sep        how segments join; pill keeps them apart
#   spacing    airy pads the segments and puts a blank line above the prompt
#   lines      the command on its own line, on the prompt's, or on its own in a frame
#   align      status, duration, kube, time...: at the right edge, or after git
#   transient  whether a finished prompt collapses to ❯ and its command
typeset -ga _starship_option_names=(look colors sep spacing lines align transient)
typeset -gA _starship_option_values=(
    look 'lean segments'
    colors 'catppuccin p10k gruvbox'
    sep 'arrow round pill'
    spacing 'compact airy'
    lines '2 1 frame'
    align 'justify left'
    transient 'on off'
)

# Kube context and gcloud project show only while the typed line starts with one
# of these. An entry ending in a space waits for that space: 's ' doesn't show
# on `sleep`.
typeset -ga _starship_kube_commands=(
    'k ' 'ka ' 'kl ' 'kc ' 'kn ' 'kcn ' 'kcnp ' 'kp ' 'kd ' 'ke '
    's ' 'sj ' 'sg ' 'sd ' 'sc ' 'oc '
    kubectl kubens kubectx kubecolor kubeseal kubent k9s helm helmfile flux fluxctl
    stern istioctl kogito skaffold cmctl sparkctl
)
typeset -ga _starship_gcloud_commands=(gcs gcloud gsutil bq)
# The variable base.toml gates the module on, and its commands
typeset -gA _starship_show_on=(
    STARSHIP_KUBE _starship_kube_commands
    STARSHIP_GCLOUD _starship_gcloud_commands
)

# Icons for origin remotes by URL pattern, e.g. starship_git_host_icons[*host.example*]=$'\U100000';
# ~/.zshrc.local or an overlay it sources can add some before this file loads.
typeset -gA starship_git_host_icons

# A folder holding one of these is an anchor: never shortened, and bold. The
# list matches anchor_files in zsh/p10k.zsh.
typeset -g _starship_anchor_files='(.bzr|.citc|.git|.hg|.node-version|.python-version|.go-version|.ruby-version|.lua-version|.java-version|.perl-version|.php-version|.tool-versions|.shorten_folder_marker|.svn|.terraform|CVS|Cargo.toml|composer.json|go.mod|package.json|stack.yaml)'

# The segments look: each module's table in base.toml, the segment it joins and
# its text. A text starts with a space; segments.zsh adds the one at its end.
typeset -ga _starship_segment_modules=(
    'env_var.STARSHIP_GIT_HOST_ICON git  $env_value'
    'git_branch git  $symbol$branch'
    'git_commit git  @$hash$tag'
    'git_state git  $state( $progress_current/$progress_total)'
    'status status  ✘$status'
    'cmd_duration duration  \uF252 $duration'
    'jobs jobs  $symbol'
    'env_var.DIRENV_DIR direnv  ▼'
    'python python  $symbol$virtualenv'
    'kubernetes kube  $symbol$context(/$namespace)'
    'gcloud gcloud  $symbol$project'
    'aws aws  $symbol$profile( $region)'
    'username user  $user'
    'hostname user @$hostname'
    'time time  \uF017 $time'
)
typeset -ga _starship_git_status_counts=(
    ahead '⇡$count' behind '⇣$count' diverged '⇣$behind_count ⇡$ahead_count'
    stashed '*$count' conflicted '~$count' staged '+$count' modified '!$count'
    renamed '»$count' deleted '✘$count' untracked '?$count'
)
