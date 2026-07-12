ecs_wait() {

    aws ecs wait services-stable \
        --cluster "$1" \
        --services "$2" \
        --region "$AWS_REGION"

}

ecs_scale() {

    aws ecs update-service \
        --cluster "$1" \
        --service "$2" \
        --desired-count "$3" \
        --region "$AWS_REGION"

}