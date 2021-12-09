BASE_DIRECTORY=$(shell git rev-parse --show-toplevel)
AWS_ACCOUNT_ID?=$(shell aws sts get-caller-identity --query Account --output text)
AWS_REGION?=us-west-2
IMAGE_REPO?=$(if $(AWS_ACCOUNT_ID),$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com,localhost:5000)

PROJECTS?=aws_eks-anywhere brancz_kube-rbac-proxy kubernetes-sigs_cluster-api-provider-vsphere kubernetes-sigs_cri-tools kubernetes-sigs_vsphere-csi-driver jetstack_cert-manager kubernetes_cloud-provider-vsphere plunder-app_kube-vip kubernetes-sigs_etcdadm fluxcd_helm-controller fluxcd_kustomize-controller fluxcd_notification-controller fluxcd_source-controller rancher_local-path-provisioner mrajashree_etcdadm-bootstrap-provider mrajashree_etcdadm-controller tinkerbell_cluster-api-provider-tinkerbell tinkerbell_hegel cloudflare_cfssl
BUILD_TARGETS=$(addprefix build-project-, $(PROJECTS))

EKSA_TOOLS_PREREQS=kubernetes-sigs_cluster-api kubernetes-sigs_cluster-api-provider-aws kubernetes-sigs_kind fluxcd_flux2 vmware_govmomi replicatedhq_troubleshoot
EKSA_TOOLS_PREREQS_BUILD_TARGETS=$(addprefix build-project-, $(EKSA_TOOLS_PREREQS))

ALL_PROJECTS=$(PROJECTS) $(EKSA_TOOLS_PREREQS) aws_bottlerocket-bootstrap aws_eks-anywhere-build-tooling kubernetes-sigs_image-builder

RELEASE_BRANCH?=

.PHONY: build-all-projects
build-all-projects: $(BUILD_TARGETS) aws_bottlerocket-bootstrap aws_eks-anywhere-build-tooling

.PHONY: aws_bottlerocket-bootstrap
aws_bottlerocket-bootstrap:
	$(MAKE) release -C projects/aws/bottlerocket-bootstrap

.PHONY: aws_eks-anywhere-build-tooling
aws_eks-anywhere-build-tooling: $(EKSA_TOOLS_PREREQS_BUILD_TARGETS)
	$(MAKE) release -C projects/aws/eks-anywhere-build-tooling

.PHONY: build-project-%
build-project-%:
	$(eval PROJECT_PATH=projects/$(subst _,/,$*))
	$(MAKE) release -C $(PROJECT_PATH) PROJECT_PATH=$(PROJECT_PATH)

.PHONY: release-binaries-images
release-binaries-images: build-all-projects

.PHONY: release-ovas
release-ovas:
	$(MAKE) release -C projects/kubernetes-sigs/image-builder

.PHONY: clean-project-%
clean-project-%:
	$(eval PROJECT_PATH=projects/$(subst _,/,$*))
	$(MAKE) clean -C $(PROJECT_PATH)

.PHONY: clean
clean: $(addprefix clean-project-, $(ALL_PROJECTS))
	rm -rf _output

.PHONY: add-generated-help-block-project-%
add-generated-help-block-project-%:
	$(eval PROJECT_PATH=projects/$(subst _,/,$*))
	$(MAKE) add-generated-help-block -C $(PROJECT_PATH) RELEASE_BRANCH=1-21

.PHONY: add-generated-help-block
add-generated-help-block: $(addprefix add-generated-help-block-project-, $(ALL_PROJECTS))

.PHONY: attribution-files-project-%
attribution-files-project-%:
	$(eval PROJECT_PATH=projects/$(subst _,/,$*))
	build/update-attribution-files/make_attribution.sh $(PROJECT_PATH)

.PHONY: attribution-files
attribution-files: $(addprefix attribution-files-project-, $(ALL_PROJECTS))
	cat _output/total_summary.txt

.PHONY: update-attribution-files
update-attribution-files: attribution-files
	build/update-attribution-files/create_pr.sh

.PHONY: run-target-in-docker
run-target-in-docker:
	build/lib/run_target_docker.sh $(PROJECT) $(MAKE_TARGET) $(IMAGE_REPO) $(RELEASE_BRANCH) $(ARTIFACTS_BUCKET)

.PHONY: update-attribution-checksums-docker
update-attribution-checksums-docker:
	build/lib/update_checksum_docker.sh $(PROJECT) $(IMAGE_REPO) $(RELEASE_BRANCH)

.PHONY: stop-docker-builder
stop-docker-builder:
	docker rm -f -v eks-a-builder

.PHONY: run-buildkit-and-registry
run-buildkit-and-registry:
	docker run -d --name buildkitd --net host --privileged moby/buildkit:v0.9.0-rootless
	docker run -d --name registry  --net host registry:2

.PHONY: stop-buildkit-and-registry
stop-buildkit-and-registry:
	docker rm -v --force buildkitd
	docker rm -v --force registry

.PHONY: generate
generate:
	build/lib/generate_projects_list.sh $(BASE_DIRECTORY)
