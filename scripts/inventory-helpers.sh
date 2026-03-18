#!/bin/bash
# Quick reference commands for homelab inventory management

# Test connectivity to all hosts
test-all() {
  ansible all -i inventory/hosts.yml -m ping
}

# Test connectivity to specific group
test-group() {
  local group="${1:?Group name required}"
  ansible "$group" -i inventory/hosts.yml -m ping
}

# List all hosts in inventory
list-hosts() {
  ansible-inventory -i inventory/hosts.yml --list | jq '.all.hosts | keys'
}

# List hosts in a group
list-group() {
  local group="${1:?Group name required}"
  ansible-inventory -i inventory/hosts.yml -y | grep -A 100 "^  $group:" | grep "^\s*[a-z]" | head -n 20
}

# Show facts about a host
show-facts() {
  local host="${1:?Host name required}"
  ansible "$host" -i inventory/hosts.yml -m setup | jq '.ansible_facts'
}

# Get service status on a host
service-status() {
  local host="${1:?Host name required}"
  ansible "$host" -i inventory/hosts.yml -m service -a "name=*" --become
}

# Run ad-hoc command
run-command() {
  local group="${1:?Group name required}"
  local cmd="${2:?Command required}"
  ansible "$group" -i inventory/hosts.yml -m shell -a "$cmd"
}

# Edit vault
edit-vault() {
  ansible-vault edit inventory/group_vars/all/vault.yml
}

# View vault
view-vault() {
  ansible-vault view inventory/group_vars/all/vault.yml
}

# Validate inventory
validate-inventory() {
  echo "Validating inventory..."
  ansible-inventory -i inventory/hosts.yml --list > /dev/null && echo "✓ Inventory is valid"
}

# Syntax check all playbooks
check-playbooks() {
  echo "Checking playbook syntax..."
  for playbook in playbooks/*.yml; do
    echo "  Checking: $playbook"
    ansible-playbook -i inventory/hosts.yml "$playbook" --syntax-check
  done
}

# Show inventory stats
inventory-stats() {
  echo "=== Homelab Inventory Statistics ==="
  echo ""
  echo "Total hosts: $(ansible-inventory -i inventory/hosts.yml --list | jq '.all.hosts | length')"
  echo ""
  echo "Groups:"
  ansible-inventory -i inventory/hosts.yml --list | jq -r '.all.children[]'
  echo ""
  echo "Host by group:"
  for group in $(ansible-inventory -i inventory/hosts.yml --list | jq -r '.all.children[]'); do
    count=$(ansible-inventory -i inventory/hosts.yml -y | grep -A 100 "^  $group:" | grep -c "^\s*[a-z]" || echo "0")
    echo "  $group: $count hosts"
  done
}

# Print usage
case "${1:-help}" in
  help)
    echo "Homelab Inventory Management Commands"
    echo ""
    echo "Usage: source scripts/inventory-helpers.sh"
    echo ""
    echo "Commands:"
    echo "  test-all              - Test connectivity to all hosts"
    echo "  test-group <group>    - Test connectivity to a group"
    echo "  list-hosts            - List all hosts"
    echo "  list-group <group>    - List hosts in a group"
    echo "  show-facts <host>     - Show facts about a host"
    echo "  service-status <host> - Show service status on a host"
    echo "  run-command <group> <cmd> - Run command on a group"
    echo "  edit-vault            - Edit vault file"
    echo "  view-vault            - View vault file"
    echo "  validate-inventory    - Validate inventory syntax"
    echo "  check-playbooks       - Check all playbook syntax"
    echo "  inventory-stats       - Show inventory statistics"
    ;;
esac
