PROGRAM=${0##*/}
MAJOR_VER='0.0.2'
MINOR_VER=''
VERSION="${MAJOR_VER}${MINOR_VER}"

workdir="$(PWD)"
verbose=0
domain=
url=
mirror_dir="${workdir}/mirror"
mirror_log_dir="${workdir}/mirror_log"
imgroot="quay.io/ovrclk"
baseimg="${imgroot}/demo-base"
img=
rmfiles=1
errlog=$(mktemp -t ${PROGRAM}-err-XXXX)
akash_conf=
dockerctr=docker-docker
app_endpoint=
akash_log=.akash
key=master

function run() {
  set -o nounset 
  set -o errexit 
  set -o pipefail
  trap finish EXIT

  [[ "${url}" ]] || url=${domain}

  info "Deploying ${domain} (mirror) to Akash TestNet"
  img="${imgroot}/demo-${domain}"
  mirror_dir="${workdir}/${domain}-mirror"
  akash_conf="${workdir}/akash.yml"
  app_endpoint="${domain}.147-75-70-13.aksh.io"
  akash_log=${workdir}/${akash_log}

  checkdeps
  mirror
  makeimg
  pushimg
  checkperm
  makeconf
  deployment-create
}

function checkdeps() {
  [ -n "$(command -v httrack)" ] || abort "httrack is not found in PATH"
  [ -n "$(command -v docker)" ] || abort "docker is not found in PATH"
  [ -n "$(command -v realpath)" ] || abort "realpath is not found in PATH"
}

function dispstep() {
  log " "
  log "\t$ ${*}"
  log " "
}

function mirror() {
  log "[mirror: begin] mirroring ${url} to ${mirror_dir}"
  httrack ${url} -O ${mirror_dir} -q | debug
  log "[mirror: done] successfully mirrored ${url} -> ${mirror_dir}"
}

function makeimg() {
  log "[make-image: begin] building container ${img}"
  local mirpath="$(realpath --relative-to . ${mirror_dir}/${domain})"
  cat > ${workdir}/Dockerfile <<EOF
  FROM ${baseimg}
  ADD ${mirpath} /usr/share/nginx/html
EOF
  docker build -t ${img} . 2>&1 | debug || abort "unable to build docker image" 
  info "[make-image: done] docker image ${img} successfully built, using:"
  dispstep "docker build . -t ${img}"
}

function pushimg() {
  log "[push-image: begin] pushing ${img}"
  docker push ${img} 2>&1 | debug || abort "Unable to push image ${img}. \nEnsure you have the appropriate permissions to push image to the registry"
  info "[push-image: done] image pushed to remote repository ${img}, using:"
  dispstep "docker push ${img}"
}

function checkperm() {
  log "[check-perm: begin] verify access to image (${img})"
  docker ps -a | grep ${dockerctr} | debug \
    && docker kill ${dockerctr} | debug
  docker run --rm --privileged --name ${dockerctr} -d docker:stable-dind 2>&1 | debug
  errmsg="\nUnable to pull image (${img}).\nThe current version of AkashNet only support public images.\nPlease ensure the repository is available publicly."
  docker run --rm --link ${dockerctr}:docker docker:edge pull ${img} 2>&1 | debug || abort ${errmsg}
  log "[check-perm done]: image (${img}) is ready for deployment"
}

function makeconf() {
  log "[make-conf: begin] creating akash manifest (${akash_conf})"
  cat > ${akash_conf} <<EOF
---
services:
  web:
    image: ${img}
    expose:
      - port: 80
        as: 80
        accept:
          - ${domain}.147.75.70.13.nip.io
          - ${app_endpoint}
        to:
          - global: true

profiles:
  compute:
    web:
      cpu: "0.25"
      memory: "1024Mi"
      disk: "5Gi"
  placement:
    westcoast:
      attributes:
        region: us-west
      pricing:
        web: 100

deployment:
  web:
    westcoast:
      profile: web
      count: 1
EOF
  info "[make-conf: done] successfully creating akash manifest (${akash_conf})"
  dispstep "cat > $(realpath --relative-to . ${akash_conf}) <<EOF\n$(cat ${akash_conf})\nEOF"
}

function deployment-create() {
  log "[deployment-create: begin] deploying to akash testnet (${akash_conf})"
  akash deployment create ${akash_conf} -k ${key} -w > ${akash_log} || abort "Unable to deploy"
  info "[deployment-create: done] deployment successful ($(depid)), using:"
  dispstep "akash deployment create $(realpath --relative-to . ${akash_conf}) -k ${key} -w > $(realpath --relative-to . ${akash_log})"
}

function depid() {
  [ -f ${akash_log} ] && cat ${akash_log} | head -1
}

function debug() {
  set +o nounset
  # read stdin when piped
  if [ -z "${1}" ]; then
    while read line ; do
      if [[ "${verbose}" == "1" ]]; then
        echo >&2 -e "                 ${line}"
      else
        echo ${line} > /dev/null
      fi
    done
  else
    if [[ "${verbose}" == "1" ]]; then
      echo >&2 -e "                 ${*}"
    fi
  fi
  set -o nounset
}

function log() {
  # read stdin when piped
  set +o nounset
  if [ -z "${1}" ]; then
    while read line ; do
      echo >&2 -e "                 ${line}"
    done
  else
    echo >&2 -e "    ${PROGRAM}: ${*}"
  fi
  set -o nounset
}

function info() {
  local msg="==> ${PROGRAM}: ${*}"
  local bold=$(tput bold)
  local reset="\033[0m"
  echo -e "${bold}${msg}${reset}"
}

function info-success() {
  local msg="${*}"
  local green=$(tput setaf 2)
  local reset="\033[0m"
  echo -e "${green}${msg}${reset}"
}

function abort() {
  local red=$(tput setaf 1)
  local reset=$(tput sgr0)
  local msg="${red}$@${reset}"
  echo >&2 -e "                 ${msg}"
  exit 1
}

function parseopts() {
  # short flags
  local flags="V"
  local inputs=("$@")
  local options=()
  local arguments=()
  local values=()
  local postion=0
  let position=0
  while [ ${position} -lt ${#inputs[*]} ]; do
    local arg="${inputs[${position}]}"
    if [ "${arg:0:1}" = "-" ]; then
      # parse long options (--option=value)
      if [ "${arg:1:1}" = "-" ]; then
        local key="${arg:2}"
        local val="${key#*=}"
        local opt="${key/=${val}}"
        local values[${#options[*]}]=${val}
        local options[${#options[*]}]=${opt}
      else
        # parse short options (-o value) and 
        # stacked options (-opq val val val)
        let index=1
        while [ ${index} -lt ${#arg} ]; do
          local opt=${arg:${index}:1}
          let index+=1
          let isflag=0
          for flag in ${flags}; do
            if [ "${opt}" == "${flag}" ]; then
              let isflag=1
            fi
          done
          # skip storing the value if this it is a flag
          if [ ${isflag} == 0 ]; then
            let position+=1
            local values[${#options[*]}]=${inputs[position]}
          fi
          local options[${#options[*]}]="${opt}"
        done
      fi
    else
      # parse positional arguments
      local arguments[${#arguments[*]}]="$arg"
    fi
    let position+=1
  done


  local index=0
  for option in "${options[@]}"; do
    case "$option" in
    "h" | "help" )
      help
      exit 0
      ;;
    "v" | "version" )
      version
      exit 0
      ;;
    "d" | "dir" )
      workdir=${values[${index}]}
      ;;
    "u" | "url" )
      url=${values[${index}]}
      ;;
    "k" | "key" )
      key=${values[${index}]}
      ;;
    "i" | "image" )
      key=${values[${index}]}
      ;;
    "V" | "verbose" )
      verbose=1
      ;;
    "rm" )
      [[ "${values[${index}]}" == "false" ]] && rmfiles=0
      ;;
    * )
      echo "Usage: $(usage)" >&2
      exit 1
      ;;
    esac
    let local index+=1
  done
  
  # accept only one argument
  if [ ${#arguments[*]} -gt 1 ]; then
    echo "Usage: $(usage)" >&2
    exit 1
  fi

  domain=${arguments[0]} 
  if [ -z "${domain}" ]; then
    ${PROGRAM} --help
    exit 1
  fi
}

function finish() {
  local exitcode=$?
  local red=$(tput setaf 1)
  local reset="\033[0m"
  local msg="${red}$@${reset}"
  log "[finish: begin]"

  # stop support services
  log "[finish kill container]: ${dockerctr}"
  docker ps -a | grep ${dockerctr} | debug \
    && docker kill ${dockerctr} | debug
  
  if [ "${rmfiles}" == "1" ]; then
    # remove files
    log "removing cache under ${workdir}"
    rm -rf 
  fi
  log "[finish: done]"

  if [ ${exitcode} -eq 0 ]; then
    info-success "\nDeployment Successful"
    info-success "====================="
    info-success ""
    info-success "Endpoint:   ${app_endpoint}"
    info-success "Deployment: $(depid)"
    info-success "Manifest:   ${akash_conf}"
    info-success "Image:      ${img}"
    rm -rf ${errlog}
    exit 0
  else
    [[ -f ${errlog} ]] && echo -e "${red}$(cat ${errlog})" | log
    info "${red}Deployment Failed"
    rm -rf ${errlog}
    exit ${exitcode}
  fi
}

function usage() {
  echo "${PROGRAM} [options] DOMAIN"
}

function help() {
  version
  echo
  echo "Usage:"
  echo "  $(usage)"
  echo
  echo "Options:"
  echo "  -d DIR --dir=DIR            Stage the files in DIR. [default: ${workdir}]"
  echo "  -u URL --url=URL            Use URL if different from DOMAIN."
  echo "  -i IMAGE --image=image      Use IMAGE as tag for container. [default: ${imgroot}/demo-DOMAIN]"
  echo "  --rm=false                  Always keep the files after the run. [default: true]"
  echo "  -V --verbose                Run in verbose mode."
  echo "  -h --help                   Display this help message."
  echo "  -v --version                Display the version number."
}

function version() {
  echo "${PROGRAM} ${VERSION}"
}

parseopts "$@"
run
