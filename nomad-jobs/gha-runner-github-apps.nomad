job "github_runner" {
    datacenters = ["dc1"]
    type = "batch"

    parameterized {
        payload = "forbidden"
        meta_required = ["GH_REPO_URL"]
    }

    vault {
        policies = ["github-hashicorp-demo"]
        change_mode   = "signal"
        change_signal = "SIGINT"
    }

    group "runners" {

        task "init" {
            lifecycle {
                hook = "prestart"
            }

            driver = "exec"

            # fetch secrets from Vault KV secret engine
            template {
                destination = "local/key.pem"
                data = <<EOF
{{with secret "demos-secret/data/github-hashicorp-demo"}}{{- index .Data.data "gh-app-private-key" -}}{{end}}
                EOF
            }

            template {
                env = true
                destination = "${NOMAD_SECRETS_DIR}/secrets.env"
                data = <<EOF
                    GH_APP_ID = "{{with secret "demos-secret/data/github-hashicorp-demo"}}{{index .Data.data "gh-app-id"}}{{end}}"
                    GH_APP_INSTALL_ID = "{{with secret "demos-secret/data/github-hashicorp-demo"}}{{index .Data.data "gh-app-install-id"}}{{end}}"
                EOF
            }

            # generate a shor-lived GitHub token using your custom GitHub Apps
            # See also: https://github.com/myoung34/docker-github-actions-runner/pull/205
            config {
                command = "/bin/bash"
                args = [
                    "-c",
                    "echo -n \"ACCESS_TOKEN=\" > ${NOMAD_ALLOC_DIR}/gh_token.txt && curl -s -L -o ./gha-token.tar.gz https://github.com/slawekzachcial/gha-token/releases/download/1.1.0/gha-token_1.1.0_linux_amd64.tar.gz && tar -xf gha-token.tar.gz && chmod +x ./gha-token && ./gha-token -a ${GH_APP_ID} -k local/key.pem -i ${GH_APP_INSTALL_ID} >> ${NOMAD_ALLOC_DIR}/gh_token.txt"
                ]
            }
        }

        task "runner" {
            driver = "docker"

            # use the generated token in the init task to register a new runner
            template {
                env = true
                destination = "secrets/token.env"
                source = "${NOMAD_ALLOC_DIR}/gh_token.txt"
            }

            env {
                EPHEMERAL           = "true"
                DISABLE_AUTO_UPDATE = "true"
                RUNNER_NAME_PREFIX  = "gh-runner"
                RUNNER_WORKDIR      = "/tmp/runner/work"
                RUNNER_SCOPE        = "repo"
                REPO_URL            = "${NOMAD_META_GH_REPO_URL}"
                LABELS              = "linux-x86,t2-micro"
            }

            config {
                image = "myoung34/github-runner:latest"
                
                privileged  = true
                userns_mode = "host"

                # Allow DooD (Docker outside of Docker)
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock",
                ]
            }
        }
    }
}