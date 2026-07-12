terraform_init() {
    terraform -chdir="$1" init
}

terraform_validate() {
    terraform -chdir="$1" validate
}

terraform_apply() {
    terraform -chdir="$1" apply -auto-approve
}

terraform_destroy() {
    terraform -chdir="$1" destroy -auto-approve
}

terraform_output() {
    terraform -chdir="$1" output -raw "$2"
}
