#!/usr/bin/env bash
###############################################################################
# python_tools.sh
#
# BitCurator's Python-based forensics tools, ported from bitcurator-salt's
# bitcurator/python-packages/*.sls. Each tool gets its own venv under /opt
# (exactly upstream's own pattern: an isolated venv per tool avoids the pip
# dependency conflicts a single shared environment would hit) with a symlink
# into /usr/local/bin. See vendor/NOTICE.md.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[BITCURATOR-PYTHON] $*"; }
try() { "$@" || log "WARNING: '$*' failed - continuing (best-effort build)."; }

make_venv() {
  local dir="$1"
  rm -rf "$dir"
  python3 -m venv "$dir"
  "$dir/bin/pip" install --upgrade \
    "pip>=24.1.3" "setuptools>=70.0.0" "wheel>=0.38.4" "importlib-metadata>=8.0.0"
}

install_analyzemft() {
  log "Installing analyzeMFT..."
  local commit=b1d0e6a0aa58d42000bfdb8e6588513bd62eaeab
  make_venv /opt/analyzemft
  /opt/analyzemft/bin/pip install --upgrade \
    "git+https://github.com/rowingdude/analyzemft.git@${commit}"
  ln -sf /opt/analyzemft/bin/analyzemft /usr/local/bin/analyzemft
}

install_bagit() {
  log "Installing bagit..."
  make_venv /opt/bagit
  /opt/bagit/bin/pip install --upgrade bagit
  ln -sf /opt/bagit/bin/bagit.py /usr/local/bin/bagit.py
}

install_brunnhilde() {
  log "Installing brunnhilde..."
  make_venv /opt/brunnhilde
  /opt/brunnhilde/bin/pip install --upgrade brunnhilde
  ln -sf /opt/brunnhilde/bin/brunnhilde.py /usr/local/bin/brunnhilde.py
}

install_opf_fido() {
  log "Installing OPF fido..."
  make_venv /opt/fido
  /opt/fido/bin/pip install --upgrade opf-fido
  ln -sf /opt/fido/bin/fido /usr/local/bin/fido
}

install_python_evtx() {
  log "Installing python-evtx..."
  local commit=1a1357accd3a75524794a6d6dcdec03c09e1660d
  make_venv /opt/python-evtx
  /opt/python-evtx/bin/pip install --upgrade xmltodict lxml
  /opt/python-evtx/bin/pip install --upgrade \
    "git+https://github.com/williballenthin/python-evtx.git@${commit}"
  local pyver
  pyver="$(/opt/python-evtx/bin/python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
  local fix_target="/opt/python-evtx/lib/python${pyver}/site-packages/evtx_scripts/evtx_eid_record_numbers.py"
  [ -f "$fix_target" ] && sed -i 's/from filter_records/from evtx_scripts.evtx_filter_records/' "$fix_target"
  local f
  for f in evtx_dump evtx_dump_chunk_slack evtx_dump_json evtx_eid_record_numbers \
           evtx_extract_record evtx_filter_records evtx_info evtx_record_structure \
           evtx_structure evtx_templates; do
    [ -x "/opt/python-evtx/bin/${f}" ] && ln -sf "/opt/python-evtx/bin/${f}" "/usr/local/bin/${f}.py"
  done
}

install_bitcurator_python_tools() {
  log "Installing bitcurator-python-tools..."
  make_venv /opt/bitcurator-python-tools
  /opt/bitcurator-python-tools/bin/pip install --upgrade \
    "git+https://github.com/bitcurator/bitcurator-python-tools.git"
  ln -sf /opt/bitcurator-python-tools/bin/identify-filenames /usr/local/bin/identify_filenames.py
  local f
  for f in build-stoplist bulk-diff cda-tool cda2-tool identify-filenames \
           post-process-exif walk_to_dfxml make_differential_dfxml; do
    [ -x "/opt/bitcurator-python-tools/bin/${f}" ] && \
      ln -sf "/opt/bitcurator-python-tools/bin/${f}" "/usr/local/bin/${f}"
  done
}

install_imagemounter() {
  log "Installing imagemounter..."
  apt_install afflib-tools avfs disktype libbde-utils libewf libewf-dev \
    libvshadow-utils ntfs-3g python3-tsk qemu-utils sleuthkit testdisk \
    vmfs-tools xfsprogs xmount libguestfs-tools mtd-utils squashfs-tools \
    git build-essential python3-dev
  make_venv /opt/imagemounter
  /opt/imagemounter/bin/pip install --upgrade "python-magic>=0.4.27" "pytsk3>=20231007"
  /opt/imagemounter/bin/pip install --upgrade imagemounter
  ln -sf /opt/imagemounter/bin/imount /usr/local/bin/imount
}

main() {
  apt_update_if_needed
  apt_install python3 python3-venv python3-pip

  try install_analyzemft
  try install_bagit
  try install_brunnhilde
  try install_opf_fido
  try install_python_evtx
  try install_bitcurator_python_tools
  try install_imagemounter

  log "Python tool venvs complete."
}

main "$@"
