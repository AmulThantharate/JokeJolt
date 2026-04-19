package main

import rego.v1

deny contains msg if {
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("Use of latest tag is not allowed for image %s", [container.image])
}

deny contains msg if {
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot
    msg := sprintf("Container %s is not running as non root", [container.name])
}