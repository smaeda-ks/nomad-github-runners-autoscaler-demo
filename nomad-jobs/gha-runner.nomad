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
        task "runner" {
            driver = "docker"

            # fetch secrets from Vault KV secret engine
            template {
                env = true
                destination = "secret/vault.env"
                data = <<EOF
                    ACCESS_TOKEN = "{{with secret "demos-secret/data/github-hashicorp-demo"}}{{index .Data.data "github-pat"}}{{end}}"
                EOF
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