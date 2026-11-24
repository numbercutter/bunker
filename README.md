<p align="center"><img src="assets/banner.svg" alt="bunker" width="640"></p>

**Your AI, behind your walls.**

bunker runs a private AI stack (Ollama, Open WebUI, Qdrant and Postgres) with one command on a Docker network that has no route to the internet. The chat UI is reachable only from your own machine, and `bunker check` proves the core network is sealed.

## Quick start

Needs Docker with the Compose plugin.

```sh
git clone https://github.com/numbercutter/bunker && cd bunker
./bunker up                      # writes .env with fresh secrets, starts the stack
./bunker pull llama3.2:3b        # a chat model
./bunker pull nomic-embed-text   # embeddings for document search
./bunker check                   # PASS means the core network is sealed
```

Open http://127.0.0.1:3000 and create the first account (it becomes the admin).

## Usage

```
bunker up              start the stack (creates .env on first run)
bunker down            stop the stack, keep data
bunker status          containers and installed models
bunker pull <model>    download a model into the shared volume
bunker check           prove the core network has no outbound route
bunker logs [service]  follow logs
```

`examples/first-run.sh` runs the full sequence and asks the model one question.

## How it works

| network | members | internet |
|---|---|---|
| `bunker_core` (`internal: true`) | ollama, qdrant, postgres, open-webui | none |
| `bunker_edge` | open-webui | yes, used only to publish `127.0.0.1:3000` |

- Ollama, Qdrant and Postgres sit only on `bunker_core`. Docker creates internal networks without a gateway, so these containers cannot open a connection outside the host.
- Open WebUI joins both networks so its port can be published, bound to `127.0.0.1` only. Its offline settings are on (`OFFLINE_MODE`, `HF_HUB_OFFLINE`, no OpenAI API, no web search, no update check, no telemetry) and embeddings come from Ollama, not a Hugging Face download.
- Model downloads need the internet, so `bunker pull` starts a temporary Ollama container on Docker's default network, writes into the `bunker_models` volume the stack uses, and exits. The running stack never gains a route out.
- `bunker check` starts a throwaway Alpine container on `bunker_core` and tries `http://1.1.1.1` and `http://example.com`. It reports PASS only if the network is marked internal and both attempts fail.
- Every image is pinned to a version tag. Upgrading is a deliberate edit to `docker-compose.yml`.

## Limits

What "no outbound access" covers: containers that sit only on `bunker_core` cannot reach the internet or your LAN over IP, and DNS names outside the stack do not resolve.

What it does not cover:

- **Open WebUI can reach out.** It is on `bunker_edge` to publish its port, and that network has a normal gateway. Its offline settings stop the outbound calls it knows about, but code paths, plugins or tools you install in it are not network-restricted. If that matters, put a small reverse proxy on the edge network instead and keep Open WebUI on `bunker_core` only.
- **The host is not sealed.** Anything running on your machine, including Docker itself pulling images, still has internet access. bunker isolates containers, not the computer.
- **Pulls trust the source.** `bunker pull` downloads from the Ollama registry. Check what you pull.
- **`check` is a probe, not a proof.** It tests two destinations on two protocols from one container. It does not audit firewall rules, IPv6 settings or other Docker networks you attach later.
- **Local access is not authentication.** Anyone with a shell on this machine can open `127.0.0.1:3000`. Open WebUI's own accounts are the only gate.
- No GPU passthrough is configured. On Linux with an NVIDIA GPU, add a `deploy.resources.reservations.devices` block to the `ollama` service.

<sub>A numbercutter instrument · MIT</sub>
