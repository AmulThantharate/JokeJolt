package main 


deny[msg] {
    container := input.spec.template.container[_]
    endswith(container.image, ":latest")
    msg := sprintf("Use of latest tag is not allowed for image %s", [container.image])
}

deny[msg] {
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot
    msg := sprintf("Container %s is not running as non root", [container.name])
}

deny[msg] {
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot
    msg := sprintf("Container %s is not running as non root", [container.name])
}