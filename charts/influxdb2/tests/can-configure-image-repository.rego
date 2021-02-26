package main

deny[msg] {
	input.kind == "StatefulSet"

	image := input.spec.template.spec.containers[0].image
	imageName := split(image, ":")[0]

	not imageName == "tests-repository"

	msg := sprintf("With values.yaml having image.repository=tests-repository; we seen an image tag of %v on the statefulset", [imageName])
}

deny[msg] {
	input.kind == "Job"

	image := input.spec.template.spec.containers[0].image
	imageName := split(image, ":")[0]

	not imageName == "tests-repository"

	msg := sprintf("With values.yaml having image.repository=tests-repository; we seen an image tag of %v on the admin setup job", [imageName])
}

deny[msg] {
	input.kind == "StatefulSet"

	image := input.spec.template.spec.containers[0].image
	imageTag := split(image, ":")[1]

	not imageTag == "2.0.2"

	msg := sprintf("With values.yaml having image.tag=2.0.2; we seen an image tag of %v on the statefulset", [imageTag])
}

deny[msg] {
	input.kind == "Job"

	image := input.spec.template.spec.containers[0].image
	imageTag := split(image, ":")[1]

	not imageTag == "2.0.2"

	msg := sprintf("With values.yaml having image.tag=2.0.2; we seen an image tag of %v on the admin setup job", [imageTag])
}
