#! /usr/bin/env bash

# ======== COLORS ======== #

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NO_COLOR='\033[0m'

# ======== LOGGING ======== #

# Set log level to INFO if it doesn't exist
if [[ -z "${LOG_LEVEL}" ]]; then
  export LOG_LEVEL="INFO"
fi

# Setup variable for log level comparison
function _set_log_level {
    case ${LOG_LEVEL} in
        FATAL)
            export LOG_LEVEL_INT=0
            ;;
        SUCCESS)
            export LOG_LEVEL_INT=1
            ;;
        ERROR)
            export LOG_LEVEL_INT=2
            ;;
        WARN)
            export LOG_LEVEL_INT=3
            ;;
        INFO)
            export LOG_LEVEL_INT=4
            ;;
        DEBUG)
            export LOG_LEVEL_INT=5
            ;;
        TRACE)
            export LOG_LEVEL_INT=6
            ;;
        *)
            echo "[${YELLOW}WARN${NO_COLOR}] :: Invalid log level '${LOG_LEVEL}' -- setting level to 'INFO'"
            export LOG_LEVEL='INFO'
            export LOG_LEVEL_INT=4
            ;;
    esac
}

# Print out log statement depending on level
function _log {
    LEVEL=$1
    MESSAGE=$2
    case ${LEVEL} in
        FATAL)
            if [[ ${LOG_LEVEL_INT} -ge 0 ]]; then
                echo -e "[${RED}FATAL${NO_COLOR}] :: ${MESSAGE}"
                exit 1
            fi
            ;;
        SUCCESS)
            if [[ ${LOG_LEVEL_INT} -ge 1 ]]; then
                echo -e "[${GREEN}SUCCESS${NO_COLOR}] :: ${MESSAGE}"
            fi
            ;;
        ERROR)
            if [[ ${LOG_LEVEL_INT} -ge 2 ]]; then
                echo -e "[${RED}ERROR${NO_COLOR}] :: ${MESSAGE}"
            fi
            ;;
        WARN)
            if [[ ${LOG_LEVEL_INT} -ge 3 ]]; then
                echo -e "[${YELLOW}WARN${NO_COLOR}] :: ${MESSAGE}"
            fi
            ;;
        INFO)
            if [[ ${LOG_LEVEL_INT} -ge 4 ]]; then
                echo -e "[${GREEN}INFO${NO_COLOR}] :: ${MESSAGE}"
            fi
            ;;
        DEBUG)
            if [[ ${LOG_LEVEL_INT} -ge 5 ]]; then
                echo -e "[${CYAN}DEBUG${NO_COLOR}] :: ${MESSAGE}"
            fi
            ;;
        TRACE)
            if [[ ${LOG_LEVEL_INT} -ge 6 ]]; then
                echo -e "[${BLUE}TRACE${NO_COLOR}] :: ${MESSAGE}"
            fi
            ;;
        *)
            echo "Invalid log level: ${LEVEL}"
    esac
}

_set_log_level

pushd ~/code >/dev/null || exit 1

for dir in */; do
    dir="${dir%/}"

    for subdir in "${dir}"/*/; do
        subdir="${subdir%/}"

        # Skip if the glob didn't match anything.
        [ -d "${subdir}" ] || continue

        # Skip sub-directories that aren't git repositories.
        [ -d "${subdir}/.git" ] || continue

        # Refresh remote-tracking refs so the pushed/merged check reflects the
        # actual remote state rather than stale local knowledge.
        git -C "${subdir}" fetch --quiet --prune 2>/dev/null

        reasons=()

        # 1. Working tree: untracked / modified / unmerged changes.
        if [ -n "$(git -C "${subdir}" status --porcelain)" ]; then
            reasons+=("uncommitted/untracked changes")
        fi

        # 2. Committed but not pushed to a remote and not merged into main.
        #    First check the upstream tracking state. If the branch once had an
        #    upstream that is now gone (deleted after a squash-merge + branch
        #    delete), the branch's original commits won't be reachable from
        #    origin/main by SHA even though the work has landed -- so treat a
        #    "gone" upstream as safe rather than flagging it.
        branch="$(git -C "${subdir}" symbolic-ref --quiet --short HEAD 2>/dev/null)"
        track="$(git -C "${subdir}" for-each-ref --format='%(upstream:track)' "refs/heads/${branch}" 2>/dev/null)"

        if [ "${track}" = "[gone]" ]; then
            :  # upstream was deleted -> merged/cleaned up, considered safe.
        else
            #    Build the set of refs that count as "safe" (pushed or merged):
            #    every remote-tracking branch, plus local main/master if present.
            excludes=(--remotes)
            for base in main master; do
                if git -C "${subdir}" show-ref --verify --quiet "refs/heads/${base}"; then
                    excludes+=("${base}")
                fi
            done

            unpushed="$(git -C "${subdir}" rev-list HEAD --not "${excludes[@]}" 2>/dev/null)"
            if [ -n "${unpushed}" ]; then
                reasons+=("commits not pushed/merged")
            fi
        fi

        if [ "${#reasons[@]}" -gt 0 ]; then
            reason_str="${reasons[0]}"
            for r in "${reasons[@]:1}"; do
                reason_str="${reason_str}; ${r}"
            done
            _log "ERROR" "DIRTY  ${subdir} (${reason_str})"
            git -C "${subdir}" status
        else
            _log "INFO" "CLEAN  ${subdir}"
        fi
        _log "DEBUG" "Branch: ${branch}"

        printf "Do you want to delete this directory? [y/n] "
        read -r answer </dev/tty
        if [ "${answer}" = "y" ]; then
            _log "INFO" "Deleting ${subdir}"
            rm -rf "${subdir}"
            _log "SUCCESS" "Deleted ${subdir}"

            # If no git repos remain in the parent directory, remove it too.
            remaining=0
            for other in "${dir}"/*/; do
                other="${other%/}"
                [ -d "${other}/.git" ] && remaining=$((remaining + 1))
            done
            if [ "${remaining}" -eq 0 ]; then
                rm -rf "${dir}"
                _log "SUCCESS" "Deleted empty parent ${dir}"
            fi
        fi
        echo ""
    done
done

popd >/dev/null
