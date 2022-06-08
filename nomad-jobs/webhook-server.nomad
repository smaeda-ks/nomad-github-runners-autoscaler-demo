job "gh_webhook_server" {
    datacenters = ["dc1"]
    type        = "service"

    vault {
        policies    = ["github-hashicorp-demo"]
        change_mode = "noop"
    }

    group "server" {
        count = 1
        network {
            port "http" {
                static = 8080
            }
        }
        task "app" {
            driver = "docker"

            # fetch secrets from Vault KV secret engine
            template {
                env         = true
                destination = "secret/gh-webhook-server.env"
                data        = <<EOF
                    NOMAD_TOKEN = "{{with secret "demos-secret/data/github-hashicorp-demo"}}{{index .Data.data "nomad-token"}}{{end}}"
                    GH_WEBHOOK_SECRET = "{{with secret "demos-secret/data/github-hashicorp-demo"}}{{index .Data.data "github-webhook-secret"}}{{end}}"
                EOF
            }

            env {
                PORT         = "8080"
                NOMAD_HOST   = "http://${NOMAD_IP_http}:4646"
                NOMAD_JOB_ID = "github_runner"
            }

            config {
                image = "jrsyo/nomad-github-runners-autoscaler:alpha"
                ports = [
                    "http",
                ]
            }
        }
    }
}