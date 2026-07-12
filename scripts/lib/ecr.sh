ecr_login() {

    local registry=$1

    aws ecr get-login-password \
        --region "$AWS_REGION" |
        docker login \
        --username AWS \
        --password-stdin "$registry"

}