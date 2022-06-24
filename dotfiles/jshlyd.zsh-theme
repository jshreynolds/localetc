# ZSH Theme - 
# Based on gnzh theme

setopt prompt_subst

() {

local PR_USER PR_USER_OP PR_PROMPT PR_HOST

# Check the UID
PR_USER='%F{green}%n%f'
PR_USER_OP='%F{green}%#%f'
PR_PROMPT='%f➤ %f'
PR_HOST='%F{green}%M%f' # no SSH

local return_code="%(?..%F{red}%? ↵%f)"

local user_host="${PR_USER}%F{cyan}@${PR_HOST}"
local current_dir="%B%F{blue}%~%f%b"
local git_branch='$(git_prompt_info)'

PROMPT="${current_dir} ${git_branch}
$PR_PROMPT"
RPROMPT="${return_code}"

ZSH_THEME_GIT_PROMPT_PREFIX="%F{yellow}‹"
ZSH_THEME_GIT_PROMPT_SUFFIX="› %f"

}
